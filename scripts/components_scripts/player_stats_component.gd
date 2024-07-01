extends Node2D

# node variables
@onready var player_node = get_parent()
@onready var combat_ui_node = GlobalSettings.combat_ui_node
@onready var health_bar_node = player_node.get_node("HealthBar")
@onready var mana_bar_node = player_node.get_node("ManaBar")
@onready var stamina_bar_node = player_node.get_node("StaminaBar")
@onready var death_timer_node = player_node.get_node("DeathTimer")

# player variables
var player_index = player_node.player_index
var stamina_slow_recovery = false
var temp_bar_percentage = 1.0
var alive = true

# health variables
var max_health = GlobalSettings.default_max_health[player_index]
var health = max_health

# mana variables
var max_mana = GlobalSettings.default_max_mana[player_index]
var mana = max_mana

# stamina variables
var max_stamina = GlobalSettings.default_max_stamina[player_index]
var stamina = max_stamina

# recover stamina every physics frame
func _physics_process(_delta):
	if stamina == max_stamina: stamina_bar_node.visible = false
	else: update_stamina_bar()

func update_health_bar():
	clamp(health, 0, max_health)
	health_bar_node.visible = health > 0&&health < max_health
	combat_ui_node.health_ui_update(player_index)
	health_bar_node.value = health

	if health == 0:
		alive = false
		death_timer_node.set_wait_time(0.5)
		death_timer_node.start()
		
		player_node.animation_node.play("death")
		player_node.set_physics_process(false)

		stamina = max_stamina
		stamina_bar_node.visible = false
		
		if GlobalSettings.current_main_player_index == player_index:
			for temp_player_node in GlobalSettings.party_player_nodes:
				if temp_player_node.player_stats_component.alive&&temp_player_node.player_index != player_index:
					GlobalSettings.update_main_player(temp_player_node.player_index)
	else:
		temp_bar_percentage = health * 1.0 / max_health
		if temp_bar_percentage > 0.5: health_bar_node.modulate = Color(0, 1, 0, 1)
		elif temp_bar_percentage > 0.1: health_bar_node.modulate = Color(1, 1, 0, 1)
		else: health_bar_node.modulate = Color(1, 0, 0, 1)

func update_mana_bar():
	mana += 0.5
	clamp(mana, 0, max_stamina)
	mana_bar_node.value = mana

func update_stamina_bar():
	clamp(stamina, 0, max_stamina)
	health_bar_node.visible = stamina < max_stamina
	if stamina == 0:
		stamina_slow_recovery = true
		stamina_bar_node.modulate = Color(1, 0.5, 0, 1)
	else:
		if stamina_slow_recovery:
			stamina += 0.25
			if stamina >= max_stamina:
				stamina_slow_recovery = false
				stamina_bar_node.modulate = Color(0.5, 0, 0, 1)
		else:
			stamina += 0.5
	
	stamina_bar_node.value = stamina

func take_damage(amount):
	if alive: health -= amount
	update_health_bar()

func update_health(amount):
	if alive:
		health += amount
		update_health_bar()