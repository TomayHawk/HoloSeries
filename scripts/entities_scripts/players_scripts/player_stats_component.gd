extends Node2D

# node variables
@onready var player_node := get_parent()
@onready var character_specifics_node := get_parent().get_node("CharacterSpecifics")
@onready var attack_timer_node := get_parent().get_node("AttackTimer")

@onready var CombatUi = GlobalSettings.CombatUi

@onready var health_bar_node := %HealthBar
@onready var shield_bar_node := %ShieldBar
@onready var mana_bar_node := %ManaBar
@onready var stamina_bar_node := %StaminaBar

@onready var knockback_timer_node := get_parent().get_node("KnockbackTimer")

@onready var combat_ui_ultimate_bar_node: Node = CombatUi.ultimate_progress_bar_nodes[0]
@onready var combat_ui_shield_bar_node: Node = CombatUi.shield_progress_bar_nodes[0]

# player variables
var party_index := -1
var alive := true
var stamina_slow_recovery := false

# stats variables
var level := 1 # max 999

var max_health := 200.0 # max 99999
var max_mana := 10.0 # max 9999
var max_stamina := 100.0 # max 500
var max_ultimate_gauge := 100 # max 100
var max_shield := 100 # max 100

var health := 200.0 # max 99999
var mana := 10.0 # max 9999
var stamina := 100.0 # max 500
var ultimate_gauge := 0 # max 100
var shield := 0 # max 100

var defence := 10.0 # max 1000
var ward := 10.0 # max 1000
var strength := 10.0 # max 1000
var intelligence := 10.0 # max 1000
var speed := 0.0 # max 256
var agility := 0.0 # max 256
var crit_chance := 0.05 # max INF
var crit_damage := 0.50 # max INF

var weapon_strength := 0.0 # max INF
var attack_multiplier := 1.0 # max INF

# temporary variables
var temp_bar_percentage := 1.0

func _ready():
	update_stats()

	update_health(99999, ["hidden", "break_limit"], Vector2.ZERO, 0.0)
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
	
	if mana == max_mana and stamina == max_stamina:
		set_physics_process(false)

func update_nodes():
	player_node = get_parent()
	character_specifics_node = player_node.get_node("CharacterSpecifics")
	knockback_timer_node = player_node.get_node("KnockbackTimer")
	position = Vector2.ZERO

