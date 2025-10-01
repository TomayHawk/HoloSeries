extends BasicEnemyBase

# ..............................................................................

# PROCESS

func _init() -> void:
	stats = BasicEnemyStats.new()
	set_variables()

func _ready() -> void:
	# start walking in a random direction
	$Animation.play(&"walk")
	$Animation.flip_h = action_vector.x < 0

# TODO: need to fix death
func _physics_process(delta: float) -> void:
	# check knockback
	if move_state == MoveState.KNOCKBACK:
		velocity -= move_state_velocity * (delta / 0.4)
	elif move_state == MoveState.IDLE and action_state != ActionState.ACTION:
		if not in_action_range:
			$Animation.play(&"walk")
		elif action_target:
			$Animation.flip_h = action_target.position.x < position.x
			if action_state == ActionState.READY:
				take_action()

	move_and_slide()

# ..............................................................................

# SET VARIABLES

func set_variables() -> void:
	# Set base variables
	action_target = null
	action_target_types = Entities.Type.PLAYERS_ALIVE
	action_target_stats = &"health"
	action_target_get_max = false
	action_vector = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()

	# Set stats
	stats.base = self

	stats.level = 1
	stats.entity_types = Entities.Type.ENEMIES

	# Base Health, Mana and Stamina
	stats.base_health = 200.0
	stats.base_mana = 10.0
	stats.base_stamina = 100.0

	# Base Basic Stats
	stats.base_defense = 10.0
	stats.base_ward = 10.0
	stats.base_strength = 10.0
	stats.base_intelligence = 10.0
	stats.base_speed = 0.0
	stats.base_agility = 0.0
	stats.base_crit_chance = 0.05
	stats.base_crit_damage = 0.50

	# Base Secondary Stats
	stats.base_weight = 1.0
	stats.base_vision = 1.0

	# Shield
	stats.shield = 0.0
	stats.max_shield = 200.0

	# Copy base values to current stats
	stats.health = stats.base_health
	stats.mana = stats.base_mana
	stats.stamina = stats.base_stamina

	stats.defense = stats.base_defense
	stats.ward = stats.base_ward
	stats.strength = stats.base_strength
	stats.intelligence = stats.base_intelligence
	stats.speed = stats.base_speed
	stats.agility = stats.base_agility
	stats.crit_chance = stats.base_crit_chance
	stats.crit_damage = stats.base_crit_damage

	stats.weight = stats.base_weight
	stats.vision = stats.base_vision

	# Set max values
	stats.max_health = stats.base_health
	stats.max_mana = stats.base_mana
	stats.max_stamina = stats.base_stamina

# ..............................................................................

# ANIMATION

func animation_end() -> void:
	if in_forced_move_state: return

	velocity = Vector2.ZERO
	if in_action_range:
		if action_state == ActionState.ACTION:
			action_state = ActionState.COOLDOWN
		$Animation.play(&"idle")
	elif enemy_in_combat:
		# remove all dead players from detection and attack arrays
		for player_node in players_in_detection_area:
			if not player_node.stats.alive:
				_on_detection_area_body_exited(player_node)
				_on_attack_area_body_exited(player_node)

		var available_player_nodes: Array[Node]
		# determine targetable player nodes
		if not players_in_attack_area.is_empty():
			available_player_nodes = players_in_attack_area
		else:
			available_player_nodes = players_in_detection_area

		action_target = null
		var target_player_health: float = INF
		# target player with lowest health
		for player_node in available_player_nodes:
			if player_node.stats.health < target_player_health:
				target_player_health = player_node.stats.health
				action_target = player_node
		# move towards player if any player in detection area
		if action_target:
			$NavigationAgent2D.target_position = action_target.position
			action_vector = to_local($NavigationAgent2D.get_next_path_position()).normalized()
			$Animation.flip_h = action_vector.x < 0.0
		# else move in a random direction
		else:
			action_vector = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		$Animation.play(&"walk")
		$Animation.flip_h = action_vector.x < 0.0
	else:
		action_vector = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		$Animation.play(&"walk")
		$Animation.flip_h = action_vector.x < 0.0

func _on_animation_frame_changed() -> void:
	if in_forced_move_state: return
			
	if $Animation.frame == 3:
		match$Animation.animation:
			"attack":
				if action_target:
					var temp_attack_direction = (action_target.position - position).normalized()
					if Damage.combat_damage(13, Damage.DamageTypes.PLAYER_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
							stats, action_target.stats):
						action_target.knockback(temp_attack_direction, 0.4)
					$Animation.flip_h = temp_attack_direction.x < 0
			"walk":
				velocity = action_vector * move_speed

# ..............................................................................

# ACTION

func take_action() -> void:
	if in_forced_move_state: return

	# attempt summon
	if $SummonCooldown.paused and randi() % 3 == 0:
		summon_nousagi()
	else:
		attack()

func attack() -> void:
	action_state = ActionState.ACTION
	$Animation.play(&"attack")
	$Animation.flip_h = action_target.position.x < position.x
	action_cooldown = randf_range(1.5, 3.0)
	
	await action_cooldown_timeout
	if in_action_range:
		action_state = ActionState.READY

func summon_nousagi() -> void:
	# create an instance of nousagi in enemies node
	var nousagi_instance: Node = load("res://entities/enemies/nousagi.tscn").instantiate()
	add_sibling(nousagi_instance)
	nousagi_instance.position = position + Vector2(5 * randf_range(-1.0, 1.0), 5 * randf_range(-1.0, 1.0)) * 5
	
	# start cooldown
	action_cooldown = randf_range(2.0, 3.5)
	action_state = ActionState.COOLDOWN
	$SummonCooldown.start(randf_range(15, 20))
	await action_cooldown_timeout
	if in_action_range and not players_in_detection_area.is_empty():
		action_state = ActionState.READY # TODO: ???
	await $SummonCooldown.timeout

# update health bar
func update_health() -> void:
	$HealthBar.visible = stats.health > 0.0 and stats.health < stats.max_health
	$HealthBar.max_value = stats.max_health
	$HealthBar.value = stats.health
	
	var health_bar_percentage = stats.health / stats.max_health
	$HealthBar.modulate = \
			"a9ff30" if health_bar_percentage > 0.5 \
			else "c8a502" if health_bar_percentage > 0.2 \
			else "a93430"
