extends Node

var players = [null, null, null, null]
var max_health = [200, 200, 200, 200]
var health = [200, 200, 200, 200]
var alive = [true, true, true, true]
var health_bar = [null, null, null, null]

var CombatUI

var health_bar_percentage = 1.0

func update_players():
	CombatUI = get_parent().get_child(2).get_node("CombatUI")
	players[0] = get_parent().get_child(2).get_node("Player")
	health_bar[0] = players[0].get_node("HealthBar")
	health_bar[0].max_value = max_health[0]

func health_bar_update(player):
	if health[player] >= max_health[player]:
		health_bar[player].visible = false
		health[player] = max_health[player]
	elif health[player] <= 0:
		health_bar[player].visible = false
		alive[player] = false
		health[player] = 0
		players[0].get_node("Animation").play("death")
		$DeathTimer.set_wait_time(0.5)
		$DeathTimer.start()
		players[0].set_physics_process(false)
		CombatUI.health_UI_update(0)
	else:
		health_bar[player].visible = true
		
		health_bar_percentage = health[player] * 1.0 / max_health[player]
		if health_bar_percentage > 0.5: health_bar[player].modulate = "a9ff30"
		elif health_bar_percentage > 0.1: health_bar[player].modulate = "c8a502"
		else: health_bar[player].modulate = "a93430"
	
	health_bar[player].value = health[player]

func take_damage(player, amount):
	if alive[player]:
		health[player] -= amount

func _on_natural_regeneration_timeout():
	for i in 4:
		if health[i] > 0&&health[i] < max_health[i]:
			health[i] += 5
			health_bar_update(0)

func _on_death_timer_timeout():
	players[0].get_node("Animation").pause()
