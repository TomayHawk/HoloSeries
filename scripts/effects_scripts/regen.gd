extends Resource

var effect_type: Entities.Status = Entities.Status.REGEN
var effect_timer: float = 5.0

var damage_types: int = \
		Damage.DamageTypes.PLAYER_HIT \
		| Damage.DamageTypes.HEAL \
		| Damage.DamageTypes.MAGIC \
		| Damage.DamageTypes.NO_CRITICAL \
		| Damage.DamageTypes.NO_MISS

var origin_stats_node: EntityStats = null
var heal_amount: float = 10.0
var count: int = 7
var min_rand: float = 0.95
var max_rand: float = 1.05

func regen_settings(types: int, stats_node: EntityStats, amount: float, set_timer: float, set_count: int, set_min: float = 0.95, set_max: float = 1.05) -> void:
	damage_types = types
	origin_stats_node = stats_node
	effect_timer = set_timer
	heal_amount = amount
	count = set_count
	min_rand = set_min
	max_rand = set_max

func effect_timeout(stats_node: EntityStats, status_index: int) -> void:
	Damage.combat_damage(heal_amount * randf_range(min_rand, max_rand), damage_types, origin_stats_node, stats_node)
	count -= 1
	if count == 0:
		stats_node.effects.remove_at(status_index)
		stats_node.effects_timers.remove_at(status_index)
		stats_node.attempt_remove_status(Entities.Status.REGEN)
	else:
		stats_node.effects_timers[status_index] = effect_timer
