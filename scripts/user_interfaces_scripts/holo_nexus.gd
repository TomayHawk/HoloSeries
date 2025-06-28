extends Node2D

# HOLONEXUS

# ..............................................................................

#region CONSTANTS

# atlas positions for empty and null nodes
const EMPTY_ATLAS_POSITION: Vector2 = Vector2(0.0, 0.0)
const NULL_ATLAS_POSITION: Vector2 = Vector2(32.0, 0.0)

# atlas positions for HP, MP, DEF, WRD, STR, INT, SPD, AGI nodes
const STATS_ATLAS_POSITIONS: Array[Vector2] = [
	Vector2(0.0, 32.0),
	Vector2(32.0, 32.0),
	Vector2(64.0, 32.0),
	Vector2(96.0, 32.0),
	Vector2(0.0, 64.0),
	Vector2(32.0, 64.0),
	Vector2(64.0, 64.0),
	Vector2(96.0, 64.0),
]

# nexus nodes atlas positions for special, white magic, black magic nodes
const ABILITY_ATLAS_POSITIONS: Array[Vector2] = [
	Vector2(64.0, 0.0),
	Vector2(96.0, 0.0),
	Vector2(128.0, 0.0),
]

# atlas positions for diamond, clover, heart, spade key nodes
const KEY_ATLAS_POSITIONS: Array[Vector2] = [
	Vector2(0.0, 96.0),
	Vector2(32.0, 96.0),
	Vector2(64.0, 96.0),
	Vector2(96.0, 96.0)
]

const NULL_MODULATE: Color = Color(0.2, 0.2, 0.2, 1.0)
const KEY_MODULATE: Color = Color(0.33, 0.33, 0.33, 1.0)
const LOCKED_MODULATE: Color = Color(0.25, 0.25, 0.25, 1.0)
const UNLOCKED_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)

# converted stats qualities for HP, MP, DEF, WRD, STR, INT, SPD, AGI nodes
const CONVERTED_QUALITIES: Array[int] = [400, 40, 15, 15, 20, 20, 4, 4]

# adjacent node indices
const ADJACENT_INDICES_1: Array[int] = [-32, -17, -16, 15, 16, 32]
const ADJACENT_INDICES_2: Array[int] = [-32, -16, -15, 16, 17, 32]

#endregion

# ..............................................................................

#region VARIABLES

# character variables
var character_stats: Array[PlayerStats] = set_characters()
var current_stats: PlayerStats = Players.main_player.stats
var current_index: int = character_stats.find(current_stats)
var unlockable_nodes: Array[int] = []
var converted_nodes: Array[int] = []

# world scene camera settings
var scene_camera_zoom: Vector2 = Players.camera.zoom
var scene_camera_limits: Array[int] = [
	Players.camera.limit_left,
	Players.camera.limit_top,
	Players.camera.limit_right,
	Players.camera.limit_bottom
]

var unlockables_load: Resource = \
		load("res://user_interfaces/user_interfaces_resources/nexus_unlockables.tscn")

# nodes
@onready var ui: CanvasLayer = $HoloNexusUi
@onready var nexus_player: CharacterBody2D = $NexusPlayer
@onready var nexus_nodes: Array[Node] = $NexusNodes.get_children()

#endregion

# ..............................................................................

#region READY

func _ready() -> void:
	Players.camera.position_smoothing_enabled = false

	# update camera
	Players.camera.update_camera($NexusPlayer, Vector2(1.0, 1.0))
	Players.camera.update_camera_limits([-679, -592, 681, 592] as Array[int])

	# initialize nodes and players
	set_nexus_nodes()
	update_nexus_player(current_index)

	# enable zoom inputs
	Inputs.zoom_inputs_enabled = true

	Players.camera.set_deferred(&"position_smoothing_enabled", true)

#endregion

# ..............................................................................

#region INPUTS

func _input(event: InputEvent) -> void:
	# ignore all unrelated inputs
	if not (event.is_action(&"tab") or event.is_action(&"esc")):
		return

	Inputs.accept_event()

	if Input.is_action_just_pressed(&"tab"):
		ui.character_selector_node.show()
	elif Input.is_action_just_released(&"tab"):
		ui.character_selector_node.hide()
	elif Input.is_action_just_pressed(&"esc"):
		if ui.inventory_ui.visible:
			ui.inventory_ui.hide()
			ui.update_nexus_ui()
		else:
			exit_nexus()

#endregion

# ..............................................................................

#region INITIALIZATION

func set_characters() -> Array[PlayerStats]:
	var temp_stats: Array[PlayerStats] = []

	# sort party players by party index
	var party_sorted: Array[Node] = Players.get_children()
	party_sorted.sort_custom(func(a, b): return a.party_index < b.party_index)

	# add party players stats to temp_stats
	for player in party_sorted:
		temp_stats.append(player.stats)
	
	# add standby character stats to temp_stats
	for stats in Players.standby_characters:
		temp_stats.append(stats)
	
	# return all stats
	return temp_stats

func set_nexus_nodes() -> void:
	# set nexus nodes textures and modulate
	for index in nexus_nodes.size():
		var node_type: int = Global.nexus_types[index]
		
		# set texture
		if node_type == -1:
			nexus_nodes[index].texture.region.position = NULL_ATLAS_POSITION
		elif node_type == 0:
			nexus_nodes[index].texture.region.position = EMPTY_ATLAS_POSITION
		elif node_type <= 8:
			nexus_nodes[index].texture.region.position = STATS_ATLAS_POSITIONS[node_type - 1]
		elif node_type <= 11:
			nexus_nodes[index].texture.region.position = ABILITY_ATLAS_POSITIONS[node_type - 9]
		else:
			nexus_nodes[index].texture.region.position = KEY_ATLAS_POSITIONS[node_type - 12]

		# set modulate
		nexus_nodes[index].modulate = \
				NULL_MODULATE if node_type == -1 \
				else KEY_MODULATE if node_type >= 12 \
				else LOCKED_MODULATE

