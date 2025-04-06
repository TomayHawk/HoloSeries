extends BasicEnemyBase

# direction variables
var nousagi_direction: Vector2 = Vector2.ZERO
var target_player_node: Node = null

# combat variables
var can_summon := false

# ................................................................................

func _ready() -> void:
	# initialize stats
	enemy_stats_node.level = 1
	# Health, Mana & Stamina
	enemy_stats_node.max_health = 200.0
	enemy_stats_node.base_health = 200.0
	enemy_stats_node.health = 200.0
	enemy_stats_node.max_mana = 10.0
	enemy_stats_node.base_mana = 10.0
	enemy_stats_node.mana = 10.0
	enemy_stats_node.max_stamina = 100.0
	enemy_stats_node.base_stamina = 100.0
	enemy_stats_node.stamina = 100.0
	# Stats
	enemy_stats_node.base_defense = 10.0
	enemy_stats_node.defense = 10.0
	enemy_stats_node.base_ward = 10.0
	enemy_stats_node.ward = 10.0
	enemy_stats_node.base_strength = 10.0
	enemy_stats_node.strength = 10.0
	enemy_stats_node.base_intelligence = 10.0
	enemy_stats_node.intelligence = 10.0
	enemy_stats_node.base_crit_chance = 0.05
	enemy_stats_node.crit_chance = 0.05
	enemy_stats_node.base_crit_damage = 0.50
	enemy_stats_node.crit_damage = 0.50

	enemy_stats_node.play("idle")
	# TEMP
	attack_state = AttackState.OUT_OF_RANGE

func _physics_process(_delta: float) -> void:
	# check knockback
	if move_state == MoveState.KNOCKBACK:
		velocity = knockback_direction * knockback_multiplier * (1 - (0.4 - knockback_timer_node.get_time_left()) / 0.4) * knockback_weight
	# animation check outside animation frame update
	elif enemy_stats_node.animation == "idle":
		# choose a player if player exists in detection area
		# face target player
		if target_player_node:
			enemy_stats_node.flip_h = (target_player_node.position - position).x < 0
		# switch to attack when ready
		if attack_state == AttackState.READY:
			attempt_attack()
		# switch to walk when outside attack mode
		elif attack_state == AttackState.OUT_OF_RANGE:
			enemy_stats_node.play("walk")

	move_and_slide()

# ................................................................................

func frame_changed() -> void:
	if move_state == MoveState.KNOCKBACK: return
	
	match enemy_stats_node.frame:
		0:
			velocity = Vector2.ZERO
			# else determine move direction
			if not attack_state != AttackState.OUT_OF_RANGE:
				enemy_stats_node.play("idle")
			elif enemy_stats_node.enemy_in_combat:
				# remove all dead players from detection and attack arrays
				for player_node in enemy_stats_node.players_in_detection_area:
					if not player_node.character_node.alive:
						enemy_stats_node._on_detection_area_body_exited(player_node)
						enemy_stats_node._on_attack_area_body_exited(player_node)

				var available_player_nodes: Array[Node]
				# determine targetable player nodes
				if not enemy_stats_node.players_in_attack_area.is_empty():
					available_player_nodes = enemy_stats_node.players_in_attack_area
				else:
					available_player_nodes = enemy_stats_node.players_in_detection_area

				target_player_node = null
				var target_player_health: float = INF
				# target player with lowest health
				for player_node in available_player_nodes:
					if player_node.character_node.health < target_player_health:
						target_player_health = player_node.character_node.health
						target_player_node = player_node
				# move towards player if any player in detection area
				if target_player_node:
					$BasicEnemy/NavigationAgent2D.target_position = target_player_node.position
					nousagi_direction = to_local($BasicEnemy/NavigationAgent2D.get_next_path_position()).normalized()
				# else move in a random direction
				else:
					nousagi_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
				enemy_stats_node.play("walk")
				enemy_stats_node.flip_h = nousagi_direction.x < 0.0
			else:
				nousagi_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
				enemy_stats_node.play("walk")
				enemy_stats_node.flip_h = nousagi_direction.x < 0
		3:
			match enemy_stats_node.animation:
				"attack":
					# attack player
					if target_player_node:
						var temp_attack_direction = (target_player_node.position - position).normalized()
						if Damage.combat_damage(13, Damage.DamageTypes.PLAYER_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
								enemy_stats_node, target_player_node.character_node): # attack player (damage)
							target_player_node.dealt_knockback(temp_attack_direction, 0.4)
						enemy_stats_node.flip_h = temp_attack_direction.x < 0
				"walk":
					velocity = nousagi_direction * walk_speed

# ................................................................................

# ATTACK

func attempt_attack() -> void:
	if can_summon and randi() % 3 == 0:
		summon_nousagi()
	else:
		attack_state = AttackState.COOLDOWN
		enemy_stats_node.play("attack")
		$BasicEnemy/AttackCooldown.start(randf_range(1.5, 3.0))

func summon_nousagi():
	# create an instance of nousagi in enemies node
	var nousagi_instance: Node = load("res://entities/enemies/enemy_specifics/nousagi.tscn").instantiate()
	add_sibling(nousagi_instance)
	nousagi_instance.position = position + Vector2(5 * randf_range(-1, 1), 5 * randf_range(-1, 1)) * 5
	
	# start cooldown
	$BasicEnemy/AttackCooldown.start(randf_range(2.0, 3.5))
	attack_state = AttackState.COOLDOWN
	$SummonCooldown.start(randf_range(15, 20))
	can_summon = false

# ................................................................................

func _on_summon_cooldown_timeout() -> void:
	can_summon = true
