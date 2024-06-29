extends CharacterBody2D

@export var speed = 150
@export var dash_speed = 500
@export var sprint_multiplier = 1.5

@onready var CombatUI = get_parent().get_node("CombatUI")

var attack_ready = true

var attack_direction = Vector2.ZERO
var enemy_body

var dash_ready = true
var sprinting = false

var current_main = false
@onready var active_player_node = get_parent().get_node("Player1")
var move_direction = Vector2.ZERO
var last_move_direction = Vector2.ZERO
var moving = false
var close_to_main = false
var distance_to_direction = 2.0
var possible_directions = [Vector2(1, 0), Vector2(0.7071, -0.7071), Vector2(0, -1), Vector2( - 0.7071, -0.7071),
						   Vector2( - 1, 0), Vector2( - 0.7071, 0.7071), Vector2(0, 1), Vector2(0.7071, 0.7071)]
var move_ready = true
var direction_ready = true
var enemy_in_attack_area = false
var enemies_in_attack_area = 0

var target_enemy_node = null
var nodes_in_attack_area = []
var target_enemy_health = 100000
var target_enemy_number = -1

var ally_attack_ready = true

func _ready():
	PartyStatsComponent.stamina[1] = PartyStatsComponent.max_stamina[1]
	PartyStatsComponent.stamina_slow_recovery[1] = false
	dash_ready = true
	$Animation.play("front_idle")

func _physics_process(_delta):
	if current_main:
		if attack_ready&&Input.is_action_just_pressed("attack"): attack()
		if Input.is_action_pressed("dash")&&!PartyStatsComponent.stamina_slow_recovery[1]&&PartyStatsComponent.stamina[1] > 0:
			if dash_ready&&Input.is_action_just_pressed("dash"):
				PartyStatsComponent.stamina[1] -= 35
				dash()
			else:
				PartyStatsComponent.stamina[1] -= 0.7
				sprinting = true
		else: sprinting = false
		movement_input()
	elif GlobalSettings.in_combat:
		choose_enemy()
		
		if enemy_in_attack_area:
			if attack_ready&&ally_attack_ready: attack()
			else: move_direction = (target_enemy_node.position - position).normalized()
			velocity = Vector2.ZERO
		elif direction_ready:
			ally_direction()
			direction_ready = false
			$DirectionCooldown.set_wait_time(randf_range(0.3, 0.5))
			$DirectionCooldown.start()
	elif direction_ready&&move_ready:
		if close_to_main:
			move_direction = possible_directions[randi() % 8]
			velocity = move_direction * speed / 1.5
		else:
			ally_direction()
		direction_ready = false
		$DirectionCooldown.set_wait_time(randf_range(0.3, 0.5))
		$DirectionCooldown.start()
	elif !move_ready:
		last_move_direction = move_direction
		velocity = Vector2(0, 0)
	
	choose_animation()
	move_and_slide()

	PartyStatsComponent.update_health_bar(1)
	CombatUI.health_UI_update(1)

#8-way movement inputs
##### optimized (temporarily)
func movement_input():
	move_direction = Input.get_vector("left", "right", "up", "down")
	velocity = move_direction * speed
	if sprinting:
		velocity *= sprint_multiplier

	if !dash_ready:
		if move_direction != Vector2.ZERO:
			velocity = move_direction * (195 + dash_speed * (1 - (0.2 - $DashCooldown.get_time_left()) / 0.2))
		else:
			velocity = last_move_direction * dash_speed * (1 - (0.2 - $DashCooldown.get_time_left()) / 0.2)

func choose_enemy():
	target_enemy_health = 100000
	target_enemy_number = -1
	
	if enemy_in_attack_area: for i in enemies_in_attack_area:
		if target_enemy_health > nodes_in_attack_area[i].get_node("EnemiesHealthComponent").health:
			target_enemy_health = nodes_in_attack_area[i].get_node("EnemiesHealthComponent").health
			target_enemy_node = nodes_in_attack_area[i]
	else: for i in GlobalSettings.enemies_in_combat.size():
		if target_enemy_health > GlobalSettings.enemies_in_combat[i].get_node("EnemiesHealthComponent").health:
			target_enemy_health = GlobalSettings.enemies_in_combat[i].get_node("EnemiesHealthComponent").health
			target_enemy_node = GlobalSettings.enemies_in_combat[i]

