class_name PlayerBase
extends EntityBase

# ..............................................................................

#region VARIABLES

var is_main_player: bool = false
var party_index: int = -1

var action_queue: Array[Node] = []
var action_fail_count: int = 0

#endregion

# ..............................................................................

#region PROCESS

func _ready() -> void:
	Combat.entering_combat.connect($PlayerActions.enter_combat)
	Combat.left_combat.connect($PlayerActions.leave_combat)

func _physics_process(_delta: float) -> void:
	# no velocity if stunned
	if move_state == MoveState.STUN:
		return

	# decrease velocity if taking knockback or dashing
	if move_state == MoveState.KNOCKBACK:
		velocity = move_state_velocity * move_state_timer / 0.4
	elif move_state == MoveState.DASH:
		velocity = move_state_velocity * move_state_timer / stats.dash_time
	# face action target when applicable
	elif not is_main_player and move_state == MoveState.IDLE and action_target:
		move_direction = ALL_DIRECTIONS[(roundi(
				(action_target.position - position).angle() / (PI / 4.0)) + 8) % 8]
		
		update_animation()

	move_and_slide()

#endregion

# ..............................................................................

#region INPUTS

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
		apply_input_velocity()
	elif Input.is_action_just_pressed(&"dash"):
		if move_state == MoveState.SPRINT and not Inputs.sprint_hold:
			end_sprint()
		else:
			attempt_dash()
	elif Input.is_action_just_released(&"dash"):
		if move_state == MoveState.SPRINT and Inputs.sprint_hold:
			end_sprint()

#endregion

# ..............................................................................

#region MOVEMENT

func apply_input_velocity() -> void:
	if in_forced_move_state:
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

	apply_movement(input_velocity)

