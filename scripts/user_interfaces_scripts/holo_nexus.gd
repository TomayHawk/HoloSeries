extends Node2D

var current_nexus_player := 0

@onready var nexus_nodes := %NexusNodes.get_children()
@onready var nexus_player_node := %NexusPlayer
@onready var nexus_player_outline_node := %PlayerOutline
@onready var nexus_player_crosshair_node := %PlayerCrosshair
@onready var nexus_ui_node := %HoloNexusUI
@onready var nexus_unlockables_node := %UnlockableNodes

# character information
@onready var last_nodes = Global.temporary_global_variable["last_nodes"].duplicate()
@onready var nodes_unlocked = Global.temporary_global_variable["unlocked"].duplicate()
@onready var nodes_qualities: Array[int] = Global.nexus_stats_qualities.duplicate()
@onready var nodes_converted = Global.temporary_global_variable["converted"].duplicate()

@onready var unlockable_load := load("res://user_interfaces/user_interfaces_resources/nexus_unlockables.tscn")
var unlockable_instance: Node = null

# nexus atlas positions
# HP, MP, DEF, WRD, ATK, INT, SPD, AGI
# diamond, clover, heart, spade
# skills, white magic, black magic
const empty_node_atlas_position := Vector2(0, 0)
const null_node_atlas_position := Vector2(32, 0)
const stats_node_atlas_position: Array[Vector2] = [Vector2(0, 32), Vector2(32, 32), Vector2(64, 32), Vector2(96, 32), Vector2(0, 64), Vector2(32, 64), Vector2(64, 64), Vector2(96, 64)]
const key_node_atlas_position: Array[Vector2] = [Vector2(0, 96), Vector2(32, 96), Vector2(64, 96), Vector2(96, 96)]
const ability_node_atlas_position: Array[Vector2] = [Vector2(64, 0), Vector2(96, 0), Vector2(128, 0)]

const converted_stats_qualities := [400, 40, 15, 15, 20, 20, 4, 4]

# ability nodes
var nodes_unlockable: Array[Array] = [[], [], [], [], []]
var ability_nodes: Array[int] = []

# non-stats nodes
var null_nodes: Array[int] = []
var key_nodes: Array[Array] = [[], [], [], []]
var skill_nodes: Array[int] = []
var white_magic_nodes: Array[int] = []
var black_magic_nodes: Array[int] = []

# adjacent node indices
const adjacents_index: Array[Array] = [[-32, -17, -16, 15, 16, 32], [-32, -16, -15, 16, 17, 32]]

# temporary variables
var temp_adjacents: Array[int] = []
var index_counter := 0

var scene_camera_zoom := Vector2(1.0, 1.0)

func _ready():
	# TODO: nexus camera limit (-679, -592, 681, 592)
	scene_camera_zoom = Players.camera_node.zoom
	Players.camera_node.update_camera(nexus_player_node, true, Vector2(1.0, 1.0))
	Players.camera_node.new_limits([-679, -592, 681, 592])

	# update board # TODO: should randomize board at start of game # TODO: block needs fixing
	temp_function()
	index_counter = 0
	for node in nexus_nodes:
		if node.texture.region.position == empty_node_atlas_position:
			node.texture.region.position = Global.nexus_stats_types[index_counter]
		else:
			Global.nexus_stats_types[index_counter] = node.texture.region.position
		index_counter += 1

	# update current player and allies in character selector
	update_nexus_player(Players.main_player_node.character_node.character_index)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"esc"):
		Inputs.accept_event()
		if nexus_ui_node.inventory_node.visible:
			nexus_ui_node.inventory_node.hide()
			nexus_ui_node.update_nexus_ui()
		else:
			exit_nexus()

func temp_function():
	for node in nexus_nodes:
		match node.texture.region.position:
			null_node_atlas_position: null_nodes.push_back(node.get_index()) # null
			key_node_atlas_position[0]: key_nodes[0].push_back(node.get_index()) # diamond
			key_node_atlas_position[1]: key_nodes[1].push_back(node.get_index()) # clover
			key_node_atlas_position[2]: key_nodes[2].push_back(node.get_index()) # heart
			key_node_atlas_position[3]: key_nodes[3].push_back(node.get_index()) # spade

	# TODO: temporary
	var party_players: Array[int] = []
	for player in Players.party_node.get_children():
		party_players.push_back(player.character_node.character_index)

	var standby_players: Array[int] = []
	for character_node in Players.standby_node.get_children():
		standby_players.push_back(character_node.character_index)

	# for each unlocked player, determine all unlockables
	for character_index in party_players + standby_players:
		for node_index in nodes_unlocked[character_index]:
			# check for adjacent unlockables
			check_adjacent_unlockables(node_index, character_index)

