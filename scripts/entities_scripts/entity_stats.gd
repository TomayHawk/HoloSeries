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

# ..............................................................................

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

# ..............................................................................

# METHODS

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
	
	# update mana
	mana = clamp(mana + value, 0.0, max_mana)

func update_stamina(value: float) -> void:
	if not alive: return
	
	# update stamina
	stamina = clamp(stamina + value, 0.0, max_stamina)

# ..............................................................................

# DEATH & REVIVE

func death() -> void:
	# decrease effects timers
	for effect in effects.duplicate():
		if effect.remove_on_death:
			effect.owner_death(self)
	
	alive = false
	stamina = max_stamina

	if base:
		base.trigger_death()

func revive(value: float) -> void:
	alive = true
	update_health(value)
	
	# TODO: update_mana(0.0)
	# TODO: update_stamina(0.0)
