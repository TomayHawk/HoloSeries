extends Node2D

const character_name := "Himemori Luna"
const character_index := 4
# default stats (Score: 4.285)
# healer
const default_level := 1
const default_max_health := 377 # +177 (+0.885 T1)
const default_max_mana := 36 # +26 (+2.6 T1)
const default_max_stamina := 100
const default_defence := 3 # -7 (-1.6 T1)
const default_shield := 13 # +3 (+0.6 T1)
const default_strength := 4 # -6 (-0.8 T1)
const default_intelligence := 18 # +8 (+1.6 T1)
const default_speed := 1 # +1 (+1 T1)
const default_agility := 1 # +1 (+1 T1)
const default_crit_chance := 0.05
const default_crit_damage := 0.50

const default_unlocked_nexus_nodes: Array[int] = [100, 132, 147]

const regular_attack_damage := 13
var temp_regular_attack_damage := 13.0

##### move attack nodes to character specifics
@onready var player_node = get_parent()
@onready var player_stats_node = get_parent().get_node("PlayerStatsComponent")
@onready var attack_shape_node = get_parent().get_node("AttackShape")
@onready var attack_cooldown_node = get_parent().get_node("AttackCooldown")
@onready var ally_attack_cooldown_node = get_parent().get_node("AllyAttackCooldown")

func update_nodes():
	player_node = get_parent()
	player_stats_node = get_parent().get_node("PlayerStatsComponent")
	attack_shape_node = get_parent().get_node("AttackShape")
	attack_cooldown_node = get_parent().get_node("AttackCooldown")
	ally_attack_cooldown_node = get_parent().get_node("AllyAttackCooldown")
	position = Vector2.ZERO

func regular_attack():
	if player_stats_node.ultimate_gauge == player_stats_node.max_ultimate_gauge:
		ultimate_attack()
		return

	if player_node.is_current_main_player: player_node.attack_direction = (get_global_mouse_position() - player_node.position).normalized()
	else:
		var temp_enemy_health = INF
		for enemy_node in player_node.ally_enemy_nodes_in_attack_area:
			if enemy_node.base_enemy_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.base_enemy_node.health
				player_node.attack_direction = (enemy_node.position - player_node.position).normalized()
		player_node.ally_attack_ready = false
		ally_attack_cooldown_node.start(randf_range(2, 3))
	
	attack_shape_node.set_target_position(player_node.attack_direction * 20)

	attack_cooldown_node.start(0.5)

	player_node.attack_register = "regular_attack_register"
	attack_shape_node.force_shapecast_update()

func regular_attack_register():
	var enemy_body = null

	if attack_shape_node.is_colliding():
		for collision_index in attack_shape_node.get_collision_count():
			enemy_body = attack_shape_node.get_collider(collision_index).get_parent()
			var knockback_weight = 1.0
			if player_node.dashing:
				temp_regular_attack_damage = regular_attack_damage * 1.5
				knockback_weight = 1.5
			else:
				temp_regular_attack_damage = regular_attack_damage
			var damage = CombatEntitiesComponent.physical_damage_calculator(temp_regular_attack_damage, player_stats_node, enemy_body.base_enemy_node)
			enemy_body.base_enemy_node.update_health(-damage[0], damage[1], player_node.attack_direction, knockback_weight)
		GlobalSettings.camera_node.screen_shake(0.1, 1, 30, 5, true)

	player_node.attack_register = ""

func ultimate_attack():
	player_stats_node.update_ultimate_gauge(-100)

	if player_node.is_current_main_player: player_node.attack_direction = (get_global_mouse_position() - player_node.position).normalized()
	else:
		var temp_enemy_health = INF
		for enemy_node in player_node.ally_enemy_nodes_in_attack_area:
			if enemy_node.base_enemy_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.base_enemy_node.health
				player_node.attack_direction = (enemy_node.position - player_node.position).normalized()
		player_node.ally_attack_ready = false
		ally_attack_cooldown_node.start(randf_range(2, 3))
	
	attack_shape_node.set_target_position(player_node.attack_direction * 20)

	attack_cooldown_node.start(0.5)

	player_node.attack_register = "ultimate_attack_register"
	attack_shape_node.force_shapecast_update()

func ultimate_attack_register():
	var enemy_body = null

	if attack_shape_node.is_colliding():
		for collision_index in attack_shape_node.get_collision_count():
			enemy_body = attack_shape_node.get_collider(collision_index).get_parent()
			var knockback_weight = 2.0
			if player_node.dashing:
				temp_regular_attack_damage = regular_attack_damage * 15
				knockback_weight = 3.0
			else:
				temp_regular_attack_damage = regular_attack_damage * 10
			var damage = CombatEntitiesComponent.physical_damage_calculator(temp_regular_attack_damage, player_stats_node, enemy_body.base_enemy_node)
			enemy_body.base_enemy_node.update_health(-damage[0], damage[1], player_node.attack_direction, knockback_weight)
		GlobalSettings.camera_node.screen_shake(0.3, 10, 30, 100, true)

	player_node.attack_register = ""
