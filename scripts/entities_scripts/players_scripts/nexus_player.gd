extends CharacterBody2D

# NEXUS PLAYER

# ..............................................................................

#region CONSTANTS

const BASE_SPEED: float = 150.0
const MAX_SPEED: float = 300.0
const SNAP_SPEED: float = 600.0

#endregion

# ..............................................................................

#region VARIABLES

var on_node: bool = false
var snapping: bool = false

var speed: float = BASE_SPEED

var move_direction: Vector2 = Vector2.ZERO
var snap_position: Vector2 = Vector2.ZERO

@onready var nexus: Node2D = get_parent()

@onready var nexus_player_outline_node: Sprite2D = $PlayerOutline
@onready var nexus_player_crosshair_node: Sprite2D = $PlayerCrosshair

#endregion

# ..............................................................................

#region READY

func _ready() -> void:
	set_physics_process(false)

#endregion

# ..............................................................................

#region PHYSICS PROCESS

func _physics_process(_delta: float) -> void:
	# deccelerate towards target position while snapping
	if snapping:
		# deccelerate if remaining distance is larger than 1 pixel
		var snap_distance := position.distance_to(snap_position)
		if snap_distance > 1:
			velocity = snap_distance * SNAP_SPEED * move_direction / 40
		# else snap and stop moving	
		else:
			velocity = Vector2.ZERO
			snapping = false
			on_node = true
			position = snap_position

			# update nexus player texture
			nexus_player_outline_node.show()
			nexus_player_crosshair_node.hide()
			# update nexus ui
			nexus.ui.update_nexus_ui()

			move_direction = Input.get_vector(&"left", &"right", &"up", &"down", 0.2)
			if move_direction == Vector2.ZERO:
				set_physics_process(false)
	else:
		# acceleration
		if speed < MAX_SPEED:
			speed += 1.0

		# update velocity
		velocity = move_direction * speed

	move_and_slide()

#endregion

# ..............................................................................

#region INPUTS

func _input(event: InputEvent) -> void:
	# ignore all unrelated inputs
	if not (event.is_action(&"left") or event.is_action(&"right") \
			or event.is_action(&"up") or event.is_action(&"down")):
		return
	
	Inputs.accept_event()
	
	if not (
			Input.is_action_just_pressed(&"left")
			or Input.is_action_just_pressed(&"right")
			or Input.is_action_just_pressed(&"up")
			or Input.is_action_just_pressed(&"down")
			or Input.is_action_just_released(&"left")
			or Input.is_action_just_released(&"right")
			or Input.is_action_just_released(&"up")
			or Input.is_action_just_released(&"down")
	):
		return
	
	if snapping:
		return

	move_direction = Input.get_vector(&"left", &"right", &"up", &"down", 0.2)

	if move_direction == Vector2.ZERO:
		if on_node:
			set_physics_process(false)
		else:
			speed = BASE_SPEED
			snap_to_nearby(position)
	else:
		on_node = false
		nexus.ui.hide_all()
		nexus_player_outline_node.hide()
		nexus_player_crosshair_node.show()
		set_physics_process(true)

#endregion

# ..............................................................................

func snap_to_nearby(initial_position):
	# calculates and chooses a nearby node
	var temp_near: int = (round((initial_position.y + 298.0) / 596 * 48) * 16) + (round((initial_position.x + 341.0) / 683 * 16))

	# clamp to closest valid node
	if temp_near < 0:
		temp_near = clamp((temp_near + 16), 0, 767)
	elif temp_near > 767:
		temp_near = clamp((temp_near - 16), 0, 767)
	
	var snap_distance := INF
	var snap_node: TextureRect = null

	if nexus.nexus_nodes[temp_near].texture.region.position != nexus.NULL_ATLAS_POSITION:
		snap_node = nexus.nexus_nodes[temp_near]
		snap_distance = initial_position.distance_to(nexus.nexus_nodes[temp_near].position + Vector2(16, 16))
	else:
		snap_node = null
		snap_distance = INF

	for temp_adjacent in nexus.get_adjacents(temp_near).duplicate():
		if initial_position.distance_to(nexus.nexus_nodes[temp_adjacent].position + Vector2(16, 16)) < snap_distance and nexus.nexus_nodes[temp_adjacent].texture.region.position != nexus.NULL_ATLAS_POSITION:
			snap_node = nexus.nexus_nodes[temp_adjacent]
			snap_distance = initial_position.distance_to(nexus.nexus_nodes[temp_adjacent].position + Vector2(16, 16))
		
		for second_temp_adjacent in nexus.get_adjacents(temp_adjacent):
			if initial_position.distance_to(nexus.nexus_nodes[second_temp_adjacent].position + Vector2(16, 16)) < snap_distance and nexus.nexus_nodes[second_temp_adjacent].texture.region.position != nexus.NULL_ATLAS_POSITION:
				snap_node = nexus.nexus_nodes[second_temp_adjacent]
				snap_distance = initial_position.distance_to(nexus.nexus_nodes[second_temp_adjacent].position + Vector2(16, 16))

	snap_position = snap_node.position + Vector2(16, 16)
	move_direction = (snap_position - initial_position).normalized()

	nexus.current_stats.last_node = snap_node.get_index()

	snapping = true

	nexus.ui.hide_all()

func snap_to_position(target_position) -> void:
	position = target_position
	snapping = false
	$PlayerOutline.show()
	$PlayerCrosshair.hide()
