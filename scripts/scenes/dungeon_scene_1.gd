extends Node2D

func _ready():
	$Player.position = GlobalSettings.next_spawn_position

func _on_world_scene_2_transit_body_entered(body):
	if body.has_method("player"):
		GlobalSettings.change_scene(get_node("/root/DungeonScene1/"), "res://scenes/world_scene_2.tscn", 3)
