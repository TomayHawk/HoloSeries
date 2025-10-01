extends Node2D

func _ready() -> void:
	Global.add_global_child("MainUi", "res://user_interfaces/main_ui.tscn")

# ..............................................................................

#region INPUTS

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

#endregion

# ..............................................................................
