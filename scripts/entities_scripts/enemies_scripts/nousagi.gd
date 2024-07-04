extends CharacterBody2D

var speed = 75
@onready var navigation_agent_node = $NavigationAgent2D
@onready var animation_node = $Animation

# nousagi animation information
var current_animation = null
var current_frame = 0
var last_frame = 1

# player information
var players_exist_in_detection_area = false
var player_nodes_in_detection_area = []
var players_exist_in_attack_area = false
var player_nodes_in_attack_area = []

# target directions
var move_direction = Vector2.ZERO
var player_direction = Vector2.ZERO
var target_player_health = 100000
var target_player_node = null

# status
var attack_ready = true
var taking_knockback = false
var dying = false

# duplicating nousagis
@onready var scene_node = get_parent().get_parent()
@onready var nousagi_load = load("res://entities/enemies/nousagi.tscn")
var nousagi_instance = null

@onready var enemy_stats_node = $EnemyStatsComponent

func _ready():
	animation_node.play("walk")
	add_to_group("enemies")

func _physics_process(_delta):
	current_animation = animation_node.get_animation()
	current_frame = animation_node.get_frame()
	
	choose_player()

	if current_frame != last_frame:
		if current_frame == 0:
			for player_node in player_nodes_in_detection_area:
				if !player_node.player_stats_node.alive:
					_on_detection_area_body_exited(player_node)
					_on_attack_area_body_exited(player_node)
			velocity = Vector2(0, 0)
			if players_exist_in_attack_area:
				if attack_ready: animation_node.play("attack")
				else: animation_node.play("idle")
			else:
				if target_player_node != null: navigation_agent_node.target_position = target_player_node.position
				animation_node.play("walk")
				if players_exist_in_detection_area: move_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
				else: move_direction = Vector2(randf_range( - 1, 1), randf_range( - 1, 1)).normalized()
				animation_node.flip_h = move_direction.x < 0
		elif current_frame == 3:
			if current_animation == "attack":
				if players_exist_in_attack_area&&target_player_node != null:
					target_player_node.player_stats_node.update_health( - 100) # attack player (damage)
					player_direction = (target_player_node.position - position).normalized()
					animation_node.flip_h = player_direction.x < 0
				$AttackCooldown.start(randf_range(1, 3))
				attack_ready = false
			elif current_animation == "walk":
				velocity = move_direction * speed
		if players_exist_in_attack_area: velocity = Vector2(0, 0)
	
	if dying:
		animation_node.play("death")
		velocity = player_direction * (-100)
		if $KnockbackTimer.get_time_left() <= 0.1:
			GlobalSettings.enemy_nodes_in_combat.erase(self)
			queue_free()

	if GlobalSettings.enemy_nodes_in_combat.is_empty(): GlobalSettings.attempt_leave_combat()
	if player_nodes_in_detection_area.is_empty(): players_exist_in_detection_area = false

	elif taking_knockback:
		animation_node.play("idle")
		velocity = player_direction * (-200) * (1 - (0.4 - $KnockbackTimer.get_time_left()) / 0.4)
	elif current_animation == "idle":
		if target_player_node != null: animation_node.flip_h = (target_player_node.position - position).x < 0
		if players_exist_in_attack_area&&attack_ready: animation_node.play("attack")
		elif !players_exist_in_attack_area:
			animation_node.play("walk")

	$EnemyStatsComponent.health_bar_update()
	move_and_slide()

	last_frame = current_frame

func choose_player():
	target_player_health = 100000
	target_player_node = null

	if players_exist_in_attack_area:
		for player_node in player_nodes_in_attack_area:
			if target_player_health > player_node.player_stats_node.health:
				# using health to choose target player
				target_player_health = player_node.player_stats_node.health
				target_player_node = player_node
	elif players_exist_in_detection_area:
		for player_node in player_nodes_in_detection_area:
			if target_player_health > player_node.player_stats_node.health:
				# using health to choose target player
				target_player_health = player_node.player_stats_node.health
				target_player_node = player_node

func summon_nousagi():
	nousagi_instance = nousagi_load.instantiate()
	get_parent().add_child(nousagi_instance)
	nousagi_instance.position = position + Vector2(5 * randf_range( - 1, 1), 5 * randf_range( - 1, 1)) * 5

func take_damage(player_index, damage):
	$EnemyStatsComponent.update_health( - damage)
	player_direction = (GlobalSettings.party_player_nodes[player_index].position - position).normalized()
	$KnockbackTimer.start(0.4)

func _on_detection_area_body_entered(body):
	if body.player_stats_node.alive:
		GlobalSettings.enter_combat()
		players_exist_in_detection_area = true
		if !GlobalSettings.enemy_nodes_in_combat.has(self): GlobalSettings.enemy_nodes_in_combat.push_back(self)
		if !player_nodes_in_detection_area.has(self): player_nodes_in_detection_area.push_back(body)

func _on_detection_area_body_exited(body):
	GlobalSettings.enemy_nodes_in_combat.erase(self)
	player_nodes_in_detection_area.erase(body)
	player_nodes_in_attack_area.erase(body)

	if GlobalSettings.enemy_nodes_in_combat.is_empty(): GlobalSettings.attempt_leave_combat()
	if player_nodes_in_detection_area.is_empty(): players_exist_in_detection_area = false

func _on_attack_area_body_entered(body):
	if body.player_stats_node.alive:
		GlobalSettings.enter_combat()
		players_exist_in_detection_area = true
		players_exist_in_attack_area = true
		if !GlobalSettings.enemy_nodes_in_combat.has(self): GlobalSettings.enemy_nodes_in_combat.push_back(self)
		if !player_nodes_in_detection_area.has(self): player_nodes_in_detection_area.push_back(body)
		if !player_nodes_in_attack_area.has(self): player_nodes_in_attack_area.push_back(body)

func _on_attack_area_body_exited(body):
	player_nodes_in_attack_area.erase(body)

	if player_nodes_in_attack_area.is_empty(): players_exist_in_attack_area = false

func _on_attack_cooldown_timeout():
	attack_ready = true

func _on_knockback_timer_timeout():
	if taking_knockback&&!dying:
		animation_node.play("walk")
	taking_knockback = false

func _on_summon_nousagi_timer_timeout():
	print("temp_summon_timer_response")
