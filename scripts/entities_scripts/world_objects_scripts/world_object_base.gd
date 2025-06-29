extends StaticBody2D

func _ready() -> void:
	set_process_input(false)

func _input(event: InputEvent) -> void:
	if (
			Input.is_action_just_pressed(&"interact") # interaction button pressed
			and Inputs.world_inputs_enabled # world inputs are enabled
			and event.is_action(&"interact") # event is an interaction event
			and get_parent().can_interact() # parent accepts interaction
	):
		Inputs.accept_event()
		get_parent().interact()

func interaction_area(status: bool) -> void:
	set_process_input(status)
