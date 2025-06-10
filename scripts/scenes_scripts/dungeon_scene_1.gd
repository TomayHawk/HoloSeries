extends Node2D

# ..............................................................................

# SCENE CHANGES

func _on_world_scene_2_transit_body_entered(body: Node) -> void:
	if body != Players.main_player_node: return
	Global.change_scene(
			"res://scenes/world_scene_2.tscn",
			Vector2(31, -103),
			[-640, -352, 640, 352],
			"res://music/asmarafulldemo.mp3"
	)
