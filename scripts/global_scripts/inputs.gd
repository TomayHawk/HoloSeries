extends Control

# TODO: deal with all inputs everywhere

var alt_pressed: bool = false

var world_inputs_enabled: bool = false
var action_inputs_enabled: bool = false
var zoom_inputs_enabled: bool = false

var sprint_hold: bool = true

func _input(event: InputEvent) -> void:
	# ignore all unrelated inputs
	if not (event.is_action(&"alt") or event.is_action(&"action") or event.is_action(&"full_screen")):
		return
	
	if event.is_action(&"alt"):
		alt_pressed = event.is_pressed()
		accept_event()
	elif Input.is_action_just_pressed(&"action"):
		if attempt_action_input():
			print("Action input")
			accept_event()
	elif Input.is_action_just_pressed(&"full_screen"):
		accept_event()
		Settings.toggle_fullscreen(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action(&"esc"): return
	
	accept_event()

	if Input.is_action_just_pressed(&"esc"):
		if Entities.requesting_entities:
			Entities.end_entities_request()
		else:
			Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")

func attempt_action_input() -> bool:
	print(action_inputs_enabled)
	if action_inputs_enabled and not Entities.requesting_entities and Players.main_player:
		# TODO: temporary code
		Players.main_player.action_input()
		return true

	return false
