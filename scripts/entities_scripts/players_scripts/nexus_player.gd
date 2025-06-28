extends CharacterBody2D

# NEXUS PLAYER

# ..............................................................................

#region CONSTANTS

const BASE_SPEED: float = 150.0
const MAX_SPEED: float = 300.0
const SNAP_SPEED: float = 15.0

const NEARBY_INDICES: Array[int] = [
	-64, -49, -48, -47, -33, -32, -31, -17, -16, -15, 
	-1, 0, 1, 15, 16, 17, 31, 32, 33, 47, 48, 49, 64,
]

#endregion

# ..............................................................................

#region VARIABLES

var on_node: bool = false
var snapping: bool = false

var speed: float = BASE_SPEED

var move_direction: Vector2 = Vector2.ZERO
var snap_position: Vector2 = Vector2.ZERO

@onready var nexus: Node2D = get_parent()

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
		var snap_distance: float = position.distance_to(snap_position)
		move_direction = (snap_position - position).normalized()
		
		# deccelerate if remaining distance is larger than 1 pixel
		if snap_distance > 1.0:
			velocity = snap_distance * SNAP_SPEED * move_direction
		# else snap to position
		else:
			snapping = false
			position = snap_position
			
			# update nexus ui
			nexus.ui.update_nexus_ui()

			move_direction = Input.get_vector(&"left", &"right", &"up", &"down", 0.2)

			if move_direction == Vector2.ZERO:
				on_node = true

				# update nexus player texture
				$PlayerCrosshair.hide()
				$PlayerOutline.show()

				set_physics_process(false)

			velocity = move_direction * speed
	else:
		# acceleration
		if speed < MAX_SPEED:
			speed += 1.5

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

	# ignore inputs if not new input
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

	# update movement
	move_direction = Input.get_vector(&"left", &"right", &"up", &"down", 0.2)

	if move_direction == Vector2.ZERO:
		if on_node:
			set_physics_process(false)
		else:
			speed = BASE_SPEED
			snap_to_nearby()
	else:
		on_node = false
		snapping = false
		nexus.ui.hide_all()
		$PlayerOutline.hide()
		$PlayerCrosshair.show()
		set_physics_process(true)

#endregion

# ..............................................................................

#region SNAPPING

func snap_to_position(target_position: Vector2) -> void:
	position = target_position
	snapping = false
	$PlayerOutline.show()
	$PlayerCrosshair.hide()

func snap_to_nearby() -> void:
	# calculate and choose an approximate nearby node
	var temp_index: int = \
			roundi((position.y + 298.0) / 596.0 * 48.0) * 16 + \
			roundi((position.x + 341.0) / 683.0 * 16.0)

	const TEXTURE_OFFSET: Vector2 = Vector2(16.0, 16.0)

	var snap_node: TextureRect = null
	var snap_distance: float = INF

	# iterate through adjacent nodes to find the nearest node
	for adjacent_index in NEARBY_INDICES:
		var current_index: int = adjacent_index + temp_index
		
		# skip if current node is out of bounds or null
		if (
				current_index < 0
				or current_index > 767
				or Global.nexus_types[current_index] == -1
		):
			continue

		var current_distance: float = position.distance_squared_to(
				nexus.nexus_nodes[current_index].position + TEXTURE_OFFSET)
		
		# update snap node based on proximity
		if current_distance < snap_distance:
			snap_node = nexus.nexus_nodes[current_index]
			snap_distance = current_distance

	# start snapping
	snap_position = snap_node.position + TEXTURE_OFFSET
	move_direction = (snap_position - position).normalized()
	nexus.current_stats.last_node = snap_node.get_index()
	snapping = true

#endregion

# ..............................................................................
