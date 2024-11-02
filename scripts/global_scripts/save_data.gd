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
