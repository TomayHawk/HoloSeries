extends CharacterBody2D

@export var speed = 75

@onready var nav_agent = $NavigationAgent2D

@onready var health_component = $EnemiesHealthComponent

var current_animation = null
var current_frame = 0
var last_frame = 1

var move_direction = Vector2.ZERO
var player_direction = Vector2.ZERO

var player = null
var player_in_area = false
var player_in_attack_area = false
var attack_ready = true
var taking_knockback = false

var dying = false

var nousagi_load = null
var nousagi_instance = null

func _ready():
	$Animation.play("walk")
	health_component.create_enemy()
	nousagi_load = load("res://entities/nousagi.tscn")

func _physics_process(_delta):
	current_animation = $Animation.get_animation()
	current_frame = $Animation.get_frame()

	if current_frame != last_frame:
		if current_frame == 0:
			if !PartyHealthComponent.alive[0]:
				player = null
				player_in_area = false
				player_in_attack_area = false
			velocity = Vector2(0, 0)
			if player_in_attack_area:
				if attack_ready: $Animation.play("attack")
				else: $Animation.play("idle")
			else:
				$Animation.play("walk")
				if player_in_area: move_direction = to_local(nav_agent.get_next_path_position()).normalized()
				else: move_direction = Vector2(randf_range( - 1, 1), randf_range( - 1, 1)).normalized()
				$Animation.flip_h = move_direction.x < 0
		elif current_frame == 3:
			if current_animation == "attack":
				if player_in_attack_area&&player != null:
					PartyHealthComponent.take_damage(0, 1)
					player_direction = (player.position - position).normalized()
					$Animation.flip_h = player_direction.x < 0
				$AttackCooldown.set_wait_time(randf_range(1, 3))
				$AttackCooldown.start()
				attack_ready = false
			elif current_animation == "walk":
				velocity = move_direction * speed
	
	if dying:
		$Animation.play("death")
		velocity = player_direction * (-100)
		if $KnockbackTimer.get_time_left() <= 0.1: queue_free()
	elif taking_knockback:
		$Animation.play("idle")
		velocity = player_direction * (-200) * (1 - (0.4 - $KnockbackTimer.get_time_left()) / 0.4)
	elif current_animation == "idle":
		if player != null: $Animation.flip_h = (player.position - position).x < 0
		if player_in_attack_area&&attack_ready: $Animation.play("attack")
		elif !player_in_attack_area:
			$Animation.play("walk")

	health_component.health_bar_update()
	move_and_slide()

	last_frame = current_frame

func take_damage(damage):
	health_component.deal_damage(damage)
	player_direction = (player.position - position).normalized()
	$KnockbackTimer.set_wait_time(0.4)
	$KnockbackTimer.start()

func _on_detection_area_body_entered(body):
	if PartyHealthComponent.health[0] > 0:
		player = body
		player_in_area = true
		if !GlobalSettings.in_combat: GlobalSettings.in_combat = true
		$SummonNousagiTimer.set_wait_time(randf_range(15, 20))
		$SummonNousagiTimer.start()

func _on_detection_area_body_exited(_body):
	player = null
	player_in_area = false
	if GlobalSettings.in_combat: GlobalSettings.in_combat = false
	$SummonNousagiTimer.stop()

func _on_attack_area_body_entered(_body):
	if PartyHealthComponent.health[0] > 0:
		player_in_attack_area = true

func _on_attack_area_body_exited(_body):
	player_in_attack_area = false

func _on_attack_cooldown_timeout():
	attack_ready = true

func _on_knockback_timer_timeout():
	if taking_knockback&&!dying:
		$Animation.play("walk")
	taking_knockback = false

func _on_navigation_timer_timeout():
	if player != null: nav_agent.target_position = player.position

func _on_summon_nousagi_timer_timeout():
	var i = randi() % 10 - 7
	while i > 0:
		nousagi_instance = nousagi_load.instantiate()
		get_parent().add_child(nousagi_instance)
		nousagi_instance.position = position + Vector2(5 + 10 * randf_range( - 1, 1), 5 + 10 * randf_range( - 1, 1))
		i -= 1
