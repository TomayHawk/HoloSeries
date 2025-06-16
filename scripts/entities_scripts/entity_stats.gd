class_name EntityStats extends Resource

# CONSTANTS

const BASE_HEALTH: float = 200.0
const BASE_MANA: float = 10.0
const BASE_STAMINA: float = 100.0

const BASE_DEFENSE: float = 10.0
const BASE_WARD: float = 10.0
const BASE_STRENGTH: float = 10.0
const BASE_INTELLIGENCE: float = 10.0
const BASE_SPEED: float = 0.0
const BASE_AGILITY: float = 0.0
const BASE_CRIT_CHANCE: float = 0.05
const BASE_CRIT_DAMAGE: float = 1.50

# ..............................................................................

var base: EntityBase = null

# STATS

var level: int = 1
var alive: bool = true
var entity_types: int = 0

# Health, Mana and Stamina
var health: float = BASE_HEALTH
var mana: float = BASE_MANA
var stamina: float = BASE_STAMINA

# Basic Stats
var defense: float = BASE_DEFENSE
var ward: float = BASE_WARD
var strength: float = BASE_STRENGTH
var intelligence: float = BASE_INTELLIGENCE
var speed: float = BASE_SPEED
var agility: float = BASE_AGILITY
var crit_chance: float = BASE_CRIT_CHANCE
var crit_damage: float = BASE_CRIT_DAMAGE

# Secondary Stats
var weight: float = 1.0
var vision: float = 1.0

# Max Health, Mana and Stamina
var max_health: float = BASE_HEALTH
var max_mana: float = BASE_MANA
var max_stamina: float = BASE_STAMINA

# Base Health, Mana and Stamina
var base_health: float = BASE_HEALTH
var base_mana: float = BASE_MANA
var base_stamina: float = BASE_STAMINA

# Base Basic Stats
var base_defense: float = BASE_DEFENSE
var base_ward: float = BASE_WARD
var base_strength: float = BASE_STRENGTH
var base_intelligence: float = BASE_INTELLIGENCE
var base_speed: float = BASE_SPEED
var base_agility: float = BASE_AGILITY
var base_crit_chance: float = BASE_CRIT_CHANCE
var base_crit_damage: float = BASE_CRIT_DAMAGE

# Base Secondary Stats
var base_weight: float = 1.0
var base_vision: float = 1.0

# Shield
var shield: float = 0.0
var max_shield: float = 200.0

# ..............................................................................

# STATS UPDATES

func update_health(value: float) -> void:
	# check if alive and not invincible
	if not alive or (value < 0.0 and has_status(Entities.Status.INVINCIBLE)):
		return

	# update health
	health = clamp(health + value, 0.0, max_health)

	# add invincibility if damage dealt
	if value < 0.0:
		add_status(Entities.Status.INVINCIBLE)

	# handle death
	if health == 0.0:
		death()

func update_mana(value: float) -> void:
	if not alive: return
	mana = clamp(mana + value, 0.0, max_mana)

func update_stamina(value: float) -> void:
	if not alive: return
	stamina = clamp(stamina + value, 0.0, max_stamina)

func update_shield(value: float) -> void:
	if not alive: return
	shield = clamp(shield + value, 0.0, max_shield)

# ..............................................................................

# DEATH & REVIVE

func death() -> void:
	# decrease effects timers
	for effect in effects.duplicate():
		if effect.remove_on_death:
			effect.remove_effect(self)
	
	alive = false
	stamina = max_stamina
	if base: base.death()

func revive(value: float) -> void:
	alive = true
	update_health(value)

# ..............................................................................

# STATUS

var status: int = 0
var effects: Array[Resource] = []

func add_status(type: Entities.Status) -> Resource:
	var effect: Resource = Entities.effect_resources[type].new()
	effects.push_back(effect)
	status |= type
	return effect

func attempt_remove_status(type: Entities.Status) -> void:
	for effect in effects:
		if effect.effect_type == type:
			return
	status &= ~type

func force_remove_status(type: Entities.Status) -> void:
	for effect in effects.duplicate():
		if effect.effect_type == type:
			effect.remove_effect(self)
	status &= ~type

func has_status(type: Entities.Status) -> bool:
	return status & type

func reset_status() -> void:
	effects.clear()
	status = 0
