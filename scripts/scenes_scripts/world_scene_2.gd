extends Node2D

func _ready():
	GlobalSettings.new_scene(self, [-10000000, -10000000, 10000000, 10000000]) # [-640, -352, 640, 352]

func _on_world_scene_1_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene("res://scenes/world_scene_1.tscn", Vector2(0, -247), "res://music/asmarafulldemo.mp3")

func _on_dungeon_scene_1_transit_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		GlobalSettings.change_scene("res://scenes/dungeon_scene_1.tscn", Vector2(0, 53), "res://music/shunkandemo3.mp3")
