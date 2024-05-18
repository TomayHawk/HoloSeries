extends CharacterBody2D

@export var speed = 75
@onready var nav_agent = $NavigationAgent2D

# nousagi animation information
var current_animation = null
var current_frame = 0
var last_frame = 1

# player information
var detected_players = [null, null, null, null]
var players_in_area = [false, false, false, false]
var players_exist_in_area = false
var players_in_attack_area = [false, false, false, false]
var players_exist_in_attack_area = false

# target directions
var move_direction = Vector2.ZERO
var player_direction = Vector2.ZERO
var target_player_health = 100000
var target_player = -1

# status
var attack_ready = true
var taking_knockback = false
var dying = false

# duplicating nousagis
@onready var nousagi_load = load("res://entities/nousagi.tscn")
var nousagi_instance = null

func _ready():
	$Animation.play("walk")
	$EnemiesHealthComponent.create_enemy()

func _physics_process(_delta):
	current_animation = $Animation.get_animation()
	current_frame = $Animation.get_frame()
	
	choose_player()

	if current_frame != last_frame:
		if current_frame == 0:
			for i in GlobalSettings.active_players: if !PartyStatsComponent.alive[i]:
				_on_detection_area_body_exited(detected_players[i])
				_on_attack_area_body_exited(detected_players[i])
			velocity = Vector2(0, 0)
			if players_exist_in_attack_area:
				if attack_ready: $Animation.play("attack")
				else: $Animation.play("idle")
			else:
				if detected_players[target_player] != null: nav_agent.target_position = detected_players[target_player].position
				$Animation.play("walk")
				if players_exist_in_area: move_direction = to_local(nav_agent.get_next_path_position()).normalized()
				else: move_direction = Vector2(randf_range( - 1, 1), randf_range( - 1, 1)).normalized()
				$Animation.flip_h = move_direction.x < 0
		elif current_frame == 3:
			if current_animation == "attack":
				if players_exist_in_attack_area&&detected_players[target_player] != null:
					PartyStatsComponent.take_damage(target_player, 10)
					player_direction = (detected_players[target_player].position - position).normalized()
					$Animation.flip_h = player_direction.x < 0
				$AttackCooldown.set_wait_time(randf_range(1, 3))
				$AttackCooldown.start()
				attack_ready = false
			elif current_animation == "walk":
				velocity = move_direction * speed
		if players_exist_in_attack_area: velocity = Vector2(0, 0)
	
	if dying:
		$Animation.play("death")
		velocity = player_direction * (-100)
		if $KnockbackTimer.get_time_left() <= 0.1: queue_free()
	elif taking_knockback:
		$Animation.play("idle")
		velocity = player_direction * (-200) * (1 - (0.4 - $KnockbackTimer.get_time_left()) / 0.4)
	elif current_animation == "idle":
		if detected_players[target_player] != null: $Animation.flip_h = (detected_players[target_player].position - position).x < 0
		if players_exist_in_attack_area&&attack_ready: $Animation.play("attack")
		elif !players_exist_in_attack_area:
			$Animation.play("walk")

	$EnemiesHealthComponent.health_bar_update()
	move_and_slide()

	last_frame = current_frame

func choose_player():
	target_player_health = 100000
	target_player = -1

	if players_exist_in_attack_area:
		for i in 4:
			if players_in_attack_area[i]&&target_player_health > PartyStatsComponent.health[i]:
				# using health to choose target player
				target_player_health = PartyStatsComponent.health[i]
				target_player = i
	elif players_exist_in_area:
		for i in 4:
			if players_in_area[i]&&target_player_health > PartyStatsComponent.health[i]:
				# using health to choose target player
				target_player_health = PartyStatsComponent.health[i]
				target_player = i

func take_damage(player_number, damage):
	$EnemiesHealthComponent.deal_damage(damage)
	player_direction = (detected_players[player_number].position - position).normalized()
	$KnockbackTimer.set_wait_time(0.4)
	$KnockbackTimer.start()

func _on_detection_area_body_entered(body):
	for i in 4: if body == GlobalSettings.players[i]&&PartyStatsComponent.health[i] > 0:
		detected_players[i] = body
		players_in_area[i] = true
		players_exist_in_area = true
		GlobalSettings.in_combat = true
		$SummonNousagiTimer.set_wait_time(randf_range(15, 20))
		$SummonNousagiTimer.start()
	#improve
	GlobalSettings.enemies_in_combat[0] = get_child(0).get_parent()

func _on_detection_area_body_exited(body):
	for i in 4: if body == GlobalSettings.players[i]:
		detected_players[i] = null
		players_in_area[i] = false
		players_exist_in_area = false
		GlobalSettings.in_combat = false
		for j in 4: if players_in_area[j]:
			players_exist_in_area = true
			GlobalSettings.in_combat = true
		$SummonNousagiTimer.stop()
	#change this
	GlobalSettings.enemies_in_combat[0] = null
	if GlobalSettings.enemies_in_combat[0] == null: GlobalSettings.in_combat = false

func _on_attack_area_body_entered(body):
	for i in 4: if body == detected_players[i]&&PartyStatsComponent.health[i] > 0:
		players_in_attack_area[i] = true
		players_exist_in_attack_area = true

func _on_attack_area_body_exited(body):
	for i in 4: if body == detected_players[i]:
		players_in_attack_area[i] = false
		players_exist_in_attack_area = false
		for j in 4: if players_in_attack_area[j]:
			players_exist_in_attack_area = true

func _on_attack_cooldown_timeout():
	attack_ready = true

func _on_knockback_timer_timeout():
	if taking_knockback&&!dying:
		$Animation.play("walk")
	taking_knockback = false

func _on_summon_nousagi_timer_timeout():
	var i = 1
	#var i = 3
	#var i = randi() % 3
	# var i = randi() % 10 - 7
	while i > 0:
		nousagi_instance = nousagi_load.instantiate()
		get_parent().add_child(nousagi_instance)
		nousagi_instance.position = position + Vector2(5 + 10 * randf_range( - 1, 1), 5 + 10 * randf_range( - 1, 1))
		i -= 1
