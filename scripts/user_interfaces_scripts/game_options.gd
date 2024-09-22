extends CanvasLayer

func _on_holo_nexus_pressed():
	GlobalSettings.pause_game(true, "in_nexus")
	GlobalSettings.on_nexus = true
	get_tree().root.add_child(load(GlobalSettings.nexus_path).instantiate())
