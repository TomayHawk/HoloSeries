extends Node

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
	"nexus_last_nodes": [167, 154, 333, 523, 132],
	"nexus_unlocked": [],
	"nexus_unlockables": [],
	"nexus_quality": [],
	"nexus_converted": [],
	"nexus_converted_type": [],
	"nexus_converted_quality": [],
	"inventory": [],
	"nexus_inventory": []
	}
]

var temp_save := {
}

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
		"nexus_last_nodes": [167, 154, 333, 523, 132],
		"nexus_unlocked": [],
		"nexus_unlockables": [],
		"nexus_quality": [],
		"nexus_converted": [],
		"nexus_converted_type": [],
		"nexus_converted_quality": [],
		"inventory": [],
		"nexus_inventory": []
	}

	print(save_file)

func load(save_file):
	print(save_file)