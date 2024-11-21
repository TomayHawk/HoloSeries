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
		"randomized_atlas_positions": [],
		"randomized_qualities": [],
		"last_nodes": [167, 154, 333, 0, 132],
		"unlocked": [[135, 167, 182], [139, 154, 170], [284, 333, 364], [], [100, 132, 147]],
		"converted": [[[]], [[]], [[]], [[]], [[]]], # [node, type, quality],
		"nexus_inventory": [0, 2, 4, 6, 8, 0, 1, 3, 5, 7, 1, 11, 111, 9, 99, 999, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1],
		#!#!# remove below
		"unlockables": [[151, 199], [171, 138], [301, 316, 348], [], [116, 164]],
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

var atlas_positions := []

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
			"randomized_atlas_positions": [],
			"randomized_qualities": [],
			"last_nodes": [167, 154, 333, 0, 132],
			"unlocked": [[135, 167, 182], [139, 154, 170], [284, 333, 364], [], [100, 132, 147]],
			"converted": [[[]], [[]], [[]], [[]], [[]]], # [node, type, quality],
			"nexus_inventory": [0, 2, 4, 6, 8, 0, 1, 3, 5, 7, 1, 11, 111, 9, 99, 999, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1],
			#!#!# remove below
			"unlockables": [[151, 199], [171, 138], [301, 316, 348], [], [116, 164]],
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
					"randomized_atlas_positions": GlobalSettings.nexus_randomized_atlas_positions.duplicate(),
					"randomized_qualities": GlobalSettings.nexus_randomized_qualities.duplicate(),
					"last_nodes": GlobalSettings.nexus_last_nodes.duplicate(),
					"unlocked": GlobalSettings.nexus_unlocked.duplicate(),
					"unlockables": GlobalSettings.nexus_unlockables.duplicate(),
					"converted": GlobalSettings.nexus_converted.duplicate(),
					"stats": GlobalSettings.nexus_stats.duplicate(),
					"nexus_inventory": GlobalSettings.nexus_inventory.duplicate()
				 }
	}

	for player_node in GlobalSettings.party_node.get_children():
		saves[save_file]["party"].push_back(GlobalSettings.player_node.character_specifics_node.character_index)

func load(save_file):
	GlobalSettings.save_index = save_file
	last_save = saves[save_file]["save_index"]

	##### temporary
	stat_nodes_randomizer(save_file)

	# instantiate WorldScene1
	GlobalSettings.tree.call_deferred("change_scene_to_file", saves[save_file]["current_scene_path"])
	
	# update Global variables
	GlobalSettings.unlocked_characters = saves[save_file]["unlocked_characters"].duplicate()
	GlobalSettings.standby_character_indices = saves[save_file]["standby"].duplicate()
	GlobalSettings.character_levels = saves[save_file]["character_levels"].duplicate()
	GlobalSettings.character_experiences = saves[save_file]["character_experiences"].duplicate()
	GlobalSettings.inventory = saves[save_file]["inventory"].duplicate()
	GlobalSettings.nexus_randomized_atlas_positions = saves[save_file]["nexus"]["randomized_atlas_positions"].duplicate()
	GlobalSettings.nexus_randomized_qualities = saves[save_file]["nexus"]["randomized_qualities"].duplicate()
	GlobalSettings.nexus_last_nodes = saves[save_file]["nexus"]["last_nodes"].duplicate()
	GlobalSettings.nexus_unlocked = saves[save_file]["nexus"]["unlocked"].duplicate()
	GlobalSettings.nexus_unlockables = saves[save_file]["nexus"]["unlockables"].duplicate()
	GlobalSettings.nexus_converted = saves[save_file]["nexus"]["converted"].duplicate()
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

