extends Node2D

# default stats (Score: 4.55)
# buffer-healer
var default_level = 999
var default_max_health = 99999 # +190 (+0.95 T1)
var default_max_mana = 9999 # +18 (+1.8 T1)
var default_max_stamina = 500 # #### should be 100
var default_defence = 1000
var default_shield = 1000
var default_strength = 1000
var default_intelligence = 1000 # +4 (+0.8 T1)
var default_speed = 256 # +1 (+1 T1)
var default_agility = 256 # +1 (+1 T1)
var default_crit_chance = 0.50
var default_crit_damage = 0.50

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
			var types = []
			var damage = GlobalSettings.physical_damage_calculator(1000, player_stats_node, enemy_body.enemy_stats_node)
			if player_node.dashing:
				damage[0] *= 1.5
				knockback_weight = 3.5
			if damage[1]:
				types.push_back("critical")
			enemy_body.enemy_stats_node.update_health( - damage[0], types, player_node.attack_direction, knockback_weight)