func update_stats():
	##### not necessary?
	player_node = get_parent()
	
	# set max stats
	max_health = character_specifics_node.default_max_health + GlobalSettings.nexus_stats[character_specifics_node.character_index][0]
	max_mana = character_specifics_node.default_max_mana + GlobalSettings.nexus_stats[character_specifics_node.character_index][1]
	max_stamina = character_specifics_node.default_max_stamina

	# set stats bars max values
	health_bar_node.max_value = max_health
	mana_bar_node.max_value = max_mana
	stamina_bar_node.max_value = max_stamina
	shield_bar_node.max_value = max_shield

	level = character_specifics_node.default_level
	defence = character_specifics_node.default_defence + GlobalSettings.nexus_stats[character_specifics_node.character_index][2]
	ward = character_specifics_node.default_ward + GlobalSettings.nexus_stats[character_specifics_node.character_index][3]
	strength = character_specifics_node.default_strength + GlobalSettings.nexus_stats[character_specifics_node.character_index][4]
	intelligence = character_specifics_node.default_intelligence + GlobalSettings.nexus_stats[character_specifics_node.character_index][5]
	speed = character_specifics_node.default_speed + GlobalSettings.nexus_stats[character_specifics_node.character_index][6]
	agility = character_specifics_node.default_agility + GlobalSettings.nexus_stats[character_specifics_node.character_index][7]
	crit_chance = character_specifics_node.default_crit_chance
	crit_damage = character_specifics_node.default_crit_damage

	player_node.walk_speed = 7000 + (50 * speed)
	##### player_node.ally_speed = 6000 + (30 * speed)
	# player_node.dash_speed = 30000 + (150 * speed)

	player_node.dash_stamina_consumption = 35 - (agility * 0.0625)
	player_node.sprinting_stamina_consumption = 0.8 - (agility * 0.00048828125)

	player_node.dash_time = 0.2 * (1 - (agility * 0.000625))

	# update stats
	if player_node in GlobalSettings.party_node.get_children():
		party_index = player_node.get_index()
		update_health(0, ["hidden"], Vector2.ZERO, 0.0)
		update_mana(0)
		update_stamina(0)
		combat_ui_ultimate_bar_node = CombatUi.ultimate_progress_bar_nodes[party_index]
		combat_ui_shield_bar_node = CombatUi.shield_progress_bar_nodes[party_index]
		combat_ui_ultimate_bar_node.max_value = max_ultimate_gauge
		combat_ui_shield_bar_node.max_value = max_shield

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
		health_bar_node.visible = health > 0 and health < max_health
		CombatUi.update_health_label(party_index, health)

		if value < 0:
			CombatEntitiesComponent.damage_display(floor(value), player_node.position + Vector2(0, -7), types + ["player_damage"])
		elif value > 0:
			CombatEntitiesComponent.damage_display(floor(value), player_node.position + Vector2(0, -7), types + ["heal"])

		# knockback handling
		if knockback_direction != Vector2.ZERO:
			player_node.current_move_state = player_node.MoveState.KNOCKBACK
			player_node.knockback_direction = knockback_direction
			player_node.knockback_weight = knockback_weight
			knockback_timer_node.start(0.4)

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
		CombatUi.update_mana_label(party_index, mana)

		if mana < max_mana: set_physics_process(true)

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
			player_node.current_move_state = player_node.MoveState.WALK
		elif stamina == max_stamina:
			stamina_slow_recovery = false
			stamina_bar_node.modulate = Color(1, 0.5, 0, 1)
		
		if stamina < max_stamina: set_physics_process(true)

func update_ultimate_gauge(value):
	if alive:
		ultimate_gauge = clamp(ultimate_gauge + value, 0, max_ultimate_gauge)
		combat_ui_ultimate_bar_node.value = ultimate_gauge

		combat_ui_ultimate_bar_node.modulate.g = (130.0 - ultimate_gauge) / max_ultimate_gauge

func update_shield(value):
	if alive:
		shield = clamp(shield + value, 0, max_shield)
		combat_ui_shield_bar_node.value = shield
		shield_bar_node.value = shield

func trigger_death():
	# stop player process
	player_node.set_physics_process(false)

	# groups
	player_node.remove_from_group("players_alive")
	player_node.add_to_group("players_dead")

	# start death animation
	alive = false
	player_node.animation_node.play("death")
	player_node.death_timer_node.start(0.5)

	# reset stamina
	stamina = max_stamina

	# hide all stats bars
	health_bar_node.visible = false
	mana_bar_node.visible = false
	stamina_bar_node.visible = false

	# avoid choose_animation() triggers
	attack_timer_node.stop()
	##### player_node.ally_direction_timer_node.stop()
	##### player_node.ally_direction_ready = true
	##### player_node.attacking = false
	player_node.current_attack_state = player_node.AttackState.READY
	
	# update main player if the player is main player
	if player_node == GlobalSettings.current_main_player_node:
		for party_player_node in GlobalSettings.party_node.get_children():
			if party_player_node.player_stats_node.alive:
				GlobalSettings.update_main_player(party_player_node)

func revive():
	update_health(0, ["hidden"], Vector2.ZERO, 0.0)
	update_mana(0)
	update_stamina(0)

	player_node.remove_from_group("players_dead")
	player_node.add_to_group("players_alive")
	
	player_node.set_physics_process(true)
	player_node.animation_node.play("up_idle")
	
	alive = true
