class_name PlayerMain extends PlayerBase

func _physics_process(_delta: float) -> void:
	var input_velocity: Vector2 = Input.get_vector(&"left", &"right", &"up", &"down", 0.2)
	
	# snap input velocity to cardinal and intercardinal directions
	if input_velocity != Vector2.ZERO:
		input_velocity = [
			Vector2(1.0, 0.0),
			Vector2(0.70710678, 0.70710678),
			Vector2(0.0, 1.0),
			Vector2(-0.70710678, 0.70710678),
			Vector2(-1.0, 0.0),
			Vector2(-0.70710678, -0.70710678),
			Vector2(0.0, -1.0),
			Vector2(0.70710678, -0.70710678)
		][(roundi(input_velocity.angle() / (PI / 4)) + 8) % 8]

	update_velocity(input_velocity)
	
	move_and_slide()

func _input(_event: InputEvent) -> void:
	# TODO: should add toggle setting for release dash
	if Input.is_action_just_pressed(&"dash"):
		dash()
