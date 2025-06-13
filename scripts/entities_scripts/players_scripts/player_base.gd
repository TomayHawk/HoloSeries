class_name PlayerBase extends EntityBase

# TODO: remove AttackShape node

const ROAM_DISTANCE: float = 75.0
const MAX_ALLY_DISTANCE: float = 200.0

var is_main_player: bool = false
var character: PlayerStats = null

# ..............................................................................

# PROCESS

func _ready() -> void:
	# connect signals
	move_state_timeout.connect(on_move_state_timeout)
	action_state_timeout.connect(on_action_state_timeout)

func _physics_process(_delta: float) -> void:
	if is_main_player:
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
	else:
		# TODO: should not be in physics process
		# attempt action
		var action_success: bool = false
		if action_state == ActionState.READY and not action_queue.is_empty():
			action_success = await action_queue[0][0].callv(action_queue[0][1])
			if action_success:
				action_queue.remove_at(0)
	
	move_and_slide()

func _input(_event: InputEvent) -> void:
	# TODO: should add toggle setting for release dash
	if Input.is_action_just_pressed(&"dash"):
		dash()

# ..............................................................................

# MOVEMENTS

# TODO: test and maybe add other knockback options (maybe also dash)
#var t = knockback_timer / 0.4
# Quadratic
#velocity = knockback_velocity * t * t
# Exponential
#velocity = knockback_velocity * pow(t, 0.5)
# Ease Out Sine
#velocity = knockback_velocity * sin(t * PI * 0.5)

func update_velocity(next_direction: Vector2) -> void:
	# no velocity if stunned
	if move_state == MoveState.STUN:
		return

	# maintain velocity if taking knockback
	if move_state == MoveState.KNOCKBACK:
		velocity = knockback_velocity * move_state_timer / 0.4
		return

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

	# TODO: stats.update_stamina(-stats.sprint_stamina) for sprinting
	
	velocity = next_direction * stats.walk_speed
	
	match move_state:
		MoveState.IDLE:
			move_state = MoveState.WALK
		MoveState.SPRINT:
			velocity *= stats.sprint_multiplier
		MoveState.DASH:
			velocity *= stats.dash_multiplier * move_state_timer / stats.dash_time

	# apply movement reduction if attacking
	if action_state == ActionState.ATTACK:
		velocity *= stats.attack_movement_reduction
	
	# update animation
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

func knockback(next_velocity: Vector2, knockback_time: float) -> void:
	if move_state == MoveState.KNOCKBACK: return
	
	knockback_velocity = next_velocity
	move_state_timer = knockback_time
	
	move_state = MoveState.KNOCKBACK
	update_animation()

# ..............................................................................

# ANIMATION

func update_animation() -> void:
	if not stats.alive or move_state in [MoveState.KNOCKBACK, MoveState.STUN]: return

	var next_animation: StringName = character.animation
	var animation_speed: float = 1.0
	
	# determine next animation based on action and move states
	if action_state == ActionState.ATTACK:
		next_animation = [
			&"right_attack",
			&"down_attack",
			&"left_attack",
			&"up_attack",
		][(roundi(attack_vector.angle() / (PI / 2)) + 4) % 4]
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
	if next_animation != character.animation:
		character.play(next_animation)

	# update animation speed
	character.speed_scale = animation_speed

# ..............................................................................

# TODO: need to implement
func filter_nodes(initial_nodes: Array[EntityBase], get_stats_nodes: bool, origin_position: Vector2 = Vector2(-1.0, -1.0), range_min: float = -1.0, range_max: float = -1.0) -> Array[Node]:
	var resultant_nodes: Array[Node] = []
	var check_distance: bool = range_max > 0
	
	if check_distance:
		range_min *= range_min
		range_max *= range_max
	
	for entity_node in initial_nodes:
		if check_distance:
			var temp_distance: float = origin_position.distance_squared_to(entity_node.position)
			if temp_distance < range_min or temp_distance > range_max:
				continue
		if entity_node is PlayerBase:
			resultant_nodes.push_back(entity_node.character if get_stats_nodes else entity_node)
		elif entity_node is BasicEnemyBase:
			resultant_nodes.push_back(entity_node.enemy_stats_node if get_stats_nodes else entity_node)
	
	return resultant_nodes

