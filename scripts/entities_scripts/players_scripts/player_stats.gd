class_name PlayerStats extends EntityStats

var node_index: int = -1

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

# ultimate variables
var max_ultimate_gauge: float = 0.0
var ultimate_gauge: float = 0.0

# combat variables
var auto_ultimate: bool = true # TODO: add more settings
var melee_range: float = 20.0
var throwable_range: float = 40.0
var projectile_range: float = 60.0
var spell_range: float = 80.0

# nexus variables
var last_node: int = -1
var unlocked_nodes: Array[int] = []
var converted_nodes: Array[Array] = []

func reset_stats() -> void:
	update_stats() # TODO

func update_stats():
	max_health = base_health
	health = base_health
	max_mana = base_mana
	mana = base_mana
	max_stamina = base_stamina
	stamina = base_stamina

	# Ultimate & Shield
	max_ultimate_gauge = 100.0
	max_shield = 100.0

	# Stats
	defense = base_defense
	ward = base_ward
	strength = base_strength
	intelligence = base_intelligence
	speed = base_speed
	agility = base_agility
	crit_chance = base_crit_chance
	crit_damage = base_crit_damage

	# Additional Stats
	base_weight = 1.0
	weight = 1.0
	base_vision = 1.0
	vision = 1.0

	update_health(0.0)
	update_mana(0.0)
	update_stamina(0.0)
	update_ultimate_gauge(0.0)
	update_shield(0.0)

func update_health(value: float) -> void:
	if not alive or (value < 0 and has_status(Entities.Status.INVINCIBLE)):
		return

	# update health
	health = clamp(health + value, 0.0, max_health)

	# update health bar & ui health label & knockback
	if base is PlayerBase:
		base.update_health_bar(health, max_health)
		Combat.ui.health_labels[node_index].text = str(int(health))

	# add invincibility if damage dealt
	if value < 0.0:
		add_status(Entities.Status.INVINCIBLE)

	# handle death
	if health == 0.0:
		trigger_death()

func update_mana(value: float) -> void:
	if not alive: return
	
	# update mana
	mana = clamp(mana + value, 0.0, max_mana)
	
	# update mana bar
	if base is PlayerBase:
		base.update_mana_bar(mana, max_mana)
		Combat.ui.mana_labels[node_index].text = str(int(mana))

	if mana < max_mana: set_physics_process(true)

func update_stamina(value: float) -> void:
	if not alive: return
	
	# update stamina
	stamina = clamp(stamina + value, 0.0, max_stamina)
	
	# update stamina bar
	if base is PlayerBase:
		base.update_stamina_bar(stamina, max_stamina)

	# handle recovery
	if stamina == 0:
		fatigue = true
		if base.move_state == base.MoveState.DASH or base.move_state == base.MoveState.SPRINT:
			base.set_move_state(base.MoveState.WALK)
	elif stamina == max_stamina:
		fatigue = false

	if stamina < max_stamina:
		set_physics_process(true)

func update_ultimate_gauge(value: float) -> void:
	if not alive: return

	# update ultimate gauge
	ultimate_gauge = clamp(ultimate_gauge + value, 0, max_ultimate_gauge)
	
	# update ultimate gauge bar
	if base is PlayerBase:
		Combat.ui.ultimate_progress_bars[node_index].value = ultimate_gauge
		Combat.ui.ultimate_progress_bars[node_index].max_value = max_ultimate_gauge
		Combat.ui.ultimate_progress_bars[node_index].modulate.g = (130.0 - ultimate_gauge) / max_ultimate_gauge

func update_shield(value: float) -> void:
	if not alive: return
	
	# update shield
	shield = clamp(shield + value, 0, max_shield)

	# update shield bar
	if base is PlayerBase:
		base.update_shield_bar(shield, max_shield)
		Combat.ui.shield_progress_bars[node_index].value = shield
		Combat.ui.shield_progress_bars[node_index].max_value = max_shield

func trigger_death() -> void:
	alive = false
	stamina = max_stamina

	if base is PlayerBase:
		base.set_attack_state(base.AttackState.READY) # TODO
		base.trigger_death()
	
	get_node(^"AttackTimer").stop() # TODO
	
	# TODO: avoid choose_animation() triggers
	# TODO: base.ally_direction_timer_node.stop()
	# TODO: base.ally_direction_ready = true
	# TODO: base.attacking = false

func revive(value: float) -> void: # TODO: doesn't need default value
	alive = true
	update_health(value)
	update_stats()
	play(&"down_idle")
