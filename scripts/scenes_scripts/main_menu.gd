extends Node2D

@onready var main_menu_options_node := %MainMenuOptions
@onready var options_menu_node := %OptionsMenuMargin
@onready var saves_menu_node := %SavesMenuMargin
@onready var save_data_node := %SaveData

const camera_limits := [-10000000, -10000000, 10000000, 10000000]

func _on_play_button_pressed():
	save_data_node.load(save_data_node.last_save)

func _on_multiplayer_button_pressed():
	pass

func _on_saves_button_pressed():
	GlobalSettings.ui_state = GlobalSettings.UiState.MAIN_MENU_SAVES
	saves_menu_node.show()
	options_menu_node.hide()

func _on_back_button_pressed():
	GlobalSettings.ui_state = GlobalSettings.UiState.MAIN_MENU
	options_menu_node.show()
	saves_menu_node.hide()

func _on_mini_games_button_pressed():
	pass

func _on_achievements_button_pressed():
	pass

func _on_leaderboards_button_pressed():
	pass

func _on_settings_button_pressed():
	GlobalSettings.esc_input()
