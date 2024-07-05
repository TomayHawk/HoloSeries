extends CanvasLayer

@onready var nexus_path = "res://scenes/holo_nexus.tscn"

func _ready():
	hide()

func _on_holo_nexus_pressed():
	get_tree().root.add_child(load(nexus_path).instantiate())
	GlobalSettings.current_scene_node.paused = true
	GlobalSettings.current_scene_node.hide()
	GlobalSettings.hide()