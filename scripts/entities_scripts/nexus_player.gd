extends CharacterBody2D

var move_direction = Vector2.ZERO
var speed = 150

@onready var nexus = get_parent()
@onready var player_node = nexus.get_node("NexusPlayer")

var on_node = false
var snapping = false

var snap_node = null
var snap_speed = 600
var snap_position = Vector2.ZERO
var snap_direction = Vector2.ZERO
var temp_snap_distance = 0
var snap_distance = 100000

var nodes_on_screen = []

# func _ready():
	# for button in nexus_node.get_children(): nodes_on_screen.push_back(button)

func _physics_process(_delta):
	if snapping:
		snap_distance = position.distance_to(snap_position)
		if snap_distance > 1:
			velocity = snap_distance * snap_speed * snap_direction / 40
		else:
			snapping = false
			on_node = true
			nexus.recent_node[nexus.current_nexus_player] = snap_node
			player_node.position = snap_position
			# player_node.hide()
	else:
		move_direction = Input.get_vector("left", "right", "up", "down")
		velocity = move_direction * speed
		if !on_node&&velocity == Vector2.ZERO: snap_to_nearest()
		elif on_node&&velocity != Vector2.ZERO:
			on_node = false
			player_node.show()

	move_and_slide()

##### need to make snapping toggleable
func snap_to_nearest():
	snap_position = Vector2.ZERO
	snap_distance = 100000

	##### should only consider nearby nodes instead of all
	for node in get_parent().nexus_nodes:
		temp_snap_distance = position.distance_to(node.position + Vector2(16, 16))
		if snap_distance > temp_snap_distance:
			snap_distance = temp_snap_distance
			snap_node = node

	snap_position = snap_node.position + Vector2(16, 16)
	snap_direction = (snap_position - position).normalized()

	snapping = true

func snap_to_pressed(recent_emitter):
	var temp_node_index = recent_emitter.get_index()
	var temp_adjacents = [temp_node_index - 8, temp_node_index - 4, temp_node_index - 3, temp_node_index + 4, temp_node_index + 5, temp_node_index + 8]
	var temp_distance = 100000
	var temp_node = null
	for node in temp_adjacents:
		if node > - 1:
			var second_temp_distance = (nexus.nexus_nodes[node].position + Vector2(16, 16)).distance_to(recent_emitter.position + Vector2(16, 16))
			if temp_distance > second_temp_distance:
				temp_node = nexus.nexus_nodes[node]
				temp_distance = second_temp_distance

	snap_node = temp_node
	snap_position = recent_emitter.position + Vector2(16, 16)
	snap_distance = position.distance_to(snap_position)
	snap_direction = (snap_position - position).normalized()

	snapping = true
