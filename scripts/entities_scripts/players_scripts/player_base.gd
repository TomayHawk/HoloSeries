class_name PlayerBase extends EntityBase

# TODO: remove AttackShape node
# TODO: switch main player while pressing alt, or pressing 1,2,3,4
# TODO: deal with all await edge cases in project
# TODO: should add toggle setting for release dash

# TODO: test and maybe add other knockback options (maybe also dash)
#var t = knockback_timer / 0.4
# Quadratic
#velocity = move_state_velocity * t * t
# Exponential
#velocity = move_state_velocity * pow(t, 0.5)
# Ease Out Sine
#velocity = move_state_velocity * sin(t * PI * 0.5)

var is_main_player: bool = false
var party_index: int = -1

# ACTION VARIABLES

var in_action_range: bool = false
var action_queue: Array[Array] = []

# ..............................................................................

#region READY

func _ready() -> void:
	await Global.get_tree().process_frame
	if not is_main_player:
		move_state_timeout.disconnect(_on_move_state_timeout)
		move_state_timeout.connect(_on_ally_move_state_timeout)
		await Global.get_tree().process_frame
		_on_ally_move_state_timeout() # TODO: temporary code to start ally movement

# endregion

# ..............................................................................

#region PHYSICS PROCESS

func _physics_process(_delta: float) -> void:
	# no velocity if stunned
	if move_state == MoveState.STUN:
		return

	# slowly decrease velocity if taking knockback or dashing
	if move_state == MoveState.KNOCKBACK:
		velocity = move_state_velocity * move_state_timer / 0.4
	elif move_state == MoveState.DASH:
		velocity = move_state_velocity * move_state_timer / stats.dash_time
	
	move_and_slide()

# endregion

# ..............................................................................

#region INPUT

func _input(event: InputEvent) -> void:
	# check input requirements
	if not is_main_player or not Inputs.world_inputs_enabled:
		return
	
	# ignore all unrelated inputs
	if not (event.is_action(&"left") or event.is_action(&"right") \
			or event.is_action(&"up") or event.is_action(&"down") \
			or event.is_action(&"dash")):
		return
	
	Inputs.accept_event()
	
	if (
			Input.is_action_just_pressed(&"left")
			or Input.is_action_just_pressed(&"right")
			or Input.is_action_just_pressed(&"up")
			or Input.is_action_just_pressed(&"down")
			or Input.is_action_just_released(&"left")
			or Input.is_action_just_released(&"right")
			or Input.is_action_just_released(&"up")
			or Input.is_action_just_released(&"down")
	):
		update_main_player_movement()
	elif Input.is_action_just_pressed(&"dash"):
		if move_state == MoveState.SPRINT and not Inputs.sprint_hold:
			end_sprint()
		else:
			attempt_dash()
	elif Input.is_action_just_released(&"dash"):
		if move_state == MoveState.SPRINT and Inputs.sprint_hold:
			end_sprint()

# endregion

# ..............................................................................

#region MOVEMENTS

func update_main_player_movement() -> void:
	if move_state in [MoveState.KNOCKBACK, MoveState.STUN]:
		return

	var input_velocity: Vector2 = Input.get_vector(&"left", &"right", &"up", &"down", 0.2)
	
	# TODO: should only check this if using a controller
	# snap input velocity to cardinal and intercardinal directions
	if input_velocity != Vector2.ZERO:
		input_velocity = [
			Vector2.RIGHT,
			Vector2(0.70710678, 0.70710678),
			Vector2.DOWN,
			Vector2(-0.70710678, 0.70710678),
			Vector2.LEFT,
			Vector2(-0.70710678, -0.70710678),
			Vector2.UP,
			Vector2(0.70710678, -0.70710678)
		][(roundi(input_velocity.angle() / (PI / 4.0)) + 8) % 8]

	update_movement(input_velocity)

func update_movement(next_direction: Vector2) -> void:
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
		Vector2(-1.0, -1.0),
		Vector2(1.0, -1.0),
		Vector2(-1.0, 1.0),
		Vector2(1.0, 1.0),
	].find(round(next_direction))]

	# set velocity to direction at walk speed
	velocity = next_direction * stats.walk_speed
	
	# update move state or multiply velocity accordingly
	match move_state:
		MoveState.IDLE:
			move_state = MoveState.WALK
		MoveState.SPRINT:
			velocity *= stats.sprint_multiplier
		MoveState.DASH:
			move_state_velocity = velocity * stats.dash_multiplier
			velocity = move_state_velocity * move_state_timer / stats.dash_time

	# apply movement reduction if attacking
	if action_state == ActionState.ACTION:
		velocity *= stats.attack_movement_reduction
	
	# update animation
	update_animation()

# endregion

# ..............................................................................

#region MOVE STATE UPDATES

# DASH

