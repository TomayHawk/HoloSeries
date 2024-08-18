extends Node2D

@onready var save_data_node := $SaveData

func _on_play_button_pressed():
	GlobalSettings.start_game(save_data_node, save_data_node.last_save)
	# queue_free()

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
