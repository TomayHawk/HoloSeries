extends Node2D

func _ready():
	GlobalSettings.update_nodes("change_scene", self)

func _on_world_scene_1_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene(0, 1, null)

func _on_dungeon_scene_1_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene(2, 4, "dungeon_bgm")
