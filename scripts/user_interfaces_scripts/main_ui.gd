extends CanvasLayer

# ..............................................................................

#region OPTIONS MENU

func _on_play_button_pressed():
	const SETTINGS_PATH: String = "user://settings.cfg"

	var saves: Resource = load("res://scripts/global_scripts/saves.gd").new()
	var config: ConfigFile = ConfigFile.new()

	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)

	saves.load_save(config.get_value("save", "last_save", 1))
	queue_free()

func _on_saves_button_pressed():
	$SavesMenuMargin.show()
	$OptionsMenuMargin.hide()

func _on_settings_button_pressed():
	Global.add_global_child("SettingsUi", "res://user_interfaces/settings_ui.tscn")

#endregion

# ..............................................................................

#region SAVES MENU

func _on_back_button_pressed():
	$OptionsMenuMargin.show()
	$SavesMenuMargin.hide()

#endregion

# ..............................................................................
