class_name CharacterBase extends AnimatedSprite2D

var base: PlayerBase = null
var stats: PlayerStats = null

var basic_damage: float = 10.0
var ultimate_damage: float = 100.0

func set_action_radius() -> void:
	pass

# TODO: currently only supports ultimate and basic attacks
func queue_action() -> void:
	if not base: return

	# check if action queue is full
	if base.action_queue.size() >= 3:
		return

	# if ultimate gauge is full, queue ultimate attack
	if stats.ultimate_gauge == stats.max_ultimate_gauge:
		base.action_queue.append([attack, [ultimate_attack, []]])
		return
	
	base.action_queue.append([attack, [basic_attack, []]])

func attack(attack_function: Callable, attack_arguments: Array) -> void:
	attack_function.callv(attack_arguments)

func _on_action_cooldown_timeout() -> void:
	if not base: return
	base.action_state = base.ActionState.READY

func death() -> void:
	play(&"death")
	await animation_finished
	pause()

# ATTACKS

func basic_attack() -> void:
	if not base: return

	if base.is_main_player:
		base.attack_vector = (get_global_mouse_position() - base.position).normalized()
	else:
		# TODO: should be dynamic
		var target_enemy_node: EnemyBase = null
		var temp_enemy_health: float = INF
		for enemy_node in base.enemy_nodes_in_attack_area:
			if enemy_node.enemy_stats_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.enemy_stats_node.health
				base.attack_vector = (enemy_node.position - base.position).normalized()
		
		#$AllyAttackCooldown.start(randf_range(2, 3))

	if base.move_state == base.MoveState.DASH:
		stats.dash_attack = true
	
	$AttackShape.set_target_position(base.attack_vector * 20)

	$AttackTimer.start(0.5)

	$AttackShape.force_shapecast_update()

	connect(&"frame_changed", Callable(self, "basic_attack_register"))

	await something

	if frame != 1: return
	disconnect(&"frame_changed", Callable(self, "basic_attack_register"))
	var temp_damage: float = basic_damage
	var enemy_body = null
	var knockback_weight = 1.0

	if stats.dash_attack:
		temp_damage *= 1.5
		knockback_weight = 1.5
		stats.dash_attack = false
	
	if $AttackShape.is_colliding():
		for collision_index in $AttackShape.get_collision_count():
			enemy_body = $AttackShape.get_collider(collision_index).base # TODO: null instance bug need fix
			if Damage.combat_damage(temp_damage,
					Damage.DamageTypes.ENEMY_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
					self, enemy_body.enemy_stats_node):
				enemy_body.knockback(base.attack_vector, knockback_weight)
		Players.camera_node.screen_shake(0.1, 1, 30, 5, true)

func ultimate_attack():
	if not base: return
	
	stats.update_ultimate_gauge(-100)

	if base.is_main_player: base.attack_vector = (get_global_mouse_position() - base.position).normalized()
	else:
		var temp_enemy_health = INF
		for enemy_node in base.enemy_nodes_in_attack_area:
			if enemy_node.enemy_stats_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.enemy_stats_node.health
				base.attack_vector = (enemy_node.position - base.position).normalized()
		base.can_attack = false
		$AllyAttackCooldown.start(randf_range(2, 3))
	
	if base.move_state == base.MoveState.DASH:
		stats.dash_attack = true
	
	$AttackShape.set_target_position(base.attack_vector * 20)

	$AttackTimer.start(0.5)
	$AttackShape.force_shapecast_update()

	connect(&"frame_changed", Callable(self, "ultimate_attack_register"))

	await something

	if frame != 1: return
	disconnect(&"frame_changed", Callable(self, "ultimate_attack_register"))
	var temp_damage: float = ultimate_damage
	var enemy_body = null
	var knockback_weight = 2.0
	if stats.dash_attack:
		temp_damage *= 1.5
		knockback_weight = 3.0
		stats.dash_attack = false

	if $AttackShape.is_colliding():
		for collision_index in $AttackShape.get_collision_count():
			enemy_body = $AttackShape.get_collider(collision_index).base
			if Damage.combat_damage(temp_damage,
					Damage.DamageTypes.ENEMY_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
					self, enemy_body.enemy_stats_node):
				enemy_body.knockback(base.attack_vector, knockback_weight)
		Players.camera_node.screen_shake(0.3, 10, 30, 100, true)