# ..............................................................................

# STATS

# update health bar and label
func update_health(value: float) -> void:
	var max_value: float = $HealthBar.max_value
	var bar_percentage: float = value / max_value
	$HealthBar.value = value
	$HealthBar.visible = value > 0.0 and value < max_value
	$HealthBar.modulate = (
			Color(0, 1, 0, 1) if bar_percentage > 0.5
			else Color(1, 1, 0, 1) if bar_percentage > 0.2
			else Color(1, 0, 0, 1)
	)
	Combat.ui.health_labels[get_index()].text = str(int(value))

# update mana bar and label
func update_mana(value: float) -> void:
	$ManaBar.value = value
	$ManaBar.visible = value < $ManaBar.max_value
	Combat.ui.mana_labels[get_index()].text = str(int(value))

# update stamina bar and move state
func update_stamina(value: float) -> void:
	$StaminaBar.value = value
	$StaminaBar.visible = value < $StaminaBar.max_value
	$StaminaBar.modulate = Color(0.5, 0, 0, 1) if stats.fatigue else Color(1, 0.5, 0, 1)
	if stats.fatigue and move_state in [MoveState.DASH, MoveState.SPRINT]:
		move_state = MoveState.WALK
		if action_state in [ActionState.READY, ActionState.COOLDOWN]:
			update_animation()

# update ultimate gauge bar
func update_ultimate_gauge(value: float) -> void:
	Combat.ui.ultimate_progress_bars[get_index()].value = value
	Combat.ui.ultimate_progress_bars[get_index()].modulate.g = (130.0 - value) / stats.max_ultimate_gauge

# update shield bar
func update_shield(value: float) -> void:
	$ShieldBar.value = value
	$ShieldBar.visible = value > 0

# ..............................................................................

# DEATH

func death() -> void:
	# pause process and update all base class variables
	super ()

	set_physics_process(false)

	# disable collisions
	$MovementHitBox.disabled = true
	$CombatHitBox/CollisionShape2D.disabled = true
	$InteractionArea/CollisionShape2D.disabled = true
	$LootableArea/CollisionShape2D.disabled = true
	$ActionArea/CollisionShape2D.disabled = true
	$ObstacleCheck.enabled = false

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
	character.death()

func revive() -> void:
	# resume process
	super ()

	set_physics_process(true)

	# queue actions

	# TODO
	# update variables
	#update_ultimate_gauge(0.0)
	#update_shield(0.0)
	#play(&"down_idle")

# ..............................................................................

# UPDATE NODES

# TODO: use arrays of SpriteFrames and Resources

# swap stats with standby stats
func swap_with_standby(next_character: PlayerStats) -> void:
	var current_character: PlayerStats = character
	var current_stats: PlayerStats = stats
	var standby_index: int = next_character.get_index()
	character = next_character
	stats = next_character.stats

	Combat.ui.name_labels[stats.node_index].text = character.CHARACTER_NAME
	Combat.ui.standby_name_labels[current_character.stats.node_index].text = current_character.CHARACTER_NAME
	
	process_interval = 0.0

	# STATES

	move_state = MoveState.IDLE
	var action_state: ActionState = ActionState.READY
	var move_direction: Directions = Directions.DOWN
	var attack_vector: Vector2 = Vector2.RIGHT

	# KNOCKBACK

	var knockback_velocity: Vector2 = Vector2.LEFT
	var knockback_timer: float = 0.0

	# DASH
	var dash_timer: float = 0.0

	if current_script is PlayerAlly:
		current_script.action_queue.clear()
		#current_script.can_move = true
		current_script.can_attack = true
		current_script.in_action_range = false
	
	return current_character

