extends Node

var last_save := 0

var settings_save := {
	"full_screen": false,
	"resolution": false,
	"window_position": false,
	"master_volume": 0.0,
	"music_volume": 0.0,
	"language": 0, ## ### use enum
	"zoom_sensitivity": 1.0,
	"screen_shake_intensity": 1.0
}

var saves := [
	{
	# global variables
	"save_index": 0,
	"inventory": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	"current_main_character_index": 4,
	
	# load variables
	"current_scene_path": "res://scenes/world_scene_1.tscn",
	"unlocked_characters": [0, 1, 2, 4],
	"party": [0, 4, 2],
	"current_main_player_position": Vector2(0, 0),
	"character_levels": [0, 0, 0, 0, 0],
	"character_experiences": [0.0, 0.0, 0.0, 0.0, 0.0],

	"combat_inventory": [999, 99, 99, 99, 999, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	
	"nexus": {
		#!#!# "randomized_nodes": [[]], # [node, type, quality],
		"last_nodes": [167, 154, 333, 0, 132],
		"unlocked": [[135, 167, 182], [139, 154, 170], [284, 333, 364], [], [100, 132, 147]],
		#!#!# "converted": [[[]], [[]], [[]], [[]], [[]]], # [node, type, quality],
		"nexus_inventory": [0, 2, 4, 6, 8, 0, 1, 3, 5, 7, 1, 11, 111, 9, 99, 999, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1],
		#!#!# remove below
		"not_randomized": true,
		"randomized_atlas_positions": [],
		"quality": [],
		"unlockables": [[151, 199], [171, 138], [301, 316, 348], [], [116, 164]],
		"converted": [[], [], [], [], []],
		"converted_type": [[], [], [], [], []],
		"converted_quality": [[], [], [], [], []],
		"stats": [[0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0]]
		#!#!#
	},
	#!#!# remove below
	"standby": [1],
	#!#!#
	},
	{},
	{}
]

func new(unlocked_characters, save_index):
	while (save_index == -1 or saves[save_index] == {}):
		save_index += 1
		
	saves[save_index] = {
		"save_index": 0,
		"inventory": [0, 0, 0],
		"current_main_character_index": 4,
			
		"current_scene_path": "res://scenes/world_scene_1.tscn",
		"unlocked_characters": [0, 1, 2, 4],
		"party": [0, 4, 2],
		"current_main_player_position": Vector2(0, 0),
		"character_levels": [0, 0, 0, 0, 0],
		"character_experiences": [0.0, 0.0, 0.0, 0.0, 0.0],

		"nexus": {
			#!#!# "randomized_nodes": [[]], # [node, type, quality],
			"last_nodes": [167, 154, 333, 0, 132],
			"unlocked": [[135, 167, 182], [139, 154, 170], [284, 333, 364], [], [100, 132, 147]],
			#!#!# "converted": [[[]], [[]], [[]], [[]], [[]]], # [node, type, quality],
			"nexus_inventory": [0, 2, 4, 6, 8, 0, 1, 3, 5, 7, 1, 11, 111, 9, 99, 999, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1],
			#!#!# remove below
			"not_randomized": true,
			"randomized_atlas_positions": [],
			"quality": [],
			"unlockables": [[151, 199], [171, 138], [301, 316, 348], [], [116, 164]],
			"converted": [[], [], [], [], []],
			"converted_type": [[], [], [], [], []],
			"converted_quality": [[], [], [], [], []],
			"stats": [[0, 0, 0, 0, 0, 0, 0, 0],
					  [0, 0, 0, 0, 0, 0, 0, 0],
					  [0, 0, 0, 0, 0, 0, 0, 0],
					  [0, 0, 0, 0, 0, 0, 0, 0],
					  [0, 0, 0, 0, 0, 0, 0, 0]]
			#!#!#
		},
		#!#!# remove below
		"standby": [1],
		#!#!#
	}
	
	##### randomize nexus
	print(unlocked_characters)
	load(save_index)

func save(save_file):
	saves[save_file] = {
		"save_index": saves[save_file]["save_index"],
		"current_scene_path": GlobalSettings.tree.current_scene.get_path(), ## ### need to fix
		"unlocked_characters": GlobalSettings.unlocked_characters.duplicate(),
		"party": [],
		"standby": GlobalSettings.standby_character_indices.duplicate(),
		"current_main_character_index": GlobalSettings.current_main_player_node.character_specifics_node.character_index,
		"current_main_player_position": GlobalSettings.current_main_player_node.position,
		"character_levels": GlobalSettings.character_levels.duplicate(),
		"character_experiences": GlobalSettings.character_experiences.duplicate(),
		"inventory": GlobalSettings.inventory.duplicate(),
		"nexus": {
					"not_randomized": GlobalSettings.nexus_not_randomized,
					"randomized_atlas_positions": GlobalSettings.nexus_randomized_atlas_positions.duplicate(),
					"last_nodes": GlobalSettings.nexus_last_nodes.duplicate(),
					"unlocked": GlobalSettings.nexus_unlocked.duplicate(),
					"unlockables": GlobalSettings.nexus_unlockables.duplicate(),
					"quality": GlobalSettings.nexus_quality.duplicate(),
					"converted": GlobalSettings.nexus_converted.duplicate(),
					"converted_type": GlobalSettings.nexus_converted_type.duplicate(),
					"converted_quality": GlobalSettings.nexus_converted_quality.duplicate(),
					"stats": GlobalSettings.nexus_stats.duplicate(),
					"nexus_inventory": GlobalSettings.nexus_inventory.duplicate()
				 }
	}

	for player_node in GlobalSettings.party_node.get_children():
		saves[save_file]["party"].push_back(GlobalSettings.player_node.character_specifics_node.character_index)

func load(save_file):
	GlobalSettings.save_index = save_file
	last_save = saves[save_file]["save_index"]

	# instantiate WorldScene1
	GlobalSettings.tree.call_deferred("change_scene_to_file", saves[save_file]["current_scene_path"])
	
	# update Global variables
	GlobalSettings.unlocked_characters = saves[save_file]["unlocked_characters"].duplicate()
	GlobalSettings.standby_character_indices = saves[save_file]["standby"].duplicate()
	GlobalSettings.character_levels = saves[save_file]["character_levels"].duplicate()
	GlobalSettings.character_experiences = saves[save_file]["character_experiences"].duplicate()
	GlobalSettings.inventory = saves[save_file]["inventory"].duplicate()
	GlobalSettings.nexus_not_randomized = saves[save_file]["nexus"]["not_randomized"]
	GlobalSettings.nexus_randomized_atlas_positions = saves[save_file]["nexus"]["randomized_atlas_positions"].duplicate()
	GlobalSettings.nexus_last_nodes = saves[save_file]["nexus"]["last_nodes"].duplicate()
	GlobalSettings.nexus_unlocked = saves[save_file]["nexus"]["unlocked"].duplicate()
	GlobalSettings.nexus_unlockables = saves[save_file]["nexus"]["unlockables"].duplicate()
	GlobalSettings.nexus_quality = saves[save_file]["nexus"]["quality"].duplicate()
	GlobalSettings.nexus_converted = saves[save_file]["nexus"]["converted"].duplicate()
	GlobalSettings.nexus_converted_type = saves[save_file]["nexus"]["converted_type"].duplicate()
	GlobalSettings.nexus_converted_quality = saves[save_file]["nexus"]["converted_quality"].duplicate()
	GlobalSettings.nexus_stats = saves[save_file]["nexus"]["stats"].duplicate()
	GlobalSettings.nexus_inventory = saves[save_file]["nexus"]["nexus_inventory"].duplicate()
	
	var base_player_path := "res://entities/players/player_base.tscn"
	var character_specifics_paths := ["res://entities/players/character_specifics/sora.tscn",
									  "res://entities/players/character_specifics/azki.tscn",
									  "res://entities/players/character_specifics/roboco.tscn",
									  "res://entities/players/character_specifics/akirose.tscn",
									  "res://entities/players/character_specifics/luna.tscn"]
	var player_standby_path := "res://entities/players/player_standby.tscn"

	var party_player_nodes = GlobalSettings.party_node.get_children()
	var player_node: Node = null
	
	# create party characters
	for character_index in saves[save_file]["party"]:
		# create base player, attach character specifics, add character to party node, update player stats, add player to "party" group
		player_node = load(base_player_path).instantiate()
		player_node.add_child(load(character_specifics_paths[character_index]).instantiate())

		party_player_nodes.push_back(player_node)
		GlobalSettings.party_node.add_child(player_node)
		player_node.player_stats_node.update_stats()
		player_node.add_to_group("party")
		GlobalSettings.combat_ui_node.character_name_label_nodes[party_player_nodes.size() - 1].text = party_player_nodes[party_player_nodes.size() - 1].character_specifics_node.character_name
		
		# position character and determine main player node
		player_node.position = saves[save_file]["current_main_player_position"]
		if character_index == saves[save_file]["current_main_character_index"]:
			GlobalSettings.current_main_player_node = player_node
			GlobalSettings.update_main_player(player_node)
		else:
			player_node.position += (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
	
	for character_index in saves[save_file]["standby"]:
		player_node = load(player_standby_path).instantiate()
		player_node.add_child(load(character_specifics_paths[character_index]).instantiate())
		GlobalSettings.standby_node.add_child(player_node)
		player_node.player_stats_node.update_stats()

	# hide unused character info slots
	for i in 4:
		if i >= party_player_nodes.size():
			GlobalSettings.combat_ui_node.players_info_nodes[i].hide()
			GlobalSettings.combat_ui_node.ultimate_progress_bar_nodes[i].hide()
			GlobalSettings.combat_ui_node.shield_progress_bar_nodes[i].hide()

	GlobalSettings.combat_ui_node.update_character_selector()
	GlobalSettings.combat_inputs_available = true

	GlobalSettings.start_bgm("res://music/asmarafulldemo.mp3")

'''
func stat_nodes_randomizer():
	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
	var area_nodes: Array[Array] = [[], [], [], [], [], [], [], [], [], [], [], []]

	# randomizer base number
	# HP, MP, DEF, WRD, ATK, INT, SPD, AGI, EMPTY
	var area_amount: Array[Array] = [[0, 6, 11, 2, 5, 2, 6, 2, 2],
									   [0, 3, 4, 1, 2, 0, 2, 0, 0],
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
	
	for area in area_amount:
		for stat in area:
			area_amount[area][stat] += round(rand_weight[area][stat] * (randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25)))
	
	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
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
	# HP, MP, DEF, WRD, ATK, INT, SPD, AGI
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

	# HP, MP, DEF, WRD, ATK, INT, SPD, AGI, EMPTY
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
					nodes_quality[node_index] = default_stats_qualities[i][default_area_stats_qualities[area_type][i]][randi()% default_stats_qualities[i][default_area_stats_qualities[area_type][i]].size()]

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
			if need_match and replacing_type_three_stat_nodes.size() > 0:
				for second_temp_node_index in replacing_type_three_stat_nodes:
					if nexus_nodes[second_temp_node_index].texture.region.position not in temp_adjacents_types:
						temp_match = second_temp_node_index
						temp_position = nexus_nodes[second_temp_node_index].texture.region.position
						need_match = false
						break
			if need_match:
				for second_temp_node_index in area_nodes:
					if need_match and (second_temp_node_index not in replacing_empty_nodes) and (second_temp_node_index not in replacing_type_two_stat_nodes):
						if nexus_nodes[second_temp_node_index].texture.region.position != empty_node_atlas_position and nexus_nodes[second_temp_node_index].texture.region.position not in temp_adjacents_types:
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
		if (temp_index < 0) or (temp_index > 767):
			temp_adjacents.erase(temp_index)

	return temp_adjacents
'''