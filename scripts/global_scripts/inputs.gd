extends Control

var mouse_in_attack_position: bool = true
var combat_inputs_enabled := true # TODO: remove ?

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"action"):
		if mouse_in_attack_position and not Entities.requesting_entities and Players.main_player_node:
			Players.main_player_node.set_attack_state(Players.main_player_node.AttackState.ATTACKING)
	elif Input.is_action_just_pressed(&"full_screen"):
		accept_event()
		Global.toggle_full_screen()
	elif Input.is_action_just_pressed(&"scroll_up"):
		#accept_event()
		Players.camera_node.zoom_input(1)
	elif Input.is_action_just_pressed(&"scroll_down"):
		#accept_event()
		Players.camera_node.zoom_input(-1)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"esc"):
		if Entities.requesting_entities:
			Entities.reset_entity_request()
		else:
			Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")
