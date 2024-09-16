extends CharacterBody2D

@onready var nexus := get_parent()
@onready var nexus_ui_node := nexus.get_node("HoloNexusUI")
@onready var nexus_player_outline_node := $Outline
@onready var nexus_player_crosshair_node := $Crosshair

@onready var character_index: int = GlobalSettings.current_main_player_node.character_specifics_node.character_index

var move_direction := Vector2.ZERO
var speed := 150
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
	# reparent camera
	GlobalSettings.camera_node.reparent(self)
	GlobalSettings.camera_node.position = Vector2(0, 0)


	# deccelerate towards target position while snapping
	if snapping:
		# deccelerate if remaining distance is larger than 1 pixel
		snap_distance = position.distance_to(snap_position)
		if snap_distance > 1:
			velocity = snap_distance * snap_speed * snap_direction / 40
		# else snap and stop moving	
		else:	
			velocity = Vector2.ZERO
			snapping = false
			on_node = true
			nexus.last_nodes[nexus.current_nexus_player] = snap_node.get_index()
			position = snap_position

			# update nexus player texture
			nexus_player_outline_node.show()
			nexus_player_crosshair_node.hide()
			# update nexus ui
			nexus_ui_node.update_nexus_ui()
	else:
		move_direction = Input.get_vector("left", "right", "up", "down")
		velocity = move_direction * speed
		# if not on node, and not moving, set speed to default and snap to nearest node
		if !on_node && velocity == Vector2.ZERO:
			speed = 150
			snap_to_target(position)
		elif velocity != Vector2.ZERO:
			# hide nexus ui while moving
			nexus_ui_node.hide_all()
			
			# accelerate by 1 until max speed
			if speed < speed_max: speed += 1
			# update nexus player texture
			if on_node:
				on_node = false
				nexus_player_outline_node.hide()
				nexus_player_crosshair_node.show()

	move_and_slide()

func snap_to_target(initial_position):
	# calculates and chooses a nearby node
    var temp_near: int = (round((initial_position.y + 298.0) / 596 * 48) * 16) + (round((initial_position.x + 341.0) / 683 * 16))
	
	# clamp to closest valid node
    if temp_near < 0:
    	temp_near = clamp((temp_near + 16), 0, 767)
    elif temp_near > 767:
        temp_near = clamp((temp_near - 16), 0, 767)

    if nexus.nexus_nodes[temp_near].texture.region.position != nexus.null_node_atlas_position:
        snap_node = nexus.nexus_nodes[temp_near]
        snap_distance = initial_position.distance_to(nexus.nexus_nodes[temp_near].position + Vector2(16, 16))
    else:
        snap_node = null
        snap_distance = INF

    for temp_adjacent in nexus.return_adjacents(temp_near).duplicate():
        if initial_position.distance_to(nexus.nexus_nodes[temp_adjacent].position + Vector2(16, 16)) < snap_distance && nexus.nexus_nodes[temp_adjacent].texture.region.position != nexus.null_node_atlas_position:
            snap_node = nexus.nexus_nodes[temp_adjacent]
            snap_distance = initial_position.distance_to(nexus.nexus_nodes[temp_adjacent].position + Vector2(16, 16))
        
        for second_temp_adjacent in nexus.return_adjacents(temp_adjacent):
            if initial_position.distance_to(nexus.nexus_nodes[second_temp_adjacent].position + Vector2(16, 16)) < snap_distance && nexus.nexus_nodes[second_temp_adjacent].texture.region.position != nexus.null_node_atlas_position:
                snap_node = nexus.nexus_nodes[second_temp_adjacent]
                snap_distance = initial_position.distance_to(nexus.nexus_nodes[second_temp_adjacent].position + Vector2(16, 16))

    snap_position = snap_node.position + Vector2(16, 16)
    snap_direction = (snap_position - initial_position).normalized()

    snapping = true

    nexus_ui_node.hide_all()
