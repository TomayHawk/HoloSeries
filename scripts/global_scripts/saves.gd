extends Resource

# TODO: should use .dat

const PLAYER_BASE_PATH: String = "res://entities/players/player_base.tscn"

const CHARACTER_SCRIPTS: Array[String] = [
	"res://scripts/entities_scripts/players_scripts/character_scripts/sora.gd",
	"res://scripts/entities_scripts/players_scripts/character_scripts/azki.gd",
	"res://scripts/entities_scripts/players_scripts/character_scripts/roboco.gd",
	"res://scripts/entities_scripts/players_scripts/character_scripts/akirose.gd",
	"res://scripts/entities_scripts/players_scripts/character_scripts/luna.gd",
]

const CONSUMABLES_INVENTORY_SIZE: int = 100
const MATERIALS_INVENTORY_SIZE: int = 101
const NEXUS_INVENTORY_SIZE: int = 102
const KEY_INVENTORY_SIZE: int = 103

# ..............................................................................

# NEW SAVE

func new_save(character_index: int) -> void:
	var player_stats: PlayerStats = load(CHARACTER_SCRIPTS[character_index]).new()

	# initialize save
	var save_data: Dictionary = {
		# scene
		"scene_path": "res://scenes/world_scene_1.tscn" as String,

		# inventories
		"consumables_inventory": [] as Array[int],
		"materials_inventory": [] as Array[int],
		"weapons_inventory": [] as Array[int],
		"armors_inventory": [] as Array[int],
		"accessories_inventory": [] as Array[int],
		"nexus_inventory": [] as Array[int],
		"key_inventory": [] as Array[int],

		# nexus
		"nexus_types": [] as Array[int],
		"nexus_qualities": [] as Array[int],
		
		# character stats
		"characters": [
			{
				# stats
				"character_index": character_index as int,
				"experience": 0 as int,
				
				# equipments
				"weapon": -1 as int,
				"headgear": -1 as int,
				"chestpiece": -1 as int,
				"leggings": -1 as int,
				"accessory_1": -1 as int,
				"accessory_2": -1 as int,
				"accessory_3": -1 as int,

				# nexus
				"last_node": player_stats.DEFAULT_UNLOCKED[1] as int,
				"unlocked_nodes": player_stats.DEFAULT_UNLOCKED as Array[int],
				"converted_nodes": [] as Array[Vector2i],
			}
		] as Array[Dictionary],

		# players
		"main_player": character_index as int,
		"main_player_position": [0.0, 0.0] as Array[float],
		"party": [character_index, -1, -1, -1] as Array[int],
	}

	# initialize inventories
	save_data["consumables_inventory"].resize(CONSUMABLES_INVENTORY_SIZE)
	save_data["materials_inventory"].resize(MATERIALS_INVENTORY_SIZE)
	save_data["nexus_inventory"].resize(NEXUS_INVENTORY_SIZE)
	save_data["key_inventory"].resize(KEY_INVENTORY_SIZE)
	save_data["consumables_inventory"].fill(0)
	save_data["materials_inventory"].fill(0)
	save_data["nexus_inventory"].fill(0)
	save_data["key_inventory"].fill(0)

	# initialize nexus
	stat_nodes_randomizer()
	save_data["nexus_types"] = Global.nexus_types
	save_data["nexus_qualities"] = Global.nexus_qualities

	# create saves directory if it doesn't exist
	var dir: DirAccess = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")

	# find an empty save file
	var file_path: String = ""
	var save_index: int = 1
	for i in [1, 2, 3]:
		var test_path: String = "user://saves/save_%d.json" % i
		if not FileAccess.file_exists(test_path):
			file_path = test_path
			save_index = i
			break

	# store save data
	if file_path != "":
		var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(save_data))
		file.close()

	# load save
	load_save(save_index)

# ..............................................................................

# LOAD SAVE

