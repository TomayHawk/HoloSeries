extends CharacterBody2D

# node variables
@onready var player_stats_node = $PlayerStatsComponent
@onready var attack_shape_node = $AttackShape
@onready var animation_node = $Animation
# timer nodes
@onready var attack_cooldown_node = $AttackCooldown
@onready var dash_cooldown_node = $DashCooldown
@onready var ally_attack_cooldown_node = $AllyAttackCooldown
@onready var ally_direction_cooldown_node = $AllyDirectionCooldown
@onready var ally_pause_timer_node = $AllyPauseTimer

# speed variables
var speed = 10000
var dash_speed = 500
var sprint_multiplier = 1.5

# player node information variables
var player_index = 0
var is_current_main_player = false

# ally variables
var ally_in_main_inner_area = false

# movement variables
var moving = false
var dashing = false
var sprinting = false
var current_move_direction = Vector2.ZERO
var last_move_direction = Vector2.ZERO
var possible_directions = [Vector2(1, 0), Vector2(0.7071, -0.7071), Vector2(0, -1), Vector2( - 0.7071, -0.7071),
						   Vector2( - 1, 0), Vector2( - 0.7071, 0.7071), Vector2(0, 1), Vector2(0.7071, 0.7071)]
# movement variables (player)
# movement variables (allies)
var ally_direction_ready = true

# combat variables
var attacking = false
var attack_direction = Vector2.ZERO
# combat variables (player)
# combat variables (allies)
var ally_attack_ready = true
var ally_enemy_in_detection_area = false
var ally_enemy_in_attack_area = false
var ally_enemy_nodes_in_detection_area = []
var ally_enemy_nodes_in_attack_area = []
var ally_target_enemy_node = null

func _ready():
	animation_node.play("front_idle")
	
func _physics_process(delta):
	# if player
	if is_current_main_player:
		# attack
		if !attacking&&Input.is_action_just_pressed("attack"): attack()

		# dash / sprint
		if player_stats_node.stamina > 0&&!player_stats_node.stamina_slow_recovery:
			# dash
			if Input.is_action_just_pressed("dash")&&!dashing:
				player_stats_node.stamina -= 35
				dash()
			# sprint
			elif Input.is_action_pressed("dash"):
				player_stats_node.stamina -= 0.7
				sprinting = true
		else: sprinting = false

		player_movement(delta)

	# if ally in combat
	elif GlobalSettings.in_combat&&ally_enemy_in_attack_area:
		moving = false
		velocity = Vector2.ZERO

		var target_enemy_health = 1000000000
		# determine enemy health
		for enemy in ally_enemy_nodes_in_attack_area:
			# target enemy with lowest health
			if enemy.enemy_stats_node.health < target_enemy_health:
				target_enemy_health = enemy.enemy_stats_node.health
				ally_target_enemy_node = enemy

		last_move_direction = (ally_target_enemy_node.position - position).normalized()
		if ally_attack_ready: attack()

		choose_animation()
	# if ally can move
	elif ally_direction_ready: ally_movement(delta)

	move_and_slide()

# movement functions
func player_movement(delta):
	# movement inputs
	current_move_direction = Input.get_vector("left", "right", "up", "down")
	velocity = current_move_direction * speed * delta
	
	if velocity != Vector2.ZERO:
		moving = true
		last_move_direction = current_move_direction
	else: moving = false

	choose_animation()

	# dash
	if dashing:
		if moving == true:
			velocity += current_move_direction * dash_speed * (1 - (0.2 - dash_cooldown_node.get_time_left()) / 0.2)
		else:
			moving = true
			velocity = last_move_direction * dash_speed * (1 - (0.2 - dash_cooldown_node.get_time_left()) / 0.2)
	# sprint
	elif sprinting: velocity *= sprint_multiplier

	# if attacking, reduce speed
	if attacking: velocity /= 2

func ally_movement(delta):
	ally_direction_ready = false
	moving = true

	if !GlobalSettings.enemy_nodes_in_combat.is_empty():
		var distance_to_enemy = 10000
		var target_enemies = []

		# determine enemies to evaluate
		if ally_enemy_in_detection_area: target_enemies = ally_enemy_nodes_in_detection_area
		else: target_enemies = GlobalSettings.enemy_nodes_in_combat

		# evaluate enemy distances
		for enemy in target_enemies:
			# target enemy with shortest distance
			if position.distance_to(enemy.position) < distance_to_enemy:
				distance_to_enemy = position.distance_to(enemy.position)
				ally_target_enemy_node = enemy

		current_move_direction = (ally_target_enemy_node.position - position).normalized()

	elif ally_in_main_inner_area:
		current_move_direction = possible_directions[randi() % 8]
		ally_direction_cooldown_node.start(randf_range(0.5, 1))
	else:
		current_move_direction = (GlobalSettings.current_main_player_node.position - position).normalized()
	
	choose_animation()

	var directions = []
	var distance_to_direction = 2
	# determine movement quadrant
	if current_move_direction.x > 0:
		if current_move_direction.y > 0: directions = [0, 6, 7]
		else: directions = [0, 1, 2]
	elif current_move_direction.x < 0:
		if current_move_direction.y > 0: directions = [4, 5, 6]
		else: directions = [2, 3, 4]
	
	# set movement direction to 8-way movement
	for i in directions:
		if current_move_direction.distance_to(possible_directions[i]) < distance_to_direction:
			distance_to_direction = current_move_direction.distance_to(possible_directions[i])
			current_move_direction = possible_directions[i]

	velocity = current_move_direction * speed * delta

	last_move_direction = current_move_direction

	if ally_in_main_inner_area: velocity /= 1.5

