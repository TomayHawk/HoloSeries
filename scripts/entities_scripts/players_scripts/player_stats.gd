class_name PlayerStats
extends EntityStats

#region CONSTANTS

const BASE_WALK_SPEED: float = 140.0
const BASE_DASH_MULTIPLIER: float = 8.0
const BASE_DASH_STAMINA: float = 36.0
const BASE_DASH_MIN_STAMINA: float = 28.0
const BASE_DASH_TIME: float = 0.2
const BASE_SPRINT_MULTIPLIER: float = 1.25
const BASE_SPRINT_STAMINA: float = 24.0 # per second
const BASE_ATTACK_MOVEMENT_REDUCTION: float = 0.3

const BASE_MANA_REGEN: float = 0.25
const BASE_STAMINA_REGEN: float = 16.0
const BASE_FATIGUE_REGEN: float = 10.0

#endregion

# ..............................................................................

#region VARIABLES

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
var experience: int = 0
var next_level_requirement: int = 400

# ultimate variables
var ultimate_gauge: float = 0.0
var max_ultimate_gauge: float = 100.0

# movement variables
var walk_speed: float = BASE_WALK_SPEED
var dash_multiplier: float = BASE_DASH_MULTIPLIER
var dash_stamina: float = BASE_DASH_STAMINA
var dash_min_stamina: float = BASE_DASH_MIN_STAMINA
var dash_time: float = BASE_DASH_TIME
var sprint_multiplier: float = BASE_SPRINT_MULTIPLIER
var sprint_stamina: float = BASE_SPRINT_STAMINA # per second
var attack_movement_reduction: float = BASE_ATTACK_MOVEMENT_REDUCTION
var fatigue: bool = false

# regeneration variables
var mana_regen: float = BASE_MANA_REGEN
var stamina_regen: float = BASE_STAMINA_REGEN
var fatigue_regen: float = BASE_FATIGUE_REGEN

# party variables
var last_action_cooldown: float = 0.0

# nexus variables
var last_node: int = -1
var unlocked_nodes: Array[int] = []
var converted_nodes: Array[Vector2i] = [] # (index, type)

#endregion

# ..............................................................................

#region PROCESS

func stats_process(process_interval: float) -> void:
	# regenerate mana
	if mana < max_mana:
		update_mana(mana_regen * process_interval)

	# update stamina
	if base.move_state == base.MoveState.SPRINT:
		update_stamina(-sprint_stamina * process_interval)
	elif base.move_state != base.MoveState.DASH and stamina < max_stamina:
		update_stamina((fatigue_regen if fatigue else stamina_regen) * process_interval)

	# decrease effects timers
	for effect in effects.duplicate():
		effect.effect_timer -= process_interval
		if effect.effect_timer <= 0.0:
			effect.effect_timeout(self)

#endregion

# ..............................................................................

#region STATS UPDATES

func update_health(value: float) -> void:
	super (value)
	if base: base.update_health()

func update_mana(value: float) -> void:
	super (value)
	if base: base.update_mana()

func update_stamina(value: float) -> void:
	super (value)

	# handle fatigue
	if stamina == 0:
		fatigue = true
	elif stamina == max_stamina:
		fatigue = false

	if base: base.update_stamina()

func update_shield(value: float) -> void:
	super (value)
	if base: base.update_shield()

func update_ultimate_gauge(value: float) -> void:
	if not alive: return
	ultimate_gauge = clamp(ultimate_gauge + value, 0, max_ultimate_gauge)
	if base: base.update_ultimate_gauge()

func update_experience(value: int) -> void:
	experience += value
	# check level up requirements
	while experience >= next_level_requirement:
		experience -= next_level_requirement
		level_up()
	
func level_up() -> void:
	level = clamp(level + 1, 1, 300) # cap level at 300
	next_level_requirement = get_xp_requirement()