func attempt_dash() -> void:
	# check dash conditions
	if stats.fatigue or stats.stamina < stats.dash_min_stamina:
		return
	if not move_state in [MoveState.WALK, MoveState.SPRINT]:
		return

	# update dash timer and stamina
	move_state_timer = stats.dash_time
	stats.update_stamina(-stats.dash_stamina)

	# update move state and velocity
	move_state = MoveState.DASH
	update_movement(velocity.normalized())

# END SPRINT

func end_sprint() -> void:
	move_state = MoveState.WALK
	update_movement(velocity.normalized())

# KNOCKBACK

func knockback(next_velocity: Vector2, duration: float) -> void:
	# check knockback conditions
	if move_state in [MoveState.KNOCKBACK, MoveState.STUN]:
		return
	
	# update velocity and knockback timer
	move_state_velocity = next_velocity
	move_state_timer = duration
	
	# update move state and animation
	move_state = MoveState.KNOCKBACK

# STUN

func stun(duration: float) -> void:
	# check stun conditions
	if move_state in [MoveState.KNOCKBACK, MoveState.STUN]:
		return

	# update velocity and stun timer
	velocity = Vector2.ZERO
	move_state_timer = duration

	# update move state and animation
	move_state = MoveState.STUN

# endregion

# ..............................................................................

#region PLAYER STATES

func _on_move_state_timeout() -> void:
	if move_state in [MoveState.KNOCKBACK, MoveState.STUN]:
		move_state = MoveState.IDLE
	elif move_state == MoveState.DASH:
		if Input.is_action_pressed(&"dash") or not Inputs.sprint_hold:
			move_state = MoveState.SPRINT
		else:
			move_state = MoveState.WALK
	update_main_player_movement()

# endregion

# ..............................................................................

#region ALLY STATES

# PlayerAlly move process
func _on_ally_move_state_timeout() -> void:
	if move_state in [MoveState.KNOCKBACK, MoveState.STUN]:
		move_state = MoveState.IDLE
	elif move_state == MoveState.DASH:
		move_state = MoveState.WALK

	# while in action, idle
	if action_state == ActionState.ACTION:
		move_state_timer = action_state_timer
		update_movement(Vector2.ZERO)
		return

	# while in action range, idle and face nearest enemy
	if Combat.in_combat() and in_action_range:
		move_direction = [Directions.RIGHT, Directions.DOWN, Directions.LEFT, Directions.UP,
				Directions.UP_LEFT, Directions.UP_RIGHT, Directions.DOWN_LEFT, Directions.DOWN_RIGHT
				][(roundi((position - Entities.target_entity_by_distance(Combat.enemies_in_combat, position, false
				).position).angle() / (PI / 4.0)) + 8) % 8]
		update_movement(Vector2.ZERO)
		return

	var ally_distance: float = position.distance_to(Players.main_player.position)
	var target_direction: Vector2 = Vector2.ZERO

	# if not in action range navigate to nearest action target
	if Combat.in_combat():
		# TODO: should not use enemies_in_combat
		action_target = Entities.target_entity_by_distance(Combat.enemies_in_combat, position, false)
		$NavigationAgent2D.target_position = action_target.position
		target_direction = to_local($NavigationAgent2D.get_next_path_position())
		move_state_timer = randf_range(0.2, 0.4) / stats.walk_speed * 140.0
	# if large ally distance, teleport to main player
	elif ally_distance > 300.0:
		ally_teleport()
		_on_ally_move_state_timeout()
		return
	# if not in idle, determine idle time based on ally distance
	elif move_state != MoveState.IDLE:
		move_state_timer = \
				randf_range(2.4, 2.6) if ally_distance < 75.0 \
				else randf_range(2.0, 2.2) if ally_distance < 100 \
				else randf_range(1.6, 1.8) if ally_distance < 150.0 \
				else randf_range(1.2, 1.4)
		update_movement(Vector2.ZERO)
		return
	# elif ally distance is larger than 75.0, navigate to main player
	elif ally_distance > 75.0:
		$NavigationAgent2D.target_position = Players.main_player.position
		target_direction = to_local($NavigationAgent2D.get_next_path_position())
		move_state_timer = randf_range(0.5, 0.7) / stats.walk_speed * 140.0
	# else random movement
	else:
		target_direction = Vector2.RIGHT.rotated(randf() * TAU)
		move_state_timer = randf_range(0.5, 0.7) / stats.walk_speed * 140.0

	# sprint with main player with conditions
	if (
			Players.main_player.move_state == MoveState.SPRINT
			and Combat.not_in_combat()
			and ally_distance > 125
			and not stats.fatigue
	):
		move_state = MoveState.SPRINT
	
	# snap target direction to the nearest 8-way angle
	const ANGLE_INCREMENT: float = PI / 4
	var snapped_angle: float = \
			roundi(target_direction.angle() / ANGLE_INCREMENT) * ANGLE_INCREMENT

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

func ally_teleport(next_position: Vector2 = Players.main_player.position) -> void:
	if not is_main_player:
		position = next_position + (Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 25)

# endregion

# ..............................................................................

#region ACTIONS

func action_input() -> void:
	if action_state != ActionState.READY:
		return

	action_state = ActionState.ACTION
	stats.basic_attack()

