extends Node2D

@onready var main_menu_options_node := %MainMenuOptions
@onready var options_menu_node := %OptionsMenuMargin
@onready var saves_menu_node := %SavesMenuMargin

@onready var save_data_node := %SaveData

func _on_play_button_pressed():
	save_data_node.load(save_data_node.last_save)

func _on_multiplayer_button_pressed():
	pass

func _on_saves_button_pressed():
	saves_menu_node.show()
	options_menu_node.hide()

func _on_back_button_pressed():
	options_menu_node.show()
	saves_menu_node.hide()

func _on_mini_games_button_pressed():
	pass

func _on_achievements_button_pressed():
	pass

func _on_leaderboards_button_pressed():
	pass

func _on_settings_button_pressed():
	main_menu_options_node.hide()
	GlobalSettings.game_options_node.show()
	GlobalSettings.combat_ui_node.hide()
	GlobalSettings.combat_inputs_available = false
	GlobalSettings.game_paused = true
	GlobalSettings.game_options_node._on_settings_pressed()
