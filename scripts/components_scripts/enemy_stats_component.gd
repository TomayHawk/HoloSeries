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

# deal damage to enemy (called by enemy)
func update_health(source_position, knockback_weight, amount):
	# no damage if currently taking knockback
	if enemy_node.taking_knockback: amount = 0
	enemy_node.taking_knockback = true
	health += amount
	
	# if max or min health, hide health bar
	health = clamp(health, 0, max_health)
	health_bar_node.visible = health != max_health

	if health == 0:
		enemy_node.dying = true
		GlobalSettings.enemy_nodes_in_combat.erase(enemy_node)
		if GlobalSettings.locked_enemy_node == self: GlobalSettings.locked_enemy_node = null
		if GlobalSettings.enemy_nodes_in_combat.is_empty(): GlobalSettings.attempt_leave_combat()
	# if health in range
	else:
		# health bar color depending on health percentages
		health_bar_percentage = health * 1.0 / max_health
		if health_bar_percentage > 0.5: health_bar_node.modulate = "a9ff30"
		elif health_bar_percentage > 0.1: health_bar_node.modulate = "c8a502"
		else: health_bar_node.modulate = "a93430"
	
	# update health bar
	health_bar_node.value = health

	enemy_node.player_direction = (source_position - enemy_node.position).normalized()
	enemy_node.knockback_weight = knockback_weight
	enemy_node.get_node("KnockbackTimer").start(0.4)