extends Node2D

const character_name := "Aki Rosenthal"
const character_index := 3
# default stats (Score: 4.18) + 2% Crit Rate + 10% Crit Damage
# physical-magic
const default_level := 1
const default_max_health := 396 # +196 (+0.98 T1)
const default_max_mana := 26 # +16 (+1.6 T1)
const default_max_stamina := 100
const default_defence := 11 # +1 (+0.2 T1)
const default_shield := 11 # +1 (+0.2 T1)
const default_strength := 14 # +4 (+0.8 T1)
const default_intelligence := 12 # +2 (+0.4 T1)
const default_speed := 0
const default_agility := 0
const default_crit_chance := 0.05 # +0.02 Crit Rate
const default_crit_damage := 0.60 # +0.10 Crit Damage

const default_unlocked_nexus_nodes := [491, 522, 523]

const regular_attack_damage := 13
var temp_regular_attack_damage := 13.0

@onready var player_node = get_parent()
@onready var player_stats_node = player_node.get_node("PlayerStatsComponent")
@onready var attack_shape_node = player_node.get_node("AttackShape")
@onready var attack_cooldown_node = player_node.get_node("AttackCooldown")
@onready var ally_attack_cooldown_node = player_node.get_node("AllyAttackCooldown")

func regular_attack():
	if player_node.is_current_main_player: player_node.attack_direction = (get_global_mouse_position() - player_node.position).normalized()
	else:
		var temp_enemy_health = INF
		for enemy_node in player_node.ally_enemy_nodes_in_attack_area:
			if enemy_node.enemy_stats_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.enemy_stats_node.health
				player_node.attack_direction = (enemy_node.position - player_node.position).normalized()
		player_node.ally_attack_ready = false
		ally_attack_cooldown_node.start(randf_range(2, 3))
	
	attack_shape_node.set_target_position(player_node.attack_direction * 20)

	attack_cooldown_node.start(0.8)
	attack_shape_node.force_shapecast_update()

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
			var damage = CombatEntitiesComponent.physical_damage_calculator(temp_regular_attack_damage, player_stats_node, enemy_body.enemy_stats_node)
			enemy_body.enemy_stats_node.update_health( - damage[0], damage[1], player_node.attack_direction, knockback_weight)
