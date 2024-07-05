extends Node

# node variables
@onready var player_node = get_parent()
@onready var combat_ui_node = GlobalSettings.combat_ui_node
@onready var health_bar_node = player_node.get_node("HealthBar")
@onready var mana_bar_node = player_node.get_node("ManaBar")
@onready var stamina_bar_node = player_node.get_node("StaminaBar")
@onready var death_timer_node = player_node.get_node("DeathTimer")

# player variables
@onready var player_index = player_node.player_index
var stamina_slow_recovery = false
var temp_bar_percentage = 1.0
var alive = true

# health variables
@onready var max_health = GlobalSettings.default_max_health[player_index]
var health = 100

# mana variables
@onready var max_mana = GlobalSettings.default_max_mana[player_index]
var mana = 100

# stamina variables
@onready var max_stamina = GlobalSettings.default_max_stamina[player_index]
var stamina = 100

func _ready():
	health = max_health
	mana = max_mana
	stamina = max_stamina

	health_bar_node.max_value = max_health
	mana_bar_node.max_value = max_mana
	stamina_bar_node.max_value = max_stamina

	health_bar_node.value = health
	mana_bar_node.value = mana
	stamina_bar_node.value = stamina

# recover stamina every physics frame
func _physics_process(_delta):
	if stamina == max_stamina: stamina_bar_node.visible = false
	else: update_stamina_bar()
	
	update_mana_bar()

func update_stats():
	max_health = GlobalSettings.default_max_health[player_index]
	max_mana = GlobalSettings.default_max_mana[player_index]
	max_stamina = GlobalSettings.default_max_stamina[player_index]

	combat_ui_node.combat_ui_health_update(player_node)
	combat_ui_node.combat_ui_mana_update(player_node)

func update_health_bar():
	health = clamp(health, 0, max_health)
	health_bar_node.visible = health > 0&&health < max_health

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
	
	combat_ui_node.combat_ui_health_update(player_node)

func update_mana_bar():
	mana += 0.004
	mana = clamp(mana, 0, max_mana)
	mana_bar_node.value = mana
	combat_ui_node.combat_ui_mana_update(player_node)

func update_stamina_bar():
	if stamina_slow_recovery:
		stamina += 0.25
	elif stamina < max_stamina:
		stamina += 0.5

	stamina = clamp(stamina, 0, max_stamina)
	stamina_bar_node.visible = stamina < max_stamina

	if stamina == 0:
		stamina_slow_recovery = true
		stamina_bar_node.modulate = Color(0.5, 0, 0, 1)
	elif stamina == max_stamina:
		stamina_slow_recovery = false
		stamina_bar_node.modulate = Color(1, 0.5, 0, 1)
	
	stamina_bar_node.value = stamina

func update_health(amount):
	if alive:
		health += amount
		update_health_bar()

func update_mana(amount):
	if alive:
		mana += amount - 0.5
		update_mana_bar()
