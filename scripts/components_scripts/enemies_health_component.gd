extends Node

# enemy node
var enemy = null

# health variables
var max_health = 100
var health = 100
var health_bar = null
var health_bar_percentage = 1.0

# knockback status
var knockback = false

# called upon instantiating (creating) each enemy
func create_enemy():
	enemy = get_parent()
	health_bar = enemy.get_node("HealthBar")
	health_bar.max_value = max_health

func health_bar_update():
	# if max or min health, hide health bar
	if health >= max_health:
		health_bar.visible = false
		health = max_health
	elif health <= 0:
		health_bar.visible = false
		health = 0
		enemy.dying = true
	# if health in range
	else:
		# show health bar
		health_bar.visible = true

		# health bar color depending on health percentages
		health_bar_percentage = health * 1.0 / max_health
		if health_bar_percentage > 0.5: health_bar.modulate = "a9ff30"
		elif health_bar_percentage > 0.1: health_bar.modulate = "c8a502"
		else: health_bar.modulate = "a93430"
	
	# update health bar
	health_bar.value = health

# deal damage to enemy (called by enemy)
func deal_damage(amount):
	# no damage if currently taking knockback
	if enemy.taking_knockback: amount = 0
	enemy.taking_knockback = true
	health -= amount
	health_bar_update()