func load_save(save_index: int = 1) -> void:
	# access save file
	var file_path: String = "user://saves/save_%d.json" % save_index
	
	if not FileAccess.file_exists(file_path):
		print("save file does not exist ", file_path)
		return # TODO: handle error

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	
	file.close()
	
	if not data:
		print("failed to parse save data from file ", file_path)
		return # TODO: handle error

	# update inventories
	copy_array(data["consumables_inventory"], Inventory.consumables_inventory)
	copy_array(data["materials_inventory"], Inventory.materials_inventory)
	copy_array(data["weapons_inventory"], Inventory.weapons_inventory)
	copy_array(data["armors_inventory"], Inventory.armors_inventory)
	copy_array(data["accessories_inventory"], Inventory.accessories_inventory)
	copy_array(data["nexus_inventory"], Inventory.nexus_inventory)
	copy_array(data["key_inventory"], Inventory.key_inventory)
	
	Combat.ui.add_items()

	# update nexus
	copy_array(data["nexus_types"], Global.nexus_types)
	copy_array(data["nexus_qualities"], Global.nexus_qualities)
	
	# update characters
	var character_stats: Array[PlayerStats] = []
	character_stats.resize(CHARACTER_SCRIPTS.size())
	character_stats.fill(null)

	for character_data in data["characters"]:
		var character_index: int = character_data["character_index"]
		var stats: PlayerStats = load(CHARACTER_SCRIPTS[character_index]).new()

		character_stats[character_index] = stats

		# experience
		stats.update_experience(character_data["experience"])

		# equipments
		stats.weapon = null if character_data["weapon"] == -1 else Inventory.weapons[character_data["weapon"]]
		stats.headgear = null if character_data["headgear"] == -1 else Inventory.armors[character_data["headgear"]]
		stats.chestpiece = null if character_data["chestpiece"] == -1 else Inventory.armors[character_data["chestpiece"]]
		stats.leggings = null if character_data["leggings"] == -1 else Inventory.armors[character_data["leggings"]]
		stats.accessory_1 = null if character_data["accessory_1"] == -1 else Inventory.accessories[character_data["accessory_1"]]
		stats.accessory_2 = null if character_data["accessory_2"] == -1 else Inventory.accessories[character_data["accessory_2"]]
		stats.accessory_3 = null if character_data["accessory_3"] == -1 else Inventory.accessories[character_data["accessory_3"]]

		# nexus
		stats.last_node = character_data["last_node"]
		copy_array(character_data["unlocked_nodes"], stats.unlocked_nodes)
		copy_converted_array(character_data["converted_nodes"], stats.converted_nodes) # TODO: will not work because of Vector2i
	
	# update party
	var main_player_index: int = data["main_player"]
	for party_index in data["party"].size():
		var character_index: int = data["party"][party_index]
		if character_index == -1:
			Combat.ui.name_labels[party_index].get_parent().modulate.a = 0.0
		else:
			var player: Node = load(PLAYER_BASE_PATH).instantiate()
			if character_index == main_player_index: player.is_main_player = true
			player.set_variables(character_stats[character_index], party_index)
			character_stats[character_index] = null
			Players.add_child(player)

	# update standby characters
	for character in character_stats:
		if not character: continue
		character.set_stats()
		
		Players.standby_characters.append(character)
		Combat.ui.add_standby_character(character)

	# update scene
	var main_player_position: Vector2 = Vector2(data["main_player_position"][0], data["main_player_position"][1])
	Global.change_scene(
			data["scene_path"],
			main_player_position,
			[ - 10000000, -10000000, 10000000, 10000000],
			"res://music/asmarafulldemo.mp3"
	)

	# TODO: temporary parameters 
	#data["nexus_types"] = temp_array[0]
	#data["nexus_qualities"] = temp_array[1]

	# TODO: temporary
	# load variables # TODO: probably don't need to be here
	#Global.nexus_types = temp_array[0] as Array[Vector2]
	#Global.nexus_qualities = temp_array[1] as Array[int]

func copy_array(save_array: Array, inventory_array: Array[int]) -> void:
	for value in save_array:
		inventory_array.append(int(value))

func copy_converted_array(save_array: Array, converted_array: Array[Vector2i]) -> void:
	for value in save_array:
		var converted_node: Vector2i = Vector2i.ZERO
		converted_node = Vector2i(roundi(value[0]), roundi(value[1]))
		converted_array.append(converted_node)

