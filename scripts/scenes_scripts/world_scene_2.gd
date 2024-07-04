extends Node2D

func _ready():
	GlobalSettings.update_nodes(self)

func _on_world_scene_1_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene(0, 1)

func _on_dungeon_scene_1_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene(2, 4)
