extends CanvasLayer

func _on_escape_pressed():
	if !GlobalSettings.game_paused:
		get_tree().paused = true
		GlobalSettings.game_paused = true
		GlobalSettings.in_settings = true
		$MarginContainer/MarginContainer2/HBoxContainer/Escape.text = "▶"
	else:
		get_tree().paused = false
		GlobalSettings.game_paused = false
		GlobalSettings.in_settings = false
		$MarginContainer/MarginContainer2/HBoxContainer/Escape.text = "II"
