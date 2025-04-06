class_name EntityStats extends AnimatedSprite2D

# ................................................................................

# STATS

var level: int = 1
var alive: bool = true

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
var effects_timers: Array[float] = []
var time_since_last_effect: float = 0.0

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	time_since_last_effect += delta
	if time_since_last_effect > 0.1:
		var effects_count: int = effects_timers.size()
		for i in effects_count:
			var index: int = effects_count - 1 - i
			effects_timers[index] -= time_since_last_effect
			if effects_timers[index] <= 0:
				effects[index].effect_timeout(self, index)
		time_since_last_effect = 0.0

func add_status(type: Entities.Status) -> Resource:
	var effect_resource: Resource = Entities.effect_resources[type].new()
	effects.push_back(effect_resource)
	effects_timers.push_back(effect_resource.effect_timer)
	status |= type
	set_process(true)
	return effect_resource

func attempt_remove_status(type: Entities.Status) -> void:
	for effect in effects:
		if effect.effect_type == type:
			return
	status &= ~type
	if status == 0:
		set_process(false)

func has_status(type: Entities.Status) -> bool:
	return status & type

func reset_status() -> void:
	status = 0
	effects.clear()
	effects_timers.clear()
	set_process(false)
