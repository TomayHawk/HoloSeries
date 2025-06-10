class_name BasicEnemyStats extends EnemyStats

# ..............................................................................

func _ready() -> void:
	update_health(0.0)

# ..............................................................................

# HEALTH AND DEATH

func update_health(value: float) -> void:
	if not alive or (value < 0 and has_status(Entities.Status.INVINCIBLE)):
		return
	
	# update health
	health = clamp(health + value, 0.0, max_health)

	# update and modulate health bar
	$HealthBar.visible = health > 0.0 and health < max_health
	$HealthBar.max_value = max_health
	$HealthBar.value = health
	
	var health_bar_percentage = health / max_health
	$HealthBar.modulate = \
			"a9ff30" if health_bar_percentage > 0.5 \
			else "c8a502" if health_bar_percentage > 0.2 \
			else "a93430"

	# add invincibility if damage dealt
	if value < 0.0:
		add_status(Entities.Status.INVINCIBLE)

	# handle death
	if health == 0.0:
		trigger_death()

func trigger_death() -> void:
	alive = false
	play(&"death")
	enemy_node.trigger_death()
