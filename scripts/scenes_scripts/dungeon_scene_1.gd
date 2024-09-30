extends Node2D

func _ready():
	GlobalSettings.update_nodes("change_scene", self)

func _on_world_scene_2_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene(1, 3, "beach_bgm")
