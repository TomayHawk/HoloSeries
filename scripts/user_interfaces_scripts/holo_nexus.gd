extends Node2D

var current_nexus_player := 0

@onready var nexus_nodes := $NexusNodes.get_children()
@onready var nexus_player_node := $NexusPlayer
@onready var nexus_player_outline_node := $NexusPlayer/Outline
@onready var nexus_player_crosshair_node := $NexusPlayer/Crosshair
@onready var nexus_ui_node := $HoloNexusUI
@onready var nexus_unlockables_node := $UnlockableNodes

# character information
@onready var last_nodes = GlobalSettings.nexus_last_nodes.duplicate()
@onready var nodes_unlocked = GlobalSettings.nexus_unlocked.duplicate()
@onready var nodes_unlockable = GlobalSettings.nexus_unlockables.duplicate()
@onready var nodes_quality = GlobalSettings.nexus_quality.duplicate()
@onready var nodes_converted = GlobalSettings.nexus_converted.duplicate()
@onready var nodes_converted_type = GlobalSettings.nexus_converted_type.duplicate()
@onready var nodes_converted_quality = GlobalSettings.nexus_converted_quality.duplicate()

@onready var unlockable_load := load("res://resources/nexus_unlockables.tscn")
var unlockable_instance: Node = null

# nexus atlas positions
# HP, MP, DEF, SHD, ATK, INT, SPD, AGI
# diamond, clover, heart, spade
# skills, white magic, black magic
const empty_node_atlas_position := Vector2(0, 0)
const null_node_atlas_position := Vector2(32, 0)
const stats_node_atlas_position: Array[Vector2] = [Vector2(0, 32), Vector2(32, 32), Vector2(64, 32), Vector2(96, 32), Vector2(0, 64), Vector2(32, 64), Vector2(64, 64), Vector2(96, 64)]
const key_node_atlas_position: Array[Vector2] = [Vector2(0, 96), Vector2(32, 96), Vector2(64, 96), Vector2(96, 96)]
const ability_node_atlas_position: Array[Vector2] = [Vector2(64, 0), Vector2(96, 0), Vector2(128, 0)]

const converted_stats_qualities := [400, 40, 15, 15, 20, 20, 4, 4]

# ability nodes
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

func _ready():
	# update camera settings
	GlobalSettings.current_camera_node = nexus_player_node.get_node("Camera2D")
	GlobalSettings.current_camera_node.zoom = Vector2(1.0, 1.0)
	GlobalSettings.target_zoom = Vector2(1.0, 1.0)
	GlobalSettings.mouse_in_zoom_area = true

	# toggle nexus inputs
	GlobalSettings.nexus_inputs_available = true
	GlobalSettings.nexus_character_selector_node = get_node("HoloNexusUI/NexusCharacterSelector")

	# update board
	if GlobalSettings.nexus_not_randomized:
		stat_nodes_randomizer()
	else:
		index_counter = 0
		for node in nexus_nodes:
			if node.texture.region.position == empty_node_atlas_position:
				node.texture.region.position = GlobalSettings.nexus_randomized_atlas_positions[index_counter]
			index_counter += 1

	# update current player and allies in character selector
	update_nexus_player(GlobalSettings.current_main_player_node.character_specifics_node.character_index)
	nexus_ui_node.update_character_selector()

