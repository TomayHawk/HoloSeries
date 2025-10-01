class_name PlayerStats
extends EntityStats

# ..............................................................................

#region CONSTANTS

const BASE_MOVE_SPEED: float = 140.0

const BASE_DASH_MULTIPLIER: float = 8.0
const BASE_DASH_STAMINA: float = 36.0
const BASE_DASH_MIN_STAMINA: float = 28.0
const BASE_DASH_TIME: float = 0.2

const BASE_SPRINT_MULTIPLIER: float = 1.25
const BASE_SPRINT_STAMINA: float = 24.0 # per second

# regeneration
const BASE_MANA_REGEN: float = 0.25
const BASE_STAMINA_REGEN: float = 16.0
const BASE_FATIGUE_REGEN: float = 10.0

#endregion

# ..............................................................................

#region VARIABLES

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
var move_speed: float = BASE_MOVE_SPEED
var move_speed_modifier: float = 1.0

var dash_multiplier: float = BASE_DASH_MULTIPLIER
var dash_stamina: float = BASE_DASH_STAMINA
var dash_min_stamina: float = BASE_DASH_MIN_STAMINA
var dash_time: float = BASE_DASH_TIME

var sprint_multiplier: float = BASE_SPRINT_MULTIPLIER
var sprint_stamina: float = BASE_SPRINT_STAMINA # per second

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

	# nexus health, mana, defense, ward, strength, intelligence, speed, agility
	var nexus_stats: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	
	# accumulate all nexus stats
	for unlocked_node in unlocked_nodes:
		var nexus_type: int = Global.nexus_types[unlocked_node]
		if nexus_type > 0 and nexus_type <= 8:
			nexus_stats[nexus_type - 1] += Global.nexus_qualities[unlocked_node]
	
	# set base stats from character constants and apply nexus modifications with clamping
	base_health = clamp(self.CHARACTER_HEALTH + nexus_stats[0], 1.0, 99999.0)
	base_mana = clamp(self.CHARACTER_MANA + nexus_stats[1], 1.0, 9999.0)
	base_defense = clamp(self.CHARACTER_DEFENSE + nexus_stats[2], 0.0, 1000.0)
	base_ward = clamp(self.CHARACTER_WARD + nexus_stats[3], 0.0, 1000.0)
	base_strength = clamp(self.CHARACTER_STRENGTH + nexus_stats[4], 0.0, 1000.0)
	base_intelligence = clamp(self.CHARACTER_INTELLIGENCE + nexus_stats[5], 0.0, 1000.0)
	base_speed = clamp(self.CHARACTER_SPEED + nexus_stats[6], 0.0, 255.0)
	base_agility = clamp(self.CHARACTER_AGILITY + nexus_stats[7], 0.0, 255.0)

	# stamina
	base_stamina = self.CHARACTER_STAMINA

	# crit stats
	base_crit_chance = self.CHARACTER_CRIT_CHANCE # 5% crit chance
	base_crit_damage = self.CHARACTER_CRIT_DAMAGE # 50% crit damage

	# weight, vision
	base_weight = 1.0
	base_vision = 1.0

	# max health, mana, stamina
	max_health = base_health
	max_mana = base_mana
	max_stamina = base_stamina

	# current stats
	health = base_health
	mana = base_mana
	stamina = max_stamina

	defense = base_defense
	ward = base_ward
	strength = base_strength
	intelligence = base_intelligence
	speed = base_speed
	agility = base_agility
	crit_chance = base_crit_chance
	crit_damage = base_crit_damage

	weight = base_weight
	vision = base_vision	

	# TODO: to be updated

	if weapon: weapon.set_stats(self)
	if headgear: headgear.set_stats(self)
	if chestpiece: chestpiece.set_stats(self)
	if leggings: leggings.set_stats(self)
	if accessory_1: accessory_1.set_stats(self)
	if accessory_2: accessory_2.set_stats(self)
	if accessory_3: accessory_3.set_stats(self)

	move_speed = BASE_MOVE_SPEED + (speed / 2.0) # max 268.0 speed
	dash_multiplier = BASE_DASH_MULTIPLIER + (speed / 128.0) # max 10.0 multiplier
	dash_stamina = BASE_DASH_STAMINA - (agility / 32.0) # min 28.0 stamina per dash
	dash_min_stamina = BASE_DASH_MIN_STAMINA - (agility / 32.0) # min 20.0 stamina per dash
	
	dash_time = BASE_DASH_TIME - (agility / 2560.0) # min 0.1s dash time
	sprint_multiplier = BASE_SPRINT_MULTIPLIER + (speed / 1280.0) # max 1.45 multiplier
	sprint_stamina = BASE_SPRINT_STAMINA - (agility / 64.0) # min 20.0 stamina per second

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

#endregion

# ..............................................................................

#region DEATH

func death() -> void:
	fatigue = false
	super ()

#endregion

# ..............................................................................