func get_xp_requirement() -> int:
	if level < 5: return 400 + (level - 1) * 125
	if level < 10: return 775 + (level - 5) * 150
	if level < 20: return 1525 + (level - 10) * 225
	if level < 40: return 3775 + (level - 20) * 350
	if level < 70: return 10775 + (level - 40) * 500
	if level < 100: return 25775 + (level - 70) * 700
	if level < 150: return 46775 + (level - 100) * 1000
	if level < 200: return 96775 + (level - 150) * 1500
	if level < 250: return 171775 + (level - 200) * 2200
	if level < 300: return 281775 + (level - 250) * 3000
	else: return 9223372036854775807 # effectively infinite

#endregion

# ..............................................................................

#region SET STATS

func set_stats() -> void:
	# TODO: update level and experience
	# TODO: update entity_types
	# set base stats
	set_base_stats()

	# update base stats from nexus nodes
	for unlocked_node in unlocked_nodes:
		# TODO: currently uses Vector2 atlas locations
		var nexus_type: int = Global.nexus_types[unlocked_node]
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
	
	# clamp base stats
	base_health = clamp(base_health, 1.0, 99999.0)
	base_mana = clamp(base_mana, 1.0, 9999.0)
	base_defense = clamp(base_defense, 0.0, 1000.0)
	base_ward = clamp(base_ward, 0.0, 1000.0)
	base_strength = clamp(base_strength, 0.0, 1000.0)
	base_intelligence = clamp(base_intelligence, 0.0, 1000.0)
	base_speed = clamp(base_speed, 0.0, 255.0)
	base_agility = clamp(base_agility, 0.0, 255.0)

	# update base stamina
	base_stamina = BASE_STAMINA

	# update base secondary stats
	base_weight = 1.0
	base_vision = 1.0

	# update base crit stats
	base_crit_chance = BASE_CRIT_CHANCE # 5% crit chance
	base_crit_damage = BASE_CRIT_DAMAGE # 50% crit damage

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

	# update health, mana and stamina
	health = max_health
	mana = max_mana
	stamina = max_stamina

	walk_speed = BASE_WALK_SPEED + (speed / 2.0) # max 268.0 speed
	dash_multiplier = BASE_DASH_MULTIPLIER + (speed / 128.0) # max 10.0 multiplier
	dash_stamina = BASE_DASH_STAMINA - (agility / 32.0) # min 28.0 stamina per dash
	dash_min_stamina = BASE_DASH_MIN_STAMINA - (agility / 32.0) # min 20.0 stamina per dash
	
	dash_time = BASE_DASH_TIME - (agility / 2560.0) # min 0.1s dash time
	sprint_multiplier = BASE_SPRINT_MULTIPLIER + (speed / 1280.0) # max 1.45 multiplier
	sprint_stamina = BASE_SPRINT_STAMINA - (agility / 64.0) # min 20.0 stamina per second
	attack_movement_reduction = BASE_ATTACK_MOVEMENT_REDUCTION + (agility / 512.0) # min 0.8 attack movement reduction

	mana_regen = BASE_MANA_REGEN + (mana / 10000.0) # max 1.25 mana per second
	stamina_regen = BASE_STAMINA_REGEN + (stamina / 25.0) # max 40.0 stamina per second
	fatigue_regen = BASE_FATIGUE_REGEN + (stamina / 50.0) # max 25.0 stamina per second

	if weapon: weapon.update_variable_stats(self)
	if headgear: headgear.update_variable_stats(self)
	if chestpiece: chestpiece.update_variable_stats(self)
	if leggings: leggings.update_variable_stats(self)
	if accessory_1: accessory_1.update_variable_stats(self)
	if accessory_2: accessory_2.update_variable_stats(self)
	if accessory_3: accessory_3.update_variable_stats(self)

	# TODO: update current stats based on effects

	# TODO: update max_shield based on stats

func set_base_stats() -> void:
	pass

#endregion

# ..............................................................................

#region DEATH

func death() -> void:
	fatigue = false
	super ()

#endregion

# ..............................................................................
