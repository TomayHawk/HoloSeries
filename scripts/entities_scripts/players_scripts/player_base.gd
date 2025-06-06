class_name PlayerBase extends EntityBase

var character: CharacterBase = null

func _ready() -> void:
	knockback_timeout.connect(_on_knockback_timer_timeout)
	dash_timeout.connect(_on_dash_timer_timeout)

# ................................................................................

# MOVEMENTS

func set_move_state(next_state: MoveState) -> void:
	if move_state == next_state or not stats.alive: return
	move_state = next_state
	update_animation()

func set_move_direction(next_direction: Directions) -> void:
	if move_direction == next_direction or not stats.alive: return
	move_direction = next_direction
	update_animation()

func update_velocity(next_direction: Vector2) -> void:
	if move_state == MoveState.STUN:
		return

	if move_state == MoveState.KNOCKBACK:
		velocity = knockback_velocity * knockback_timer / 0.4
		return
		# TODO: test and maybe add other knockback options
		#var t = knockback_timer / 0.4
		# Quadratic
		#velocity = knockback_velocity * t * t
		# Exponential
		#velocity = knockback_velocity * pow(t, 0.5)
		# Ease Out Sine
		#velocity = knockback_velocity * sin(t * PI * 0.5)

	if next_direction == Vector2.ZERO:
		set_move_state(MoveState.IDLE)
		velocity = Vector2.ZERO
		return
	
	# set move direction
	set_move_direction([
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
	].find(next_direction)])
	
	var temp_velocity: Vector2 = next_direction * stats.walk_speed

	match move_state:
		MoveState.IDLE:
			set_move_state(MoveState.WALK)
		MoveState.SPRINT:
			temp_velocity *= stats.sprint_multiplier
			stats.update_stamina(-stats.sprint_stamina)
		MoveState.DASH:
			temp_velocity *= stats.dash_multiplier * dash_timer / stats.dash_time

	if attack_state == AttackState.ATTACK:
		temp_velocity *= stats.attack_movement_reduction
	
	velocity = temp_velocity

func dash() -> void:
	if (stats.stamina < stats.dash_min_stamina
			or stats.fatigue
			or move_state == MoveState.KNOCKBACK
			or move_state == MoveState.STUN
	): return

	dash_timer = stats.dash_time
	stats.update_stamina(-stats.dash_stamina)

	set_move_state(MoveState.DASH)

func dealt_knockback(next_velocity: Vector2, knockback_time: float) -> void:
	if move_state == MoveState.KNOCKBACK: return
	knockback_velocity = next_velocity
	knockback_timer = knockback_time
	set_move_state(MoveState.KNOCKBACK)

# ................................................................................

# ATTACK

func set_attack_state(next_state: AttackState) -> void:
	if attack_state == next_state or not stats.alive: return
	# ally conditions
	if not is_main_player:
		#if not ally_can_attack:
			#return
		if attack_state != AttackState.READY and next_state == AttackState.ATTACK:
			return

	attack_state = next_state

	if attack_state == AttackState.ATTACK: attempt_attack()

	update_animation()

func attempt_attack(attack_name: String = "") -> void:
	if character != get_node_or_null(^"CharacterBase"):
		set_attack_state(AttackState.READY) # TODO: depends
		return
	
	if attack_name != "":
		pass # call attack with conditions
	elif character.auto_ultimate and character.ultimate_gauge == character.max_ultimate_gauge:
		character.ultimate_attack()
	else:
		character.basic_attack()

# ................................................................................

# ANIMATION

func update_animation() -> void:
	if (
		not stats.alive
		or move_state == MoveState.KNOCKBACK
		or move_state == MoveState.STUN
	): return

	var next_animation: StringName = character.animation
	var animation_speed: float = 1.0
	
	if attack_state == AttackState.ATTACK:
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
		][move_direction % 2 + 2 if (move_direction > 3) else move_direction]
	else:
		next_animation = [
			&"up_walk",
			&"down_walk",
			&"left_walk",
			&"right_walk"
		][move_direction % 2 + 2 if (move_direction > 3) else move_direction]

		animation_speed = 2.0 if move_state == MoveState.DASH \
				else stats.sprint_multiplier if move_state == MoveState.SPRINT else 1.0
		
	if next_animation != character.animation:
		character.play(next_animation)
	if animation_speed != character.speed_scale:
		character.speed_scale = animation_speed

