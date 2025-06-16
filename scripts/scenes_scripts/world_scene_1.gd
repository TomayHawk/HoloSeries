extends Node2D

# TODO: can dash past transit bodies

# ..............................................................................

# SCENE CHANGES

func _on_world_scene_2_transit_body_entered(body: Node) -> void:
	if body != Players.main_player: return
	Global.change_scene(
			"res://scenes/world_scene_2.tscn",
			Vector2(0, 341),
			[-640, -352, 640, 352],
			"res://music/asmarafulldemo.mp3"
	)
