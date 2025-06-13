class_name Character extends EntityStats

# movement variables
var walk_speed: float = 140.0
var dash_multiplier: float = 1120.0
var dash_stamina: float = 35.0
var dash_min_stamina: float = 25.0
var dash_time: float = 0.2
var sprint_multiplier: float = 175.0
var sprint_stamina: float = 0.8
var attack_movement_reduction: float = 0.3

var fatigue: bool = false

# combat variables
var auto_ultimate: bool = true # TODO: add more settings
var attack_range: float = 20.0
var ultimate_gauge: float = 0.0
var max_ultimate_gauge: float = 100.0
var basic_damage: float = 10.0
var ultimate_damage: float = 100.0

# nexus variables
var last_node: int = -1
var unlocked_nodes: Array[int] = []
var converted_nodes: Array[Array] = []

# ally variables
var max_ally_distance: float = 250.0

# ..............................................................................

# STATS UPDATES

func update_health(value: float) -> void:
	super (value)
	if base: base.update_health(health)

func update_mana(value: float) -> void:
	super (value)
	if base: base.update_mana(mana)

func update_stamina(value: float) -> void:
	super (value)

	# handle fatigue
	if stamina == 0:
		fatigue = true
	elif stamina == max_stamina:
		fatigue = false

	if base: base.update_stamina(stamina)

func update_shield(value: float) -> void:
	super (value)
	if base: base.update_shield(shield)

func update_ultimate_gauge(value: float) -> void:
	if not alive: return
	ultimate_gauge = clamp(ultimate_gauge + value, 0, max_ultimate_gauge)
	if base: base.update_ultimate_gauge(ultimate_gauge)

# ..............................................................................

# DEATH & REVIVE

func death() -> void:
	super ()
	fatigue = false
	if base: base.death()

func revive(value: float) -> void:
	super (value)
	if base: base.revive()

# ..............................................................................

# TODO: move below to character specific scripts

func queue_action() -> void:
	if not base: return
	
	# check if action queue is full
	if base.action_queue.size() >= 3:
		return

	# if ultimate gauge is full, queue ultimate attack
	if stats.ultimate_gauge == max_ultimate_gauge:
		base.action_queue.append([ultimate_attack, []])
		return
	
	get_parent().action_queue.append([basic_attack, []])

# ATTACKS

func basic_attack() -> void:
	if not base: return

	if base.is_main_player:
		base.attack_vector = (get_global_mouse_position() - base.position).normalized()
	else:
		var temp_enemy_health = INF
		for enemy_node in base.enemy_nodes_in_attack_area:
			if enemy_node.enemy_stats_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.enemy_stats_node.health
				base.attack_vector = (enemy_node.position - base.position).normalized()
		base.can_attack = false
		$AllyAttackCooldown.start(randf_range(2, 3))

	if base.move_state == base.MoveState.DASH:
		dash_attack = true
	
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

	if dash_attack:
		temp_damage *= 1.5
		knockback_weight = 1.5
		dash_attack = false
	
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
	
	update_ultimate_gauge(-100)

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
		dash_attack = true
	
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
	if dash_attack:
		temp_damage *= 1.5
		knockback_weight = 3.0
		dash_attack = false

	if $AttackShape.is_colliding():
		for collision_index in $AttackShape.get_collision_count():
			enemy_body = $AttackShape.get_collider(collision_index).base
			if Damage.combat_damage(temp_damage,
					Damage.DamageTypes.ENEMY_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
					self, enemy_body.enemy_stats_node):
				enemy_body.knockback(base.attack_vector, knockback_weight)
		Players.camera_node.screen_shake(0.3, 10, 30, 100, true)
