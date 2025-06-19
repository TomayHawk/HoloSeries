class_name Nousagi extends BasicEnemyBase

# direction variables
var nousagi_direction: Vector2 = Vector2.ZERO
var target_player_node: Node = null

# combat variables
var can_summon: bool = false

# ..............................................................................

func _init() -> void:
	stats = BasicEnemyStats.new()
	set_stats()

func _ready() -> void:
	# start walking in a random direction
	nousagi_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	$Animation.play(&"walk")
	$Animation.flip_h = nousagi_direction.x < 0

# TODO: need to fix death
func _physics_process(delta: float) -> void:
	# check knockback
	if move_state == MoveState.KNOCKBACK:
		velocity -= knockback_velocity * (delta / 0.4)
	elif move_state == MoveState.IDLE and action_state != ActionState.ACTION:
		if not in_action_range:
			$Animation.play(&"walk")
		elif target_player_node:
			$Animation.flip_h = (target_player_node.position - position).x < 0
			if action_state == ActionState.READY:
				attempt_attack()

	move_and_slide()

# ..............................................................................

# SET STATS

func set_stats() -> void:
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
	if move_state in [MoveState.KNOCKBACK, MoveState.STUN]: return

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

		target_player_node = null
		var target_player_health: float = INF
		# target player with lowest health
		for player_node in available_player_nodes:
			if player_node.stats.health < target_player_health:
				target_player_health = player_node.stats.health
				target_player_node = player_node
		# move towards player if any player in detection area
		if target_player_node:
			$NavigationAgent2D.target_position = target_player_node.position
			nousagi_direction = to_local($NavigationAgent2D.get_next_path_position()).normalized()
			$Animation.flip_h = nousagi_direction.x < 0.0
		# else move in a random direction
		else:
			nousagi_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		$Animation.play(&"walk")
		$Animation.flip_h = nousagi_direction.x < 0.0
	else:
		nousagi_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		$Animation.play(&"walk")
		$Animation.flip_h = nousagi_direction.x < 0.0

func _on_animation_frame_changed() -> void:
	if move_state in [MoveState.KNOCKBACK, MoveState.STUN]: return
			
	if $Animation.frame == 3:
		match $Animation.animation:
			"attack":
				if target_player_node:
					var temp_attack_direction = (target_player_node.position - position).normalized()
					if Damage.combat_damage(13, Damage.DamageTypes.PLAYER_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
							stats, target_player_node.stats):
						target_player_node.knockback(temp_attack_direction, 0.4)
					$Animation.flip_h = temp_attack_direction.x < 0
			"walk":
				velocity = nousagi_direction * walk_speed

# ..............................................................................

# ATTACK

func attempt_attack() -> void:
	if can_summon and randi() % 3 == 0:
		summon_nousagi()
	else:
		action_state = ActionState.ACTION
		$Animation.play(&"attack")
		$AttackCooldown.start(randf_range(1.5, 3.0))
		await $AttackCooldown.timeout
		if in_action_range:
			action_state = ActionState.READY

func summon_nousagi():
	# create an instance of nousagi in enemies node
	var nousagi_instance: Node = load("res://entities/enemies/nousagi.tscn").instantiate()
	add_sibling(nousagi_instance)
	nousagi_instance.position = position + Vector2(5 * randf_range(-1, 1), 5 * randf_range(-1, 1)) * 5
	
	# start cooldown
	$AttackCooldown.start(randf_range(2.0, 3.5))
	action_state = ActionState.COOLDOWN
	$SummonCooldown.start(randf_range(15, 20))
	can_summon = false
	await $AttackCooldown.timeout
	if in_action_range and not players_in_detection_area.is_empty():
		action_state = ActionState.READY
	await $SummonCooldown.timeout
	can_summon = true

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
