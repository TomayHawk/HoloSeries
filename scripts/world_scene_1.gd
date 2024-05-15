extends Node2D

func _ready():
	$Player.position = GlobalSettings.last_player_positions[1]

func _on_world_scene_2_transit_body_entered(body):
	if body.has_method("player"):
		GlobalSettings.change_scene(get_node("/root/WorldScene1/"), "res://scenes/world_scene_2.tscn", 1, Vector2(0, 20))
