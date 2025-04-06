extends StaticBody2D

# COMPLETE

var active: bool = false

func _input(_event: InputEvent) -> void:
	if active and Input.is_action_just_pressed(&"interact") and get_parent().can_interact():
		get_parent().interact()
		Inputs.accept_event()

func interaction_area(status: bool) -> void:
	active = status
