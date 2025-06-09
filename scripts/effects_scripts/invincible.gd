extends Resource

var effect_type: Entities.Status = Entities.Status.INVINCIBLE
var effect_timer: float = 0.1
var remove_on_death: bool = true

func effect_timeout(stats_node: EntityStats) -> void:
	stats_node.effects.erase(self)
	stats_node.attempt_remove_status(Entities.Status.INVINCIBLE)

func owner_death(stats_node: EntityStats) -> void:
	stats_node.effects.erase(self)
	stats_node.attempt_remove_status(Entities.Status.INVINCIBLE)
