extends Node2D

# ..............................................................................

#region ACTION STATES

# TODO: should not just be basic attack or ultimate attack
func action_input() -> void:
	var base_player: PlayerBase = get_parent()

	# check action state
	if base_player.action_state != base_player.ActionState.READY:
		return
	
	base_player.stats.basic_attack()

func enter_combat() -> void:
	if not get_parent().is_main_player:
		prepare_action()

func leave_combat() -> void:
	var base_player: PlayerBase = get_parent()

	# if is main player or in action, ignore or resolve naturally
	if base_player.is_main_player or base_player.action_state == base_player.ActionState.ACTION:
		return

	# reset action variables
	base_player.reset_action()
	base_player.reset_action_targets()
	base_player.action_queue.clear()
	base_player.action_fail_count = 0

# TODO: queue_action should not just be basic attack
func queue_action(action: Node = null) -> void:
	var base_player: PlayerBase = get_parent()
	
	if not action:
		base_player.action = base_player.stats.basic_attack
	
	base_player.action_queue.append(action)

func prepare_action() -> void:
	var base_player: PlayerBase = get_parent()

	# if action queue is empty, create a new action
	if base_player.action_queue.is_empty():
		base_player.queue_action()

	# initialize next action
	base_player.action_callable = base_player.action_queue.pop_front()
	await base_player.action_callable.call(true)

func attempt_action() -> void:
	var base_player: PlayerBase = get_parent()

	if base_player.action_callable == Callable():
		print("Action not found")
		await prepare_action()
	
	# set action target and action vector
	set_action_target()
	
	# if failed to find action target, wait 0.5 seconds to try again
	if not base_player.action_target:
		base_player.action_state = base_player.ActionState.COOLDOWN
		base_player.action_cooldown = 0.5
		base_player.action_fail_count += 1
		return

	# update movement
	base_player.apply_movement(Vector2.ZERO)

	# call action
	base_player.action_callable.call()

func set_action_target() -> void:
	var base_player: PlayerBase = get_parent()
	
	# if taking action, return
	if base_player.action_state == base_player.ActionState.ACTION:
		return
	
	# if no action candidates, reset action target and return
	if base_player.action_target_candidates.is_empty():
		base_player.action_target = null
		return

	# set action target
	base_player.action_target = Entities.target_entity_by_stats(
			base_player.action_target_candidates, base_player.action_target_stats, base_player.action_target_get_max)

	# set action vector
	base_player.action_vector = (base_player.action_target.position - base_player.position).normalized()

#endregion
