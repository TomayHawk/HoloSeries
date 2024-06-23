extends CanvasLayer

@onready var nexus_load = load("res://scenes/holo_nexus.tscn")

func _on_holo_nexus_pressed():
	GlobalSettings.players[GlobalSettings.current_main_player].get_node("Camera2D").enabled = false
	add_child(nexus_load.instantiate())
	$Control/SettingsOptions.hide()
