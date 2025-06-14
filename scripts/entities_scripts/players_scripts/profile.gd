class_name Profile extends EntityStats

var animation: SpriteFrames = null

# equipment variables
var weapon: Weapon = null
var headgear: Headgear = null
var chestpiece: Chestpiece = null
var leggings: Leggings = null
var accessory_1: Accessory = null
var accessory_2: Accessory = null
var accessory_3: Accessory = null

# stats variables
var experience: float = 0.0

# ultimate variables
var ultimate_gauge: float = 0.0
var max_ultimate_gauge: float = 100.0

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

# nexus variables
var last_node: int = -1
var unlocked_nodes: Array[int] = []
var converted_nodes: Array[Array] = []

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

# SET STATS
func set_stats() -> void:
	# TODO: update level and experience
	# TODO: update entity_types
	# set base stats
	set_base_stats()

	# update base stats from nexus nodes
	for unlocked_node in unlocked_nodes:
		# TODO: currently uses Vector2 atlas locations
		var nexus_type: int = 1 # TODO: Global.nexus_types[unlocked_node]
		match nexus_type:
			1: # Health
				base_health += Global.nexus_qualities[unlocked_node]
			2: # Mana
				base_mana += Global.nexus_qualities[unlocked_node]
			3: # Defense
				base_defense += Global.nexus_qualities[unlocked_node]
			4: # Ward
				base_ward += Global.nexus_qualities[unlocked_node]
			5: # Strength
				base_strength += Global.nexus_qualities[unlocked_node]
			6: # Intelligence
				base_intelligence += Global.nexus_qualities[unlocked_node]
			7: # Speed
				base_speed += Global.nexus_qualities[unlocked_node]
			8: # Agility
				base_agility += Global.nexus_qualities[unlocked_node]
	
	# update base stamina
	base_stamina = 100.0

	# update base secondary stats
	base_weight = 1.0
	base_vision = 1.0

	# update max health, mana and stamina
	max_health = base_health
	max_mana = base_mana
	max_stamina = base_stamina

	# update basic stats
	defense = base_defense
	ward = base_ward
	strength = base_strength
	intelligence = base_intelligence
	speed = base_speed
	agility = base_agility
	crit_chance = base_crit_chance
	crit_damage = base_crit_damage

	# update secondary stats
	weight = base_weight
	vision = base_vision

	if weapon: weapon.set_stats(self)
	if headgear: headgear.set_stats(self)
	if chestpiece: chestpiece.set_stats(self)
	if leggings: leggings.set_stats(self)
	if accessory_1: accessory_1.set_stats(self)
	if accessory_2: accessory_2.set_stats(self)
	if accessory_3: accessory_3.set_stats(self)
	# TODO: update current stats based on effects
	# TODO: update 

	# update health, mana and stamina
	health = max_health
	mana = max_mana
	stamina = max_stamina

func set_base_stats() -> void:
	pass

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

# below from CharacterBase

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
	if ultimate_gauge == max_ultimate_gauge:
		base.action_queue.append([attack, [ultimate_attack, []]])
		return
	
	base.action_queue.append([attack, [basic_attack, []]])

func attack(attack_function: Callable, attack_arguments: Array) -> void:
	attack_function.callv(attack_arguments)

func _on_action_cooldown_timeout() -> void:
	if not base: return
	base.action_state = base.ActionState.READY

# ATTACKS

func basic_attack() -> void:
	if not base: return

	var attack_shape: Area2D = base.get_node(^"AttackShape")
	var animation_node: AnimatedSprite2D = base.get_node(^"AnimatedSprite2D")

	if base.is_main_player:
		base.attack_vector = (base.get_global_mouse_position() - base.position).normalized()
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
		dash_attack = true
	
	attack_shape.set_target_position(base.attack_vector * 20)

	base.action_state_timer = 0.5

	attack_shape.force_shapecast_update()
	
	await animation_node.frame_changed

	var temp_damage: float = basic_damage
	var enemy_body = null
	var knockback_weight = 1.0

	if dash_attack:
		temp_damage *= 1.5
		knockback_weight = 1.5
		dash_attack = false
	
	if attack_shape.is_colliding():
		for collision_index in attack_shape.get_collision_count():
			enemy_body = attack_shape.get_collider(collision_index).base # TODO: null instance bug need fix
			if Damage.combat_damage(temp_damage,
					Damage.DamageTypes.ENEMY_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
					self, enemy_body.enemy_stats_node):
				enemy_body.knockback(base.attack_vector, knockback_weight)
		Players.camera_node.screen_shake(0.1, 1, 30, 5, true)
	
	await animation_node.finished

func ultimate_attack():
	if not base: return

	var attack_shape: Area2D = base.get_node(^"AttackShape")
	var animation_node: AnimatedSprite2D = base.get_node(^"AnimatedSprite2D")
	
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
	
	attack_shape.set_target_position(base.attack_vector * 20)

	$AttackTimer.start(0.5)
	attack_shape.force_shapecast_update()

	await animation_node.frame_changed

	var temp_damage: float = ultimate_damage
	var enemy_body = null
	var knockback_weight = 2.0
	if dash_attack:
		temp_damage *= 1.5
		knockback_weight = 3.0
		dash_attack = false

	if attack_shape.is_colliding():
		for collision_index in attack_shape.get_collision_count():
			enemy_body = attack_shape.get_collider(collision_index).base
			if Damage.combat_damage(temp_damage,
					Damage.DamageTypes.ENEMY_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
					self, enemy_body.enemy_stats_node):
				enemy_body.knockback(base.attack_vector, knockback_weight)
		Players.camera_node.screen_shake(0.3, 10, 30, 100, true)

	await animation_node.finished
