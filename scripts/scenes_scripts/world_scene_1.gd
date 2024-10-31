extends Node2D

func _ready():
	GlobalSettings.new_scene(self, [-208, -288, 224, 64])

func _on_world_scene_2_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene("res://scenes/world_scene_2.tscn", Vector2(0, 341), "res://music/asmarafulldemo.mp3")
