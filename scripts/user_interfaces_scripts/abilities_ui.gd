extends CanvasLayer

func _input(event: InputEvent) -> void:
	# ignore all unrelated inputs
	if not event.is_action(&"esc"):
		return
	
	Inputs.accept_event()

	if Input.is_action_just_pressed(&"esc"):
		exit_ui()

func exit_ui() -> void:
	Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")
	queue_free()