func return_adjacents(temp_node_index):
	temp_adjacents.clear()
	
	if (temp_node_index % 32) < 16:
		for temp_index in adjacents_index[0]: temp_adjacents.push_back(temp_node_index + temp_index)
	else:
		for temp_index in adjacents_index[1]: temp_adjacents.push_back(temp_node_index + temp_index)

	for temp_index in temp_adjacents.duplicate():
		if (temp_index < 0) or (temp_index > 767):
			temp_adjacents.erase(temp_index)

	return temp_adjacents

func update_nexus_player(player):
	current_nexus_player = player
	nexus_player_node.character_index = player

	# clear unlockable textures
	for past_unlockable_nodes in nexus_unlockables_node.get_children():
		past_unlockable_nodes.queue_free()

	index_counter = 0
	for node in nexus_nodes:
		# return to default texture positions
		node.texture.region.position = Global.nexus_stats_types[index_counter]

		# modulate null nodes, unlocked nodes and locked nodes
		if index_counter in null_nodes:
			nexus_nodes[index_counter].modulate = Color(0.2, 0.2, 0.2, 1)
		elif index_counter in nodes_unlocked[player]:
			nexus_nodes[index_counter].modulate = Color(1, 1, 1, 1)
		else:
			node.modulate = Color(0.25, 0.25, 0.25, 1)
			
			# check and outline unlockables
			if index_counter in nodes_unlockable[player]:
				unlockable_instance = unlockable_load.instantiate()
				unlockable_instance.name = str(index_counter)
				nexus_unlockables_node.add_child(unlockable_instance)
				unlockable_instance.position = nexus_nodes[index_counter].position
		
		index_counter += 1

	# update converted nodes
	# TODO: need to update quality
	if not nodes_converted[player][0].is_empty():
		for converted_node in nodes_converted[player]:
			nexus_nodes[converted_node[0]].texture.region.position = converted_node[1]
	
	# update key textures
	for key_type in 4:
		for temp_node_index in key_nodes[key_type]:
			nexus_nodes[temp_node_index].modulate = Color(0.33, 0.33, 0.33, 1)

	# update player position
	nexus_player_node.position = nexus_nodes[last_nodes[player]].position + Vector2(16, 16)
	nexus_player_node.snapping = false
	nexus_player_outline_node.show()
	nexus_player_crosshair_node.hide()

func unlock_node():
	# if unlockable, unlock node
	if last_nodes[current_nexus_player] in nodes_unlockable[current_nexus_player]:
		nodes_unlocked[current_nexus_player].push_back(last_nodes[current_nexus_player])
		nodes_unlockable[current_nexus_player].erase(last_nodes[current_nexus_player])
		
		# remove unlockables outline
		nexus_unlockables_node.remove_child(nexus_unlockables_node.get_node(str(last_nodes[current_nexus_player])))

		# update node texture
		nexus_nodes[last_nodes[current_nexus_player]].modulate = Color(1, 1, 1, 1)

		# check for adjacent unlockables
		check_adjacent_unlockables(last_nodes[current_nexus_player], current_nexus_player)

func check_adjacent_unlockables(origin_index, player):
	# for each adjacent node
	for adjacent in return_adjacents(origin_index).duplicate():
		# if node is not unlocked and node is not null
		if adjacent not in nodes_unlocked[player] and nexus_nodes[adjacent].texture.region.position != null_node_atlas_position:
			# check if adjacent has at least 2 unlocked neighbors
			for second_adjacent in return_adjacents(adjacent):
				# if second adjacent is unlocked, is not the original node, and adjacent is not in unlockables
				if (second_adjacent in nodes_unlocked[player]) and (second_adjacent != origin_index) and adjacent not in nodes_unlockable[player]:
					# add adjacent node to unlockables
					nodes_unlockable[player].push_back(adjacent)

					# create unlockables outline for adjacent node
					unlockable_instance = unlockable_load.instantiate()
					unlockable_instance.name = str(adjacent)
					nexus_unlockables_node.add_child(unlockable_instance)
					unlockable_instance.position = nexus_nodes[adjacent].position
					break

func exit_nexus():
	Global.temporary_global_variable["unlocked"] = nodes_unlocked.duplicate()
	Global.nexus_stats_qualities = nodes_qualities.duplicate()

	# TODO: temporary
	var party_players: Array[int] = []
	for player in Players.party_node.get_children():
		party_players.push_back(player.character_node.character_index)

	var standby_players: Array[int] = []
	for character_node in Players.standby_node.get_children():
		standby_players.push_back(character_node.character_index)

	Players.camera_node.update_camera(Players.main_player_node, true, scene_camera_zoom)

	Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")
	queue_free()
