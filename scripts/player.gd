extends CharacterBody2D

@export var speed = 150

@onready var CombatUI = get_parent().get_node("CombatUI")

var input_direction
var last_input_direction = Vector2.ZERO
var input_active = false

var attack_ready = true

var attack_direction = Vector2.ZERO
var enemy_body

func _ready():
	$Animation.play("front_idle")
	PartyHealthComponent.update_players()

func _physics_process(_delta):
	if attack_ready&&Input.is_action_just_pressed("attack"): attack()

	#8-way movement inputs
	##### optimized (temporarily)
	input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed

	if input_direction != Vector2.ZERO:
		last_input_direction = input_direction
		input_active = true
	else:
		input_active = false

	if !attack_ready:
		if input_active:
			velocity /= 2
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
	
	move_and_slide()
	PartyHealthComponent.health_bar_update(0)
	CombatUI.health_UI_update(0)

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
		print(enemy_body)
		enemy_body.take_damage(20)

func _on_npc_detection_area_body_entered(body):
	body.area_status(true)

func _on_npc_detection_area_body_exited(body):
	body.area_status(false)

func _on_attack_cooldown_timeout():
	attack_ready = true