func stat_nodes_randomizer():
	GlobalSettings.nexus_not_randomized = false

	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
	var area_nodes: Array[Array] = [[], [], [], [], [], [], [], [], [], [], [], []]

	index_counter = 0
	for temp_node in nexus_nodes:
		match temp_node.modulate:
			Color(1, 0, 1, 1): area_nodes[0].push_back(index_counter) # white magic (pink)
			Color(1, 0.501961, 0.501961, 1): area_nodes[1].push_back(index_counter) # white magic 2 (light coral)
			Color(0.501961, 0, 1, 1): area_nodes[2].push_back(index_counter) # black magic (purple)
			Color(0.501961, 0, 0.501961, 1): area_nodes[3].push_back(index_counter) # black magic 2 (dark magenta)
			Color(1, 0, 0, 1): area_nodes[4].push_back(index_counter) # summon (red)
			Color(1, 1, 0, 1): area_nodes[5].push_back(index_counter) # buff (yellow)
			Color(0.501961, 1, 1, 1): area_nodes[6].push_back(index_counter) # debuff (light blue)
			Color(1, 0.501961, 0, 1): area_nodes[7].push_back(index_counter) # skills (orange)
			Color(0.501961, 0.501961, 0, 1): area_nodes[8].push_back(index_counter) # skills 2 (olive)
			Color(0, 1, 0, 1): area_nodes[9].push_back(index_counter) # physical (green)
			Color(0, 0.501961, 0, 1): area_nodes[10].push_back(index_counter) # physical 2 (dark green)
			Color(0, 0.501961, 1, 1): area_nodes[11].push_back(index_counter) # tank (blue)
			Color(1, 1, 1, 1): ability_nodes.push_back(index_counter) # ability nodes
		index_counter += 1

	# randomizer base number
	# HP, MP, DEF, SHD, ATK, INT, SPD, AGI, EMPTY
	const area_amount: Array[Array] = [[6, 11, 2, 5, 2, 6, 2, 2],
									   [3, 4, 1, 2, 0, 2, 0, 0],
									   [11, 18, 3, 4, 3, 10, 3, 3],
									   [3, 6, 1, 2, 1, 3, 1, 1],
									   [4, 4, 1, 1, 1, 4, 1, 1],
									   [11, 8, 3, 3, 5, 4, 3, 3],
									   [6, 8, 2, 2, 2, 4, 2, 2],
									   [11, 7, 3, 2, 5, 3, 3, 3],
									   [3, 2, 1, 0, 2, 1, 1, 1],
									   [13, 4, 3, 2, 9, 1, 3, 3],
									   [5, 1, 2, 1, 4, 0, 2, 2],
									   [8, 2, 3, 1, 2, 1, 0, 0]]

	# randomizer weight
	const rand_weight: Array[Array] = [[2, 3, 1, 1, 1, 2, 1, 1],
									   [1, 1, 0, 1, 0, 1, 0, 0],
									   [3, 5, 1, 1, 1, 3, 1, 1],
									   [1, 2, 0, 1, 0, 1, 0, 0],
									   [1, 1, 0, 0, 0, 1, 0, 0],
									   [3, 2, 1, 1, 2, 1, 1, 1],
									   [2, 2, 1, 1, 1, 1, 1, 1],
									   [3, 2, 1, 1, 2, 1, 1, 1],
									   [1, 1, 0, 0, 0, 0, 0, 0],
									   [3, 1, 1, 1, 3, 0, 1, 1],
									   [1, 0, 1, 0, 1, 0, 1, 1],
									   [2, 1, 1, 1, 1, 0, 0, 0]]
	
	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
	var rand_resultant_amount: Array[int] = []
	var rand_resultant_types: Array[Vector2] = []
	var weighted_flactuation := 0

	# for each area type
	for area_type in area_nodes.size():
		rand_resultant_amount.clear()
		rand_resultant_types.clear()

		# determine an amount for each stat type
		for stat_type in 8:
			weighted_flactuation = round(rand_weight[area_type][stat_type] * (randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25)))
			rand_resultant_amount.push_back(area_amount[area_type][stat_type] + weighted_flactuation)

		# create an array of Vector2 positions for each node in area
		for i in 8:
			for j in rand_resultant_amount[i]:
				rand_resultant_types.push_back(stats_node_atlas_position[i])
		for i in (area_nodes[area_type].size() - rand_resultant_types.size()):
			rand_resultant_types.push_back(empty_node_atlas_position)
		
		rand_resultant_types.shuffle()

		# assign Vector2 texture positions for each node in area
		index_counter = 0
		for temp_node_index in area_nodes[area_type]:
			nexus_nodes[temp_node_index].texture.region.position = rand_resultant_types[index_counter]
			index_counter += 1

		stat_nodes_secondary_randomizer(area_nodes[area_type])
	
	# save randomized textures
	for node in nexus_nodes:
		GlobalSettings.nexus_randomized_atlas_positions.push_back(node.texture.region.position)
			
	for node in nexus_nodes:
		match node.texture.region.position:
			null_node_atlas_position: null_nodes.push_back(node.get_index()) # null
			key_node_atlas_position[0]: key_nodes[0].push_back(node.get_index()) # diamond
			key_node_atlas_position[1]: key_nodes[1].push_back(node.get_index()) # clover
			key_node_atlas_position[2]: key_nodes[2].push_back(node.get_index()) # heart
			key_node_atlas_position[3]: key_nodes[3].push_back(node.get_index()) # spade

	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
	# HP, MP, DEF, SHD, ATK, INT, SPD, AGI
	const default_area_stats_qualities := [[0, 0, 0, 0, 0, 0, 0, 0],
										   [1, 2, 0, 2, 0, 2, 1, 1],
										   [0, 0, 0, 0, 0, 0, 0, 0],
										   [1, 2, 0, 2, 0, 2, 1, 1],
										   [0, 0, 0, 0, 0, 0, 0, 0],
										   [0, 0, 0, 0, 0, 0, 1, 1],
										   [0, 0, 0, 0, 0, 0, 1, 1],
										   [0, 0, 0, 0, 0, 0, 0, 0],
										   [1, 1, 1, 1, 1, 1, 2, 2],
										   [0, 0, 0, 0, 0, 0, 0, 0],
										   [2, 1, 2, 0, 2, 0, 1, 1],
										   [1, 0, 1, 1, 0, 0, 0, 0]]

	# HP, MP, DEF, SHD, ATK, INT, SPD, AGI, EMPTY
	const default_stats_qualities := {
	0: [[200, 200, 300], [200, 200, 300, 300, 300, 400], [300, 300, 400]],
	1: [[10, 10, 20], [10, 10, 20, 20, 40], [20, 20, 40]],
	2: [[5, 10], [5, 10, 10, 15], [10, 15]],
	3: [[5, 10], [5, 10, 10, 15], [10, 15]],
	4: [[5, 5, 5, 10], [5, 10], [10]],
	5: [[5, 5, 5, 10], [5, 10], [10]],
	6: [[1, 1, 2, 2, 2, 3], [1, 2, 3, 3, 4], [3, 4]],
	7: [[1, 1, 2, 2, 2, 3], [1, 2, 3, 3, 4], [3, 4]]
	}

	for i in 768:
		nodes_quality.push_back(0)

	# save amount
	for area_type in area_nodes.size():
		for node_index in area_nodes[area_type]:
			for i in stats_node_atlas_position.size():
				if nexus_nodes[node_index].texture.region.position == stats_node_atlas_position[i]:
					nodes_quality[node_index] = default_stats_qualities[i][default_area_stats_qualities[area_type][i]][randi() % default_stats_qualities[i][default_area_stats_qualities[area_type][i]].size()]

	# for each unlocked player, determine all unlockables
	for character_index in GlobalSettings.unlocked_characters:
		for node_index in nodes_unlocked[character_index]:
			# check for adjacent unlockables
			check_adjacent_unlockables(node_index, character_index)

