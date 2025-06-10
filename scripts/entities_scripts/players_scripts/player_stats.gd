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

# combat variables
var auto_ultimate: bool = true # TODO: add more settings
var melee_range: float = 20.0
var throwable_range: float = 40.0
var projectile_range: float = 60.0
var spell_range: float = 80.0

# ultimate variables
var max_ultimate_gauge: float = 0.0
var ultimate_gauge: float = 0.0

# nexus variables
var last_node: int = -1
var unlocked_nodes: Array[int] = []
var converted_nodes: Array[Array] = []

# ..............................................................................

# STATS UPDATES

func update_health(value: float) -> void:
	super (value)

	# update health bar & ui health label
	if base:
		base.update_health_bar(health)
		Combat.ui.health_labels[node_index].text = str(int(health))

func update_mana(value: float) -> void:
	super (value)
	
	# update mana bar & ui mana label
	if base:
		base.update_mana_bar(mana)
		Combat.ui.mana_labels[node_index].text = str(int(mana))

func update_stamina(value: float) -> void:
	super (value)
	
	# update stamina bar
	if base:
		base.update_stamina_bar(stamina, max_stamina)

	# handle recovery
	if stamina == 0:
		fatigue = true
		if base.move_state in [base.MoveState.DASH, base.MoveState.SPRINT]:
			base.move_state = base.MoveState.WALK
			base.update_animation()
	elif stamina == max_stamina:
		fatigue = false

func update_ultimate_gauge(value: float) -> void:
	if not alive: return

	# update ultimate gauge
	ultimate_gauge = clamp(ultimate_gauge + value, 0, max_ultimate_gauge)
	
	# update ultimate gauge bar
	if base:
		Combat.ui.ultimate_progress_bars[node_index].value = ultimate_gauge
		Combat.ui.ultimate_progress_bars[node_index].max_value = max_ultimate_gauge
		Combat.ui.ultimate_progress_bars[node_index].modulate.g = (130.0 - ultimate_gauge) / max_ultimate_gauge

func update_shield(value: float) -> void:
	if not alive: return
	
	# update shield
	shield = clamp(shield + value, 0, max_shield)

	# update shield bar
	if base:
		base.update_shield_bar(shield, max_shield)
		Combat.ui.shield_progress_bars[node_index].value = shield
		Combat.ui.shield_progress_bars[node_index].max_value = max_shield

# ..............................................................................

# DEATH & REVIVE

func death() -> void:
	super ()

	if base:
		pass
		#base.set_attack_state(base.ActionState.READY) # TODO: reset variables
	
	#get_node(^"AttackTimer").stop() # TODO
	
	# TODO: avoid choose_animation() triggers
	# TODO: base.ally_direction_timer_node.stop()
	# TODO: base.ally_direction_ready = true
	# TODO: base.attacking = false

func revive(value: float) -> void:
	super (value)
	# TODO
	# update variables
	#update_ultimate_gauge(0.0)
	#update_shield(0.0)
	#play(&"down_idle")
