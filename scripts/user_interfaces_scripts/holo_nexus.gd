class_name HoloNexus
extends Node2D

# HOLO NEXUS

# ..............................................................................

#region CONSTANTS

# atlas positions for empty and null nodes
const EMPTY_ATLAS_POSITION: Vector2 = Vector2(0, 0)
const NULL_ATLAS_POSITION: Vector2 = Vector2(32, 0)

# atlas positions for HP, MP, DEF, WRD, ATK, INT, SPD, AGI nodes
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
const LOCKED_MODULATE: Color = Color(0.25, 0.25, 0.25, 1.0)
const UNLOCKED_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)

# converted stats qualities for HP, MP, DEF, WRD, ATK, INT, SPD, AGI nodes
const CONVERTED_QUALITIES: Array[int] = [400, 40, 15, 15, 20, 20, 4, 4]

# adjacent node indices
const ADJACENT_INDICES: Array[Array] = [
	[-32, -17, -16, 15, 16, 32],
	[-32, -16, -15, 16, 17, 32]
]

#endregion

# ..............................................................................

#region VARIABLES

# character variables
var current_stats: PlayerStats = Players.main_player.stats
var character_stats: Array[PlayerStats] = set_characters()

# world scene camera settings
var scene_camera_zoom: Vector2 = Players.camera.zoom
var scene_camera_limits: Array[int] = [
	Players.camera.limit_left,
	Players.camera.limit_top,
	Players.camera.limit_right,
	Players.camera.limit_bottom
]

# nodes
@onready var ui: CanvasLayer = $HoloNexusUi
@onready var nexus_nodes: Array[Node] = $NexusNodes.get_children()

#endregion

# ..............................................................................

#region READY

func _ready() -> void:
	# update camera
	Players.camera.update_camera($NexusPlayer, Vector2(1.0, 1.0))
	Players.camera.update_camera_limits([-679, -592, 681, 592])

	# TODO: temporary code
	temp_function()

	# initialize nodes and players
	update_nexus_player(Players.main_player.stats.CHARACTER_INDEX)

	# enable zoom inputs
	Inputs.zoom_inputs_enabled = true

#endregion


func temp_function() -> void:
	pass

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
		if ui.inventory_node.visible:
			ui.inventory_node.hide()
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
		temp_stats.append(stats.CHARACTER_INDEX)
	
	# return all stats
	return temp_stats

#endregion

# ..............................................................................

func update_nexus_player(next_stats: PlayerStats) -> void:
	# reset unlockables overlays
	for unlockable_overlay in $Unlockables.get_children():
		unlockable_overlay.free()

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
		nexus_nodes[index].modulate = LOCKED_MODULATE if node_type != -1 else NULL_MODULATE

	# update current stats
	current_stats = next_stats

	# for each unlocked node, update texture and modulate
	for index in next_stats.unlocked_nodes:
		var node_type: int = Global.nexus_types[index]

		# update texture
		if node_type == -1 or node_type >= 12:
			nexus_nodes[index].texture.region.position = EMPTY_ATLAS_POSITION
		
		# update modulate
		nexus_nodes[index].modulate = UNLOCKED_MODULATE

	# for each converted node, update texture
	for converted in next_stats.converted_nodes:
		nexus_nodes[converted.x].texture.region.position = \
				EMPTY_ATLAS_POSITION if converted.y == 0 else STATS_ATLAS_POSITIONS[converted.y - 1]

	# for each unlocked node, update unlockables
	for index in next_stats.unlocked_nodes:
		add_adjacent_unlockables(index)


	# TODO: continue from here





		# check and outline unlockables
		if index_counter in unlockables[character_index]:
			var unlockable_instance: TextureRect = load("res://user_interfaces/user_interfaces_resources/nexus_unlockables.tscn").instantiate()
			unlockable_instance.name = str(index_counter)
			$Unlockables.add_child(unlockable_instance)
			unlockable_instance.position = nexus_nodes[index_counter].position

	for converted_node in current_stats.converted_nodes:
		var converted_index: int = converted_node.x

		if Global[nexus_types[converted_index]] == 0:
			continue

		nexus_nodes[converted_node.x].
	
	# update converted nodes
	# TODO: need to update quality
	for converted_node in nodes_converted[character_index]:
		nexus_nodes[converted_node[0]].texture.region.position = converted_node[1]
	
	# update key textures
	for key_type in 4:
		for temp_node_index in key_nodes[key_type]:
			nexus_nodes[temp_node_index].modulate = Color(0.33, 0.33, 0.33, 1)

	# update player position
	$NexusPlayer.position = nexus_nodes[last_nodes[character_index]].position + Vector2(16, 16)
	$NexusPlayer.snapping = false
	$NexusPlayer/PlayerOutline.show()
	$NexusPlayer/PlayerCrosshair.hide()

