extends CharacterBody2D

var move_direction = Vector2.ZERO
var speed = 150

var last_node = null # #### set this to default node

@onready var nexus_node = get_parent().get_node("Control")
@onready var player_node = get_parent().get_node("NexusPlayer")
var on_node = true
var snapping = false
var snap_ready = true
var snap_node = null
var snap_speed = 600
var snap_position = Vector2.ZERO
var snap_direction = Vector2.ZERO
var temp_snap_distance = 0
var snap_distance = 100000
var snap_texture = null
var snap_region = Rect2(Vector2.ZERO, Vector2.ZERO)
var warping = true

var nodes_on_screen = []

func _ready():
	for button in nexus_node.get_children(): nodes_on_screen.push_back(button)

func _physics_process(_delta):
	if snapping:
		print("hi")
		snap_distance = position.distance_to(snap_position)
		print(snap_distance)
		if snap_distance > 8:
			velocity = snap_distance * snap_speed * snap_direction / 40
		else:
			print("done")
			snapping = false
			player_node.hide()
			snap_region = snap_texture.get_region()
			snap_texture.set_region(Rect2(snap_region.position + Vector2(32, 0), snap_region.size))
	else:
		move_direction = Input.get_vector("left", "right", "up", "down")
		velocity = move_direction * speed
		if velocity == Vector2.ZERO&&snap_ready: snap_to_nearest()
		elif !snap_ready&&velocity != Vector2.ZERO:
			snap_ready = true
			snap_region = snap_texture.get_region()
			snap_texture.set_region(Rect2(snap_region.position + Vector2( - 32, 0), snap_region.size))
			player_node.show()

	move_and_slide()

#make snapping toggleable
func snap_to_nearest():
	snap_position = Vector2.ZERO
	snap_distance = 100000

	for i in nodes_on_screen:
		temp_snap_distance = position.distance_to(i.position)
		if snap_distance > temp_snap_distance:
			snap_distance = temp_snap_distance
			print(i)
			snap_node = i

	snap_position = snap_node.position + Vector2(16, 16)
	snap_direction = (snap_position - position).normalized()
	snap_texture = snap_node.texture_normal
	snapping = true
	snap_ready = false

func _on_texture_button_pressed(extra_arg_0):
	print(extra_arg_0)
	snap_node = get_node(extra_arg_0)
	print(snap_node)
	snap_distance = position.distance_to(snap_node.position)
	snap_position = snap_node.position + Vector2(16, 16)
	snap_direction = (snap_position - position).normalized()
	snap_texture = snap_node.texture_normal
	snapping = true
	snap_ready = false