'''

func update_nodes(swap_base: PlayerBase = null, swap_stats: PlayerStats = null) -> void:
	elif swap_stats != stats: # Party -> Standby
		pass
	
	update_stats()
	
	if base:
		name = &"PlayerStats"
		var player_node: PlayerBase = base
		# movement variables
		player_node.walk_speed = 70.0
		player_node.sprint_multiplier = 1.25
		player_node.sprint_stamina = 0.8
		player_node.dash_multiplier = 8.0
		player_node.dash_stamina = 35.0
		player_node.dash_min_stamina = 25.0
		player_node.dash_time = 0.2
		player_node.attack_movement_reduction = 0.3

		# ally variables
		player_node.can_move = true
		player_node.can_attack = true
		player_node.in_action_range = false

		# knockback variables
		player_node.knockback_direction = Vector2.ZERO
		player_node.knockback_weight = 0.0
		player_node.character = self
		player_node.walk_speed = 140 + speed * 0.5
		player_node.dash_stamina = 35 - (agility * 0.0625)
		player_node.sprint_stamina = 0.8 - (agility * 0.00048828125)
		player_node.dash_time = 0.2 * (1 - (agility * 0.001953125)) # minimum 0.1s dash time
		player_node.update_velocity(Vector2.ZERO)
		player_node.set_action_state(ActionState.READY)
		# TODO: player_node.ally_speed = 60 + (30 * speed)
		# player_node.dash_multiplier = 300 + (150 * speed)
	else:
		Combat.ui.standby_level_labels[node_index].text = str(level)
		Combat.ui.standby_health_labels[node_index].text = str(int(health))
		Combat.ui.standby_mana_labels[node_index].text = str(int(mana))

'''

# ..............................................................................

# TODO: need to add signal connections
func input_in_hit_box_area(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if Input.is_action_just_pressed(&"action") and event.is_action_pressed(&"action"): # TODO: not sure if this works.
		if self in Entities.entities_available:
			Inputs.accept_event()
			Entities.choose_entity(self)
		elif stats.alive:
			Inputs.accept_event()
			Players.update_main_player(self)

func _on_lootable_area_entered(body: Node2D) -> void:
	if body.nearby_player_nodes.is_empty():
		body.nearby_player_nodes.append(self)
		body.target_player_node = self
	elif not body.nearby_player_nodes.has(self):
		body.nearby_player_nodes.append(self)
	
	body.set_physics_process(true)

func _on_lootable_area_exited(body: Node2D) -> void:
	body.nearby_player_nodes.erase(self)

	if body.nearby_player_nodes.is_empty():
		body.set_physics_process(false)
		body.target_player_node = null
		body.multiplier = 0.0
	else:
		var target_player_node: PlayerBase = null
		var least_distance: float = INF
		for player_node in body.nearby_player_nodes:
			var temp_distance: float = body.global_position.distance_squared_to(player_node.global_position)
			if temp_distance < least_distance:
				target_player_node = player_node
				least_distance = temp_distance
		body.target_player_node = target_player_node

func on_move_state_timeout() -> void:
	if move_state == MoveState.STUN:
		move_state = MoveState.IDLE
		update_animation()
	elif move_state == MoveState.KNOCKBACK:
		move_state = MoveState.IDLE
		update_animation()
	elif move_state == MoveState.DASH:
		if Input.is_action_pressed(&"dash"):
			move_state = MoveState.SPRINT
		else:
			move_state = MoveState.WALK
		update_animation()

func on_action_state_timeout() -> void:
	pass

func _on_action_area_body_entered(_body: Node2D) -> void:
	in_action_range = $ActionArea.get_overlapping_bodies().filter(func(node): return node.is_instance_of(action_target))

func _on_action_area_body_exited(_body: Node2D) -> void:
	in_action_range = $ActionArea.get_overlapping_bodies().filter(func(node): return node.is_instance_of(action_target))

# TODO: need to add signal connections
func _on_interaction_area_body_entered(body: Node2D) -> void:
	body.interaction_area(true)

# TODO: need to add signal connections
func _on_interaction_area_body_exited(body: Node2D) -> void:
	body.interaction_area(false)

# TODO: BELOW ADDED FROM PLAYER ALLY SCRIPT

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
