extends Node

# players information
var active_players = 0
var players = [null, null, null, null]
var alive = [true, true, true, true]

# health information
var max_health = [200, 200, 200, 200]
var health = [200, 200, 200, 200]
var health_bar = [null, null, null, null]

# stamina information
var max_stamina = [100, 100, 100, 100]
var stamina = [100, 100, 100, 100]
var stamina_bar = [null, null, null, null]
var stamina_slow_recovery = [false, false, false, false]

var bar_percentage = 1.0

var combat_UI_node

# death update
@onready var death_timers = [$DeathTimer1, $DeathTimer2, $DeathTimer3, $DeathTimer4]
var dying = []

# recover stamina every physics frame
func _physics_process(_delta):
	for i in active_players:
		if stamina[i] == max_stamina[i]:stamina_bar[i].visible = false
		else: update_stamina_bar(i)

# update variables (called by GlobalSettings)
func update_nodes():
	for i in 4: players[i] = GlobalSettings.players[i]
	active_players = GlobalSettings.active_players

	for i in active_players:
		health_bar[i] = players[i].get_node("HealthBar")
		health_bar[i].max_value = max_health[i]

		stamina_bar[i] = players[i].get_node("StaminaBar")
		stamina_bar[i].max_value = max_stamina[i]

		stamina_bar[i].visible = false

func update_health_bar(player):
	if health[player] >= max_health[player]:
		health_bar[player].visible = false
		health[player] = max_health[player]
	elif health[player] <= 0:
		health_bar[player].visible = false
		health[player] = 0
		alive[player] = false

		for i in 4:
			if death_timers[i].is_stopped():
				death_timers[i].set_wait_time(0.5)
				death_timers[i].start()
				break
		
		dying.push_back(player)
		
		players[player].set_physics_process(false)
		players[player].get_node("Animation").play("death")

		stamina[player] = max_stamina[player]
		stamina_bar[player].visible = false

		combat_UI_node.health_UI_update(player)
		
		if GlobalSettings.current_main_player == player:
			for i in 4:
				if players[i] != null&&alive[i]&&GlobalSettings.current_main_player != i:
					GlobalSettings.update_main_player(i)
					break
	else:
		health_bar[player].visible = true
		bar_percentage = health[player] * 1.0 / max_health[player]
		if bar_percentage > 0.5: health_bar[player].modulate = "a9ff30"
		elif bar_percentage > 0.1: health_bar[player].modulate = "c8a502"
		else: health_bar[player].modulate = "a93430"
	
	health_bar[player].value = health[player]

func update_stamina_bar(player):
	if stamina[player] > max_stamina[player]:
		stamina_bar[player].visible = false
		stamina[player] = max_stamina[player]
	elif stamina[player] < 0:
		stamina_bar[player].visible = true
		stamina[player] = 0

		stamina_slow_recovery[player] = true
		stamina_bar[player].modulate = "a93430"
	else:
		stamina_bar[player].visible = true
		if stamina_slow_recovery[player]:
			stamina[player] += 0.25
			if stamina[player] >= max_stamina[player]:stamina_slow_recovery[player] = false
		else:
			stamina[player] += 0.5
	
	stamina_bar[player].value = stamina[player]

func take_damage(player, amount):
	if alive[player]:health[player] -= amount

# recover health every 5.0 seconds
func _on_natural_regeneration_timeout():
	for i in active_players:
		if alive[i]&&health[i] < max_health[i]:
			health[i] += 5
			update_health_bar(i)

# death animation time
func _on_death_timer_timeout():
	players[dying.pop_front()].get_node("Animation").pause()
