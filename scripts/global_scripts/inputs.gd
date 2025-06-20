extends Control

var world_inputs_enabled: bool = false
var action_inputs_enabled: bool = false

var sprint_hold: bool = true

func _input(event: InputEvent) -> void:
	# end propogation for mouse motion and screen touch events
	if event is InputEventMouseMotion or event is InputEventScreenTouch:
		accept_event()
		return
	
	# ignore all unrelated inputs
	if not (event.is_action(&"action") or event.is_action(&"full_screen") \
			or event.is_action(&"scroll_up") or event.is_action(&"scroll_down")):
				return
	
	if not event.is_action(&"action"):
		accept_event()

	if Input.is_action_just_pressed(&"action"):
		if attempt_action_input():
			print("Action input accepted")
			accept_event()
	elif Input.is_action_just_pressed(&"full_screen"):
		Settings.toggle_fullscreen(
				DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED)
	elif Input.is_action_just_pressed(&"scroll_up"):
		Players.camera_node.zoom_input(1)
	elif Input.is_action_just_pressed(&"scroll_down"):
		Players.camera_node.zoom_input(-1)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action(&"esc"):
		return

	accept_event()

	if Input.is_action_just_pressed(&"esc"):
		if Entities.requesting_entities:
			Entities.end_entities_request()
		else:
			Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")

func attempt_action_input() -> bool:
	if action_inputs_enabled and not Entities.requesting_entities and Players.main_player:
		# TODO: temporary code
		Players.main_player.action_input()
		return true

	return false
