extends Node

# enemy node
@onready var enemy_node = get_parent()
@onready var health_bar_node = enemy_node.get_node("HealthBar")

# health variables
var max_health = 100
var health = 100
var health_bar_percentage = 1.0

# knockback status
var knockback = false

# called upon instantiating (creating) each enemy
func ready():
	health_bar_node.max_value = max_health

func health_bar_update():
	# if max or min health, hide health bar
	clamp(health, 0, max_health)
	health_bar_node.visible = health != max_health

	if health == 0:
		enemy_node.dying = true
	# if health in range
	else:
		# health bar color depending on health percentages
		health_bar_percentage = health * 1.0 / max_health
		if health_bar_percentage > 0.5: health_bar_node.modulate = "a9ff30"
		elif health_bar_percentage > 0.1: health_bar_node.modulate = "c8a502"
		else: health_bar_node.modulate = "a93430"
	
	# update health bar
	health_bar_node.value = health

# deal damage to enemy (called by enemy)
func update_health(amount):
	# no damage if currently taking knockback
	if enemy_node.taking_knockback: amount = 0
	enemy_node.taking_knockback = true
	health += amount
	health_bar_update()
