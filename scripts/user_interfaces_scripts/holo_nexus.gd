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
var nexus_character: int = 0
var unlockables: Array[Array] = []

var scene_camera_zoom := Vector2(1.0, 1.0)
var scene_camera_limits: Array[int] = []

@onready var nexus_nodes: Array[Node] = $NexusNodes.get_children()
@onready var ui: CanvasLayer = $HoloNexusUi

#endregion

# ..............................................................................

func _ready():
	scene_camera_zoom = Players.camera.zoom
	Players.camera.update_camera($NexusPlayer, Vector2(1.0, 1.0))
	Inputs.zoom_inputs_enabled = true
	scene_camera_limits = [Players.camera.limit_left, Players.camera.limit_top, Players.camera.limit_right, Players.camera.limit_bottom]
	Players.camera.update_camera_limits([-679, -592, 681, 592])

	# update board # TODO: should randomize board at start of game # TODO: block needs fixing
	# TODO: update STATS_ATLAS_POSITIONS to include Empty
	temp_function()
	var index_counter := 0
	for node in nexus_nodes:
		if node.texture.region.position == EMPTY_ATLAS_POSITION:
			if Global.nexus_types[index_counter] != -1: # TODO: temporary code
				node.texture.region.position = Global.nexus_types[index_counter]
		else:
			Global.nexus_types[index_counter] = -1 # TODO: temporary code, changed from -> #node.texture.region.position
		index_counter += 1

	# update current player and allies in character selector
	update_nexus_player(Players.main_player.stats.CHARACTER_INDEX)

func _input(event: InputEvent) -> void:
	# ignore all unrelated inputs
	if not event.is_action(&"esc"):
		return
	
	Inputs.accept_event()
	
	if Input.is_action_just_pressed(&"esc"):
		exit_nexus()

func temp_function():
	for node in nexus_nodes:
		match node.texture.region.position:
			NULL_ATLAS_POSITION: null_nodes.append(node.get_index()) # null
			KEY_ATLAS_POSITIONS[0]: key_nodes[0].append(node.get_index()) # diamond
			KEY_ATLAS_POSITIONS[1]: key_nodes[1].append(node.get_index()) # clover
			KEY_ATLAS_POSITIONS[2]: key_nodes[2].append(node.get_index()) # heart
			KEY_ATLAS_POSITIONS[3]: key_nodes[3].append(node.get_index()) # spade

	# TODO: temporary
	var party_players: Array[int] = []
	for player in Players.get_children():
		party_players.append(player.stats.CHARACTER_INDEX)

	var standby_players: Array[int] = []
	for character in Players.standby_node.get_children():
		standby_players.append(character.CHARACTER_INDEX)

	# for each unlocked player, determine all unlockables
	for CHARACTER_INDEX in party_players + standby_players:
		for node_index in nodes_unlocked[CHARACTER_INDEX]:
			# check for adjacent unlockables
			check_adjacent_unlockables(node_index, CHARACTER_INDEX)

func return_adjacents(temp_node_index):
	var temp_adjacents: Array[int] = []
	
	if (temp_node_index % 32) < 16:
		for temp_index in ADJACENT_INDICES[0]: temp_adjacents.append(temp_node_index + temp_index)
	else:
		for temp_index in ADJACENT_INDICES[1]: temp_adjacents.append(temp_node_index + temp_index)

	for temp_index in temp_adjacents.duplicate():
		if (temp_index < 0) or (temp_index > 767):
			temp_adjacents.erase(temp_index)

	return temp_adjacents

func update_nexus_player(player):
	nexus_character = player
	$NexusPlayer.CHARACTER_INDEX = player

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
		elif index_counter in nodes_unlocked[player]:
			nexus_nodes[index_counter].modulate = Color(1, 1, 1, 1)
		else:
			node.modulate = Color(0.25, 0.25, 0.25, 1)
			
			# check and outline unlockables
			if index_counter in unlockables[player]:
				var unlockable_instance: TextureRect = load("res://user_interfaces/user_interfaces_resources/nexus_unlockables.tscn").instantiate()
				unlockable_instance.name = str(index_counter)
				$UnlockableNodes.add_child(unlockable_instance)
				unlockable_instance.position = nexus_nodes[index_counter].position
		
		index_counter += 1

	# update converted nodes
	# TODO: need to update quality
	for converted_node in nodes_converted[player]:
		nexus_nodes[converted_node[0]].texture.region.position = converted_node[1]
	
	# update key textures
	for key_type in 4:
		for temp_node_index in key_nodes[key_type]:
			nexus_nodes[temp_node_index].modulate = Color(0.33, 0.33, 0.33, 1)

	# update player position
	$NexusPlayer.position = nexus_nodes[last_nodes[player]].position + Vector2(16, 16)
	$NexusPlayer.snapping = false
	$NexusPlayer/PlayerOutline.show()
	$NexusPlayer/PlayerCrosshair.hide()

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
		check_adjacent_unlockables(last_nodes[nexus_character], nexus_character)

func check_adjacent_unlockables(origin_index, player):
	# for each adjacent node
	for adjacent in return_adjacents(origin_index).duplicate():
		# if node is not unlocked and node is not null
		if adjacent not in nodes_unlocked[player] and nexus_nodes[adjacent].texture.region.position != NULL_ATLAS_POSITION:
			# check if adjacent has at least 2 unlocked neighbors
			for second_adjacent in return_adjacents(adjacent):
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
