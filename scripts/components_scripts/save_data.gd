extends Node

var last_save := 0

var saves := [
	{
	"save_index": 0,
	"resolution": Vector2(1280, 720),
	"current_scene_path": "res://scenes/world_scene_1.tscn",
	"unlocked_characters": [true, false, true, true, true],
	"party": [0, 4, 3, -1],
	"standby": [2],
	"current_main_player": 0,
	"current_main_player_position": Vector2(0, 0),
	"inventory": [],
	"nexus_last_nodes": [167, 154, 333, 523, 132],
	"nexus_unlocked": [],
	"nexus_unlockables": [],
	"nexus_quality": [],
	"nexus_converted": [],
	"nexus_converted_type": [],
	"nexus_converted_quality": [],
	"nexus_inventory": []
	}
]

func save(save_file):
	save_file = {
		"save_index": 0,
		"resolution": Vector2(1280, 720),
		"current_scene_path": "res://scenes/world_scene_1.tscn",
		"unlocked_characters": [true, false, true, true, true],
		"party": [0, 4, 3, -1],
		"standby": [2],
		"current_main_player": 0,
		"current_main_player_position": Vector2(0, 0),
		"inventory": [],
		"nexus_last_nodes": [167, 154, 333, 523, 132],
		"nexus_unlocked": [],
		"nexus_unlockables": [],
		"nexus_quality": [],
		"nexus_converted": [],
		"nexus_converted_type": [],
		"nexus_converted_quality": [],
		"nexus_inventory": []
	}

func load(save_file):
	last_save = save_file["save_index"]

	# instantiate WorldScene1
	get_tree().call_deferred("change_scene_to_file", save_file["current_scene_path"])
	
	var i = 0
	for character_unlocked in save_file["unlocked_characters"]:
		if character_unlocked:
			# create base player
			GlobalSettings.standby_player_nodes.push_back(load(GlobalSettings.base_player_path).instantiate())
			# attach character specifics
			GlobalSettings.standby_player_nodes[i].add_child(load(GlobalSettings.character_specifics_paths[i]).instantiate())
			# put player in Standby
			GlobalSettings.standby_node.add_child(GlobalSettings.standby_player_nodes[i])
			GlobalSettings.standby_player_nodes[i].player_stats_node.update_stats()
			##### add unlocked nodes (should be erased after adding "unlock character")
			GlobalSettings.nexus_nodes_unlocked[i] = GlobalSettings.standby_player_nodes[i].character_specifics_node.default_unlocked_nexus_nodes.duplicate()
		i += 1

	##### ????
	i = 0
	for character_index in save_file["party"]:
		for player_node in GlobalSettings.standby_player_nodes:
			if player_node.character_specifics_node.character_index == character_index:
				GlobalSettings.party_player_nodes.push_back(player_node)
				GlobalSettings.standby_player_nodes.erase(player_node)
				player_node.reparent(party_node)
				GlobalSettings.party_player_nodes[i].player_stats_node.update_stats()
				combat_ui_node.character_name_label_nodes[i].text = party_player_nodes[i].character_specifics_node.character_name
				break
		i += 1
	
	current_main_player_node = party_player_nodes[0]
	update_main_player(current_main_player_node)
	party_player_nodes[0].position = spawn_positions[0]

	for player_node in GlobalSettings.party_player_nodes:
		player_node.add_to_group("party")
		if player_node != current_main_player_node:
			player_node.position = current_main_player_node.position + (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
		
	
	for player_node in standby_player_nodes:
		player_node.add_to_group("standby")
		player_node.set_physics_process(false)
		player_node.hide()
	
	i = 3
	for party_player_empty in (4 - party_player_nodes.size()):
		combat_ui_node.players_info_nodes[i].hide()
		combat_ui_node.players_progress_bar_nodes[i].hide()
		i -= 1