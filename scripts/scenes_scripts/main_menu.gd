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
	$SaveData.load_save($SaveData.last_save)

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