func ally_direction():
	if GlobalSettings.in_combat: move_direction = (target_enemy_node.position - position).normalized()
	else:
		move_direction = (active_player_node.position - position).normalized()
	distance_to_direction = 2
	#optimize this
	if move_direction.x > 0:
		if move_direction.y > 0: for i in [0, 6, 7]:
			if move_direction.distance_to(possible_directions[i]) < distance_to_direction:
				distance_to_direction = move_direction.distance_to(possible_directions[i])
				move_direction = possible_directions[i]
		else: for i in [0, 1, 2]:
			if move_direction.distance_to(possible_directions[i]) < distance_to_direction:
				distance_to_direction = move_direction.distance_to(possible_directions[i])
				move_direction = possible_directions[i]
	elif move_direction.x < 0:
		if move_direction.y > 0: for i in [4, 5, 6]:
			if move_direction.distance_to(possible_directions[i]) < distance_to_direction:
				distance_to_direction = move_direction.distance_to(possible_directions[i])
				move_direction = possible_directions[i]
		else: for i in [2, 3, 4]:
			if move_direction.distance_to(possible_directions[i]) < distance_to_direction:
				distance_to_direction = move_direction.distance_to(possible_directions[i])
				move_direction = possible_directions[i]
	velocity = move_direction * speed

func choose_animation():
	if velocity != Vector2.ZERO:
		last_move_direction = move_direction
		moving = true
	else:
		moving = false
	
	if !attack_ready:
		if moving:
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
			last_move_direction = attack_direction
			if abs(attack_direction.x) >= abs(attack_direction.y):
				$Animation.play("side_attack")
				$Animation.flip_h = attack_direction.x < 0
			elif attack_direction.y > 0:
				$Animation.play("front_attack")
			else:
				$Animation.play("back_attack")
	else:
		if moving:
			if move_direction.x != 0:
				$Animation.play("side_walk")
				$Animation.flip_h = move_direction.x < 0
			elif move_direction.y > 0:
				$Animation.play("front_walk")
			else:
				$Animation.play("back_walk")
		else:
			if abs(last_move_direction.x) >= abs(last_move_direction.y):
				$Animation.play("side_idle")
				$Animation.flip_h = last_move_direction.x < 0
			elif last_move_direction.y > 0:
				$Animation.play("front_idle")
			else:
				$Animation.play("back_idle")

func update_active_player():
	active_player_node = GlobalSettings.players[GlobalSettings.current_main_player]

func attack():
	if current_main: attack_direction = (get_global_mouse_position() - position).normalized()
	else:
		attack_direction = (target_enemy_node.position - position).normalized()
		ally_attack_ready = false
		$AllyAttackCooldown.set_wait_time(randf_range(3, 4))
		$AllyAttackCooldown.start()
	$AttackShape.set_target_position(attack_direction * 20)
	attack_ready = false
	enemy_body = null
	$AttackCooldown.set_wait_time(0.8)
	$AttackCooldown.start()
	$AttackShape.force_shapecast_update()
	if $AttackShape.is_colliding():
		enemy_body = $AttackShape.get_collider(0).get_parent()
		if !dash_ready: enemy_body.take_damage(1, 50)
		else: enemy_body.take_damage(1, 20)

func dash():
	dash_ready = false
	$DashCooldown.set_wait_time(0.2)
	$DashCooldown.start()

func _on_npc_detection_area_body_entered(body):
	if body.has_method("area_status"):
		body.area_status(true)
	elif !current_main&&body.has_method("choose_player"):
		nodes_in_attack_area.push_back(body)
		enemies_in_attack_area += 1
		enemy_in_attack_area = true

func _on_npc_detection_area_body_exited(body):
	if body.has_method("area_status"):
		body.area_status(false)
	elif !current_main&&body.has_method("choose_player"):
		nodes_in_attack_area.erase(body)
		enemies_in_attack_area -= 1
		if enemies_in_attack_area == 0: enemy_in_attack_area = false

func _on_attack_cooldown_timeout():
	attack_ready = true

func _on_dash_cooldown_timeout():
	dash_ready = true

func _on_entities_detection_area_body_exited(body):
	if !current_main&&body == GlobalSettings.players[GlobalSettings.current_main_player]&&PartyStatsComponent.alive[1]:
		position = GlobalSettings.players[GlobalSettings.current_main_player].position + Vector2(20 + (10 * randf_range(0, 1)), 20 + (10 * randf_range(0, 1)))
		close_to_main = true
		direction_ready = true
		move_ready = true
		attack_ready = true
		ally_attack_ready = true

func _on_inner_ally_area_body_entered(body):
	if !current_main&&body == active_player_node: close_to_main = true

func _on_inner_ally_area_body_exited(body):
	if !current_main&&body == active_player_node&&!GlobalSettings.in_combat:
		if $PauseTimer.is_inside_tree():
			$PauseTimer.set_wait_time(0.2)
			$PauseTimer.start()
		close_to_main = false

func _on_direction_cooldown_timeout():
	direction_ready = true
	if close_to_main:
		move_ready = false
		$PauseTimer.set_wait_time(randf_range(2, 3))
		$PauseTimer.start()

func _on_pause_timer_timeout():
	move_ready = true

func _on_ally_attack_cooldown_timeout():
	ally_attack_ready = true

func _on_combat_hit_box_area_input_event(_event_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if !current_main&&PartyStatsComponent.alive[1]:
				GlobalSettings.update_main_player(1)