# randomizes all empty nodes with randomized stat types and stat qualities
func stat_nodes_randomizer(save_file):
	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
	var area_nodes: Array[Array] = [[132, 133, 134, 146, 147, 149, 163, 164, 165, 166, 179, 182, 196, 198, 199, 211, 212, 213, 214, 215, 228, 229, 231, 232, 243, 244, 245, 246, 247, 260, 261, 262, 264, 277, 278, 279, 280, 292, 294, 296, 309, 310, 311, 324, 325, 327, 328, 340],
									[258, 274, 291, 306, 307, 322, 323, 338, 339, 354, 356, 371, 386, 387, 388, 403, 419],
									[456, 504, 520, 521, 536, 537, 538, 553, 554, 555, 567, 568, 570, 584, 585, 586, 587, 599, 601, 602, 603, 615, 616, 619, 631, 632, 633, 634, 648, 649, 650, 658, 664, 666, 667, 674, 675, 680, 682, 690, 691, 693, 696, 697, 698, 706, 707, 708, 709, 710, 712, 713, 714, 721, 722, 723, 724, 725, 726, 728, 729, 737, 738, 740, 741, 742, 743, 744, 745, 746, 752, 753, 756, 758, 759, 760, 761],
									[484, 499, 530, 562, 564, 565, 579, 580, 594, 595, 596, 597, 598, 611, 612, 627, 628, 644, 645, 646, 660, 661, 677, 678],
									[326, 341, 342, 357, 373, 389, 390, 404, 406, 421, 423, 437, 438, 439, 453, 455, 469, 470, 471, 485, 486, 487, 500, 501, 502, 503, 517, 534, 535, 551, 566],
									[2, 3, 4, 7, 16, 17, 19, 20, 21, 22, 23, 24, 32, 33, 34, 36, 37, 38, 41, 48, 49, 50, 51, 53, 54, 55, 56, 64, 66, 67, 70, 71, 72, 73, 80, 81, 82, 83, 86, 87, 88, 89, 96, 97, 98, 99, 105, 106, 118, 119, 121, 129, 135, 136, 137, 138, 145, 151, 152, 153, 168, 169, 184, 185, 201, 233, 249, 265],
									[144, 160, 161, 176, 193, 208, 224, 240, 257, 272, 288, 304, 320, 336, 352, 384, 385, 400, 401, 417, 432, 433, 449, 464, 480, 496, 512, 528, 529, 544, 545, 560, 561, 577, 593, 608, 609, 610, 624, 625, 640, 641, 642, 657, 672, 704, 705],
									[10, 11, 12, 26, 42, 43, 44, 58, 59, 60, 75, 90, 92, 108, 123, 124, 139, 154, 155, 156, 171, 173, 187, 188, 189, 190, 191, 203, 205, 207, 218, 219, 220, 223, 235, 236, 237, 238, 239, 250, 252, 253, 254, 266, 267, 268, 269, 270, 282, 283, 284, 297, 298, 300, 314, 315, 329, 330, 331, 345, 346],
									[13, 15, 29, 30, 46, 61, 78, 93, 95, 110, 111, 126, 127, 142, 143, 159],
									[364, 376, 377, 378, 379, 380, 393, 394, 395, 396, 397, 408, 409, 410, 411, 412, 425, 426, 427, 429, 441, 442, 443, 444, 445, 459, 460, 461, 474, 475, 476, 477, 491, 493, 494, 507, 508, 509, 523, 524, 525, 526, 540, 541, 542, 557, 558, 559, 572, 573, 574, 575, 591, 604, 605, 606, 607, 621, 623, 636, 652, 684, 699],
									[638, 653, 654, 655, 668, 669, 670, 671, 685, 686, 687, 700, 701, 703, 716, 718, 719, 731, 732, 733, 734, 748, 749, 750, 764, 765, 766],
									[271, 286, 287, 316, 317, 318, 319, 333, 334, 335, 348, 349, 350, 351, 366, 367, 398, 399, 414, 415, 430, 431, 447, 463, 479, 495, 510, 511]]

	# area stat number
	# Empty, HP, MP, DEF, WRD, ATK, INT, SPD, AGI, EMPTY
	var area_amount: Array[Array] = [[6, 11, 2, 5, 2, 6, 2, 2],
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

	# area stat flactuation
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

	const stats_node_atlas_position: Array[Vector2] = [Vector2(0, 32), Vector2(32, 32), Vector2(64, 32), Vector2(96, 32), Vector2(0, 64), Vector2(32, 64), Vector2(64, 64), Vector2(96, 64)]
	const empty_node_atlas_position := Vector2(0, 0)
	var area_texture_positions: Array[Vector2] = []
	
	var area_size := 0
	var area_texture_positions_size := 0
	var i := 0

	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
	# HP, MP, DEF, WRD, ATK, INT, SPD, AGI
	const area_stats_qualities := [[0, 0, 0, 0, 0, 0, 0, 0],
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
	const stats_qualities := {
	0: [[200, 200, 300], [200, 200, 300, 300, 300, 400], [300, 300, 400]],
	1: [[10, 10, 20], [10, 10, 20, 20, 40], [20, 20, 40]],
	2: [[5, 10], [5, 10, 10, 15], [10, 15]],
	3: [[5, 10], [5, 10, 10, 15], [10, 15]],
	4: [[5, 5, 5, 10], [5, 10], [10]],
	5: [[5, 5, 5, 10], [5, 10], [10]],
	6: [[1, 1, 2, 2, 2, 3], [1, 2, 3, 3, 4], [3, 4]],
	7: [[1, 1, 2, 2, 2, 3], [1, 2, 3, 3, 4], [3, 4]]
	}

	var node_qualities := []

	atlas_positions.clear()
	for j in 768:
		atlas_positions.push_back(Vector2(-1, -1))
		node_qualities.push_back(0)

	# for each area
	for area_index in area_nodes.size():
		area_size = area_nodes[area_index].size()

		# randomize the number of each stat type
		for stat_index in stats_node_atlas_position.size():
			area_amount[area_index][stat_index] += round(rand_weight[area_index][stat_index] * (randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25)))

		# create an array of Vector2 positions for area stat nodes
		area_texture_positions.clear()

		for stat_type in area_amount[area_index].size():
			for j in area_amount[area_index][stat_type]:
				area_texture_positions.push_back(stats_node_atlas_position[stat_type])

		for remaining_nodes in (area_size - area_texture_positions.size() + 1):
			area_texture_positions.push_back(empty_node_atlas_position)

		# find satifying stat type for each node
		area_nodes[area_index].shuffle()
		area_texture_positions.shuffle()

		area_texture_positions_size = area_texture_positions.size()

		for node_index in area_nodes[area_index]:
			i = 0
			while (area_texture_positions_size >= i):
				atlas_positions[node_index] = area_texture_positions[area_texture_positions_size - 1 - i]
				if has_illegal_adjacents(node_index):
					i += 1
				else:
					area_texture_positions.pop_at(area_texture_positions_size - 1 - i)
					area_texture_positions_size -= 1
					break
			
			if (i > area_size):
				atlas_positions[node_index] = area_texture_positions.pop_at(randi() % (area_size))
				area_texture_positions_size -= 1

	saves[save_file]["nexus"]["randomized_atlas_positions"] = atlas_positions.duplicate()

	# randomize stat node qualities
	for j in 768:
		node_qualities.push_back(0)

	for area_index in area_nodes.size():
		for node_index in area_nodes[area_index]:
			for stat_index in stats_node_atlas_position.size():
				if atlas_positions[node_index] == stats_node_atlas_position[stat_index]:
					node_qualities[node_index] = stats_qualities[stat_index][area_stats_qualities[area_index][stat_index]][randi() % stats_qualities[stat_index][area_stats_qualities[area_index][stat_index]].size()]

	saves[save_file]["nexus"]["randomized_qualities"] = node_qualities.duplicate()

func has_illegal_adjacents(node_index):
	const adjacents_index: Array[Array] = [[-32, -17, -16, 15, 16, 32], [-32, -16, -15, 16, 17, 32]]
	var adjacents := []
	
	# determine adjacents
	if (node_index % 32) < 16:
		for temp_index in adjacents_index[0]: adjacents.push_back(node_index + temp_index)
	else:
		for temp_index in adjacents_index[1]: adjacents.push_back(node_index + temp_index)

	# remove outside range
	for temp_index in adjacents.duplicate():
		if (temp_index < 0) or (temp_index > 767):
			adjacents.erase(temp_index)
	
	# check for identical
	for adjacent_index in adjacents:
		if atlas_positions[node_index] == atlas_positions[adjacent_index]:
			return true
	
	return false