func get_adjacents(origin_index: int) -> Array[int]:
	var node_count: int = $NexusNodes.get_child_count()
	
	var temp_adjacents: Array[int] = []
	var origin_position: Vector2 = nexus_nodes[origin_index].position
	
	for temp_index in ADJACENT_INDICES[0 if (origin_index % 32) < 16 else 1]:
		var current_index: int = origin_index + temp_index
		
		# check if current index is within bounds
		if (current_index < 0) or (current_index >= node_count):
			continue
		
		# check if current node is actually nearby
		if origin_position.distance_squared_to(nexus_nodes[current_index].position) > 10000:
			continue
		
		temp_adjacents.append(current_index)

	return temp_adjacents

func unlock_node():
	# if unlockable, unlock node
	if last_nodes[current_stats] in unlockables[current_stats]:
		nodes_unlocked[current_stats].append(last_nodes[current_stats])
		unlockables[current_stats].erase(last_nodes[current_stats])
		
		# remove unlockables outline
		$Unlockables.remove_child($Unlockables.get_node(str(last_nodes[current_stats])))

		# update node texture
		nexus_nodes[last_nodes[current_stats]].modulate = Color(1, 1, 1, 1)

		# check for adjacent unlockables
		add_adjacent_unlockables(current_stats, last_nodes[current_stats])

func add_adjacent_unlockables(origin_index):
	# for each adjacent node
	for adjacent in get_adjacents(origin_index).duplicate():
		# if node is not unlocked and node is not null
		if adjacent not in nodes_unlocked[player] and nexus_nodes[adjacent].texture.region.position != NULL_ATLAS_POSITION:
			# check if adjacent has at least 2 unlocked neighbors
			for second_adjacent in get_adjacents(adjacent):
				# if second adjacent is unlocked, is not the original node, and adjacent is not in unlockables
				if (second_adjacent in nodes_unlocked[player]) and (second_adjacent != origin_index) and adjacent not in unlockables[player]:
					# add adjacent node to unlockables
					unlockables[player].append(adjacent)

					# create unlockables outline for adjacent node
					var unlockable_instance: TextureRect = load("res://user_interfaces/user_interfaces_resources/nexus_unlockables.tscn").instantiate()
					unlockable_instance.name = str(adjacent)
					$Unlockables.add_child(unlockable_instance)
					unlockable_instance.position = nexus_nodes[adjacent].position
					break

func exit_nexus():
	# TODO: temporary
	var party_players: Array[int] = []
	for player in Players.get_children():
		party_players.append(player.stats.CHARACTER_INDEX)

	var standby_players: Array[int] = []
	for character in Players.standby_node.get_children():
		standby_players.append(character.CHARACTER_INDEX)

	Players.camera.update_camera(Players.main_player, scene_camera_zoom)
	Players.camera.update_camera_limits(scene_camera_limits)
	Inputs.zoom_inputs_enabled = true

	Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")
	queue_free()
