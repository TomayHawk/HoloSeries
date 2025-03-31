class_name PlayerStats extends EntityStats

var party_index: int = -1
var stamina_slow_recovery: bool = false

# combat variables
var auto_ultimate: bool = true # TODO: add more settings
var base_melee_range: float = 20.0
var melee_range: float = 20.0
var base_throwable_range: float = 40.0
var throwable_range: float = 40.0
var base_projectile_range: float = 60.0
var projectile_range: float = 60.0
var base_spell_range: float = 80.0
var spell_range: float = 80.0

func _ready() -> void:
	play(&"down_idle")

func _physics_process(_delta: float) -> void:
	# regenerate mana
	if mana != max_mana:
		update_mana(0.004)

	# regenerate stamina
	if stamina != max_stamina:
		update_stamina(0.25 if stamina_slow_recovery else 0.5)
	
	if mana == max_mana and stamina == max_stamina:
		set_physics_process(false)

func update_nodes() -> void:
	position = Vector2.ZERO

	if get_parent() is CharacterBody2D:
		name = &"CharacterBase"
		get_parent().character_node = self
		get_parent().set_attack_state(get_parent().AttackState.READY)
		get_parent().update_velocity(Vector2.ZERO)
	else:
		party_index = -1

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

	if get_parent() is PlayerBase:
		get_parent().walk_speed = 140 + speed * 0.5
		get_parent().dash_stamina = 35 - (agility * 0.0625)
		get_parent().sprint_stamina = 0.8 - (agility * 0.00048828125)
		get_parent().dash_time = 0.2 * (1 - (agility * 0.001953125)) # minimum 0.1s dash time
		# TODO: get_parent().ally_speed = 60 + (30 * speed)
		# get_parent().dash_speed = 300 + (150 * speed)

		# update stats
		party_index = get_parent().get_index()
		update_health(0.0)
		update_mana(0)
		update_stamina(0)
		Combat.ui.ultimate_progress_bar_nodes[party_index].max_value = max_ultimate_gauge
		Combat.ui.shield_progress_bar_nodes[party_index].max_value = max_shield

func update_health(value: float) -> void:
	if not alive or (value < 0 and has_status(Entities.Status.INVINCIBLE)):
		return

	# update health
	health = clamp(health + value, 0.0, max_health)

	# update health bar & ui health label & knockback
	if get_parent() is PlayerBase:
		get_parent().update_health_bar(health, max_health)
		Combat.ui.update_health_label(party_index, health)

	# add invincibility if damage dealt
	if value < 0:
		add_status(Entities.Status.INVINCIBLE)

	# handle death
	if health == 0.0:
		trigger_death()

func update_mana(value: float) -> void:
	if not alive: return
	
	# update mana
	mana = clamp(mana + value, 0.0, max_mana)
	
	# update mana bar
	if get_parent() is PlayerBase:
		get_parent().update_mana_bar(mana, max_mana)
		Combat.ui.update_mana_label(party_index, mana)

	if mana < max_mana: set_physics_process(true)

func update_stamina(value: float) -> void:
	if not alive: return
	
	# update stamina
	stamina = clamp(stamina + value, 0.0, max_stamina)
	
	# update stamina bar
	if get_parent() is PlayerBase:
		get_parent().update_stamina_bar(stamina, max_stamina)

	# handle recovery
	if stamina == 0:
		stamina_slow_recovery = true
		if get_parent().move_state == get_parent().MoveState.DASH or get_parent().move_state == get_parent().MoveState.SPRINT:
			get_parent().set_move_state(get_parent().MoveState.WALK)
	elif stamina == max_stamina:
		stamina_slow_recovery = false

	if stamina < max_stamina:
		set_physics_process(true)

func update_ultimate_gauge(value: float) -> void:
	if not alive: return

	# update ultimate gauge
	ultimate_gauge = clamp(ultimate_gauge + value, 0, max_ultimate_gauge)
	
	# update ultimate gauge bar
	if get_parent() is PlayerBase:
		Combat.ui.ultimate_progress_bar_nodes[party_index].value = ultimate_gauge
		Combat.ui.ultimate_progress_bar_nodes[party_index].modulate.g = (130.0 - ultimate_gauge) / max_ultimate_gauge

func update_shield(value: float) -> void:
	if not alive: return
	
	# update shield
	shield = clamp(shield + value, 0, max_shield)

	# update shield bar
	if get_parent() is PlayerBase:
		get_parent().update_shield_bar(shield, max_shield)
		Combat.ui.shield_progress_bar_nodes[party_index].value = shield

func trigger_death() -> void:
	alive = false
	stamina = max_stamina

	if get_parent() is PlayerBase:
		get_parent().set_attack_state(get_parent().AttackState.READY) # TODO
		get_parent().trigger_death()
	
	get_node(^"AttackTimer").stop() # TODO
	
	# TODO: avoid choose_animation() triggers
	# TODO: get_parent().ally_direction_timer_node.stop()
	# TODO: get_parent().ally_direction_ready = true
	# TODO: get_parent().attacking = false

func revive(value: float = 0) -> void: # TODO: doesn't need default value
	alive = true
	update_health(value)
	play("up_idle")

	if get_parent() is PlayerBase:
		get_parent().set_physics_process(true)
		get_parent().update_health_bar(health, max_health)
		get_parent().update_mana_bar(mana, max_mana)
		get_parent().update_stamina_bar(stamina, max_stamina)
		Combat.ui.update_health_label(party_index, health)
		Combat.ui.update_mana_label(party_index, mana)
