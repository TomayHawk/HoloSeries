extends CharacterBody2D

# node variables
@onready var player_stats_node = $PlayerStatsComponent
@onready var attack_shape_node = $AttackShape
@onready var navigation_agent_node = $NavigationAgent2D
@onready var obstacle_check_node = $ObstacleCheck

@onready var character_specifics_node = $CharacterSpecifics
@onready var animation_node = $CharacterSpecifics/Animation

# timer nodes
@onready var attack_cooldown_node = $AttackCooldown
@onready var dash_cooldown_node = $DashCooldown
@onready var ally_attack_cooldown_node = $AllyAttackCooldown
@onready var ally_direction_cooldown_node = $AllyDirectionCooldown
@onready var ally_idle_cooldown_node = $AllyIdleCooldown
@onready var ally_pause_timer_node = $AllyPauseTimer
@onready var death_timer_node = $DeathTimer

# speed variables
var speed = 10000
var ally_speed = 6000
var dash_speed = 30000
var sprint_multiplier = 1.25

# player node information variables
var party_index = 0
var character_index = 0
var is_current_main_player = false

# ally variables
var ally_in_main_detection_area = false
var ally_in_main_inner_area = false

# movement variables
var moving = false
var dashing = false
var dash_stamina_consumption = 35
var dash_time = 0.2
var sprinting = false
var sprinting_stamina_consumption = 0.8
var current_move_direction = Vector2.ZERO
var last_move_direction = Vector2.ZERO
var possible_directions = [Vector2(1, 0), Vector2(0.7071, -0.7071), Vector2(0, -1), Vector2( - 0.7071, -0.7071),
						   Vector2( - 1, 0), Vector2( - 0.7071, 0.7071), Vector2(0, 1), Vector2(0.7071, 0.7071)]
# movement variables (player)
# movement variables (allies)
var ally_direction_ready = true
var ray_cast_obstacles = true

# combat variables
var attacking = false
var attack_direction = Vector2.ZERO
# combat variables (player)
# combat variables (allies)
var ally_attack_ready = true
var ally_enemy_in_attack_area = false
var ally_enemy_nodes_in_attack_area = []
var ally_target_enemy_node = null

# knockback variables
var taking_knockback = false
var knockback_direction = Vector2.ZERO
var knockback_weight = 0.0

func _ready():
	var i = 0
	for party_player_node in GlobalSettings.party_player_nodes:
		if self == party_player_node:
			party_index = i
			break
		i += 1

	animation_node.play("front_idle")
	
func _physics_process(delta):
	# if player
	if is_current_main_player:
		# attack
		if !attacking&&GlobalSettings.player_can_attack:
			attack()

		# dash / sprint
		if player_stats_node.stamina > 0&&!player_stats_node.stamina_slow_recovery:
			# dash
			if Input.is_action_just_pressed("dash")&&!dashing:
				player_stats_node.stamina -= dash_stamina_consumption
				dash()
			# sprint
			elif Input.is_action_pressed("dash"):
				player_stats_node.stamina -= sprinting_stamina_consumption
				sprinting = true
			elif sprinting:
				sprinting = false
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
	elif ally_direction_ready&&!attacking: ally_movement(delta)

	if taking_knockback:
		velocity = knockback_direction * 200 * (1 - (0.4 - $KnockbackTimer.get_time_left()) / 0.4) * knockback_weight

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
			velocity += current_move_direction * dash_speed * delta * (1 - (dash_time - dash_cooldown_node.get_time_left()) / dash_time)
		else:
			moving = true
			velocity = last_move_direction * dash_speed * delta * (1 - (dash_time - dash_cooldown_node.get_time_left()) / dash_time)
	# sprint
	elif sprinting: velocity *= sprint_multiplier

	# if attacking, reduce speed
	if attacking: velocity /= 2

