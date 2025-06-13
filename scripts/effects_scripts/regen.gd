extends Resource

var effect_type: Entities.Status = Entities.Status.REGEN
var effect_timer: float = 5.0
var remove_on_death: bool = true

var damage_types: int = \
		Damage.DamageTypes.PLAYER_HIT \
		| Damage.DamageTypes.HEAL \
		| Damage.DamageTypes.MAGIC \
		| Damage.DamageTypes.NO_CRITICAL \
		| Damage.DamageTypes.NO_MISS

var origin_stats_node: EntityStats = null

# Healing settings
var heal_interval: float = 5.0
var heal_amount: float = 10.0
var count: int = 7
var min_rand: float = 0.95
var max_rand: float = 1.05

func regen_settings(types: int, stats_node: EntityStats, amount: float, set_timer: float, set_count: int, set_min: float = 0.95, set_max: float = 1.05) -> void:
	damage_types = types
	origin_stats_node = stats_node
	effect_timer = set_timer
	heal_interval = set_timer
	heal_amount = amount
	count = set_count
	min_rand = set_min
	max_rand = set_max

func effect_timeout(stats_node: EntityStats) -> void:
	Damage.combat_damage(heal_amount * randf_range(min_rand, max_rand), damage_types, origin_stats_node, stats_node)
	count -= 1
	if count == 0:
		stats_node.effects.erase(self)
		stats_node.attempt_remove_status(Entities.Status.REGEN)
	else:
		effect_timer = heal_interval

func remove_effect(stats_node: EntityStats) -> void:
	stats_node.effects.erase(self)
	stats_node.attempt_remove_status(Entities.Status.REGEN)
