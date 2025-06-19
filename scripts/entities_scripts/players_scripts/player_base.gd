class_name PlayerBase extends EntityBase

# TODO: remove AttackShape node
# TODO: switch main player while pressing alt, or pressing 1,2,3,4
# TODO: deal with all await edge cases in project
# TODO: should add toggle setting for release dash

# TODO: test and maybe add other knockback options (maybe also dash)
#var t = knockback_timer / 0.4
# Quadratic
#velocity = knockback_velocity * t * t
# Exponential
#velocity = knockback_velocity * pow(t, 0.5)
# Ease Out Sine
#velocity = knockback_velocity * sin(t * PI * 0.5)

var is_main_player: bool = false
var party_index: int = -1

# ACTION VARIABLES

var in_action_range: bool = false
var action_queue: Array[Array] = []

var action_type: ActionType = ActionType.ATTACK
var action_target: EntityBase = null
var action_target_type: GDScript = EntityBase
var action_target_priority: StringName = &""
var action_target_get_max: bool = true
var action_vector: Vector2 = Vector2.DOWN
var action_fail_count: int = 0

# ..............................................................................

# PHYSICS PROCESS

func _physics_process(_delta: float) -> void:
	# no velocity change if stunned
	if move_state == MoveState.STUN:
		pass
	# slowly decrease velocity if taking knockback
	elif move_state == MoveState.KNOCKBACK:
		velocity = knockback_velocity * move_state_timer / 0.4
	elif is_main_player:
		update_main_player_movement()
	
	move_and_slide()

# INPUT

# TODO: add sprint toggle setting
func _input(_event: InputEvent) -> void:
	if not is_main_player or not Inputs.combat_inputs_enabled:
		return
	
	if Input.is_action_just_pressed(&"dash"):
		if move_state != MoveState.DASH:
			dash()
		elif move_state == MoveState.SPRINT:
			end_sprint()
	elif Input.is_action_just_released(&"dash"):
		if move_state == MoveState.SPRINT:
			end_sprint()

# ..............................................................................

# MOVEMENTS

func update_main_player_movement() -> void:
	var input_velocity: Vector2 = Input.get_vector(&"left", &"right", &"up", &"down", 0.2)
	
	# TODO: should only check this if using a controller
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

	update_movement(input_velocity)

