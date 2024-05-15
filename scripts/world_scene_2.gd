extends Node2D

func _ready():
	$Player.position = GlobalSettings.last_player_positions[2]

func _on_world_scene_1_transit_body_entered(body):
	if body.has_method("player"):
		GlobalSettings.change_scene(get_node("/root/WorldScene2/"), "res://scenes/world_scene_1.tscn", 2, Vector2(0, -20))