func apply_movement(next_direction: Vector2) -> void:
	# if no direction, set idle state
	if next_direction == Vector2.ZERO:
		move_state = MoveState.IDLE
		velocity = Vector2.ZERO
		update_animation()
		return
	
	# update move direction
	move_direction = ALL_DIRECTIONS[[
		Vector2(1.0, 0.0),
		Vector2(1.0, 1.0),
		Vector2(0.0, 1.0),
		Vector2(-1.0, 1.0),
		Vector2(-1.0, 0.0),
		Vector2(-1.0, -1.0),
		Vector2(0.0, -1.0),
		Vector2(1.0, -1.0),
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

# TODO: need to test
func toggle_text_box_process(toggled: bool) -> void:
	if not stats.alive: return

	set_process(toggled)
	set_physics_process(toggled)

	if toggled:
		move_state_timer = 0.0
		if is_main_player:
			set_process_input(true)
		else:
			_on_move_state_timeout()
	else:
		apply_movement(Vector2.ZERO)
		if is_main_player:
			set_process_input(false)

#endregion

# ..............................................................................

#region MOVE STATES

func _on_move_state_timeout() -> void:
	move_state_timer = 0.0

	# update move states
	if in_forced_move_state:
		move_state = MoveState.IDLE
	elif move_state == MoveState.DASH:
		if is_main_player and (Input.is_action_pressed(&"dash") or not Inputs.sprint_hold):
			move_state = MoveState.SPRINT
		else:
			move_state = MoveState.WALK
	
	# handle main player move states
	if is_main_player:
		apply_input_velocity()
		return

	# if not main player:

	# while in action, stay idle
	if action_state == ActionState.ACTION:
		move_state_timer = max(0.5, action_cooldown)
		apply_movement(Vector2.ZERO)
		return

	var ally_distance: float = position.distance_to(Players.main_player.position)
	var target_direction: Vector2 = Vector2.ZERO

	# if in combat and close to main player
	if Combat.in_combat() and ally_distance < 300.0:
		# if in action range, attempt action
		if in_action_range:
			$PlayerActions.attempt_action()
			apply_movement(Vector2.ZERO)
			move_state_timer = max(0.5, action_cooldown)
			return

		# if not in action range, navigate to the nearest candidate by quality
		action_target = \
		Entities.target_entity_by_distance(
				Combat.enemies_in_combat,
				position,
				false
		)

		# move towards action target
		$NavigationAgent2D.target_position = action_target.position
		target_direction = to_local($NavigationAgent2D.get_next_path_position())
		move_state_timer = randf_range(0.2, 0.4) / stats.walk_speed * stats.BASE_WALK_SPEED

	# elif large ally distance, teleport to main player
	elif ally_distance > 300.0:
		ally_teleport()
		_on_move_state_timeout()
		return

	# elif not in idle, enter idle
	elif move_state != MoveState.IDLE:
		move_state_timer = \
				randf_range(2.4, 2.6) if ally_distance < 75.0 \
				else randf_range(2.0, 2.2) if ally_distance < 100 \
				else randf_range(1.6, 1.8) if ally_distance < 150.0 \
				else randf_range(1.2, 1.4)
		apply_movement(Vector2.ZERO)
		return
	
	# elif ally distance is larger than 75.0 (between 75.0 and 300.0), navigate to main player
	elif ally_distance > 75.0:
		$NavigationAgent2D.target_position = Players.main_player.position
		target_direction = to_local($NavigationAgent2D.get_next_path_position())
		move_state_timer = randf_range(0.5, 0.7) / stats.walk_speed * stats.BASE_WALK_SPEED
	
	# else move randomly (not in combat, and ally distance is less than 75.0)
	else:
		target_direction = Vector2.RIGHT.rotated(randf() * TAU)
		move_state_timer = randf_range(0.5, 0.7) / stats.walk_speed * stats.BASE_WALK_SPEED

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
	var snapped_angle: float = roundi(target_direction.angle() / ANGLE_INCREMENT) * ANGLE_INCREMENT

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

	apply_movement(target_direction)

# TODO: need to limit teleportation locations using collisions
func ally_teleport(next_position: Vector2 = Players.main_player.position) -> void:
	if is_main_player: return
	position = next_position + (Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 25)

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
	apply_movement(velocity.normalized())

# END SPRINT

func end_sprint() -> void:
	move_state = MoveState.WALK
	apply_movement(velocity.normalized())

# KNOCKBACK

func knockback(next_velocity: Vector2, duration: float) -> void:
	# check if move state can be changed
	if in_forced_move_state:
		return
	
	# update velocity and knockback timer
	move_state_velocity = next_velocity
	move_state_timer = duration
	
	# update move state and animation
	move_state = MoveState.KNOCKBACK

# STUN

func stun(duration: float) -> void:
	# check if move state can be changed
	if in_forced_move_state:
		return

	# update velocity and stun timer
	velocity = Vector2.ZERO
	move_state_timer = duration

	# update move state and animation
	move_state = MoveState.STUN

#endregion

# ..............................................................................

#region ANIMATIONS

func update_animation() -> void:
	if not stats.alive or in_forced_move_state:
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

#endregion

# ..............................................................................

#region UPDATE NODES

# used to initialize players
func set_variables(next_stats: PlayerStats, next_party_index: int) -> void:
	# update main player variables and signals
	if is_main_player:
		Players.main_player = self
		Players.camera.update_camera(self)

	# update party index
	party_index = next_party_index

	# update stats
	stats = next_stats
	stats.base = self
	stats.set_stats()

	# update stats ui and stats bars
	Combat.ui.update_party_ui(party_index, stats)
	set_max_values()

	# update movement and animation
	if is_main_player:
		_on_move_state_timeout()
	else:
		update_animation()

func switch_to_main() -> void:
	# update main player
	is_main_player = true
	Players.main_player = self
	
	# update camera
	Players.camera.update_camera(self)
	
	# if not in forced move state, reset move state
	if not in_forced_move_state and move_state_timer > 0.0:
		_on_move_state_timeout()
	
	# store and reset action state
	stats.last_action_cooldown = action_cooldown if action_state == ActionState.COOLDOWN else 0.0
	action_cooldown = 0.0
	action_cooldown_timeout.emit()
	
	# reset action variables
	action_callable = Callable()
	action_vector = Vector2.DOWN
	action_fail_count = 0
	in_action_range = false

func switch_to_ally() -> void:
	is_main_player = false

	# reset entities request
	Entities.end_entities_request()

	# if not in forced move state, reset move state
	if not in_forced_move_state:
		_on_move_state_timeout()

	# update action state and cooldown
	if action_cooldown > 0.0:
		action_cooldown = max(action_cooldown, stats.last_action_cooldown)
	elif stats.last_action_cooldown > 0.0:
		action_state = ActionState.COOLDOWN
		action_cooldown = stats.last_action_cooldown
	else:
		action_state = ActionState.READY
	
	$PlayerActions.queue_action()

func switch_character(next_stats: PlayerStats) -> void:
	stats.base = null
	stats.last_action_cooldown = action_cooldown
	
	stats = next_stats
	stats.base = self
	set_max_values()

	$Animation.sprite_frames = stats.animation
	apply_input_velocity()
	
	action_cooldown = stats.last_action_cooldown
	action_state = ActionState.COOLDOWN if action_cooldown > 0.0 else ActionState.READY

	process_interval = 0.0

	# update player ui
	Combat.ui.update_party_ui(party_index, stats)

#endregion

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
	Combat.ui.health_labels[party_index].text = str(int(stats.health))

# update mana bar and label
func update_mana() -> void:
	$ManaBar.value = stats.mana
	$ManaBar.visible = stats.mana < stats.max_mana
	Combat.ui.mana_labels[party_index].text = str(int(stats.mana))

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
	Combat.ui.shield_progress_bars[party_index].value = stats.shield
	Combat.ui.shield_progress_bars[party_index].modulate.a = 1.0 if stats.shield > 0 else 0.0

# update ultimate gauge bar
func update_ultimate_gauge() -> void:
	Combat.ui.ultimate_progress_bars[party_index].value = stats.ultimate_gauge
	Combat.ui.ultimate_progress_bars[party_index].modulate.g = (130.0 - stats.ultimate_gauge) / stats.max_ultimate_gauge

# update maximum bar values
func set_max_values() -> void:
	$HealthBar.max_value = stats.max_health
	$ManaBar.max_value = stats.max_mana
	$StaminaBar.max_value = stats.max_stamina
	$ShieldBar.max_value = stats.max_shield
	Combat.ui.ultimate_progress_bars[party_index].max_value = stats.max_ultimate_gauge

	update_health()
	update_mana()
	update_stamina()
	update_shield()
	update_ultimate_gauge()

#endregion

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
		var alive_party_players = Players.get_children().filter(func(node: Node) -> bool: return node.stats.alive)
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
	$PlayerActions/ActionArea/CollisionShape2D.disabled = disable

#endregion

# ..............................................................................

#region SIGNALS

# Action State Timer

func _on_action_cooldown_timeout() -> void:
	action_state = ActionState.READY
	
	if not is_main_player:
		$PlayerActions.attempt_action()

# CombatHitBox

func _on_combat_hit_box_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if Input.is_action_just_pressed(&"action") and event.is_action_pressed(&"action"):
		if self in Entities.entities_available:
			Inputs.accept_event()
			Entities.choose_entity(self)
		elif Inputs.alt_pressed and not is_main_player:
			Inputs.accept_event()
			Players.switch_main_player(self)

func _on_combat_hit_box_mouse_entered() -> void:
	if self in Entities.entities_available or Inputs.alt_pressed:
		Inputs.action_inputs_enabled = false
		Inputs.zoom_inputs_enabled = false

func _on_combat_hit_box_mouse_exited() -> void:
	Inputs.action_inputs_enabled = true
	Inputs.zoom_inputs_enabled = true

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

func _on_action_area_body_entered(body: Node2D) -> void:
	# if is main player, ignore
	if is_main_player:
		return
	
	# if body does not match any action target types, ignore
	if not body.stats.entity_types & action_target_types:
		return
	
	# if body is already a candidate, ignore
	if action_target_candidates.has(body):
		return

	# update action target variables
	action_target_candidates.append(body)
	in_action_range = true

	# attempt action if ready
	if action_state == ActionState.READY:
		$PlayerActions.attempt_action()

func _on_action_area_body_exited(body: Node2D) -> void:
	action_target_candidates.erase(body)
	in_action_range = action_target_candidates.size()
	
	if not is_main_player and not in_action_range:
		_on_move_state_timeout()

#endregion

# ..............................................................................

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
