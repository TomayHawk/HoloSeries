extends Node2D

func _ready():
	GlobalSettings.update_nodes("change_scene", self)

func _on_world_scene_1_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene("world_scene_1", 1, "beach_bgm")

func _on_dungeon_scene_1_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene("dungeon_scene_1", 4, "dungeon_bgm")
