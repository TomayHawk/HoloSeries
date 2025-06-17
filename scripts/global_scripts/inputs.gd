extends Control

var mouse_in_combat_area: bool = false
var combat_inputs_enabled: bool = false

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"full_screen"):
		accept_event()
		Settings.toggle_fullscreen(
				DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED)
	elif Input.is_action_just_pressed(&"scroll_up"):
		Players.camera_node.zoom_input(1)
	elif Input.is_action_just_pressed(&"scroll_down"):
		Players.camera_node.zoom_input(-1)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"action"):
		if mouse_in_combat_area and not Entities.requesting_entities and Players.main_player:
			Players.main_player.action_request()
	elif Input.is_action_just_pressed(&"esc"):
		if Entities.requesting_entities:
			Entities.end_entities_request()
		else:
			Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")
