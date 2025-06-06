class_name EntityStats extends Resource

var base: EntityBase = null

# STATS

var level: int = 1
var alive: bool = true
var entity_types: int = 0

# Health, Mana, Stamina and Shield
var max_health: float = 100.0
var max_mana: float = 100.0
var max_stamina: float = 100.0
var max_shield: float = 100.0

var health: float = 100.0
var mana: float = 100.0
var stamina: float = 100.0
var shield: float = 100.0

# Basic Stats
var defense: float = 10.0
var ward: float = 10.0
var strength: float = 10.0
var intelligence: float = 10.0
var speed: float = 10.0
var agility: float = 10.0
var crit_chance: float = 10.0
var crit_damage: float = 10.0

# Secondary Stats
var weight: float = 1.0
var vision: float = 1.0

# ................................................................................

# STATUS

var status: int = 0
var effects: Array[Resource] = []

func add_status(type: Entities.Status) -> Resource:
	var effect: Resource = Entities.effect_resources[type].new()
	effects.push_back(effect)
	status |= type
	if base:
		base.set_process(true)
	return effect

func attempt_remove_status(type: Entities.Status) -> void:
	for effect in effects:
		if effect.effect_type == type:
			return
	status &= ~type
	if not status and base:
		base.set_process(false)

func force_remove_status(type: Entities.Status) -> void:
	for effect in effects.duplicate():
		if effect.effect_type == type:
			effect.effect_timeout(self)
			effects.erase(effect)
	status &= ~type
	if not status and base:
		base.set_process(false)

func has_status(type: Entities.Status) -> bool:
	return status & type

func reset_status() -> void:
	status = 0
	effects.clear()
	if base:
		base.set_process(false)
