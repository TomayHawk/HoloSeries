class_name PlayerBase extends EntityBase

var is_main_player: bool = false

# movement variables
var walk_speed: float = 70.0
var sprint_multiplier: float = 1.25
var sprint_stamina: float = 0.8
var dash_multiplier: float = 8.0
var dash_stamina: float = 35.0
var dash_minimum_stamina: float = 25.0
var dash_time: float = 0.2
var attack_movement_multiplier: float = 0.3

# ally variables
var ally_can_move: bool = true
var ally_can_attack: bool = true
var ally_in_attack_position: bool = false
var enemy_nodes_in_attack_area: Array[Node] = []

# knockback variables
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_weight: float = 0.0

@onready var character_node: AnimatedSprite2D = get_node_or_null(^"CharacterBase")

# ................................................................................

# PROCESS LOOP AND INPUTS

func _physics_process(_delta: float) -> void:
	if move_state == MoveState.KNOCKBACK:
		update_velocity(knockback_direction)
	elif is_main_player:
		update_velocity(Input.get_vector(&"left", &"right", &"up", &"down"))
	elif character_node:
		character_node.ally_process()
	move_and_slide()

func _input(_event: InputEvent) -> void:
	if not is_main_player: return
	
	if Input.is_action_just_pressed(&"dash") and character_node.stamina > dash_minimum_stamina and not character_node.stamina_slow_recovery:
		set_move_state(MoveState.DASH)
		dash()
	elif Input.is_action_just_released(&"dash") and move_state == MoveState.DASH:
		set_move_state(MoveState.WALK)

# ................................................................................

# UPDATE VARIABLES

# called when switching characters
func update_variables() -> void: # TODO
	# movement variables
	walk_speed = 70.0
	sprint_multiplier = 1.25
	sprint_stamina = 0.8
	dash_multiplier = 8.0
	dash_stamina = 35.0
	dash_minimum_stamina = 25.0
	dash_time = 0.2
	attack_movement_multiplier = 0.3

	# ally variables
	ally_can_move = true
	ally_can_attack = true
	ally_in_attack_position = false

	# knockback variables
	knockback_direction = Vector2.ZERO
	knockback_weight = 0.0

# ................................................................................

# ANIMATION

func update_animation() -> void:
	if not character_node.alive or move_state == MoveState.KNOCKBACK: return

	const animations: Dictionary[Directions, Array] = {
		Directions.UP: [&"up_idle", &"up_walk", &"up_attack"],
		Directions.DOWN: [&"down_idle", &"down_walk", &"down_attack"],
		Directions.LEFT: [&"left_idle", &"left_walk", &"left_attack"],
		Directions.RIGHT: [&"right_idle", &"right_walk", &"right_attack"],
		Directions.UP_LEFT: [&"left_idle", &"left_walk", &"left_attack"],
		Directions.DOWN_LEFT: [&"left_idle", &"left_walk", &"left_attack"],
		Directions.UP_RIGHT: [&"right_idle", &"right_walk", &"right_attack"],
		Directions.DOWN_RIGHT: [&"right_idle", &"right_walk", &"right_attack"],
	}

	var next_animation: StringName = character_node.animation
	var animation_speed: float = 1.0
	
	if attack_state == AttackState.ATTACKING:
		var attack_face_direction: Directions
		if abs(attack_direction.x) < abs(attack_direction.y):
			attack_face_direction = Directions.UP if attack_direction.y < 0 else Directions.DOWN
		else:
			attack_face_direction = Directions.LEFT if attack_direction.x < 0 else Directions.RIGHT
		next_animation = animations[attack_face_direction][2]
	else:
		match move_state:
			MoveState.IDLE:
				next_animation = animations[move_direction][0]
			MoveState.WALK:
				next_animation = animations[move_direction][1]
			MoveState.DASH:
				next_animation = animations[move_direction][1]
				animation_speed = 2.0
			MoveState.SPRINT:
				next_animation = animations[move_direction][1]
				animation_speed = sprint_multiplier
			MoveState.KNOCKBACK:
				pass
		
	if next_animation != character_node.animation:
		character_node.play(next_animation)
	if animation_speed != character_node.speed_scale:
		character_node.speed_scale = animation_speed

# ................................................................................

# MOVEMENTS

func set_move_state(next_state: MoveState) -> void:
	if move_state == next_state or not character_node.alive: return
	move_state = next_state
	update_animation()

