extends CharacterBody2D

@onready var nexus := get_parent()
@onready var nexus_ui_node := nexus.get_node("HoloNexusUI")

@onready var character_index: int = GlobalSettings.current_main_player_node.character_specifics_node.character_index

var move_direction := Vector2.ZERO
var speed := 150.0
const speed_max := 300

var on_node := false
var snapping := false

var snap_node: Node = null
const snap_speed := 600.0
var snap_position := Vector2.ZERO
var snap_direction := Vector2.ZERO
var temp_snap_distance := 0.0
var snap_distance := INF

var nodes_on_screen: Array[Node] = []

const adjacents_index: Array[Array] = [[-64, -49, -48, -33, -32, -31, -17, -16, -1, 1, 15, 16, 31, 32, 33, 47, 48, 64],
									   [-64, -48, -47, -33, -32, -31, -16, -15, -1, 1, 16, 17, 31, 32, 33, 48, 49, 64]]

func _physics_process(_delta):
	GlobalSettings.camera_node.reparent(self)
	GlobalSettings.camera_node.position = Vector2(0, 0)

	if snapping:
		snap_distance = position.distance_to(snap_position)
		if snap_distance > 1:
			velocity = snap_distance * snap_speed * snap_direction / 40
		else:
			velocity = Vector2.ZERO
			snapping = false
			on_node = true
			nexus.last_nodes[nexus.current_nexus_player] = snap_node.get_index()
			position = snap_position

			$Sprite2D.show()
			$Sprite2D2.hide()

			nexus_ui_node.update_nexus_ui()
	else:
		move_direction = Input.get_vector("left", "right", "up", "down")
		velocity = move_direction * speed
		if !on_node && velocity == Vector2.ZERO:
			speed = 150
			snap_to_target(position)
		elif velocity != Vector2.ZERO:
			nexus_ui_node.hide_all()
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

	if nexus.nexus_nodes[temp_rand].texture.region.position != nexus.null_node_atlas_position:
		snap_node = nexus.nexus_nodes[temp_rand]
		snap_distance = initial_position.distance_to(nexus.nexus_nodes[temp_rand].position + Vector2(16, 16))
	else:
		snap_node = null
		snap_distance = INF

	for temp_next in temp_adjacents: if (temp_next > -1) && (temp_next < 768):
		if fmod(temp_next, 32) < 16:
			second_temp_adjacents = [temp_next - 32, temp_next - 17, temp_next - 16, temp_next + 15, temp_next + 16, temp_next + 32]
		else:
			second_temp_adjacents = [temp_next - 32, temp_next - 16, temp_next - 15, temp_next + 16, temp_next + 17, temp_next + 32]
		
		if initial_position.distance_to(nexus.nexus_nodes[temp_next].position + Vector2(16, 16)) < snap_distance && nexus.nexus_nodes[temp_next].texture.region.position != nexus.null_node_atlas_position:
			snap_node = nexus.nexus_nodes[temp_next]
			snap_distance = initial_position.distance_to(nexus.nexus_nodes[temp_next].position + Vector2(16, 16))
		
		for second_temp_next in second_temp_adjacents: if (second_temp_next > -1) && (second_temp_next < 768):
			if initial_position.distance_to(nexus.nexus_nodes[second_temp_next].position + Vector2(16, 16)) < snap_distance && nexus.nexus_nodes[second_temp_next].texture.region.position != nexus.null_node_atlas_position:
				snap_node = nexus.nexus_nodes[second_temp_next]
				snap_distance = initial_position.distance_to(nexus.nexus_nodes[second_temp_next].position + Vector2(16, 16))

	snap_position = snap_node.position + Vector2(16, 16)
	snap_direction = (snap_position - initial_position).normalized()

	snapping = true

	nexus_ui_node.hide_all()

func snap_to_pressed(recent_emitter):
	var temp_node_index = recent_emitter.get_index()
	var temp_adjacents = [temp_node_index - 32, temp_node_index - 16, temp_node_index - 15, temp_node_index + 15, temp_node_index + 16, temp_node_index + 32]
	var temp_distance = INF
	var temp_node = null
	for node in temp_adjacents:
		if node > -1:
			var second_temp_distance = (nexus.nexus_nodes[node].position + Vector2(16, 16)).distance_to(recent_emitter.position + Vector2(16, 16))
			if temp_distance > second_temp_distance:
				temp_node = nexus.nexus_nodes[node]
				temp_distance = second_temp_distance

	snap_node = temp_node
	snap_position = recent_emitter.position + Vector2(16, 16)
	snap_distance = position.distance_to(snap_position)
	snap_direction = (snap_position - position).normalized()

	snapping = true

func update_nexus_player(target_character_index):
	position = nexus.nexus_nodes[nexus.last_nodes[target_character_index]].position + Vector2(16, 16)