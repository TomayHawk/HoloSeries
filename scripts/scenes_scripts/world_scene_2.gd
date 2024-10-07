extends Node2D

func _on_world_scene_1_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene("world_scene_1", 0, 1, "beach_bgm")

func _on_dungeon_scene_1_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene("dungeon_scene_1", 2, 4, "dungeon_bgm")