func set_move_direction(direction: Directions) -> void:
	if move_direction == direction or not character_node.alive: return
	move_direction = direction
	update_animation()

func update_velocity(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		set_move_state(MoveState.IDLE)
		velocity = Vector2.ZERO
		return
	
	if VECTOR_TO_DIRECTION.has(direction):
		set_move_direction(VECTOR_TO_DIRECTION[direction])
	 
	var temp_velocity: Vector2 = direction * walk_speed

	match move_state:
		MoveState.IDLE:
			set_move_state(MoveState.WALK)
		MoveState.SPRINT:
			temp_velocity *= sprint_multiplier
			character_node.update_stamina(-sprint_stamina)
		MoveState.DASH:
			temp_velocity *= dash_multiplier * (1.0 - (dash_time - $DashTimer.get_time_left()) / dash_time)
		MoveState.KNOCKBACK:
			temp_velocity = knockback_direction * 200 * (1.0 - (0.4 - $KnockbackTimer.get_time_left()) / 0.4) * knockback_weight

	if attack_state == AttackState.ATTACKING:
		temp_velocity *= attack_movement_multiplier
	
	velocity = temp_velocity

func dash() -> void:
	$DashTimer.start(dash_time)
	character_node.update_stamina(-dash_stamina)

func dealt_knockback(direction: Vector2, weight: float = 1.0) -> void:
	if move_state == MoveState.KNOCKBACK: return
	if direction == Vector2.ZERO or weight == 0.0: return
	set_move_state(MoveState.KNOCKBACK)
	
	knockback_direction = direction
	knockback_weight = weight

	get_node(^"KnockbackTimer").start(0.4)

# ................................................................................

# ATTACK

func set_attack_state(next_state: AttackState) -> void:
	if attack_state == next_state or not character_node.alive: return
	# ally conditions
	if not is_main_player:
		#if not ally_can_attack:
			#return
		if attack_state != AttackState.READY and next_state == AttackState.ATTACKING:
			return

	attack_state = next_state

	if attack_state == AttackState.ATTACKING: attempt_attack()

	update_animation()

func attempt_attack(attack_name: String = "") -> void:
	if character_node != get_node_or_null("CharacterBase"):
		set_attack_state(AttackState.READY) # TODO: depends
		return
	
	if attack_name != "":
		pass # call attack with conditions
	elif character_node.auto_ultimate and character_node.ultimate_gauge == character_node.max_ultimate_gauge:
		character_node.ultimate_attack()
	else:
		character_node.basic_attack()

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
			resultant_nodes.push_back(entity_node.character_node if get_stats_nodes else entity_node)
		elif entity_node is BasicEnemyBase:
			resultant_nodes.push_back(entity_node.base_enemy_node if get_stats_nodes else entity_node)
	
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
	character_node.play(&"death")
	
	# handle main player
	if is_main_player:
		var alive_party_players = Entities.entities_of_type[Entities.Type.PLAYERS_PARTY_ALIVE].call()
		if alive_party_players.size() == 0:
			print("GAME OVER") # TODO
		else:
			Players.update_main_player(alive_party_players[0])

# ................................................................................

func _on_combat_hit_box_area_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if Input.is_action_just_pressed(&"action"): # TODO
		if Entities.requesting_entities and self in Entities.entities_available and not self in Entities.entities_chosen:
			Entities.entities_chosen.push_back(self)
			if Entities.entities_requested_count == Entities.entities_chosen.size():
				Entities.choose_entities()
		elif character_node.alive:
			Players.update_main_player(self)

func _on_combat_hit_box_area_mouse_entered() -> void:
	if not is_main_player or self in Entities.entities_available:
		Inputs.mouse_in_attack_position = false

func _on_combat_hit_box_area_mouse_exited() -> void:
	Inputs.mouse_in_attack_position = true

func _on_interaction_area_body_entered(body: Node) -> void:
	if is_main_player:
		body.interaction_area(true)

func _on_interaction_area_body_exited(body: Node) -> void:
	if is_main_player:
		body.interaction_area(false)

func _on_knockback_timer_timeout() -> void:
	set_move_state(MoveState.IDLE)

func _on_dash_timer_timeout() -> void:
	if Input.is_action_pressed(&"dash"):
		set_move_state(MoveState.SPRINT)
	else:
		set_move_state(MoveState.WALK)

func _on_death_timer_timeout() -> void:
	character_node.pause()

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
