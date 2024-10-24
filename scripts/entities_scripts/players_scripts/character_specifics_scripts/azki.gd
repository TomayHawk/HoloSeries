extends Node2D

const character_name := "AZKi"
const character_index := 1
# default stats (Score: 4.265) + 5% Crit Rate
# buffer-skills
const default_level := 1
const default_max_health := 373 # +173 (+0.865 T1)
const default_max_mana := 40 # +30 (+3 T1)
const default_max_stamina := 100
const default_defence := 8 # -2 (-0.2 T1)
const default_ward := 6 # -4 (-0.8 T1)
const default_strength := 9 # -1 (-0.2 T1)
const default_intelligence := 12 # +2 (+0.4 T1)
const default_speed := 2 # +2 (+2 T1)
const default_agility := 2 # +2 (+2 T1)
const default_crit_chance := 0.10 # +0.05 Crit Rate
const default_crit_damage := 0.50

const default_unlocked_nexus_nodes: Array[int] = [139, 154, 170]

const regular_attack_damage := 13
var temp_regular_attack_damage := 13.0

var dash_attack := false

##### move attack nodes to character specifics
@onready var player_node = get_parent()
@onready var player_stats_node = get_parent().get_node_or_null("PlayerStatsComponent")
@onready var attack_shape_node = get_parent().get_node_or_null("AttackShape")
@onready var attack_timer_node = get_parent().get_node_or_null("AttackTimer")
@onready var ally_attack_cooldown_node = get_parent().get_node_or_null("PlayerAlly/AllyAttackCooldown")

func update_nodes():
	player_node = get_parent()
	player_stats_node = get_parent().get_node_or_null("PlayerStatsComponent")
	attack_shape_node = get_parent().get_node_or_null("AttackShape")
	attack_timer_node = get_parent().get_node_or_null("AttackTimer")
	ally_attack_cooldown_node = get_parent().get_node_or_null("PlayerAlly/AllyAttackCooldown")
	position = Vector2.ZERO

func regular_attack():
	if player_stats_node.ultimate_gauge == player_stats_node.max_ultimate_gauge:
		ultimate_attack()
		return

	if player_node.is_current_main_player: player_node.attack_direction = (get_global_mouse_position() - player_node.position).normalized()
	else:
		var temp_enemy_health = INF
		for enemy_node in player_node.enemy_nodes_in_attack_area:
			if enemy_node.base_enemy_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.base_enemy_node.health
				player_node.attack_direction = (enemy_node.position - player_node.position).normalized()
		player_node.ally_can_attack = false
		ally_attack_cooldown_node.start(randf_range(2, 3))

	if player_node.current_move_state == player_node.MoveState.DASH:
		dash_attack = true
	
	attack_shape_node.set_target_position(player_node.attack_direction * 20)

	attack_timer_node.start(0.5)

	player_node.attack_register = "regular_attack_register"
	attack_shape_node.force_shapecast_update()

func regular_attack_register():
	var enemy_body = null
	var knockback_weight = 1.0

	if dash_attack:
		temp_regular_attack_damage = regular_attack_damage * 1.5
		knockback_weight = 1.5
		dash_attack = false
	else:
		temp_regular_attack_damage = regular_attack_damage

	if attack_shape_node.is_colliding():
		for collision_index in attack_shape_node.get_collision_count():
			enemy_body = attack_shape_node.get_collider(collision_index).get_parent()
			var damage = CombatEntitiesComponent.physical_damage_calculator(temp_regular_attack_damage, player_stats_node, enemy_body.base_enemy_node)
			enemy_body.base_enemy_node.update_health(-damage[0], damage[1], player_node.attack_direction, knockback_weight)
		GlobalSettings.camera_node.screen_shake(0.1, 1, 30, 5, true)

	player_node.attack_register = ""

func ultimate_attack():
	player_stats_node.update_ultimate_gauge(-100)

	if player_node.is_current_main_player: player_node.attack_direction = (get_global_mouse_position() - player_node.position).normalized()
	else:
		var temp_enemy_health = INF
		for enemy_node in player_node.enemy_nodes_in_attack_area:
			if enemy_node.base_enemy_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.base_enemy_node.health
				player_node.attack_direction = (enemy_node.position - player_node.position).normalized()
		player_node.ally_can_attack = false
		ally_attack_cooldown_node.start(randf_range(2, 3))
	
	if player_node.current_move_state == player_node.MoveState.DASH:
		dash_attack = true
	
	attack_shape_node.set_target_position(player_node.attack_direction * 20)

	attack_timer_node.start(0.5)

	player_node.attack_register = "ultimate_attack_register"
	attack_shape_node.force_shapecast_update()

func ultimate_attack_register():
	var enemy_body = null
	var knockback_weight = 2.0
	if dash_attack:
		temp_regular_attack_damage = regular_attack_damage * 15
		knockback_weight = 3.0
		dash_attack = false
	else:
		temp_regular_attack_damage = regular_attack_damage * 10

	if attack_shape_node.is_colliding():
		for collision_index in attack_shape_node.get_collision_count():
			enemy_body = attack_shape_node.get_collider(collision_index).get_parent()
			var damage = CombatEntitiesComponent.physical_damage_calculator(temp_regular_attack_damage, player_stats_node, enemy_body.base_enemy_node)
			enemy_body.base_enemy_node.update_health(-damage[0], damage[1], player_node.attack_direction, knockback_weight)
		GlobalSettings.camera_node.screen_shake(0.3, 10, 30, 100, true)

	player_node.attack_register = ""