func queue_attack() -> void:
	action_type = ActionType.ATTACK
	action_target_type = Entities.Type.ENEMIES
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
		var candidate_nodes: Array[EntityBase] = Entities.type_entities_array($ActionArea.get_overlapping_bodies(
				).filter(func(node: Node) -> bool: return node.stats.entity_types & action_target_type))
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

# endregion

# ..............................................................................

#region ANIMATIONS

func update_animation() -> void:
	if not stats.alive or move_state in [MoveState.KNOCKBACK, MoveState.STUN]:
		return

	var next_animation: StringName = $Animation.animation
	var animation_speed: float = 1.0
	
	# determine next animation based on action and move states
	if action_state == ActionState.ACTION:
		# attack
		next_animation = [
			&"right_attack",
			&"down_attack",
			&"left_attack",
			&"up_attack",
		][(roundi(action_vector.angle() / (PI / 2)) + 4) % 4]
	elif move_state == MoveState.IDLE:
		# idle
		next_animation = [
			&"up_idle",
			&"down_idle",
			&"left_idle",
			&"right_idle"
		][move_direction if (move_direction < 4) else move_direction % 2 + 2]
	else:
		# move
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
	if next_animation != $Animation.animation:
		$Animation.play(next_animation)
		$Animation.frame_changed.emit()
		$Animation.animation_finished.emit()

	# update animation speed
	$Animation.speed_scale = animation_speed

# endregion

# ..............................................................................

#region UPDATE NODES

func switch_to_main() -> void:
	is_main_player = true
	move_state_timeout.disconnect(_on_ally_move_state_timeout)
	move_state_timeout.connect(_on_move_state_timeout)
	Players.camera_node.new_parent(self)
	Entities.end_entities_request()
	
	# TODO: update action variables

	if action_state == ActionState.COOLDOWN:
		if action_state_timer > 0.0:
			stats.last_action_state_timer = action_state_timer
			action_state = ActionState.READY
			action_state_timer = 0.0
			action_state_timeout.emit()
	else:
		action_state = ActionState.READY
		stats.last_action_state_timer = 0.0
	
	if not move_state in [MoveState.KNOCKBACK, MoveState.STUN] and move_state_timer > 0.0:
		move_state_timer = 0.0
		move_state_timeout.emit()

func switch_to_ally() -> void:
	is_main_player = false
	move_state_timeout.disconnect(_on_move_state_timeout)
	move_state_timeout.connect(_on_ally_move_state_timeout)

	# TODO: update action variables

	action_state_timer = max(action_state_timer, stats.last_action_state_timer)

	if action_state_timer > 0.0:
		action_state = ActionState.COOLDOWN
	else:
		action_state = ActionState.READY
	
	if not move_state in [MoveState.KNOCKBACK, MoveState.STUN]:
		move_state_timer = 0.0
		move_state_timeout.emit()

func switch_character(next_stats: PlayerStats) -> void:
	stats.base = null
	stats.last_action_state_timer = action_state_timer if action_state == ActionState.COOLDOWN else 0.0
	stats = next_stats

	next_stats.base = self
	set_max_values()

	move_state_timer = 0.0
	update_main_player_movement()
	$Animation.sprite_frames = next_stats.animation
	
	
	action_state = ActionState.READY
	action_state_timer = 0.0

	process_interval = 0.0

	# TODO: update actions

	# update player ui
	Combat.ui.update_party_ui(party_index, next_stats)

# endregion

# ..............................................................................

#region STATS

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

# endregion

# ..............................................................................

#region DEATH & REVIVE

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
			Players.switch_main_player(alive_party_players[0])
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
	$InteractionArea/CollisionShape2D.disabled = disable
	$LootableArea/CollisionShape2D.disabled = disable
	$ActionArea/CollisionShape2D.disabled = disable

# endregion

# ..............................................................................

#region SIGNALS

# CombatHitBox

func _on_combat_hit_box_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if Input.is_action_just_pressed(&"action") and event.is_action_pressed(&"action"):
		if self in Entities.entities_available:
			Inputs.accept_event()
			Entities.choose_entity(self)
		elif Entities.switching_main_player and not is_main_player:
			Inputs.accept_event()
			Players.switch_main_player(self)

func _on_combat_hit_box_mouse_entered() -> void:
	if self in Entities.entities_available or Entities.switching_main_player:
		Inputs.action_inputs_enabled = false

func _on_combat_hit_box_mouse_exited() -> void:
	Inputs.action_inputs_enabled = true

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
	queue_attack()

func _on_action_area_body_exited(_body: Node2D) -> void:
	await Global.get_tree().process_frame
	in_action_range = is_in_action_range()
	if not is_main_player and not in_action_range:
		move_state_timer = 0.0
		_on_ally_move_state_timeout()

func is_in_action_range() -> bool:
	return not $ActionArea.get_overlapping_bodies().filter(
			func(node): return node.stats.entity_types & action_target_type).is_empty()

# endregion

# ..............................................................................
