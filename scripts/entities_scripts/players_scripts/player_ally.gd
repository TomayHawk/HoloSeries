class_name PlayerAlly extends PlayerBase

const ROAM_DISTANCE: float = 75.0
const MAX_ALLY_DISTANCE: float = 200.0

# PlayerAlly physics process
func _physics_process(_delta: float) -> void:
	# attempt action
	var action_success: bool = false
	if action_state == ActionState.READY and not action_queue.is_empty():
		action_success = await action_queue[0][0].callv(action_queue[0][1])
		if action_success:
			action_queue.remove_at(0)
	
	move_and_slide()

# TODO: IMPLEMENTING RIGHT NOW
func enter_attack_range() -> void:
	if not in_action_range:
		in_action_range = true
		action_state = ActionState.READY

# TODO: IMPLEMENTING RIGHT NOW
func exit_attack_range() -> void:
	in_action_range = false

# PlayerAlly move process
func _on_ally_move_timer_timeout() -> void:
	# if ally in another move state, continue timer
	if move_state_timer > 0.0:
		$AllyMoveTimer.start(move_state_timer)
		return
	
	# if ally in action state, continue timer
	if not action_state in [ActionState.READY, ActionState.COOLDOWN]:
		$AllyMoveTimer.start($AllyActionTimer.time_left)
		return

	var ally_distance: float = position.distance_to(Players.main_player_node.position)
	var move_timer: float = 0.0
	
	# handle idle state
	if move_state != MoveState.IDLE:
		# determine idle time based on ally distance
		move_timer = \
				randf_range(1.6, 1.8) if ally_distance < ROAM_DISTANCE \
				else randf_range(0.8, 1.0) if ally_distance < 100 \
				else randf_range(0.4, 0.6) if ally_distance < 150 \
				else 0.0

		# if in idle distance, update velocity to zero
		if move_timer > 0.0:
			update_velocity(Vector2.ZERO)
			$AllyMoveTimer.start(move_timer)
			return
		
		# if large ally distance, teleport to main player
		if ally_distance > MAX_ALLY_DISTANCE:
			pass # TODO: teleport to main player
	
	# if not in idle state, find target direction
	var target_direction: Vector2 = Vector2.ZERO

	# if in combat, navigate to target enemy
	if Combat.in_combat():
		# TODO: move this somewhere else
		# TODO: should be dynamic
		# target enemy with shortest distance
		var target_enemy_node: Node2D = null
		var enemy_distance: float = INF
		for enemy_node in Combat.enemy_nodes_in_combat:
			if position.distance_to(enemy_node.position) < enemy_distance:
				enemy_distance = position.distance_to(enemy_node.position)
				target_enemy_node = enemy_node
		
		# navigate to target enemy
		$NavigationAgent2D.target_position = target_enemy_node.position
		target_direction = to_local($NavigationAgent2D.get_next_path_position())
		move_timer = randf_range(0.2, 0.4)
	# if not in combat and not in roam distance, navigate to player
	elif ally_distance > ROAM_DISTANCE:
		$NavigationAgent2D.target_position = Players.main_player_node.position
		target_direction = to_local($NavigationAgent2D.get_next_path_position())
		move_timer = randf_range(0.5, 0.7)
	# else navigate to player
	else:
		target_direction = Vector2.RIGHT.rotated(randf() * TAU)
		move_timer = randf_range(0.5, 0.7)
	
	# sprint with main player if not in combat and ally distance is large enough
	if (
			Players.main_player_node.move_state == MoveState.SPRINT
			and Combat.not_in_combat()
			and ally_distance > 125
			# TODO: need to check fatigue
	):
		move_state = MoveState.SPRINT
	
	# snap target direction to the nearest 8-way angle
	const ANGLE_INCREMENT: float = PI / 4
	var snapped_angle: float = \
			round(target_direction.angle() / ANGLE_INCREMENT) * ANGLE_INCREMENT

	# possible angles by proximity to the snapped angle
	var possible_angles: Array[float] = [
		snapped_angle,
		snapped_angle + ANGLE_INCREMENT,
		snapped_angle - ANGLE_INCREMENT,
		snapped_angle + ANGLE_INCREMENT * 2,
		snapped_angle - ANGLE_INCREMENT * 2,
		snapped_angle + ANGLE_INCREMENT * 3,
		snapped_angle - ANGLE_INCREMENT * 3,
		snapped_angle + ANGLE_INCREMENT * 4,
	]

	# find the closest non-colliding direction
	for possible_angle in possible_angles:
		# attempt possible direction
		target_direction = Vector2.RIGHT.rotated(possible_angle)
		
		# check for collisions
		$ObstacleCheck.set_target_position(target_direction * 10.0)
		$ObstacleCheck.force_shapecast_update()

		# if not colliding, break
		if not $ObstacleCheck.is_colliding():
			break

	update_velocity(target_direction)
	$AllyMoveTimer.start(move_timer)

func _on_action_area_body_entered(body: Node) -> void:
	# TODO: this should be dynamic
	# target enemy with lowest health
	var target_enemy_node: Node2D = null
	var lowest_health: float = INF
	for enemy_node in $ActionArea.get_overlapping_bodies():
		if enemy_node.stats.health < lowest_health:
			lowest_health = enemy_node.stats.health
			target_enemy_node = enemy_node
		
	# face enemy
	var enemy_direction = (target_enemy_node.position - position).normalized()
	move_direction = [
		Directions.RIGHT,
		Directions.DOWN,
		Directions.LEFT,
		Directions.UP,
	][(roundi(enemy_direction.angle() / (PI / 2)) + 4) % 4]

	update_velocity(Vector2.ZERO)
	#update_animation()

func _on_action_area_body_exited(body: Node) -> void:
	pass