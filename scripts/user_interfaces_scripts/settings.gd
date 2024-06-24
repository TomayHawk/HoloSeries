extends CanvasLayer

@onready var nexus_load = load("res://scenes/holo_nexus.tscn")

func _on_holo_nexus_pressed():
	get_tree().active = false
	get_parent().add_child(nexus_load.instantiate())
	get_parent().get_node("HoloNexus/NexusPlayer/Camera2D").make_current()
	# GlobalSettings.players[GlobalSettings.current_main_player].get_node("Camera2D")
	$Control/SettingsOptions.hide()
