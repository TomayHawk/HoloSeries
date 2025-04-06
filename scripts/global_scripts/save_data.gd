extends Node

var last_save: int = 1

var settings: Dictionary = {
	"is_full_screen": false as bool,
	"resolution": Vector2i(1280, 720) as Vector2i,
	"window_position": Vector2i(640, 360) as Vector2i,
	"master_volume": 0.0 as float,
	"music_volume": 0.0 as float,
}

var saves: Array[Dictionary] = [
	{},
	{
		# scene
		"scene_path": "res://scenes/world_scene_1.tscn" as String,

		# inventories
		"consumables": [123, 45, 6, 78, 999, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as PackedInt32Array,
		"materials": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as PackedInt32Array,
		"weapons": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as PackedInt32Array,
		"armors": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as PackedInt32Array,
		"accessories": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as PackedInt32Array,
		"nexus": [0, 2, 4, 6, 8, 0, 1, 3, 5, 7, 1, 11, 111, 9, 99, 999, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1] as PackedInt32Array,
		"key": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as PackedInt32Array,
		
		# players
		"main_player": 4 as int,
		"main_player_position": Vector2(0, 0) as Vector2,
		"party": [0, 4, -1, 2] as Array[int],
		"standby": [1] as Array[int],
		"experiences": [0, 0, 0, 0, 0] as Array[int],
		
		# nexus
		"nexus_stats_types": [] as Array[Vector2],
		"nexus_stats_qualities": [] as Array[int],
		"last_nodes": [167, 154, 333, -1, 132] as Array[int],
		"unlocked": [[135, 167, 182], [139, 154, 170], [284, 333, 364], [], [100, 132, 147]] as Array[Array],
		"converted": [[[]], [[]], [[]], [[]], [[]]] as Array[Array], # saves["converted"][character_index][i] = [node, type, quality]
	},
	{},
]

var atlas_positions: Array[Vector2] = []

# initialize settings
func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings["is_full_screen"] else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(settings["resolution"])
	DisplayServer.window_set_position(settings["window_position"])
	Global.set_master_volume(settings["master_volume"])
	Global.set_music_volume(settings["music_volume"])

func new_save(character_index: int, save_index: int) -> void:
	# initialize save
	var current_save: Dictionary = {
		# scene
		"scene_path": "res://scenes/world_scene_1.tscn" as String,

		# inventories
		"consumables": [] as PackedInt32Array,
		"materials": [] as PackedInt32Array,
		"weapons": [] as PackedInt32Array,
		"armors": [] as PackedInt32Array,
		"accessories": [] as PackedInt32Array,
		"nexus": [] as PackedInt32Array,
		"key": [] as PackedInt32Array,
		
		# players
		"main_player": character_index as int,
		"main_player_position": Vector2(0, 0) as Vector2,
		"party": [character_index, -1, -1, -1] as Array[int],
		"standby": [] as Array[int],
		"experiences": [] as Array[int],
		
		# nexus
		"nexus_stats_types": [] as Array[Vector2],
		"nexus_stats_qualities": [] as Array[int],
		"last_nodes": [] as Array[int],
		"unlocked": [] as Array[Array],
		"converted": [] as Array[Array],
	}

	# initialize inventories
	const INVENTORY_NAMES: Array[String] = ["consumables", "materials", "weapons", "armors", "accessories", "nexus", "key"]
	const INVENTORY_SIZES: Array[int] = [100, 101, 102, 103, 104, 105, 106]

	for i in INVENTORY_NAMES.size():
		current_save[INVENTORY_NAMES[i]].resize(INVENTORY_SIZES[i])
		current_save[INVENTORY_NAMES[i]].fill(0)

	# initialize players
	const CHARACTER_COUNT: int = 20
	const CHARACTER_DEFAULT_KEYS: Array[String] = ["experiences", "last_nodes", "unlocked", "converted"]
	const CHARACTER_DEFAULT_VALUES: Array = [-1, -1, [], []]

	for i in CHARACTER_DEFAULT_KEYS.size():
		current_save[CHARACTER_DEFAULT_KEYS[i]].resize(CHARACTER_COUNT)
		current_save[CHARACTER_DEFAULT_KEYS[i]].fill(CHARACTER_DEFAULT_VALUES[i])

	# TODO: initialize nexus

	# set character info
	const DEFAULT_NEXUS_NODES: Array[Array] = [
		[135, 167, 182],
		[139, 154, 170],
		[284, 333, 364],
		[491, 522, 523],
		[100, 132, 147],
	]

	current_save["experiences"][character_index] = 0
	current_save["last_nodes"][character_index] = DEFAULT_NEXUS_NODES[character_index][1]
	current_save["unlocked"][character_index] = DEFAULT_NEXUS_NODES[character_index]

	# copy save
	saves[save_index] = current_save
	
	# load save
	load_save(save_index)

func load_save(save_index: int = last_save) -> void:
	last_save = save_index

	# scene
	Global.tree.call_deferred("change_scene_to_file", saves[save_index]["scene_path"])
	
	# inventories
	Inventory.consumables_inventory = saves[save_index]["consumables"].duplicate()
	Inventory.materials_inventory = saves[save_index]["materials"].duplicate()
	Inventory.weapons_inventory = saves[save_index]["weapons"].duplicate()
	Inventory.armors_inventory = saves[save_index]["armors"].duplicate()
	Inventory.accessories_inventory = saves[save_index]["accessories"].duplicate()
	Inventory.nexus_inventory = saves[save_index]["nexus"].duplicate()
	Inventory.key_inventory = saves[save_index]["key"].duplicate()
	
	# players
	const BASE_PLAYER_PATH: String = "res://entities/players/player_base.tscn"
	const CHARACTER_BASE_PATH: Array[String] = [
		"res://entities/players/character_base/sora.tscn",
		"res://entities/players/character_base/azki.tscn",
		"res://entities/players/character_base/roboco.tscn",
		"res://entities/players/character_base/akirose.tscn",
		"res://entities/players/character_base/luna.tscn",
	]

	const DEFAULT_STATS: Array[Array] = [
		[999, 99999.0, 9999.0, 500.0, 1000.0, 1000.0, 1000.0, 1000.0, 255.0, 255.0, 0.50, 0.50],
		[1, 373.0, 40.0, 100.0, 8.0, 6.0, 9.0, 12.0, 2.0, 2.0, 0.10, 0.50],
		[1, 465.0, 10.0, 120.0, 18.0, 13.0, 16.0, 4.0, 0.0, 1.0, 0.50, 0.65],
		[1, 396.0, 26.0, 100.0, 11.0, 11.0, 14.0, 12.0, 0.0, 0.0, 0.05, 0.60],
		[1, 377.0, 36.0, 100.0, 3.0, 13.0, 4.0, 18.0, 1.0, 1.0, 0.05, 0.50],
	]

	var node_index: int = 0
	# create party players
	for character_index in saves[save_index]["party"]:
		if character_index == -1:
			Combat.ui.name_labels[node_index].get_parent().modulate.a = 0.0
			node_index += 1
			continue
		
		var player_node: Node = load(BASE_PLAYER_PATH).instantiate()
		player_node.add_child(load(CHARACTER_BASE_PATH[character_index]).instantiate())
		Players.party_node.add_child(player_node)
		
		player_node.character_node.node_index = node_index
		player_node.character_node.level = DEFAULT_STATS[character_index][0]
		player_node.character_node.base_health = DEFAULT_STATS[character_index][1]
		player_node.character_node.base_mana = DEFAULT_STATS[character_index][2]
		player_node.character_node.base_stamina = DEFAULT_STATS[character_index][3]
		player_node.character_node.base_defense = DEFAULT_STATS[character_index][4]
		player_node.character_node.base_ward = DEFAULT_STATS[character_index][5]
		player_node.character_node.base_strength = DEFAULT_STATS[character_index][6]
		player_node.character_node.base_intelligence = DEFAULT_STATS[character_index][7]
		player_node.character_node.base_speed = DEFAULT_STATS[character_index][8]
		player_node.character_node.base_agility = DEFAULT_STATS[character_index][9]
		player_node.character_node.base_crit_chance = DEFAULT_STATS[character_index][10]
		player_node.character_node.base_crit_damage = DEFAULT_STATS[character_index][11]
		player_node.character_node.reset_stats() # TODO
		player_node.character_node.update_nodes() # TODO

		# position character and determine main player node
		player_node.position = saves[save_index]["main_player_position"]
		if character_index == saves[save_index]["main_player"]:
			player_node.is_main_player = true
			Players.main_player_node = player_node
			Players.camera_node.new_parent(player_node)
		else:
			player_node.position += (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
		
		node_index += 1
	
	node_index = 0

	# TODO: need to hide standbys
	for character_index in saves[save_index]["standby"]:
		var character_node: Node = load(CHARACTER_BASE_PATH[character_index]).instantiate()
		Players.standby_node.add_child(character_node)

		character_node.node_index = node_index
		character_node.level = DEFAULT_STATS[character_index][0]
		character_node.base_health = DEFAULT_STATS[character_index][1]
		character_node.base_mana = DEFAULT_STATS[character_index][2]
		character_node.base_stamina = DEFAULT_STATS[character_index][3]
		character_node.base_defense = DEFAULT_STATS[character_index][4]
		character_node.base_ward = DEFAULT_STATS[character_index][5]
		character_node.base_strength = DEFAULT_STATS[character_index][6]
		character_node.base_intelligence = DEFAULT_STATS[character_index][7]
		character_node.base_speed = DEFAULT_STATS[character_index][8]
		character_node.base_agility = DEFAULT_STATS[character_index][9]
		character_node.base_crit_chance = DEFAULT_STATS[character_index][10]
		character_node.base_crit_damage = DEFAULT_STATS[character_index][11]

		var standby_button: Button = load("res://user_interfaces/user_interfaces_resources/combat_ui_character_button.tscn").instantiate()
		Combat.ui.get_node(^"CharacterSelector/MarginContainer/ScrollContainer/CharacterSelectorVBoxContainer").add_child(standby_button)
		standby_button.pressed.connect(Players.update_standby_player.bind(standby_button.get_index()))
		standby_button.pressed.connect(Combat.ui.button_pressed)
		standby_button.mouse_entered.connect(Combat.ui._on_control_mouse_entered)
		standby_button.mouse_exited.connect(Combat.ui._on_control_mouse_exited)
		
		Combat.ui.standby_name_labels.push_back(standby_button.get_node(^"Name"))
		Combat.ui.standby_level_labels.push_back(standby_button.get_node(^"Level"))
		Combat.ui.standby_health_labels.push_back(standby_button.get_node(^"HealthAmount"))
		Combat.ui.standby_mana_labels.push_back(standby_button.get_node(^"ManaAmount"))

		character_node.reset_stats() # TODO
		character_node.update_nodes() # TODO

		node_index += 1

	Inputs.mouse_in_attack_position = true
	Inputs.combat_inputs_enabled = true

	Global.start_bgm("res://music/asmarafulldemo.mp3")

	stat_nodes_randomizer(save_index) # TODO: temporary

	# TODO: temporary
	# load variables # TODO: probably don't need to be here
	Global.nexus_stats_types = saves[save_index]["nexus_stats_types"]
	Global.nexus_stats_qualities = saves[save_index]["nexus_stats_qualities"]
	
	Global.temporary_global_variable["last_nodes"] = saves[save_index]["last_nodes"]
	Global.temporary_global_variable["unlocked"] = saves[save_index]["unlocked"]
	Global.temporary_global_variable["converted"] = saves[save_index]["converted"]

func save(save_index):
	saves[save_index] = Global.current_save.duplicate()

	for player_node in Players.party_node.get_children():
		saves[save_index]["party"].push_back(Global.player_node.character_node.character_index)

# randomizes all empty nodes with randomized stat types and stat qualities
func stat_nodes_randomizer(save_index):
	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
	var area_nodes: Array[Array] = [
		[132, 133, 134, 146, 147, 149, 163, 164, 165, 166, 179, 182, 196, 198, 199, 211, 212, 213, 214, 215, 228, 229, 231, 232, 243, 244, 245, 246, 247, 260, 261, 262, 264, 277, 278, 279, 280, 292, 294, 296, 309, 310, 311, 324, 325, 327, 328, 340],
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
		[271, 286, 287, 316, 317, 318, 319, 333, 334, 335, 348, 349, 350, 351, 366, 367, 398, 399, 414, 415, 430, 431, 447, 463, 479, 495, 510, 511]
	]

	# area stat number
	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
	# Empty, HP, MP, DEF, WRD, ATK, INT, SPD, AGI, EMPTY
	var area_amount: Array[Array] = [
		[6, 11, 2, 5, 2, 6, 2, 2],
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
		[8, 2, 3, 1, 2, 1, 0, 0]
	]

	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
	# area stat flactuation
	const rand_weight: Array[Array] = [
		[2, 3, 1, 1, 1, 2, 1, 1],
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
		[2, 1, 1, 1, 1, 0, 0, 0]
	]

	const stats_node_atlas_position: Array[Vector2] = [Vector2(0, 32), Vector2(32, 32), Vector2(64, 32), Vector2(96, 32), Vector2(0, 64), Vector2(32, 64), Vector2(64, 64), Vector2(96, 64)]
	const empty_node_atlas_position := Vector2(0, 0)
	var area_texture_positions: Array[Vector2] = []
	
	var area_size := 0
	var area_texture_positions_size := 0
	var i := 0

	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
	# HP, MP, DEF, WRD, ATK, INT, SPD, AGI
	const area_stats_qualities := [
		[0, 0, 0, 0, 0, 0, 0, 0],
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
		[1, 0, 1, 1, 0, 0, 0, 0]
	]

	# HP, MP, DEF, WRD, ATK, INT, SPD, AGI, EMPTY
	const stats_qualities := [
		[[200, 200, 300], [200, 200, 300, 300, 300, 400], [300, 300, 400]],
		[[10, 10, 20], [10, 10, 20, 20, 40], [20, 20, 40]],
		[[5, 10], [5, 10, 10, 15], [10, 15]],
		[[5, 10], [5, 10, 10, 15], [10, 15]],
		[[5, 5, 5, 10], [5, 10], [10]],
		[[5, 5, 5, 10], [5, 10], [10]],
		[[1, 1, 2, 2, 2, 3], [1, 2, 3, 3, 4], [3, 4]],
		[[1, 1, 2, 2, 2, 3], [1, 2, 3, 3, 4], [3, 4]],
	]

	var node_qualities: Array[int] = []

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

			if (i > area_texture_positions_size):
				atlas_positions[node_index] = area_texture_positions.pop_at(randi() % (area_texture_positions_size))
				area_texture_positions_size -= 1

	saves[save_index]["nexus_stats_types"] = atlas_positions.duplicate()

	# randomize stat node qualities
	for j in 768:
		node_qualities.push_back(0)

	for area_index in area_nodes.size():
		for node_index in area_nodes[area_index]:
			for stat_index in stats_node_atlas_position.size():
				if atlas_positions[node_index] == stats_node_atlas_position[stat_index]:
					node_qualities[node_index] = stats_qualities[stat_index][area_stats_qualities[area_index][stat_index]][randi() % stats_qualities[stat_index][area_stats_qualities[area_index][stat_index]].size()]

	saves[save_index]["nexus_stats_qualities"] = node_qualities.duplicate()

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
