class_name HoloNexus
extends Node2D

# HOLO NEXUS

# ..............................................................................

#region CONSTANTS

# atlas positions for empty and null nodes
const EMPTY_ATLAS_POSITION: Vector2 = Vector2(0, 0)
const NULL_ATLAS_POSITION: Vector2 = Vector2(32, 0)

# atlas positions for HP, MP, DEF, WRD, ATK, INT, SPD, AGI nodes
const STATS_ATLAS_POSITIONS: Array[Vector2] = [Vector2(0, 32), Vector2(32, 32), Vector2(64, 32), Vector2(96, 32), Vector2(0, 64), Vector2(32, 64), Vector2(64, 64), Vector2(96, 64)]

# nexus nodes atlas positions for special, white magic, black magic nodes
const ABILITY_ATLAS_POSITIONS: Array[Vector2] = [Vector2(64, 0), Vector2(96, 0), Vector2(128, 0)]

# atlas positions for diamond, clover, heart, spade key nodes
const KEY_ATLAS_POSITIONS: Array[Vector2] = [Vector2(0, 96), Vector2(32, 96), Vector2(64, 96), Vector2(96, 96)]

# converted stats qualities for HP, MP, DEF, WRD, ATK, INT, SPD, AGI nodes
const CONVERTED_QUALITIES: Array[int] = [400, 40, 15, 15, 20, 20, 4, 4]

# adjacent node indices
const ADJACENT_INDICES: Array[Array] = [[-32, -17, -16, 15, 16, 32], [-32, -16, -15, 16, 17, 32]]

#endregion

# ..............................................................................

#region VARIABLES

# character variables
var nexus_character: int = Players.main_player.stats.CHARACTER_INDEX
var character_stats: Array[PlayerStats] = set_characters()
var unlockables: Array[Array] = []

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
	set_unlockables()
	set_stats_textures()
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

# for each character, determine all unlockables
func set_unlockables() -> void:
	for stats in character_stats:
		for node_index in stats.unlocked_nodes:
			add_adjacent_unlockables(stats, node_index)

# set stats nodes textures
func set_stats_textures() -> void:
	for index in $NexusNodes.get_child_count():
		# 1-8: HP, MP, DEF, WRD, ATK, INT, SPD, AGI
		var nexus_type: int = Global.nexus_types[index]
		if nexus_type >= 1 and nexus_type <= 8:
			nexus_nodes[index].texture.region.position = STATS_ATLAS_POSITIONS[nexus_type - 1]

#endregion

# ..............................................................................

func update_nexus_player(character_index: int) -> void:
	nexus_character = character_index
	$NexusPlayer.CHARACTER_INDEX = character_index

	# clear unlockable textures
	for past_unlockable_nodes in $UnlockableNodes.get_children():
		past_unlockable_nodes.queue_free()

	var index_counter := 0
	for node in nexus_nodes:
		# return to default texture positions
		# TODO
		#node.texture.region.position = Global.nexus_types[index_counter]
		# modulate null nodes, unlocked nodes and locked nodes
		if index_counter in null_nodes:
			nexus_nodes[index_counter].modulate = Color(0.2, 0.2, 0.2, 1)
		elif index_counter in nodes_unlocked[character_index]:
			nexus_nodes[index_counter].modulate = Color(1, 1, 1, 1)
		else:
			node.modulate = Color(0.25, 0.25, 0.25, 1)
			
			# check and outline unlockables
			if index_counter in unlockables[character_index]:
				var unlockable_instance: TextureRect = load("res://user_interfaces/user_interfaces_resources/nexus_unlockables.tscn").instantiate()
				unlockable_instance.name = str(index_counter)
				$UnlockableNodes.add_child(unlockable_instance)
				unlockable_instance.position = nexus_nodes[index_counter].position
		
		index_counter += 1

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
	if last_nodes[nexus_character] in unlockables[nexus_character]:
		nodes_unlocked[nexus_character].append(last_nodes[nexus_character])
		unlockables[nexus_character].erase(last_nodes[nexus_character])
		
		# remove unlockables outline
		$UnlockableNodes.remove_child($UnlockableNodes.get_node(str(last_nodes[nexus_character])))

		# update node texture
		nexus_nodes[last_nodes[nexus_character]].modulate = Color(1, 1, 1, 1)

		# check for adjacent unlockables
		add_adjacent_unlockables(nexus_character, last_nodes[nexus_character])

func add_adjacent_unlockables(player, origin_index):
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
					$UnlockableNodes.add_child(unlockable_instance)
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
