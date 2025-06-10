class_name PlayerAlly extends PlayerBase

# TODO: IMPLEMENTING RIGHT NOW
func enter_attack_range() -> void:
	if not in_attack_range:
		in_attack_range = true
		action_state = ActionState.READY

# TODO: IMPLEMENTING RIGHT NOW
func exit_attack_range() -> void:
	in_attack_range = false

func _on_ally_move_cooldown_timeout() -> void:
	if Combat.in_combat() or move_state in [MoveState.KNOCKBACK, MoveState.STUN, MoveState.IDLE]:
		can_move = true
		return

	var ally_distance: float = position.distance_to(Players.main_player_node.position)
	var idle_time: float = \
			randf_range(1.6, 1.8) if ally_distance < 70 \
			else randf_range(0.8, 1.0) if ally_distance < 100 \
			else randf_range(0.4, 0.6) if ally_distance < 160 \
			else 0.0

	if idle_time > 0.0:
		update_velocity(Vector2.ZERO)
		$AllyIdleCooldown.start(idle_time)
		can_move = false
	else:
		# TODO: add teleport when far
		can_move = true
