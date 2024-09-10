extends Node2D

func _ready():
	GlobalSettings.update_nodes(self, "change_scene")

func _on_world_scene_2_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene(1, 2)