# ................................................................................

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

# TODO: IMPLEMENTING RIGHT NOW
func enter_attack_range() -> void:
	if attack_state == AttackState.OUT_OF_RANGE:
		attack_state = AttackState.READY
	# TODO: COOLDOWN ?

# TODO: IMPLEMENTING RIGHT NOW
func exit_attack_range() -> void:
	if attack_state == AttackState.READY:
		attack_state = AttackState.OUT_OF_RANGE

# ................................................................................

# STAT BARS

func update_health_bar(value: float, max_value: float) -> void:
	$HealthBar.value = value
	$HealthBar.max_value = max_value
	$HealthBar.visible = value > 0.0 and value < max_value
	
	# modulate health bar
	var temp_bar_percentage: float = value / max_value
	$HealthBar.modulate = \
			Color(0, 1, 0, 1) if temp_bar_percentage > 0.5 \
			else Color(1, 1, 0, 1) if temp_bar_percentage > 0.2 \
			else Color(1, 0, 0, 1)

func update_mana_bar(value: float, max_value: float) -> void:
	$ManaBar.value = value
	$ManaBar.max_value = max_value
	$ManaBar.visible = value < max_value

func update_stamina_bar(value: float, max_value: float) -> void:
	$StaminaBar.value = value
	$StaminaBar.max_value = max_value
	$StaminaBar.visible = value < max_value

	# modulate stamina bar
	if value == 0:
		$StaminaBar.modulate = Color(0.5, 0, 0, 1)
	elif value == max_value:
		$StaminaBar.modulate = Color(1, 0.5, 0, 1)

func update_shield_bar(value: float, max_value: float) -> void:
	$ShieldBar.value = value
	$ShieldBar.max_value = max_value
	$ShieldBar.visible = value > 0

# ................................................................................

# DEATH

func trigger_death() -> void:
	# stop player process
	set_physics_process(false)

	# hide all stats bars
	$HealthBar.hide()
	$ManaBar.hide()
	$StaminaBar.hide()

	$DeathTimer.start(0.5)
	character.play(&"death")
	
	# handle main player
	if is_main_player:
		var alive_party_players = Entities.entities_of_type[Entities.Type.PLAYERS_ALIVE].call()
		if alive_party_players.is_empty():
			print("GAME OVER") # TODO
		else:
			Players.update_main_player(alive_party_players[0])

# ................................................................................

func _on_combat_hit_box_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if Input.is_action_just_pressed(&"action") and event is InputEventMouseButton:
		if Entities.requesting_entities and self in Entities.entities_available and not self in Entities.entities_chosen:
			Inputs.accept_event()
			Entities.choose_entity(self)
		elif character.alive:
			Inputs.accept_event()
			Players.update_main_player(self)

func _on_combat_hit_box_area_mouse_entered() -> void:
	if not is_main_player or (self in Entities.entities_available and not self in Entities.entities_chosen):
		Inputs.mouse_in_attack_range = false

func _on_combat_hit_box_area_mouse_exited() -> void:
	Inputs.mouse_in_attack_range = true

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if is_main_player:
		body.interaction_area(true)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if is_main_player:
		body.interaction_area(false)

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

func _on_knockback_timer_timeout() -> void:
	set_move_state(MoveState.IDLE)

func _on_dash_timer_timeout() -> void:
	if Input.is_action_pressed(&"dash"):
		set_move_state(MoveState.SPRINT)
	else:
		set_move_state(MoveState.WALK)

func _on_death_timer_timeout() -> void:
	character.pause()

# PlayerAlly
func _on_ally_move_cooldown_timeout() -> void:
	if is_main_player: return

	var distance_to_main_player := position.distance_to(Players.main_player_node.position)

	if Combat.in_combat() and not Combat.leaving_combat():
		ally_can_move = true
	elif distance_to_main_player < 70 and velocity != Vector2.ZERO:
		update_velocity(Vector2.ZERO)
		$AllyMoveCooldown.start(randf_range(1.5, 2))
	elif distance_to_main_player < 100 and velocity != Vector2.ZERO:
		update_velocity(Vector2.ZERO)
		$AllyMoveCooldown.start(randf_range(0.7, 0.8))
	else:
		ally_can_move = true

	# TODO: add teleport when far?