func update_movement(next_direction: Vector2 = Vector2.ZERO) -> void:
	# if no direction, set idle state
	if next_direction == Vector2.ZERO:
		move_state = MoveState.IDLE
		velocity = Vector2.ZERO
		update_animation()
		return
	
	# update move direction
	move_direction = [
		Directions.UP,
		Directions.DOWN,
		Directions.LEFT,
		Directions.RIGHT,
		Directions.UP_LEFT,
		Directions.UP_RIGHT,
		Directions.DOWN_LEFT,
		Directions.DOWN_RIGHT,
	][[
		Vector2(0.0, -1.0),
		Vector2(0.0, 1.0),
		Vector2(-1.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(-0.70710678, -0.70710678),
		Vector2(0.70710678, -0.70710678),
		Vector2(-0.70710678, 0.70710678),
		Vector2(0.70710678, 0.70710678),
	].find(next_direction)]
	
	velocity = next_direction * stats.walk_speed
	
	match move_state:
		MoveState.IDLE:
			move_state = MoveState.WALK
		MoveState.SPRINT:
			velocity *= stats.sprint_multiplier
		MoveState.DASH:
			velocity *= stats.dash_multiplier * move_state_timer / stats.dash_time

	# apply movement reduction if attacking
	if action_state == ActionState.ACTION:
		velocity *= stats.attack_movement_reduction
	
	# update animation
	update_animation()

# END SPRINT

func end_sprint() -> void:
	move_state = MoveState.WALK
	update_animation()

# DASH

func dash() -> void:
	if stats.fatigue: return
	if stats.stamina < stats.dash_min_stamina: return
	if move_state in [MoveState.KNOCKBACK, MoveState.STUN]: return

	move_state_timer = stats.dash_time
	stats.update_stamina(-stats.dash_stamina)

	move_state = MoveState.DASH
	update_animation()

# KNOCKBACK

func knockback(next_velocity: Vector2, duration: float) -> void:
	if move_state == MoveState.KNOCKBACK: return
	
	knockback_velocity = next_velocity
	move_state_timer = duration
	
	move_state = MoveState.KNOCKBACK
	update_animation()

func stun(duration: float) -> void:
	if move_state == MoveState.STUN: return

	velocity = Vector2.ZERO
	move_state_timer = duration

	move_state = MoveState.STUN
	update_animation()

# ..............................................................................

# ANIMATION

func update_animation() -> void:
	if not stats.alive or move_state in [MoveState.KNOCKBACK, MoveState.STUN]: return

	var animation_node: AnimatedSprite2D = $Animation
	var next_animation: StringName = animation_node.animation
	var animation_speed: float = 1.0
	
	# determine next animation based on action and move states
	if action_state == ActionState.ACTION:
		next_animation = [
			&"right_attack",
			&"down_attack",
			&"left_attack",
			&"up_attack",
		][(roundi(action_vector.angle() / (PI / 2)) + 4) % 4]
	elif move_state == MoveState.IDLE:
		next_animation = [
			&"up_idle",
			&"down_idle",
			&"left_idle",
			&"right_idle"
		][move_direction if (move_direction < 4) else move_direction % 2 + 2]
	else:
		next_animation = [
			&"up_walk",
			&"down_walk",
			&"left_walk",
			&"right_walk"
		][move_direction if (move_direction < 4) else move_direction % 2 + 2]
		
		# update animation speed based on movement speed
		animation_speed = stats.walk_speed / 70.0
		if move_state == MoveState.DASH:
			animation_speed *= 2.0
		elif move_state == MoveState.SPRINT:
			animation_speed *= stats.sprint_multiplier
	
	# play animation if changed
	if next_animation != animation_node.animation:
		animation_node.play(next_animation)

	# update animation speed
	animation_node.speed_scale = animation_speed

# ..............................................................................

# ACTIONS

func action_request() -> void:
	pass # TODO

func queue_attack() -> void:
	action_type = ActionType.ATTACK
	action_target_type = EnemyBase
	action_target_priority = &"health"
	action_target_get_max = false

	action_fail_count = 0
	in_action_range = is_in_action_range()
	action_queue.pop_front()

	choose_action_target()

func choose_action_target() -> void:
	# if is ally, is in action range, not taking action, and not in knockback or stun states
	if (
			not is_main_player
			and in_action_range
			and action_state != ActionState.ACTION
			and not move_state in [MoveState.KNOCKBACK, MoveState.STUN]
	):
		# determine candidate action targets
		var candidate_nodes: Array[EntityBase] = $ActionArea.get_overlapping_bodies(
				).filter(func(node: Node) -> bool: return node.is_instance_of(action_target_type))
		# choose action target
		action_target = \
				Entities.target_entity_by_stats(candidate_nodes, action_target_priority, action_target_get_max)

		# face enemy
		action_vector = (action_target.position - position).normalized()

		move_direction = [
			Directions.RIGHT,
			Directions.DOWN,
			Directions.LEFT,
			Directions.UP,
		][(roundi(action_vector.angle() / (PI / 2)) + 4) % 4]

		# stop movement
		update_movement(Vector2.ZERO)

# ..............................................................................

# STATS

# update health bar and label
func update_health() -> void:
	var bar_percentage: float = stats.health / stats.max_health
	$HealthBar.value = stats.health
	$HealthBar.visible = stats.health > 0.0 and stats.health < stats.max_health
	$HealthBar.modulate = (
			Color(0, 1, 0, 1) if bar_percentage > 0.5
			else Color(1, 1, 0, 1) if bar_percentage > 0.2
			else Color(1, 0, 0, 1)
	)
	Combat.ui.health_labels[get_index()].text = str(int(stats.health))

# update mana bar and label
func update_mana() -> void:
	$ManaBar.value = stats.mana
	$ManaBar.visible = stats.mana < stats.max_mana
	Combat.ui.mana_labels[get_index()].text = str(int(stats.mana))

# update stamina bar and move state
func update_stamina() -> void:
	$StaminaBar.value = stats.stamina
	$StaminaBar.visible = stats.stamina < stats.max_stamina
	$StaminaBar.modulate = Color(0.5, 0, 0, 1) if stats.fatigue else Color(1, 0.5, 0, 1)
	if stats.fatigue and move_state in [MoveState.DASH, MoveState.SPRINT]:
		move_state = MoveState.WALK
		if action_state in [ActionState.READY, ActionState.COOLDOWN]:
			update_animation()

# update shield bar
func update_shield() -> void:
	$ShieldBar.value = stats.shield
	$ShieldBar.visible = stats.shield > 0

# update ultimate gauge bar
func update_ultimate_gauge() -> void:
	Combat.ui.ultimate_progress_bars[get_index()].value = stats.ultimate_gauge
	Combat.ui.ultimate_progress_bars[get_index()].modulate.g = (130.0 - stats.ultimate_gauge) / stats.max_ultimate_gauge

# update maximum bar values
func set_max_values() -> void:
	$HealthBar.max_value = stats.max_health
	$ManaBar.max_value = stats.max_mana
	$StaminaBar.max_value = stats.max_stamina
	$ShieldBar.max_value = stats.max_shield
	Combat.ui.ultimate_progress_bars[get_index()].max_value = stats.max_ultimate_gauge

	update_health()
	update_mana()
	update_stamina()
	update_shield()
	update_ultimate_gauge()

# ..............................................................................

# DEATH & REVIVE

func death() -> void:
	# pause process and update all base class variables
	super ()

	set_physics_process(false)

	# disable collisions
	disable_collisions(true)

	# hide stats bars
	$HealthBar.hide()
	$ManaBar.hide()
	$StaminaBar.hide()
	$ShieldBar.hide()

	# handle main player death
	if is_main_player:
		var alive_party_players = Players.party_node.get_children().filter(func(node: Node) -> bool: return node.stats.alive)
		if not alive_party_players.is_empty():
			Players.update_main_player(alive_party_players[0])
		else:
			print("GAME OVER") # TODO

	# play death animation
	var animation_node: AnimatedSprite2D = $Animation
	animation_node.play(&"death")
	
	# await death animation finished
	await animation_node.animation_finished
	
	# pause animation accordingly
	if not stats.alive and animation_node.animation == &"death":
		animation_node.pause()

func revive() -> void:
	# resume process
	super ()

	set_physics_process(true)

	# enable collisions
	disable_collisions(false)

	# update animation
	$Animation.animation_finished.emit()
	update_animation()

	# TODO: queue actions

	# TODO
	# update variables
	#update_ultimate_gauge(0.0)
	#update_shield(0.0)
	#play(&"down_idle")

func disable_collisions(disable: bool) -> void:
	$MovementHitBox.disabled = disable
	$CombatHitBox/CollisionShape2D.disabled = disable
	$InteractionArea/CollisionShape2D.disabled = disable
	$LootableArea/CollisionShape2D.disabled = disable
	$ActionArea/CollisionShape2D.disabled = disable

# ..............................................................................

# UPDATE NODES

func switch_main(next_stats: PlayerStats) -> void:
	pass

func update_stats(next_stats: PlayerStats) -> void:
	stats = next_stats
	stats.base = self

	# STATES

	move_state = MoveState.IDLE
	# TODO: action_state = ActionState.READY
	var move_direction: Directions = Directions.DOWN
	
	action_vector = Vector2.DOWN
	knockback_velocity = Vector2.UP
	move_state_timer = 0.0
	# TODO: action_state_timer = 0.0
	process_interval = 0.0

	# TODO: queue actions

# ..............................................................................

# SIGNALS

# CombatHitBox

# TODO: add either Inputs.accept_event() or event.accept() if it exists
func _on_combat_hit_box_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if Input.is_action_just_pressed(&"action") and event.is_action_pressed(&"action"):
		if self in Entities.entities_available:
			Entities.choose_entity(self)
		elif Entities.switching_main_player and not is_main_player:
			Players.update_main_player(self)

# InteractionArea

func _on_interaction_area_body_entered(body: Node2D) -> void:
	body.interaction_area(true)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	body.interaction_area(false)

# LootableArea

func _on_lootable_area_area_entered(body: Node2D) -> void:
	body.player_entered(self)

func _on_lootable_area_area_exited(body: Node2D) -> void:
	body.player_exited(self)

# ActionArea

func _on_action_area_body_entered(_body: Node2D) -> void:
	in_action_range = is_in_action_range()
	choose_action_target()

func _on_action_area_body_exited(_body: Node2D) -> void:
	in_action_range = is_in_action_range()

func is_in_action_range() -> bool:
	return not $ActionArea.get_overlapping_bodies().filter(
			func(node): return is_instance_of(node.get_script(), action_target_type)).is_empty()

# State Timers

func _on_move_state_timeout() -> void:
	# TODO: if not is_main_player:
	# TODO: 	update_ally_move_state()
	if move_state in [MoveState.KNOCKBACK, MoveState.STUN]:
		move_state = MoveState.IDLE
		if is_main_player:
			update_movement()
	elif move_state == MoveState.DASH:
		if Input.is_action_pressed(&"dash"):
			move_state = MoveState.SPRINT
		else:
			move_state = MoveState.WALK
		update_animation()

func _on_action_state_timeout() -> void:
	match action_state:
		ActionState.READY:
			action_state = ActionState.ACTION
		ActionState.ACTION:
			action_state = ActionState.COOLDOWN
			if not action_queue.is_empty():
				action_queue[0][0].callv(action_queue[0][1])
		ActionState.COOLDOWN:
			action_state = ActionState.READY

# ..............................................................................

# TODO: BELOW ADDED FROM PLAYER ALLY SCRIPT

# PlayerAlly move process
func update_ally_move_state() -> void:
	# if ally in another move state, continue timer
	if move_state_timer > 0.0:
		$AllyMoveTimer.start(move_state_timer)
		return
	
	# if ally in action state, continue timer
	if not action_state in [ActionState.READY, ActionState.COOLDOWN]:
		$AllyMoveTimer.start($AllyActionTimer.time_left)
		return

	var ally_distance: float = position.distance_to(Players.main_player.position)
	var move_timer: float = 0.0
	
	# handle idle state
	if move_state != MoveState.IDLE:
		# determine idle time based on ally distance
		move_timer = \
				randf_range(1.6, 1.8) if ally_distance < 75.0 \
				else randf_range(0.8, 1.0) if ally_distance < 100 \
				else randf_range(0.4, 0.6) if ally_distance < 150 \
				else 0.0

		# if in idle distance, update velocity to zero
		if move_timer > 0.0:
			update_movement(Vector2.ZERO)
			$AllyMoveTimer.start(move_timer)
			return
		
		# if large ally distance, teleport to main player
		if ally_distance > 200.0:
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
	elif ally_distance > 75.0:
		$NavigationAgent2D.target_position = Players.main_player.position
		target_direction = to_local($NavigationAgent2D.get_next_path_position())
		move_timer = randf_range(0.5, 0.7)
	# else navigate to player
	else:
		target_direction = Vector2.RIGHT.rotated(randf() * TAU)
		move_timer = randf_range(0.5, 0.7)
	
	# sprint with main player if not in combat and ally distance is large enough
	if (
			Players.main_player.move_state == MoveState.SPRINT
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

	update_movement(target_direction)
	$AllyMoveTimer.start(move_timer)
