extends CanvasLayer

func _on_play_button_pressed():
	get_tree().root.add_child(load("res://components/global_game_settings.tscn").instantiate())
	queue_free()

func _on_saves_button_pressed():
	pass

func _on_multiplayer_button_pressed():
	pass

func _on_mini_games_button_pressed():
	pass

func _on_achievements_button_pressed():
	pass

func _on_leaderboards_button_pressed():
	pass

func _on_settings_button_pressed():
	pass
