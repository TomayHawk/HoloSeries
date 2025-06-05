class_name EntityStats extends Resource

signal status_added(type: Entities.Status)
signal status_removed(type: Entities.Status)

# ................................................................................

var base: EntityBase = null

# STATS

var level: int = 1
var alive: bool = true
var entity_types: int = 0

# Health, Mana & Stamina
var max_health: float = 1.0
var base_health: float = 1.0
var health: float = 1.0
var max_mana: float = 1.0
var base_mana: float = 1.0
var mana: float = 1.0
var max_stamina: float = 1.0
var base_stamina: float = 1.0
var stamina: float = 1.0

# Ultimate & Shield
var max_ultimate_gauge: float = 0.0
var ultimate_gauge: float = 0.0
var max_shield: float = 0.0
var shield: float = 0.0

# Stats
var base_defense: float = 0.0
var defense: float = 0.0
var base_ward: float = 0.0
var ward: float = 0.0
var base_strength: float = 0.0
var strength: float = 0.0
var base_intelligence: float = 0.0
var intelligence: float = 0.0
var base_speed: float = 0.0
var speed: float = 0.0
var base_agility: float = 0.0
var agility: float = 0.0
var base_crit_chance: float = 0.0
var crit_chance: float = 0.0
var base_crit_damage: float = 0.0
var crit_damage: float = 0.0

# Additional Stats
var base_weight: float = 1.0
var weight: float = 1.0
var base_vision: float = 1.0
var vision: float = 1.0

# ................................................................................

# STATUS

var status: int = 0
var effects: Array[Resource] = []

func add_status(type: Entities.Status) -> Resource:
	var effect: Resource = Entities.effect_resources[type].new()
	effects.push_back(effect)
	if not has_status(type):
		emit_signal("status_added", type)
	status |= type
	if base:
		base.set_process(true)
	return effect

func attempt_remove_status(type: Entities.Status) -> void:
	for effect in effects:
		if effect.effect_type == type:
			return
	status &= ~type
	emit_signal("status_removed", type)
	if not status and base:
		base.set_process(false)

func force_remove_status(type: Entities.Status) -> void:
	for effect in effects.duplicate():
		if effect.effect_type == type:
			effects.erase(effect)
	status &= ~type
	emit_signal("status_removed", type)
	if not status and base:
		base.set_process(false)

func has_status(type: Entities.Status) -> bool:
	return status & type

func reset_status() -> void:
	status = 0
	effects.clear()
	if base:
		base.set_process(false)
