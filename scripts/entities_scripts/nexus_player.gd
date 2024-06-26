extends CharacterBody2D

var move_direction = Vector2.ZERO
var speed = 150
var speed_max = 300

@onready var nexus = get_parent()

var on_node = false
var snapping = false

var snap_node = null
var snap_speed = 600
var snap_position = Vector2.ZERO
var snap_direction = Vector2.ZERO
var temp_snap_distance = 0
var snap_distance = 100000

var nodes_on_screen = []

const adjacents_index = [[ - 64, - 49, - 48, - 33, - 32, - 31, - 17, - 16, - 1, 1, 15, 16, 31, 32, 33, 47, 48, 64],
						 [- 64, - 48, - 47, - 33, - 32, - 31, - 16, - 15, - 1, 1, 16, 17, 31, 32, 33, 48, 49, 64]]

# func _ready():
	# for button in nexus_node.get_children(): nodes_on_screen.push_back(button)

func _physics_process(_delta):
	# print(position)
	# GlobalSettings.players[GlobalSettings.current_main_player].get_node("Camera2D").enabled = false
	# get_node("Camera2D").make_current()
	# get_node("Camera2D").position = position
	# print(get_node("Camera2D").is_current())

	if snapping:
		snap_distance = position.distance_to(snap_position)
		if snap_distance > 1:
			velocity = snap_distance * snap_speed * snap_direction / 40
		else:
			print("hi")
			velocity = Vector2.ZERO
			snapping = false
			on_node = true
			nexus.last_node[nexus.current_nexus_player] = snap_node.get_index()
			position = snap_position

			$Sprite2D.show()
			$Sprite2D2.hide()
	else:
		move_direction = Input.get_vector("left", "right", "up", "down")
		velocity = move_direction * speed
		if !on_node&&velocity == Vector2.ZERO:
			speed = 150
			snap_to_target(position)
		elif velocity != Vector2.ZERO:
			if speed < speed_max: speed += 1
			if on_node:
				on_node = false
				$Sprite2D.hide()
				$Sprite2D2.show()

	move_and_slide()

##### need to make snapping toggleable
func snap_to_target(initial_position):
	var temp_rand = (round((initial_position.y + 298.0) / 596 * 48) * 16) + (round((initial_position.x + 341.0) / 683 * 16))
	var temp_adjacents
	var second_temp_adjacents

	if temp_rand < 0: temp_rand += 16
	elif temp_rand > 767:
		temp_rand -= 16
		if temp_rand > 767: temp_rand -= 1

	if fmod(temp_rand, 32) < 16:
		temp_adjacents = [temp_rand - 32, temp_rand - 17, temp_rand - 16, temp_rand + 15, temp_rand + 16, temp_rand + 32]
	else:
		temp_adjacents = [temp_rand - 32, temp_rand - 16, temp_rand - 15, temp_rand + 16, temp_rand + 17, temp_rand + 32]

	snap_node = nexus.nexus_nodes[temp_rand]
	snap_distance = initial_position.distance_to(nexus.nexus_nodes[temp_rand].position + Vector2(16, 16))

	for temp_next in temp_adjacents: if (temp_next > - 1)&&(temp_next < 767):
		if fmod(temp_next, 32) < 16:
			second_temp_adjacents = [temp_next - 32, temp_next - 17, temp_next - 16, temp_next + 15, temp_next + 16, temp_next + 32]
		else:
			second_temp_adjacents = [temp_next - 32, temp_next - 16, temp_next - 15, temp_next + 16, temp_next + 17, temp_next + 32]
		
		if initial_position.distance_to(nexus.nexus_nodes[temp_next].position + Vector2(16, 16)) < snap_distance:
			snap_node = nexus.nexus_nodes[temp_next]
			snap_distance = initial_position.distance_to(nexus.nexus_nodes[temp_next].position + Vector2(16, 16))
		
		for second_temp_next in second_temp_adjacents: if (second_temp_next > - 1)&&(second_temp_next < 767):
			if initial_position.distance_to(nexus.nexus_nodes[second_temp_next].position + Vector2(16, 16)) < snap_distance:
				snap_node = nexus.nexus_nodes[second_temp_next]
				snap_distance = initial_position.distance_to(nexus.nexus_nodes[second_temp_next].position + Vector2(16, 16))

	snap_position = snap_node.position + Vector2(16, 16)
	snap_direction = (snap_position - initial_position).normalized()

	snapping = true

func snap_to_pressed(recent_emitter):
	var temp_node_index = recent_emitter.get_index()
	var temp_adjacents = [temp_node_index - 32, temp_node_index - 16, temp_node_index - 15, temp_node_index + 15, temp_node_index + 16, temp_node_index + 32]
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
