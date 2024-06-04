extends Node2D

func _ready():
	GlobalSettings.update_nodes()
	GlobalSettings.players[GlobalSettings.current_main_player].position = GlobalSettings.next_spawn_position

func _on_world_scene_1_transit_body_entered(body):
	if body.current_main: GlobalSettings.change_scene(get_node("/root/WorldScene2/"), "res://scenes_s/world_scene_1.tscn", 1)

func _on_dungeon_scene_1_transit_body_entered(body):
	if body.current_main: GlobalSettings.change_scene(get_node("/root/WorldScene2/"), "res://scenes/dungeon_scene_1.tscn", 4)
