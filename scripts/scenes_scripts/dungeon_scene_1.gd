extends Node2D

func _ready():
	GlobalSettings.new_scene(self, [-10000000, -10000000, 10000000, 10000000]) # [-576, -144, 128, 80]

func _on_world_scene_2_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene("res://scenes/world_scene_2.tscn", Vector2(31, -103), "res://music/asmarafulldemo.mp3")
