extends Node

# node variables
@onready var player_node = get_parent()
@onready var combat_ui_node = GlobalSettings.combat_ui_node

@onready var health_bar_node = player_node.get_node("HealthBar")
@onready var mana_bar_node = player_node.get_node("ManaBar")
@onready var stamina_bar_node = player_node.get_node("StaminaBar")

@onready var knockback_timer = player_node.get_node("KnockbackTimer")

# player variables
var party_index = 0
var character_index = 0
var alive = true
var stamina_slow_recovery = false

# stats variables
var max_health = 100
var max_mana = 100
var max_stamina = 100

var health = 100
var mana = 100
var stamina = 100

var defence = 0
var shield = 0
var strength = 0
var intellegence = 0
var speed = 0
var agility = 0

# temporary variables
var temp_bar_percentage = 1.0

func _ready():
	update_stats()

	update_health(99999, [], Vector2.ZERO, 0.0)
	update_mana(9999)
	update_stamina(999)

func _physics_process(_delta):
	# regenerate mana
	if mana != max_mana:
		update_mana(0.004)

	# regenerate stamina
	if stamina != max_stamina:
		if stamina_slow_recovery:
			update_stamina(0.25)
		else:
			update_stamina(0.5)

func update_stats():
	party_index = player_node.party_index
	character_index = player_node.party_index # #### temporary

	# set max stats
	max_health = GlobalSettings.default_max_health[character_index]
	max_mana = GlobalSettings.default_max_mana[character_index]
	max_stamina = GlobalSettings.default_max_stamina[character_index]

	# set stats bars max values
	health_bar_node.max_value = max_health
	mana_bar_node.max_value = max_mana
	stamina_bar_node.max_value = max_stamina

	# update stats
	update_health(0, [], Vector2.ZERO, 0.0)
	update_mana(0)
	update_stamina(0)

func update_health(amount, types, knockback_direction, knockback_weight):
	if alive:
		# normal combat damage handling
		if types.has("normal_combat_damage"):
			amount += (amount * (0.7 - (((defence - 1000) * (defence - 1000)) * 1.0 / 1425000))) + (defence * 1.0 / 3)
			amount = clamp(amount, -99999, -1)

		# set limit
		if types.has("break_limit"):
			amount = clamp(amount, -99999, 99999)
		else:
			amount = clamp(amount, -9999, 9999)

		# update health bar
		health = clamp(health + amount, 0, max_health)
		health_bar_node.value = health
		health_bar_node.visible = health > 0&&health < max_health
		combat_ui_node.update_health_label(party_index, health)

		# knockback handling
		if knockback_direction != Vector2.ZERO:
			player_node.taking_knockback = true
			player_node.knockback_direction = knockback_direction
			player_node.knockback_weight = knockback_weight
			knockback_timer.start(0.4)

		# check death
		if health == 0:
			trigger_death()
		else:
			# determine health bar modulation based on percentage
			temp_bar_percentage = health * 1.0 / max_health
			if temp_bar_percentage > 0.5: health_bar_node.modulate = Color(0, 1, 0, 1)
			elif temp_bar_percentage > 0.2: health_bar_node.modulate = Color(1, 1, 0, 1)
			else: health_bar_node.modulate = Color(1, 0, 0, 1)

func update_mana(amount):
	if alive:
		# update mana bar
		mana = clamp(mana + amount, 0, max_mana)
		mana_bar_node.value = mana
		mana_bar_node.visible = mana < max_mana
		combat_ui_node.update_mana_label(party_index, mana)

func update_stamina(amount):
	if alive:
		# update stamina bar
		stamina = clamp(stamina + amount, 0, max_stamina)
		stamina_bar_node.value = stamina
		stamina_bar_node.visible = stamina < max_stamina

		# deal with slow recovery
		if stamina == 0:
			stamina_slow_recovery = true
			stamina_bar_node.modulate = Color(0.5, 0, 0, 1)
		elif stamina == max_stamina:
			stamina_slow_recovery = false
			stamina_bar_node.modulate = Color(1, 0.5, 0, 1)

func trigger_death():
	# stop player process
	player_node.set_physics_process(false)

	# groups
	player_node.remove_from_group("alive")

	# start death animation
	alive = false
	player_node.animation_node.set_speed_scale(1.0)
	player_node.animation_node.play("death")
	player_node.death_timer_node.start(0.5)

	# reset stamina
	stamina = max_stamina

	# hide all stats bars
	health_bar_node.visible = false
	mana_bar_node.visible = false
	stamina_bar_node.visible = false

	# avoid choose_animation() triggers
	player_node.attack_cooldown_node.stop()
	player_node.ally_direction_cooldown_node.stop()
	
	# update main player if the player is main player
	if player_node == GlobalSettings.current_main_player_node:
		for party_player_node in GlobalSettings.party_player_nodes:
			if party_player_node.player_stats_node.alive:
				GlobalSettings.update_main_player(party_player_node)

func revive():
	alive = true
	player_node.reset_variables()
	player_node.add_to_group("alive")
	player_node.set_physics_process(true)