#endregion

# ..............................................................................

#region PLAYER UPDATE

func update_nexus_player(next_index: int) -> void:
	var next_stats: PlayerStats = character_stats[next_index]

	# reset unlockables outlines
	for unlockable_outline in $Unlockables.get_children():
		unlockable_outline.free()

	# for each unlocked node, reset texture and modulate
	for index in current_stats.unlocked_nodes:
		var node_type: int = Global.nexus_types[index]
		
		# reset texture
		if node_type == -1:
			nexus_nodes[index].texture.region.position = NULL_ATLAS_POSITION
		elif node_type == 0:
			nexus_nodes[index].texture.region.position = EMPTY_ATLAS_POSITION
		elif node_type <= 8:
			nexus_nodes[index].texture.region.position = STATS_ATLAS_POSITIONS[node_type - 1]
		elif node_type <= 11:
			nexus_nodes[index].texture.region.position = ABILITY_ATLAS_POSITIONS[node_type - 9]
		else:
			nexus_nodes[index].texture.region.position = KEY_ATLAS_POSITIONS[node_type - 12]

		# reset modulate
		nexus_nodes[index].modulate = \
				NULL_MODULATE if node_type == -1 \
				else KEY_MODULATE if node_type >= 12 \
				else LOCKED_MODULATE

	# update current stats and index
	current_stats = next_stats
	current_index = next_index

	# for each unlocked node, update texture and modulate
	for index in next_stats.unlocked_nodes:
		var node_type: int = Global.nexus_types[index]

		# update texture
		if node_type == -1 or node_type >= 12:
			nexus_nodes[index].texture.region.position = EMPTY_ATLAS_POSITION
		
		# update modulate
		nexus_nodes[index].modulate = UNLOCKED_MODULATE

	# reset converted nodes array
	converted_nodes.clear()

	# for each converted node, update texture
	for converted in next_stats.converted_nodes:
		converted_nodes.append(converted.x)
		nexus_nodes[converted.x].texture.region.position = \
				EMPTY_ATLAS_POSITION if converted.y == 0 else STATS_ATLAS_POSITIONS[converted.y - 1]

	# reset unlockable nodes array
	unlockable_nodes.clear()

	# for each unlocked node, update unlockables
	for index in next_stats.unlocked_nodes:
		add_adjacent_unlockables(index)

	# update player position
	$NexusPlayer.snap_to_position(nexus_nodes[next_stats.last_node].position + Vector2(16.0, 16.0))

#endregion

# ..............................................................................

#region FUNCTIONS

func get_adjacents(origin_index: int) -> Array[int]:
	var temp_adjacents: Array[int] = []
	var node_count: int = $NexusNodes.get_child_count()
	var origin_position: Vector2 = nexus_nodes[origin_index].position
	
	for temp_index in (ADJACENT_INDICES_1 if (origin_index % 32) < 16 else ADJACENT_INDICES_2):
		var adjusted_index: int = origin_index + temp_index
		
		# check if current index is within bounds
		if (adjusted_index < 0) or (adjusted_index >= node_count):
			continue
		
		# check if current node is not null
		if Global.nexus_types[adjusted_index] == -1:
			continue
		
		# check if current node is actually nearby
		if origin_position.distance_squared_to(nexus_nodes[adjusted_index].position) > 10000:
			continue
		
		temp_adjacents.append(adjusted_index)

	return temp_adjacents

func add_adjacent_unlockables(index: int) -> void:
	# for each adjacent node of index
	for adjacent in get_adjacents(index):
		# skip if adjacent is already unlocked, is in unlockables, or is null
		if (
				adjacent in current_stats.unlocked_nodes
				or adjacent in unlockable_nodes
				or nexus_nodes[adjacent].texture.region.position == NULL_ATLAS_POSITION
		):
			continue

		# for each adjacent node of adjacents
		for second_adjacent in get_adjacents(adjacent):
			# skip if second adjacent is not unlocked, is the original node, or adjacent is in unlockables
			if (
					not second_adjacent in current_stats.unlocked_nodes
					or second_adjacent == index
			):
				continue

			# if adjacent has at least 2 unlocked neighbors, add adjacent to unlockables
			unlockable_nodes.append(adjacent)

			# create unlockables outline for adjacent node
			var unlockable_instance: TextureRect = unlockables_load.instantiate()
			$Unlockables.add_child(unlockable_instance)
			unlockable_instance.name = str(adjacent)
			unlockable_instance.position = nexus_nodes[adjacent].position
			break

func unlock_node() -> void:
	var node_index: int = current_stats.last_node

	current_stats.unlocked_nodes.append(node_index)
	unlockable_nodes.erase(node_index)
	
	# remove unlockable outline
	$Unlockables.remove_child($Unlockables.get_node(str(node_index)))

	# update node texture
	nexus_nodes[node_index].modulate = UNLOCKED_MODULATE

	# check for adjacent unlockables
	add_adjacent_unlockables(node_index)

#endregion

# ..............................................................................

#region EXIT

func exit_nexus():
	Players.camera.update_camera(Players.main_player, scene_camera_zoom)
	Players.camera.update_camera_limits(scene_camera_limits)

	Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")
	queue_free()

#endregion

# ..............................................................................
