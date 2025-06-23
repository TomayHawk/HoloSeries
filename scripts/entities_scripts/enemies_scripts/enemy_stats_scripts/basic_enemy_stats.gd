class_name BasicEnemyStats
extends EnemyStats

# ..............................................................................

# PROCESS

func stats_process(process_interval: float) -> void:
	# decrease effects timers
	for effect in effects.duplicate():
		effect.effect_timer -= process_interval
		if effect.effect_timer <= 0.0:
			effect.effect_timeout(self)

# ..............................................................................

# STATS UPDATES

func update_health(value: float) -> void:
	super (value)
	if base: base.update_health()

func update_shield(value: float) -> void:
	super (value)
	if base: base.update_shield()

# ..............................................................................

# SET STATS

# TODO
func set_stats() -> void:
	pass
