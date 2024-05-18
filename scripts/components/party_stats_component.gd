extends Node

var players = [null, null, null, null]
var max_health = [200, 200, 200, 200]
var health = [200, 200, 200, 200]
var max_stamina = [100, 100, 100, 100]
var stamina = [100, 100, 100, 100]
var alive = [true, true, true, true]
var health_bar = [null, null, null, null]
var stamina_bar = [null, null, null, null]

var CombatUI

var bar_percentage = 1.0
var stamina_slow_recovery = false

func _physics_process(_delta):
	for i in GlobalSettings.active_players:
		if stamina[i] < max_stamina[i]:
			if stamina_slow_recovery:
				stamina_bar_slow_update(i)
			else:
				stamina_bar_update(i)

func update_players_stats():
	CombatUI = get_parent().get_child(2).get_node("CombatUI")

	players[0] = get_parent().get_child(2).get_node_or_null("Player1")
	players[1] = get_parent().get_child(2).get_node_or_null("Player2")
	players[2] = get_parent().get_child(2).get_node_or_null("Player3")
	players[3] = get_parent().get_child(2).get_node_or_null("Player4")

	for i in GlobalSettings.active_players:
		# get and set players health bar to max_health
		health_bar[i] = players[i].get_node("HealthBar")
		health_bar[i].max_value = max_health[i]
		# get and set players stamina bar to max_stamina
		stamina_bar[i] = players[i].get_node("StaminaBar")
		stamina_bar[i].max_value = max_stamina[i]
		# hide stamina bar
		stamina_bar[i].visible = false

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
		bar_percentage = health[player] * 1.0 / max_health[player]
		if bar_percentage > 0.5: health_bar[player].modulate = "a9ff30"
		elif bar_percentage > 0.1: health_bar[player].modulate = "c8a502"
		else: health_bar[player].modulate = "a93430"
	
	health_bar[player].value = health[player]

func stamina_bar_update(player):
	if stamina[player] >= max_stamina[player]:
		stamina_bar[player].visible = false
		stamina[player] = max_stamina[player]
	elif stamina[player] <= 0:
		stamina[player] = 0
		stamina_slow_recovery = true
		stamina_bar[player].modulate = "a93430"
	else:
		stamina_bar[player].visible = true
		stamina[player] += 0.5
	stamina_bar[player].value = stamina[player]

func stamina_bar_slow_update(player):
	stamina[player] += 0.25
	if stamina[player] >= max_stamina[player]:
		stamina_bar[player].modulate = "c8a502"
		stamina_slow_recovery = false
	stamina_bar[player].value = stamina[player]

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
