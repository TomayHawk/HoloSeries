extends BasicEnemyBase

# direction variables
var nousagi_direction: Vector2 = Vector2.ZERO
var target_player_node: Node = null

# combat variables
var can_summon := false

# ..............................................................................

func _ready() -> void:
	# initialize stats
	enemy_stats_node.level = 1
	# Health, Mana, Stamina & Shield
	enemy_stats_node.max_health = 200.0
	enemy_stats_node.max_mana = 10.0
	enemy_stats_node.max_stamina = 100.0
	enemy_stats_node.max_shield = 0.0
	
	enemy_stats_node.health = 200.0
	enemy_stats_node.mana = 10.0
	enemy_stats_node.stamina = 100.0
	enemy_stats_node.shield = 0.0
	
	# Stats
	enemy_stats_node.defense = 10.0
	enemy_stats_node.ward = 10.0
	enemy_stats_node.strength = 10.0
	enemy_stats_node.intelligence = 10.0
	enemy_stats_node.crit_chance = 0.05
	enemy_stats_node.crit_damage = 0.50

	# Additional Stats
	enemy_stats_node.weight = 1.0
	enemy_stats_node.vision = 1.0

	nousagi_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	enemy_stats_node.play(&"walk")
	enemy_stats_node.flip_h = nousagi_direction.x < 0
	# TEMP
	action_state = ActionState.OUT_OF_RANGE

func _physics_process(delta: float) -> void:
	# check knockback
	if move_state == MoveState.KNOCKBACK:
		if enemy_stats_node.alive:
			velocity -= knockback_velocity * (delta / 0.4)
	elif move_state == MoveState.IDLE and action_state != ActionState.ATTACK:
		if action_state == ActionState.OUT_OF_RANGE:
			enemy_stats_node.play(&"walk")
		elif target_player_node:
			enemy_stats_node.flip_h = (target_player_node.position - position).x < 0
			if action_state == ActionState.READY:
				attempt_attack()

	move_and_slide()

# ..............................................................................

# STATES

func update_velocity(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		move_state = MoveState.IDLE
		velocity = Vector2.ZERO
		return
	
	var temp_velocity: Vector2 = direction * walk_speed

	match move_state:
		MoveState.IDLE:
			move_state = MoveState.WALK
	
	velocity = temp_velocity

func update_animation() -> void:
	pass

# ..............................................................................

func frame_changed() -> void:
	if move_state == MoveState.KNOCKBACK: return
	
	match enemy_stats_node.frame:
		0:
			velocity = Vector2.ZERO
			if action_state != ActionState.OUT_OF_RANGE:
				if action_state == ActionState.ATTACK:
					action_state = ActionState.COOLDOWN
				enemy_stats_node.play(&"idle")
			elif enemy_in_combat:
				# remove all dead players from detection and attack arrays
				for player_node in players_in_detection_area:
					if not player_node.character.alive:
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
					if player_node.character.health < target_player_health:
						target_player_health = player_node.character.health
						target_player_node = player_node
				# move towards player if any player in detection area
				if target_player_node:
					$NavigationAgent2D.target_position = target_player_node.position
					nousagi_direction = to_local($NavigationAgent2D.get_next_path_position()).normalized()
					enemy_stats_node.flip_h = nousagi_direction.x < 0.0
				# else move in a random direction
				else:
					nousagi_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
				enemy_stats_node.play(&"walk")
				enemy_stats_node.flip_h = nousagi_direction.x < 0.0
			else:
				nousagi_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
				enemy_stats_node.play(&"walk")
				enemy_stats_node.flip_h = nousagi_direction.x < 0
		3:
			match enemy_stats_node.animation:
				"attack":
					# attack player
					if target_player_node:
						var temp_attack_direction = (target_player_node.position - position).normalized()
						if Damage.combat_damage(13, Damage.DamageTypes.PLAYER_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
								enemy_stats_node, target_player_node.character):
							target_player_node.knockback(temp_attack_direction, 0.4)
						enemy_stats_node.flip_h = temp_attack_direction.x < 0
				"walk":
					velocity = nousagi_direction * walk_speed

# ..............................................................................

# ATTACK

func attempt_attack() -> void:
	if can_summon and randi() % 3 == 0:
		summon_nousagi()
	else:
		action_state = ActionState.ATTACK
		enemy_stats_node.play(&"attack")
		$AttackCooldown.start(randf_range(1.5, 3.0))
		await $AttackCooldown.timeout
		if action_state != ActionState.OUT_OF_RANGE:
			action_state = ActionState.READY

func summon_nousagi():
	# create an instance of nousagi in enemies node
	var nousagi_instance: Node = load("res://entities/enemies/enemy_specifics/nousagi.tscn").instantiate()
	add_sibling(nousagi_instance)
	nousagi_instance.position = position + Vector2(5 * randf_range(-1, 1), 5 * randf_range(-1, 1)) * 5
	
	# start cooldown
	$AttackCooldown.start(randf_range(2.0, 3.5))
	action_state = ActionState.COOLDOWN
	$SummonCooldown.start(randf_range(15, 20))
	can_summon = false
	await $AttackCooldown.timeout
	if action_state != ActionState.OUT_OF_RANGE and not players_in_detection_area.is_empty():
		action_state = ActionState.READY
	await $SummonCooldown.timeout
	can_summon = true

# ..............................................................................

# ATTACK

#func set_attack_state(next_state: ActionState) -> void:
#    if action_state == next_state or not character.alive: return
#    # ally conditions
#    if not is_main_player:
#        #if not can_attack:
#            #return
#        if action_state != ActionState.READY and next_state == ActionState.ATTACK:
#            return
#
#    action_state = next_state
#
#    if action_state == ActionState.ATTACK: attempt_attack()
#
#    update_animation()
#
#func attempt_attack(attack_name: String = "") -> void:
#    if character != get_node_or_null(^"Character"):
#        set_attack_state(ActionState.READY) # TODO: depends
#        return
#    
#    if attack_name != "":
#        pass # call attack with conditions
#    elif character.auto_ultimate and character.ultimate_gauge == character.max_ultimate_gauge:
#        character.ultimate_attack()
#    else:
#        character.basic_attack()

# TODO: need to implement
#func filter_nodes(initial_nodes: Array[EntityBase], get_stats_nodes: bool, origin_position: Vector2 = Vector2(-1.0, -1.0), range_min: float = -1.0, range_max: float = -1.0) -> Array[Node]:
#    var resultant_nodes: Array[Node] = []
#    var check_distance: bool = range_max > 0
#    
#    if check_distance:
#        range_min *= range_min
#        range_max *= range_max
#    
#    for entity_node in initial_nodes:
#        if check_distance:
#            var temp_distance: float = origin_position.distance_squared_to(entity_node.position)
#            if temp_distance < range_min or temp_distance > range_max:
#                continue
#        if entity_node is PlayerBase:
#            resultant_nodes.push_back(entity_node.character if get_stats_nodes else entity_node)
#        elif entity_node is BasicEnemyBase:
#            resultant_nodes.push_back(entity_node.enemy_stats_node if get_stats_nodes else entity_node)
#    
#    return resultant_nodes

# TODO: IMPLEMENTING RIGHT NOW
#func enter_attack_range() -> void:
#    if action_state == ActionState.OUT_OF_RANGE:
#        action_state = ActionState.READY
#    # TODO: COOLDOWN ?

# TODO: IMPLEMENTING RIGHT NOW
#func exit_attack_range() -> void:
#    if action_state == ActionState.READY:
#        action_state = ActionState.OUT_OF_RANGE