func stat_nodes_secondary_randomizer(area_nodes):
	var empty_adjacents_count := 0
	var same_adjacents_count := 0

	var replacing_empty_nodes: Array[int] = []
	var replacing_stat_nodes: Array[int] = []
	var replacing_type_two_stat_nodes: Array[int] = []
	var replacing_type_three_stat_nodes: Array[int] = []

	var need_match = true
	var temp_adjacents_types: Array[Vector2] = []
	var temp_match: int = -1
	var temp_position := Vector2.ZERO
	
	for i in 10:
		replacing_empty_nodes.clear()
		replacing_stat_nodes.clear()
		replacing_type_two_stat_nodes.clear()
		replacing_type_three_stat_nodes.clear()

		# for each node in area
		for temp_node_index in area_nodes:
			# add each empty node with (at least 2 empty adjacent nodes) to replacing_empty_nodes
			if nexus_nodes[temp_node_index].texture.region.position == empty_node_atlas_position:
				empty_adjacents_count = 0
				for adjacent in return_adjacents(temp_node_index):
					if nexus_nodes[adjacent].texture.region.position == empty_node_atlas_position:
						empty_adjacents_count += 1
					if empty_adjacents_count == 2:
						replacing_empty_nodes.push_back(temp_node_index)
						empty_adjacents_count = 0
						break
			# add each stat node to appropriate type of replacing_stat_nodes
			else:
				empty_adjacents_count = 0
				same_adjacents_count = 0
				for second_temp_node_index in return_adjacents(temp_node_index):
					if nexus_nodes[second_temp_node_index].texture.region.position == empty_node_atlas_position:
						empty_adjacents_count += 1
					elif nexus_nodes[second_temp_node_index].texture.region.position == nexus_nodes[temp_node_index].texture.region.position:
						same_adjacents_count += 1
				if same_adjacents_count > 0:
					if empty_adjacents_count < 2:
						replacing_stat_nodes.push_back(temp_node_index) # at least 1 same type adjacent and at most 1 empty type adjacent
					else:
						replacing_type_two_stat_nodes.push_back(temp_node_index) # at least 1 same type adjacent and at least 2 empty type adjacents
				elif empty_adjacents_count < 2:
					replacing_type_three_stat_nodes.push_back(temp_node_index) # at most 1 empty type adjacents
		
		replacing_empty_nodes.shuffle()
		replacing_stat_nodes.shuffle()
		replacing_type_two_stat_nodes.shuffle()
		replacing_type_three_stat_nodes.shuffle()

		for temp_node_index in replacing_empty_nodes.duplicate():
			need_match = true
			temp_adjacents_types.clear()
			for adjacent in return_adjacents(temp_node_index).duplicate():
				temp_adjacents_types.push_back(nexus_nodes[adjacent].texture.region.position)
			if replacing_stat_nodes.size() > 0:
				for second_temp_node_index in replacing_stat_nodes:
					if nexus_nodes[second_temp_node_index].texture.region.position not in temp_adjacents_types:
						temp_match = second_temp_node_index
						temp_position = nexus_nodes[second_temp_node_index].texture.region.position
						need_match = false
						break
			if need_match && replacing_type_three_stat_nodes.size() > 0:
				for second_temp_node_index in replacing_type_three_stat_nodes:
					if nexus_nodes[second_temp_node_index].texture.region.position not in temp_adjacents_types:
						temp_match = second_temp_node_index
						temp_position = nexus_nodes[second_temp_node_index].texture.region.position
						need_match = false
						break
			if need_match:
				for second_temp_node_index in area_nodes:
					if need_match && second_temp_node_index not in replacing_empty_nodes && second_temp_node_index not in replacing_type_two_stat_nodes:
						if nexus_nodes[second_temp_node_index].texture.region.position != empty_node_atlas_position && nexus_nodes[second_temp_node_index].texture.region.position not in temp_adjacents_types:
							temp_match = second_temp_node_index
							temp_position = nexus_nodes[second_temp_node_index].texture.region.position
							need_match = false

							for second_adjacent in return_adjacents(temp_node_index):
								if nexus_nodes[second_adjacent].texture.region.position == empty_node_atlas_position:
									need_match = true

			if !need_match:
				nexus_nodes[temp_node_index].texture.region.position = nexus_nodes[temp_match].texture.region.position
				nexus_nodes[temp_match].texture.region.position = empty_node_atlas_position
				replacing_empty_nodes.erase(temp_node_index)
				replacing_stat_nodes.erase(temp_match)
				replacing_type_three_stat_nodes.erase(temp_match)
	
	area_nodes.shuffle()

	for temp_node_index in area_nodes:
		if nexus_nodes[temp_node_index].texture.region.position != empty_node_atlas_position:
			index_counter = 0

			# count same type adjacent nodes
			for adjacent in return_adjacents(temp_node_index).duplicate():
				if nexus_nodes[adjacent].texture.region.position == nexus_nodes[temp_node_index].texture.region.position:
					for second_temp_node_index in area_nodes:
						if nexus_nodes[second_temp_node_index].texture.region.position != nexus_nodes[temp_node_index].texture.region.position:
							for second_adjacent in return_adjacents(second_temp_node_index):
								if nexus_nodes[second_adjacent].texture.region.position == empty_node_atlas_position:
									index_counter += 1

									temp_position = nexus_nodes[temp_node_index].texture.region.position
									nexus_nodes[temp_node_index].texture.region.position = nexus_nodes[second_temp_node_index].texture.region.position
									nexus_nodes[second_temp_node_index].texture.region.position = temp_position
									break
					break