func dash():
	dashing = true
	dash_cooldown_node.start(0.2)

# combat functions
func attack():
	attacking = true

	if is_current_main_player: attack_direction = (get_global_mouse_position() - position).normalized()
	else:
		var temp_enemy_health = 10000000000
		for enemy_node in ally_enemy_nodes_in_attack_area:
			if enemy_node.enemy_stats_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.enemy_stats_node.health
				attack_direction = (enemy_node.position - position).normalized()
		ally_attack_ready = false
		ally_attack_cooldown_node.start(randf_range(3, 4))
	
	attack_shape_node.set_target_position(attack_direction * 20)

	attack_cooldown_node.start(0.8)
	attack_shape_node.force_shapecast_update()

	var enemy_body = null
	if attack_shape_node.is_colliding():
		for collision_index in attack_shape_node.get_collision_count():
			enemy_body = attack_shape_node.get_collider(collision_index).get_parent()
			if dashing: enemy_body.take_damage(0, 50)
			else: enemy_body.take_damage(0, 20)

func choose_animation():
	if attacking:
		if abs(attack_direction.x) >= abs(attack_direction.y):
			if attack_direction.x > 0:
				animation_node.play("right_attack")
			else:
				animation_node.play("left_attack")
		elif attack_direction.y > 0:
			animation_node.play("front_attack")
		else:
			animation_node.play("back_attack")
	else:
		if moving:
			if current_move_direction.x > 0: animation_node.play("right_walk")
			elif current_move_direction.x < 0: animation_node.play("left_walk")
			elif current_move_direction.y > 0: animation_node.play("front_walk")
			else: animation_node.play("back_walk")
		else:
			if abs(last_move_direction.x) >= abs(last_move_direction.y):
				if last_move_direction.x > 0: animation_node.play("right_idle")
				else: animation_node.play("left_idle")
			elif last_move_direction.y > 0: animation_node.play("front_idle")
			else: animation_node.play("back_idle")

func _on_combat_hit_box_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if GlobalSettings.requesting_entities&&self in GlobalSettings.available_entities:
				GlobalSettings.chosen_entities.push_back(self)
				GlobalSettings.chosen_entities_count += 1
				if GlobalSettings.request_entities_count == GlobalSettings.chosen_entities_count:
					GlobalSettings.choose_entities()
			elif !is_current_main_player&&player_stats_node.alive:
				player_stats_node.update_main_player(player_index)

func _on_entities_detection_area_body_exited(body):
	if body == GlobalSettings.current_main_player_node&&player_stats_node.alive:
		position = body.position + Vector2((randf_range(15, 25) * ((randi() % 2) * 2 - 1)), (randf_range(15, 25) * ((randi() % 2) * 2 - 1)))
		ally_in_main_inner_area = true

func _on_inner_entities_detection_area_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		ally_in_main_inner_area = true
	elif body.has_method("choose_player"):
		ally_enemy_in_detection_area = true
		ally_enemy_nodes_in_detection_area.push_back(body)

func _on_inner_entities_detection_area_body_exited(body):
	if body == GlobalSettings.current_main_player_node&&!GlobalSettings.in_combat:
		ally_in_main_inner_area = false
	elif body.has_method("choose_player"):
		ally_enemy_nodes_in_detection_area.erase(body)
		if ally_enemy_nodes_in_detection_area.is_empty(): ally_enemy_in_detection_area = false

func _on_interaction_area_body_entered(body):
	# npc can be interacted
	if body.has_method("area_status"):
		body.area_status(true)
	# enemy is inside attack
	elif !is_current_main_player&&body.has_method("choose_player"):
		ally_enemy_nodes_in_attack_area.push_back(body)
		ally_enemy_in_attack_area = true
		
		velocity = Vector2(0, 0)
		moving = false
		ally_direction_ready = true

func _on_interaction_area_body_exited(body):
	# npc cannot be interacted
	if is_current_main_player:
		if body.has_method("area_status"):
			body.area_status(false)
	# enemy is outside attack area
	else:
		if body.has_method("choose_player"):
			ally_enemy_nodes_in_attack_area.erase(body)
			if ally_enemy_nodes_in_attack_area.is_empty(): ally_enemy_in_attack_area = false

func _on_attack_cooldown_timeout():
	attacking = false
	last_move_direction = attack_direction
	choose_animation()

func _on_dash_cooldown_timeout():
	dashing = false

func _on_ally_attack_cooldown_timeout():
	ally_attack_ready = true

func _on_ally_direction_cooldown_timeout():
	if !GlobalSettings.enemy_nodes_in_combat.is_empty():
		ally_pause_timer_node.start(randf_range(0.2, 0.4))
	elif ally_in_main_inner_area:
		ally_pause_timer_node.start(randf_range(1.5, 2))
	else:
		ally_pause_timer_node.start(randf_range(0.5, 0.8))
	velocity = Vector2(0, 0)
	moving = false

	choose_animation()

func _on_ally_pause_timer_timeout():
	ally_direction_ready = true

func _on_death_timer_timeout():
	animation_node.pause()
