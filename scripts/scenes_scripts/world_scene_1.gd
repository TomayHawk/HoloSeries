extends Node2D

func _ready():
	GlobalSettings.update_nodes()
	GlobalSettings.players[GlobalSettings.current_main_player].position = GlobalSettings.next_spawn_position

func _on_world_scene_2_transit_body_entered(body):
	if body.current_main:
		GlobalSettings.change_scene("res://scenes/world_scene_2.tscn", 2)
