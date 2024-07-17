extends Node

# node variables
@onready var player_node := get_parent()
@onready var character_specifics_node := player_node.get_node("CharacterSpecifics")

@onready var combat_ui_node := GlobalSettings.combat_ui_node

@onready var health_bar_node := player_node.get_node("HealthBar")
@onready var mana_bar_node := player_node.get_node("ManaBar")
@onready var stamina_bar_node := player_node.get_node("StaminaBar")

@onready var knockback_timer := player_node.get_node("KnockbackTimer")

# player variables
var party_index := 0
var alive := true
var stamina_slow_recovery := false

# stats variables
var level := 1

var max_health := 200.0
var max_mana := 10.0
var max_stamina := 100.0

var health := 200.0
var mana := 10.0
var stamina := 100.0

var defence := 10.0
var shield := 10.0
var strength := 10.0
var intelligence := 10.0
var speed := 0.0
var agility := 0.0
var crit_chance := 0.05
var crit_damage := 0.50

var weapon_strength := 0.0
var attack_multiplier := 1.0

# temporary variables
var temp_bar_percentage := 1.0

func _ready():
	update_stats()

	update_health(99999, ["break_limit"], Vector2.ZERO, 0.0)
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
	var i = 0
	for party_player_node in GlobalSettings.party_player_nodes:
		if player_node == party_player_node:
			party_index = i
			break
		i += 1

	# set max stats
	max_health = character_specifics_node.default_max_health
	max_mana = character_specifics_node.default_max_mana
	max_stamina = character_specifics_node.default_max_stamina

	# set stats bars max values
	health_bar_node.max_value = max_health
	mana_bar_node.max_value = max_mana
	stamina_bar_node.max_value = max_stamina

	# update stats
	update_health(0, [], Vector2.ZERO, 0.0)
	update_mana(0)
	update_stamina(0)

	level = character_specifics_node.default_level
	defence = character_specifics_node.default_defence
	shield = character_specifics_node.default_shield
	strength = character_specifics_node.default_strength
	intelligence = character_specifics_node.default_intelligence
	speed = character_specifics_node.default_speed
	agility = character_specifics_node.default_agility
	crit_chance = character_specifics_node.default_crit_chance
	crit_damage = character_specifics_node.default_crit_damage

	player_node.speed = 2000 + (50 * speed)
	player_node.ally_speed = 6000 + (30 * speed)
	player_node.dash_speed = 30000 + (150 * speed)

	player_node.dash_stamina_consumption = 35 - (agility * 0.0625)
	player_node.sprinting_stamina_consumption = 0.8 - (agility * 0.00048828125)

	player_node.dash_time = 0.2 * (1 - (agility * 0.000625))

func update_health(value, types, knockback_direction, knockback_weight):
	if alive:
		# normal combat damage handling
		if types.has("normal_combat_damage"):
			value += (value * (0.7 - (((defence - 1000) * (defence - 1000)) * 1.0 / 1425000))) + (defence * 1.0 / 3)
			value = clamp(value, -99999, 0)

		# set limit
		if types.has("break_limit"):
			value = clamp(value, -99999, 99999)
		else:
			value = clamp(value, -9999, 9999)

		# update health bar
		health = clamp(health + value, 0, max_health)
		health_bar_node.value = health
		health_bar_node.visible = health > 0&&health < max_health
		combat_ui_node.update_health_label(party_index, health)

		if value < 0:
			CombatEntitiesComponent.damage_display(floor(value), player_node.position + Vector2(0, -7), ["player_damage"])
		elif value > 0:
			CombatEntitiesComponent.damage_display(floor(value), player_node.position + Vector2(0, -7), ["heal"])

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

func update_mana(value):
	if alive:
		# update mana bar
		mana = clamp(mana + value, 0, max_mana)
		mana_bar_node.value = mana
		mana_bar_node.visible = mana < max_mana
		combat_ui_node.update_mana_label(party_index, mana)

func update_stamina(value):
	if alive:
		# update stamina bar
		stamina = clamp(stamina + value, 0, max_stamina)
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
	player_node.add_to_group("alive")
	player_node.set_physics_process(true)
