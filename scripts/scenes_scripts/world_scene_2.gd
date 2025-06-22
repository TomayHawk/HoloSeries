extends Node2D

# ..............................................................................

# READY

func _ready() -> void:
	Global.new_scene_ready.emit()

# ..............................................................................

# SCENE CHANGES

func _on_world_scene_1_transit_body_entered(body: Node) -> void:
	if not body.is_main_player: return
	$WorldScene1Transit/CollisionShape2D.set_deferred("disabled", true)
	Global.change_scene(
			"res://scenes/world_scene_1.tscn",
			Vector2(0, -247),
			[-208, -288, 224, 64],
			"res://music/asmarafulldemo.mp3"
	)

func _on_dungeon_scene_1_transit_body_entered(body: Node) -> void:
	if not body.is_main_player: return
	$DungeonScene1Transit/CollisionShape2D.set_deferred("disabled", true)
	Global.change_scene(
			"res://scenes/dungeon_scene_1.tscn",
			Vector2(0, 53),
			[-10000000, -10000000, 10000000, 10000000],
			"res://music/shunkandemo3.mp3"
	)

# ..............................................................................
