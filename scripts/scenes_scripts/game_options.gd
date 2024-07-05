extends CanvasLayer

@onready var nexus_path = "res://user_interfaces/holo_nexus.tscn"

func _ready():
	hide()

func _on_holo_nexus_pressed():
	get_tree().root.add_child(load(nexus_path).instantiate())
	get_tree().paused = true
	GlobalSettings.game_paused = true
	GlobalSettings.combat_ui_node.hide()
	GlobalSettings.current_scene_node.hide()
	GlobalSettings.hide()
	GlobalSettings.on_nexus = true
	hide()