func ally_movement(delta):
	ally_direction_ready = false
	moving = true

	if GlobalSettings.in_combat&&!GlobalSettings.leaving_combat:
		var distance_to_enemy = 10000
		# evaluate enemy distances
		for enemy in GlobalSettings.enemy_nodes_in_combat:
			# target enemy with shortest distance
			if position.distance_to(enemy.position) < distance_to_enemy:
				distance_to_enemy = position.distance_to(enemy.position)
				ally_target_enemy_node = enemy

		navigation_agent_node.target_position = ally_target_enemy_node.position
		current_move_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
		ally_direction_cooldown_node.start(randf_range(0.2, 0.4))

	elif ally_in_main_inner_area:
		current_move_direction = possible_directions[randi() % 8]
		ally_direction_cooldown_node.start(randf_range(0.5, 0.7))
	else:
		navigation_agent_node.target_position = GlobalSettings.current_main_player_node.position
		current_move_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
		ally_direction_cooldown_node.start(randf_range(0.5, 0.7))

	# assume currently facing obstacle
	ray_cast_obstacles = true
	# each possible walk direction
	var directions = [0, 1, 2, 3, 4, 5, 6, 7]
	var originally_selected_direction = current_move_direction
	var temp_snapped = Vector2.ZERO

	# while facing obstacles
	while ray_cast_obstacles:
		var distance_to_direction = INF
		
		# for each possible direction
		for i in directions:
			# if distance to snapped direction is shorter than current distance to snapped direction, set new snapped direction
			if originally_selected_direction.distance_to(possible_directions[i]) < distance_to_direction:
				distance_to_direction = originally_selected_direction.distance_to(possible_directions[i])
				temp_snapped = possible_directions[i]

		current_move_direction = temp_snapped

		# check for obstacles
		obstacle_check_node.set_target_position(current_move_direction * 20)
		obstacle_check_node.force_shapecast_update()

		# if facing obstacles
		if obstacle_check_node.is_colliding():
			# remove currently selected direction
			for i in directions:
				if current_move_direction == possible_directions[i]:
					directions.erase(i)
			
			if directions.is_empty():
				for i in 8:
					if originally_selected_direction.distance_to(possible_directions[i]) < distance_to_direction:
						distance_to_direction = originally_selected_direction.distance_to(possible_directions[i])
						temp_snapped = possible_directions[i]
				current_move_direction = temp_snapped

				ray_cast_obstacles = false
		else:
			ray_cast_obstacles = false

	velocity = current_move_direction * ally_speed * delta

	last_move_direction = current_move_direction

	choose_animation()

	if !GlobalSettings.in_combat:
		if ally_in_main_inner_area: velocity /= 1.5
		elif ally_in_main_detection_area: velocity /= 1.25

func reset_variables():
	var i = 0
	for party_player_node in GlobalSettings.party_player_nodes:
		if self == party_player_node:
			party_index = i
			break
		i += 1

	is_current_main_player = self == GlobalSettings.current_main_player_node

	moving = false
	dashing = false
	sprinting = false
	current_move_direction = Vector2.ZERO
	last_move_direction = Vector2.ZERO

	attacking = false
	attack_direction = Vector2.ZERO

	ally_attack_ready = true
	ally_target_enemy_node = null

	attack_cooldown_node.stop()
	ally_attack_cooldown_node.stop()
	ally_direction_cooldown_node.stop()
	death_timer_node.stop()

	velocity = Vector2.ZERO
	choose_animation()

	ally_direction_ready = false
	ally_pause_timer_node.start(randf_range(0.2, 0.5))

func dash():
	dashing = true
	dash_cooldown_node.start(dash_time)

# combat functions
func attack():
	attacking = true
	character_specifics_node.regular_attack()

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
			if GlobalSettings.requesting_entities&&self in GlobalSettings.entities_available&&!(self in GlobalSettings.entities_chosen):
				GlobalSettings.entities_chosen.push_back(self)
				GlobalSettings.entities_chosen_count += 1
				if GlobalSettings.entities_request_count == GlobalSettings.entities_chosen_count:
					GlobalSettings.choose_entities()
			elif !is_current_main_player&&player_stats_node.alive:
				GlobalSettings.update_main_player(self)

func _on_outer_entities_detection_area_body_exited(body):
	if body == GlobalSettings.current_main_player_node&&player_stats_node.alive:
		position = body.position + Vector2((randf_range(15, 25) * ((randi() % 2) * 2 - 1)), (randf_range(15, 25) * ((randi() % 2) * 2 - 1)))
		ally_in_main_inner_area = true

func _on_entities_detection_area_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		ally_in_main_detection_area = true

func _on_entities_detection_area_body_exited(body):
	if body == GlobalSettings.current_main_player_node:
		ally_in_main_detection_area = false

func _on_inner_entities_detection_area_body_entered(body):
	if body == GlobalSettings.current_main_player_node:
		ally_idle_cooldown_node.stop()
		ally_in_main_inner_area = true

func _on_inner_entities_detection_area_body_exited(body):
	if body == GlobalSettings.current_main_player_node:
		if ally_idle_cooldown_node.is_inside_tree():
			ally_idle_cooldown_node.start(1.5)

func _on_interaction_area_body_entered(body):
	# npc can be interacted
	if is_current_main_player&&body.has_method("area_status"):
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
	if GlobalSettings.in_combat&&!GlobalSettings.leaving_combat:
		ally_direction_ready = true
	else:
		if ally_in_main_inner_area:
			ally_pause_timer_node.start(randf_range(1.5, 2))
		else:
			ally_direction_ready = true
		velocity = Vector2(0, 0)
		moving = false
	
	choose_animation()

func _on_ally_idle_cooldown_timeout():
	ally_in_main_inner_area = false

func _on_ally_pause_timer_timeout():
	ally_direction_ready = true

func _on_knockback_timer_timeout():
	taking_knockback = false

func _on_death_timer_timeout():
	animation_node.pause()

func _on_combat_hit_box_area_mouse_entered():
	if GlobalSettings.requesting_entities:
		GlobalSettings.mouse_in_attack_area = false

func _on_combat_hit_box_area_mouse_exited():
	GlobalSettings.mouse_in_attack_area = true
