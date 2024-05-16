extends CharacterBody2D

@export var speed = 150
@export var dash_speed = 500
@export var sprint_multiplier = 1.5

@onready var CombatUI = get_parent().get_node("CombatUI")

var input_direction
var last_input_direction = Vector2.ZERO
var input_active = false

var attack_ready = true

var attack_direction = Vector2.ZERO
var enemy_body

var dash_ready = true
var sprinting = false

func _ready():
	$Animation.play("front_idle")
	PartyStatsComponent.update_players()

func _physics_process(_delta):
	if attack_ready&&Input.is_action_just_pressed("attack"): attack()
	if !PartyStatsComponent.stamina_slow_recovery:
		if dash_ready&&Input.is_action_just_pressed("dash"):
			PartyStatsComponent.stamina[0] -= 35
			dash()
		elif Input.is_action_pressed("dash")&&PartyStatsComponent.stamina[0] > 0:
			PartyStatsComponent.stamina[0] -= 0.7
			sprinting = true
		else: sprinting = false
	else: sprinting = false
	movement_input()
	move_and_slide()
	PartyStatsComponent.health_bar_update(0)
	CombatUI.health_UI_update(0)

#8-way movement inputs
##### optimized (temporarily)
func movement_input():
	input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	if sprinting:
		velocity *= sprint_multiplier

	if input_direction != Vector2.ZERO:
		last_input_direction = input_direction
		input_active = true
	else:
		input_active = false

	if !attack_ready:
		if input_active:
			velocity /= 1.25
			if abs(attack_direction.x) >= abs(attack_direction.y):
				##### need to combine walk
				$Animation.play("side_attack")
				$Animation.flip_h = attack_direction.x < 0
			elif attack_direction.y > 0:
				##### need to combine walk
				$Animation.play("front_attack")
			else:
				##### need to combine walk
				$Animation.play("back_attack")
		else:
			last_input_direction = attack_direction
			if abs(attack_direction.x) >= abs(attack_direction.y):
				$Animation.play("side_attack")
				$Animation.flip_h = attack_direction.x < 0
			elif attack_direction.y > 0:
				$Animation.play("front_attack")
			else:
				$Animation.play("back_attack")
	else:
		if input_active:
			if input_direction.x != 0:
				$Animation.play("side_walk")
				$Animation.flip_h = input_direction.x < 0
			elif input_direction.y > 0:
				$Animation.play("front_walk")
			else:
				$Animation.play("back_walk")
		else:
			if abs(last_input_direction.x) >= abs(last_input_direction.y):
				$Animation.play("side_idle")
				$Animation.flip_h = last_input_direction.x < 0
			elif last_input_direction.y > 0:
				$Animation.play("front_idle")
			else:
				$Animation.play("back_idle")

	if !dash_ready:
		if input_direction != Vector2.ZERO:
			velocity = input_direction * (195 + dash_speed * (1 - (0.2 - $DashCooldown.get_time_left()) / 0.2))
		else:
			velocity = last_input_direction * dash_speed * (1 - (0.2 - $DashCooldown.get_time_left()) / 0.2)

func player():
	pass

func attack():
	attack_direction = (get_global_mouse_position() - position).normalized()
	$AttackShape.set_target_position(attack_direction * 20)
	attack_ready = false
	enemy_body = null
	$AttackCooldown.set_wait_time(0.8)
	$AttackCooldown.start()
	$AttackShape.force_shapecast_update()
	if $AttackShape.is_colliding():
		enemy_body = $AttackShape.get_collider(0).get_parent()
		if !dash_ready: enemy_body.take_damage(50)
		else: enemy_body.take_damage(20)

func dash():
	dash_ready = false
	$DashCooldown.set_wait_time(0.2)
	$DashCooldown.start()

func _on_npc_detection_area_body_entered(body):
	body.area_status(true)

func _on_npc_detection_area_body_exited(body):
	body.area_status(false)

func _on_attack_cooldown_timeout():
	attack_ready = true

func _on_dash_cooldown_timeout():
	dash_ready = true
