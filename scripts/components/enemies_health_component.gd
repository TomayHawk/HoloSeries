extends Node

var enemy_node = null
var max_health = 100
var health = 100
var health_bar = null
var knockback = false

var health_bar_percentage = 1.0

func create_enemy():
	enemy_node = get_parent()
	health_bar = enemy_node.get_node("HealthBar")
	health_bar.max_value = max_health

func health_bar_update():
	if health >= max_health:
		health_bar.visible = false
		health = max_health
	elif health <= 0:
		health_bar.visible = false
		enemy_node.dying = true
		health = 0
	else:
		health_bar.visible = true
		
		health_bar_percentage = health * 1.0 / max_health
		if health_bar_percentage > 0.5: health_bar.modulate = "a9ff30"
		elif health_bar_percentage > 0.1: health_bar.modulate = "c8a502"
		else: health_bar.modulate = "a93430"
	
	health_bar.value = health

func deal_damage(amount):
	if enemy_node.taking_knockback: amount = 0
	enemy_node.taking_knockback = true
	health -= amount
	health_bar_update()