# ..............................................................................

# SAVE

func save(_save_index):
	pass

# ..............................................................................

# NEW SAVE NEXUS RANDOMIZER

# randomizes all empty nodes with randomized stat types and stat qualities
func stat_nodes_randomizer(): # TODO: need to change
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

	const STATS_ATLAS_POSITIONS: Array[Vector2] = [Vector2(0, 32), Vector2(32, 32), Vector2(64, 32), Vector2(96, 32), Vector2(0, 64), Vector2(32, 64), Vector2(64, 64), Vector2(96, 64)]
	const EMPTY_ATLAS_POSITION := Vector2(0, 0)
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

	var atlas_positions: Array[Vector2] = []

	for j in 768:
		atlas_positions.append(Vector2(-1, -1))
		node_qualities.append(0)

	# for each area
	for area_index in area_nodes.size():
		area_size = area_nodes[area_index].size()

		# randomize the number of each stat type
		for stat_index in STATS_ATLAS_POSITIONS.size():
			area_amount[area_index][stat_index] += round(rand_weight[area_index][stat_index] * (randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25)))

		# create an array of Vector2 positions for area stat nodes
		area_texture_positions.clear()

		for stat_type in area_amount[area_index].size():
			for j in area_amount[area_index][stat_type]:
				area_texture_positions.append(STATS_ATLAS_POSITIONS[stat_type])

		for remaining_nodes in (area_size - area_texture_positions.size() + 1):
			area_texture_positions.append(EMPTY_ATLAS_POSITION)

		# find satifying stat type for each node
		area_nodes[area_index].shuffle()
		area_texture_positions.shuffle()

		area_texture_positions_size = area_texture_positions.size()

		for node_index in area_nodes[area_index]:
			i = 0
			while (area_texture_positions_size >= i):
				atlas_positions[node_index] = area_texture_positions[area_texture_positions_size - 1 - i]
				if has_illegal_adjacents(atlas_positions, node_index):
					i += 1
				else:
					area_texture_positions.pop_at(area_texture_positions_size - 1 - i)
					area_texture_positions_size -= 1
					break

			if (i > area_texture_positions_size):
				atlas_positions[node_index] = area_texture_positions.pop_at(randi() % (area_texture_positions_size))
				area_texture_positions_size -= 1

	for area_index in area_nodes.size():
		for node_index in area_nodes[area_index]:
			for stat_index in STATS_ATLAS_POSITIONS.size():
				if atlas_positions[node_index] == STATS_ATLAS_POSITIONS[stat_index]:
					node_qualities[node_index] = stats_qualities[stat_index][area_stats_qualities[area_index][stat_index]][randi() % stats_qualities[stat_index][area_stats_qualities[area_index][stat_index]].size()]

	# TODO: TEMPORARY CODE
	var temp_array_1: Array[int] = []
	for atlas_position in atlas_positions:
		if STATS_ATLAS_POSITIONS.has(atlas_position):
			temp_array_1.append(STATS_ATLAS_POSITIONS.find(atlas_position))
		else:
			temp_array_1.append(-1)
	# TODO: TEMPORARY CODE
	Global.nexus_types = temp_array_1
	Global.nexus_qualities = node_qualities

func has_illegal_adjacents(atlas_positions, node_index):
	const ADJACENT_INDICES: Array[Array] = [[-32, -17, -16, 15, 16, 32], [-32, -16, -15, 16, 17, 32]]
	var adjacents := []
	
	# determine adjacents
	if (node_index % 32) < 16:
		for temp_index in ADJACENT_INDICES[0]: adjacents.append(node_index + temp_index)
	else:
		for temp_index in ADJACENT_INDICES[1]: adjacents.append(node_index + temp_index)

	# remove outside range
	for temp_index in adjacents.duplicate():
		if (temp_index < 0) or (temp_index > 767):
			adjacents.erase(temp_index)
	
	# check for identical
	for adjacent_index in adjacents:
		if atlas_positions[node_index] == atlas_positions[adjacent_index]:
			return true
	
	return false
