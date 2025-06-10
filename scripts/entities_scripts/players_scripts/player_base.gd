class_name PlayerBase extends EntityBase

# TODO: not sure about the type
var alternate_script: PlayerBase = null
var character: CharacterBase = null

func _ready() -> void:
	knockback_timeout.connect(on_knockback_timeout)
	dash_timeout.connect(on_dash_timeout)
	if self is PlayerAlly:
		alternate_script = PlayerMain.new()
	else:
		alternate_script = PlayerAlly.new()

# ..............................................................................

# MOVEMENTS

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
		move_state = MoveState.IDLE
		velocity = Vector2.ZERO
		update_animation()
		return
	
	# set move direction
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
	update_animation()
	
	var temp_velocity: Vector2 = next_direction * stats.walk_speed

	match move_state:
		MoveState.IDLE:
			move_state = MoveState.WALK
			update_animation()
		MoveState.SPRINT:
			temp_velocity *= stats.sprint_multiplier
			stats.update_stamina(-stats.sprint_stamina)
		MoveState.DASH:
			temp_velocity *= stats.dash_multiplier * dash_timer / stats.dash_time

	if action_state == ActionState.ATTACK:
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

	move_state = MoveState.DASH
	update_animation()

func knockback(next_velocity: Vector2, knockback_time: float) -> void:
	if move_state == MoveState.KNOCKBACK: return
	knockback_velocity = next_velocity
	knockback_timer = knockback_time
	move_state = MoveState.KNOCKBACK
	update_animation()

# ..............................................................................

# ATTACK

func set_action_state(next_state: ActionState) -> void:
	if action_state == next_state or not stats.alive: return
	# ally conditions
	if self is PlayerAlly:
		#if not can_attack:
			#return
		if action_state != ActionState.READY and next_state == ActionState.ATTACK:
			return

	action_state = next_state

	if action_state == ActionState.ATTACK: attempt_attack()

	update_animation()

func attempt_attack(attack_name: String = "") -> void:
	if character != get_node_or_null(^"CharacterBase"):
		set_action_state(ActionState.READY) # TODO: depends
		return
	
	if attack_name != "":
		pass # call attack with conditions
	elif character.auto_ultimate and character.ultimate_gauge == character.max_ultimate_gauge:
		character.ultimate_attack()
	else:
		character.basic_attack()

# ..............................................................................

# ANIMATION

func update_animation() -> void:
	if (
		not stats.alive
		or move_state == MoveState.KNOCKBACK
		or move_state == MoveState.STUN
	): return

	var next_animation: StringName = character.animation
	var animation_speed: float = 1.0
	
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

		animation_speed = stats.walk_speed / 70.0
		if move_state == MoveState.DASH:
			animation_speed *= 2.0
		elif move_state == MoveState.SPRINT:
			animation_speed *= stats.sprint_multiplier
		
	if next_animation != character.animation:
		character.play(next_animation)
	if animation_speed != character.speed_scale:
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

# ..............................................................................

# UPDATE NODES

# swap base scripts when switching main players
func swap_base() -> void:
	var current_script: PlayerBase = get_script()

	# swap scripts
	set_script(alternate_script)

	# copy variables from current_script to alternate_script
	alternate_script.stats = current_script.stats

	alternate_script.process_interval = current_script.process_interval
	
	alternate_script.move_state = current_script.move_state
	alternate_script.action_state = current_script.action_state
	alternate_script.move_direction = current_script.move_direction
	alternate_script.attack_vector = current_script.attack_vector

	alternate_script.update_animation()

	current_script.dash_timer = 0.0

	# reset ally variables
	if current_script is PlayerAlly:
		current_script.action_queue.clear()
		current_script.can_move = true
		current_script.can_attack = true
		current_script.in_attack_range = false
	
	# TODO: update signals?

	alternate_script = current_script

# swap stats with standby stats
func swap_with_standby(next_character: CharacterBase) -> CharacterBase:
	var current_character: CharacterBase = character
	var current_stats: PlayerStats = stats
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

	var current_script: PlayerBase = get_script()

	if current_script is PlayerAlly:
		current_script.action_queue.clear()
		current_script.can_move = true
		current_script.can_attack = true
		current_script.in_attack_range = false
	
	return current_character

'''

func update_nodes(swap_base: PlayerBase = null, swap_stats: PlayerStats = null) -> void:
	elif swap_stats != stats: # Party -> Standby
		pass
	
	update_stats()
	
	if base:
		name = &"CharacterBase"
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
		player_node.in_attack_range = false

		# knockback variables
		player_node.knockback_direction = Vector2.ZERO
		player_node.knockback_weight = 0.0
		player_node.character = self
		player_node.walk_speed = 140 + speed * 0.5
		player_node.dash_stamina = 35 - (agility * 0.0625)
		player_node.sprint_stamina = 0.8 - (agility * 0.00048828125)
		player_node.dash_time = 0.2 * (1 - (agility * 0.001953125)) # minimum 0.1s dash time
		player_node.update_velocity(Vector2.ZERO)
		player_node.set_action_state(base.ActionState.READY)
		# TODO: player_node.ally_speed = 60 + (30 * speed)
		# player_node.dash_multiplier = 300 + (150 * speed)
	else:
		Combat.ui.standby_level_labels[node_index].text = str(level)
		Combat.ui.standby_health_labels[node_index].text = str(int(health))
		Combat.ui.standby_mana_labels[node_index].text = str(int(mana))

'''

# ..............................................................................

# DEATH

func trigger_death() -> void:
	# stop player process
	set_physics_process(false)

	# hide stats bars
	$HealthBar.hide()
	$ShieldBar.hide()
	$ManaBar.hide()
	$StaminaBar.hide()

	# start death animation
	character.play(&"death")

	# reset player variables
	move_state = MoveState.STUN
	action_state = ActionState.COOLDOWN
	knockback_timer = 0.0
	dash_timer = 0.0
	
	# handle main player
	if self is PlayerMain:
		var alive_party_players = Entities.entities_of_type[Entities.Type.PLAYERS_ALIVE].call()
		if alive_party_players.is_empty():
			print("GAME OVER") # TODO
		else:
			Players.update_main_player(alive_party_players[0])

	await Global.get_tree().create_timer(0.5).timeout

	if not stats.alive:
		character.pause() # TODO

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

func on_knockback_timeout() -> void:
	if move_state == MoveState.KNOCKBACK:
		move_state = MoveState.IDLE
		update_animation()

func on_dash_timeout() -> void:
	if move_state == MoveState.DASH:
		if Input.is_action_pressed(&"dash"):
			move_state = MoveState.SPRINT
		else:
			move_state = MoveState.WALK
		update_animation()
