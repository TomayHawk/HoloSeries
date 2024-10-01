extends Node

var last_save := 0

var saves := [
	{
	"save_index": 0,
	"current_scene_path": "res://scenes/world_scene_1.tscn",
	"unlocked_characters": [0, 1, 2, 4],
	"party": [0, 4, 2],
	"standby": [1],
	"current_main_player": 4,
	"current_main_player_position": Vector2(0, 0),
	"character_levels": [0, 0, 0, 0, 0],
	"character_experiences": [0.0, 0.0, 0.0, 0.0, 0.0],
	"inventory": [0, 0, 0],
	"nexus_not_randomized": true,
	"nexus_randomized_atlas_positions": [],
	"nexus_last_nodes": [167, 154, 333, 0, 132],
	"nexus_unlocked": [[135, 167, 182], [139, 154, 170], [284, 333, 364], [], [100, 132, 147]],
	"nexus_unlockables": [[151, 199], [171, 138], [301, 316, 348], [], [116, 164]],
	"nexus_quality": [],
	"nexus_converted": [[], [], [], [], []],
	"nexus_converted_type": [[], [], [], [], []],
	"nexus_converted_quality": [[], [], [], [], []],
	"nexus_stats": [[0, 0, 0, 0, 0, 0, 0, 0],
					[0, 0, 0, 0, 0, 0, 0, 0],
					[0, 0, 0, 0, 0, 0, 0, 0],
					[0, 0, 0, 0, 0, 0, 0, 0],
					[0, 0, 0, 0, 0, 0, 0, 0]],
	"nexus_inventory": [0, 2, 4, 6, 8, 0, 1, 3, 5, 7, 1, 11, 111, 9, 99, 999, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1]
	}
]

func save(save_file):
	saves[save_file] = {
		"save_index": saves[save_file]["save_index"],
		"current_scene_path": GlobalSettings.current_scene_node.get_path(), ## ### need to fix
		"unlocked_characters": GlobalSettings.unlocked_characters.duplicate(),
		"party": [],
		"standby": GlobalSettings.standby_character_indices.duplicate(),
		"current_main_player": GlobalSettings.current_main_player_node.character_specifics_node.character_index,
		"current_main_player_position": GlobalSettings.current_main_player_node.position,
		"character_levels": GlobalSettings.character_levels.duplicate(),
		"character_experiences": GlobalSettings.character_experiences.duplicate(),
		"inventory": GlobalSettings.inventory.duplicate(),
		"nexus_not_randomized": GlobalSettings.nexus_not_randomized,
		"nexus_randomized_atlas_positions": GlobalSettings.nexus_randomized_atlas_positions.duplicate(),
		"nexus_last_nodes": GlobalSettings.nexus_last_nodes.duplicate(),
		"nexus_unlocked": GlobalSettings.nexus_unlocked.duplicate(),
		"nexus_unlockables": GlobalSettings.nexus_unlockables.duplicate(),
		"nexus_quality": GlobalSettings.nexus_quality.duplicate(),
		"nexus_converted": GlobalSettings.nexus_converted.duplicate(),
		"nexus_converted_type": GlobalSettings.nexus_converted_type.duplicate(),
		"nexus_converted_quality": GlobalSettings.nexus_converted_quality.duplicate(),
		"nexus_stats": GlobalSettings.nexus_stats.duplicate(),
		"nexus_inventory": GlobalSettings.nexus_inventory.duplicate()
	}

	for player_node in GlobalSettings.party_player_nodes:
		saves[save_file]["party"].push_back(GlobalSettings.player_node.character_specifics_node.character_index)

func load(save_file):
	GlobalSettings.current_save = save_file
	last_save = saves[save_file]["save_index"]

	# instantiate WorldScene1
	get_tree().call_deferred("change_scene_to_file", saves[save_file]["current_scene_path"])
	
	# update Global variables
	GlobalSettings.unlocked_characters = saves[save_file]["unlocked_characters"].duplicate()
	GlobalSettings.standby_character_indices = saves[save_file]["standby"].duplicate()
	GlobalSettings.character_levels = saves[save_file]["character_levels"].duplicate()
	GlobalSettings.character_experiences = saves[save_file]["character_experiences"].duplicate()
	GlobalSettings.inventory = saves[save_file]["inventory"].duplicate()
	GlobalSettings.nexus_not_randomized = saves[save_file]["nexus_not_randomized"]
	GlobalSettings.nexus_randomized_atlas_positions = saves[save_file]["nexus_randomized_atlas_positions"].duplicate()
	GlobalSettings.nexus_last_nodes = saves[save_file]["nexus_last_nodes"].duplicate()
	GlobalSettings.nexus_unlocked = saves[save_file]["nexus_unlocked"].duplicate()
	GlobalSettings.nexus_unlockables = saves[save_file]["nexus_unlockables"].duplicate()
	GlobalSettings.nexus_quality = saves[save_file]["nexus_quality"].duplicate()
	GlobalSettings.nexus_converted = saves[save_file]["nexus_converted"].duplicate()
	GlobalSettings.nexus_converted_type = saves[save_file]["nexus_converted_type"].duplicate()
	GlobalSettings.nexus_converted_quality = saves[save_file]["nexus_converted_quality"].duplicate()
	GlobalSettings.nexus_stats = saves[save_file]["nexus_stats"].duplicate()
	GlobalSettings.nexus_inventory = saves[save_file]["nexus_inventory"].duplicate()
	
	var base_player_path := "res://entities/players/player.tscn"
	var character_specifics_paths := ["res://entities/players/character_specifics/sora.tscn",
									  "res://entities/players/character_specifics/azki.tscn",
									  "res://entities/players/character_specifics/roboco.tscn",
									  "res://entities/players/character_specifics/akirose.tscn",
									  "res://entities/players/character_specifics/luna.tscn"]
	var player_standby_path := "res://entities/players/player_standby.tscn"

	var party_player_nodes = GlobalSettings.party_player_nodes
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
		if character_index == saves[save_file]["current_main_player"]:
			GlobalSettings.current_main_player_node = player_node
			GlobalSettings.update_nodes("update_main_player", player_node)
		else:
			player_node.position += (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
	
	for character_index in saves[save_file]["standby"]:
		player_node = load(player_standby_path).instantiate()
		player_node.add_child(load(character_specifics_paths[character_index]).instantiate())
		GlobalSettings.standby_player_nodes.push_back(player_node)
		GlobalSettings.standby_node.add_child(player_node)
		player_node.player_stats_node.update_stats()

	# hide unused character info slots
	for i in 4:
		if i >= party_player_nodes.size():
			GlobalSettings.combat_ui_node.players_info_nodes[i].hide()
			GlobalSettings.combat_ui_node.players_progress_bar_nodes[i].hide()

	GlobalSettings.combat_ui_node.update_character_selector()
	GlobalSettings.combat_inputs_available = true
	GlobalSettings.mouse_in_zoom_area = true