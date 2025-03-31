extends Resource

var effect_type: Entities.Status = Entities.Status.INVINCIBLE
var effect_timer: float = 0.1

func effect_timeout(stats_node: EntityStats, status_index: int) -> void:
	stats_node.effects.remove_at(status_index)
	stats_node.effects_timers.remove_at(status_index)
	stats_node.attempt_remove_status(Entities.Status.INVINCIBLE)
