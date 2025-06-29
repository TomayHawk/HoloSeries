extends CanvasLayer

# ..............................................................................

# INPUTS

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"esc"):
		Inputs.accept_event()
		if $SavesMenuMargin.is_visible():
			$SavesMenuMargin.hide()
			$OptionsMenuMargin.show()
		elif Global.get_node_or_null(^"SettingsUi"):
			Global.remove_global_child("SettingsUi")
		else:
			Global.add_global_child("SettingsUi", "res://user_interfaces/settings_ui.tscn")

# ..............................................................................

# OPTIONS MENU

func _on_play_button_pressed():
	const SETTINGS_PATH: String = "user://settings.cfg"

	var saves: Resource = load("res://scripts/global_scripts/saves.gd").new()
	var config: ConfigFile = ConfigFile.new()

	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)

	saves.load_save(config.get_value("save", "last_save", 1))

func _on_saves_button_pressed():
	$SavesMenuMargin.show()
	$OptionsMenuMargin.hide()

func _on_settings_button_pressed():
	Global.add_global_child("SettingsUi", "res://user_interfaces/settings_ui.tscn")

# ..............................................................................

# SAVES MENU

func _on_back_button_pressed():
	$OptionsMenuMargin.show()
	$SavesMenuMargin.hide()

# ..............................................................................