func return_adjacents(temp_node_index):
	temp_adjacents.clear()
	
	if (temp_node_index % 32) < 16:
		for temp_index in adjacents_index[0]: temp_adjacents.push_back(temp_node_index + temp_index)
	else:
		for temp_index in adjacents_index[1]: temp_adjacents.push_back(temp_node_index + temp_index)

	for temp_index in temp_adjacents.duplicate():
		if (temp_index < 0) || (temp_index > 767):
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
		node.texture.region.position = GlobalSettings.nexus_randomized_atlas_positions[index_counter]

		# update texture positions for converted nodes
		if index_counter in nodes_converted[player]:
			node.texture.region.position = nodes_converted_type[player][nodes_converted_type[player].find(index_counter)]

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
	
	# update key textures
	for key_type in 4:
		for temp_node_index in key_nodes[key_type]:
			nexus_nodes[temp_node_index].modulate = Color(0.33, 0.33, 0.33, 1)

	# update player position
	nexus_player_node.position = nexus_nodes[last_nodes[player]].position + Vector2(16, 16)
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
		if adjacent not in nodes_unlocked[player] && nexus_nodes[adjacent].texture.region.position != null_node_atlas_position:
			# check if adjacent has at least 2 unlocked neighbors
			for second_adjacent in return_adjacents(adjacent):
				# if second adjacent is unlocked, is not the original node, and adjacent is not in unlockables
				if (second_adjacent in nodes_unlocked[player]) && (second_adjacent != origin_index) && adjacent not in nodes_unlockable[player]:
					# add adjacent node to unlockables
					nodes_unlockable[player].push_back(adjacent)

					# create unlockables outline for adjacent node
					unlockable_instance = unlockable_load.instantiate()
					unlockable_instance.name = str(adjacent)
					nexus_unlockables_node.add_child(unlockable_instance)
					unlockable_instance.position = nexus_nodes[adjacent].position
					break

func exit_nexus():
	GlobalSettings.nexus_unlocked = nodes_unlocked.duplicate()
	GlobalSettings.nexus_quality = nodes_quality.duplicate()

	# for each player, count unlocked stat nodes
	for character_index in GlobalSettings.unlocked_characters:
		GlobalSettings.nexus_stats[character_index] = [0, 0, 0, 0, 0, 0, 0, 0]

		for unlocked_index in nodes_unlocked[character_index]:
			if stats_node_atlas_position.find(nexus_nodes[unlocked_index].texture.region.position) != -1:
				GlobalSettings.nexus_stats[character_index][stats_node_atlas_position.find(nexus_nodes[unlocked_index].texture.region.position)] += 1

	# update camera
	GlobalSettings.update_nodes("exit_nexus", false)
	queue_free()
