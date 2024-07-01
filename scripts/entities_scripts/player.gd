extends CharacterBody2D

# node variables
@onready var current_player_node = GlobalSettings.players[GlobalSettings.current_main_player]
@onready var player_stats_node = $PlayerStatsComponent
@onready var attack_shape_node = $AttackShape
@onready var animation_node = $Animation
@onready var combat_ui_node = get_parent().get_node("CombatUI")
# timer nodes
@onready var attack_cooldown_node = $AttackCooldown
@onready var dash_cooldown_node = $DashCooldown
@onready var ally_attack_cooldown_node = $AllyAttackCooldown
@onready var ally_direction_cooldown_node = $AllyDirectionCooldown
@onready var ally_pause_timer_node = $AllyPauseTimer

# speed variables
var speed = 1200
var dash_speed = 500
var sprint_multiplier = 1.5

# player node information variables
var player_index = 0
var is_current_main_player = false

# ally variables
var close_to_current_main_player = false

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
	player_stats_node.stamina = player_stats_node.max_stamina
	player_stats_node.stamina_slow_recovery = false
	dashing = false

func _physics_process(delta):
	# if player
	if is_current_main_player:
		# attack
		if !attacking&&GlobalSettings.player_attack: attack()

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
			if enemy.get_node("EnemiesHealthComponent").health < target_enemy_health:
				target_enemy_health = enemy.get_node("EnemiesHealthComponent").health
				ally_target_enemy_node = enemy

		attack_direction = (ally_target_enemy_node.position - position).normalized()
		if ally_attack_ready: attack()

		choose_animation()
	# if ally can move
	elif ally_direction_ready: ally_movement(delta)
	
	if velocity != Vector2.ZERO: last_move_direction = current_move_direction

	move_and_slide()

# movement functions
func player_movement(delta):
	# movement inputs
	current_move_direction = Input.get_vector("left", "right", "up", "down")
	velocity = current_move_direction * speed * delta
	
	if velocity != Vector2.ZERO: moving = true
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

	if GlobalSettings.in_combat:
		var distance_to_enemy = 10000
		var target_enemies = []

		# determine enemies to evaluate
		if ally_enemy_in_detection_area: target_enemies = ally_enemy_nodes_in_detection_area
		else: target_enemies = GlobalSettings.enemies_in_combat

		# evaluate enemy distances
		for enemy in target_enemies:
			# target enemy with shortest distance
			if position.distance_to(enemy.position) < distance_to_enemy:
				distance_to_enemy = position.distance_to(enemy.position)
				ally_target_enemy_node = enemy
	elif close_to_current_main_player:
		current_move_direction = possible_directions[randi() % 8]
	else:
		current_move_direction = (current_player_node.position - position).normalized()
	
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
	if close_to_current_main_player: velocity /= 1.5

	ally_direction_cooldown_node.start(randf_range(0.3, 0.5))

func dash():
	dashing = true
	dash_cooldown_node.start(0.2)

# combat functions
func attack():
	attacking = true

	if is_current_main_player: attack_direction = (get_global_mouse_position() - position).normalized()
	else:
		ally_attack_ready = false
		ally_attack_cooldown_node.start(randf_range(3, 4))
	
	attack_shape_node.set_target_position(attack_direction * 20)

	attack_cooldown_node.start(0.8)
	attack_shape_node.force_shapecast_update()

	var enemy_body = null
	if attack_shape_node.is_colliding():
		for collider_index in attack_shape_node.get_collider_count():
			enemy_body = attack_shape_node.get_collider(collider_index).get_parent()
			if dashing: enemy_body.take_damage(0, 50)
			else: enemy_body.take_damage(0, 20)

func choose_animation():
	if attacking:
		if attack_direction.x > 0: animation_node.play("right_attack")
		elif attack_direction.x < 0: animation_node.play("left_attack")
		elif attack_direction.y > 0: animation_node.play("front_attack")
		else: animation_node.play("back_attack")
	else:
		if moving:
			if current_move_direction.x > 0: animation_node.play("right_walk")
			elif current_move_direction.x < 0: animation_node.play("left_walk")
			elif current_move_direction.y > 0: animation_node.play("front_walk")
			else: animation_node.play("back_walk")
		else:
			var face_direction = null
			if ally_enemy_in_attack_area: face_direction = attack_direction
			else: face_direction = last_move_direction
			if face_direction.x > 0: animation_node.play("right_idle")
			elif face_direction.x < 0: animation_node.play("left_idle")
			elif face_direction.y > 0: animation_node.play("front_idle")
			else: animation_node.play("back_idle")

func _on_combat_hit_box_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if combat_ui_node.choosing_player:
				combat_ui_node.choose_player(self)
			elif !is_current_main_player&&player_stats_node.alive:
				player_stats_node.update_main_player(player_index)

func _on_entities_detection_area_body_exited(body):
	if !is_current_main_player&&body == current_player_node&&player_stats_node.alive:
		position = body.position + Vector2(20 + (10 * randf_range(0, 1)), 20 + (10 * randf_range(0, 1)))
		close_to_current_main_player = true

func _on_inner_entities_detection_area_body_entered(body):
	if !is_current_main_player&&body == current_player_node:
		close_to_current_main_player = true

func _on_inner_entities_detection_area_body_exited(body):
	if !is_current_main_player&&body == current_player_node&&!GlobalSettings.in_combat:
		if $PauseTimer.is_inside_tree():
			$PauseTimer.start(0.5)
		is_current_main_player = false

func _on_interaction_area_body_entered(body):
	# npc can be interacted
	if body.has_method("area_status"):
		body.area_status(true)
	# enemy is inside attack
	elif !is_current_main_player&&body.has_method("choose_player"):
		ally_enemy_nodes_in_attack_area.push_back(body)
		ally_enemy_in_attack_area = true

func _on_interaction_area_body_exited(body):
	# npc cannot be interacted
	if body.has_method("area_status"):
		body.area_status(false)
	# enemy is outside attack area
	elif !is_current_main_player&&body.has_method("choose_player"):
		ally_enemy_nodes_in_attack_area.erase(body)
		if ally_enemy_nodes_in_attack_area.is_empty(): ally_enemy_in_attack_area = false

func _on_attack_cooldown_timeout():
	attacking = false

func _on_dash_cooldown_timeout():
	dashing = false

func _on_ally_attack_cooldown_timeout():
	if close_to_current_main_player:
		ally_direction_ready = false
		ally_pause_timer_node.start(randf_range(2, 3))
	else:
		ally_direction_ready = true

func _on_ally_direction_cooldown_timeout():
	velocity = Vector2(0, 0)

func _on_ally_pause_timer_timeout():
	ally_direction_ready = true

func _on_death_timer_timeout():
	animation_node.pause()
