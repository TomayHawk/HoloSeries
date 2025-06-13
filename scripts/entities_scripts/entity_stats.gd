class_name EntityStats extends Resource

var base: EntityBase = null

# STATS

var level: int = 1
var alive: bool = true
var entity_types: int = 0

# Health, Mana and Stamina
var health: float = 200.0
var mana: float = 10.0
var stamina: float = 100.0

# Basic Stats
var defense: float = 10.0
var ward: float = 10.0
var strength: float = 10.0
var intelligence: float = 10.0
var speed: float = 0.0
var agility: float = 0.0
var crit_chance: float = 0.05
var crit_damage: float = 0.50

# Secondary Stats
var weight: float = 1.0
var vision: float = 1.0

# Max Health, Mana and Stamina
var max_health: float = 200.0
var max_mana: float = 10.0
var max_stamina: float = 100.0

# Base Health, Mana and Stamina
var base_health: float = 200.0
var base_mana: float = 10.0
var base_stamina: float = 100.0

# Base Basic Stats
var base_defense: float = 10.0
var base_ward: float = 10.0
var base_strength: float = 10.0
var base_intelligence: float = 10.0
var base_speed: float = 0.0
var base_agility: float = 0.0
var base_crit_chance: float = 0.05
var base_crit_damage: float = 0.50

# Base Secondary Stats
var base_weight: float = 1.0
var base_vision: float = 1.0

# Shield
var shield: float = 100.0

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
	shield += value

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
