extends Node2D

func _on_world_scene_2_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene("world_scene_2", 1, 3, "beach_bgm")
