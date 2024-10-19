extends CharacterBody2D

# node variables
@onready var player_stats_node := get_node_or_null("PlayerStatsComponent")
@onready var attack_shape_node := %AttackShape
@onready var navigation_agent_node := %NavigationAgent2D
@onready var obstacle_check_node := %ObstacleCheck

@onready var character_specifics_node := get_node_or_null("CharacterSpecifics")
@onready var animation_node := get_node_or_null("CharacterSpecifics/Animation")

# timer nodes
@onready var attack_cooldown_node := %AttackCooldown
@onready var dash_cooldown_node := %DashCooldown
@onready var ally_attack_cooldown_node := %AllyAttackCooldown
@onready var ally_direction_cooldown_node := %AllyDirectionCooldown
@onready var ally_pause_timer_node := %AllyPauseTimer
@onready var knockback_timer_node := %KnockbackTimer
@onready var death_timer_node := %DeathTimer

# speed variables
var speed := 7000.0
var ally_speed := 6000.0
var dash_speed := 30000.0
var temp_ally_speed := 6000.0
const sprint_multiplier := 1.25

enum direction_states {UP, DOWN, LEFT, RIGHT, UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT}
enum move_states {IDLE, WALK, DASH, SPRINT, KNOCKBACK}
enum attack_states {READY, ATTACK, WAIT}

var animation_strings := ["up_idle", "down_idle", "left_idle", "right_idle",
						  "up_walk", "down_walk", "left_walk", "right_walk",
						  "up_attack", "down_attack", "left_attack", "right_attack",
						  "death"]
var animation_index := 0

var current_face_direction := direction_states.UP:
	set(next_direction):
		current_face_direction = next_direction
		animation_index = current_face_direction
		if current_attack_state == attack_states.ATTACK: animation_index += 8
		elif current_move_state == move_states.IDLE: animation_index += 4
		elif current_move_state == move_states.KNOCKBACK: animation_index += 4 ## ### need to add knockback animation
		animation_node.play(animation_strings[animation_index])

var current_move_direction_2 := direction_states.UP:
	set(next_direction):
		if current_move_direction_2 == next_direction: return
		current_move_direction_2 = next_direction
		if current_move_direction_2 in [direction_states.UP_LEFT, direction_states.UP_RIGHT]:
			if current_face_direction == direction_states.UP: current_face_direction = direction_states.UP
			elif current_move_direction_2 == direction_states.UP_LEFT: current_face_direction = direction_states.LEFT
			else: current_face_direction = direction_states.RIGHT
		elif current_move_direction_2 in [direction_states.DOWN_LEFT, direction_states.DOWN_RIGHT]:
			if current_face_direction == direction_states.DOWN: current_face_direction = direction_states.DOWN
			elif current_move_direction_2 == direction_states.DOWN_LEFT: current_face_direction = direction_states.LEFT
			else: current_face_direction = direction_states.RIGHT
		else: current_face_direction = current_move_direction_2

var current_move_vectors := {
	direction_states.UP: Vector2(0, -1),
	direction_states.DOWN: Vector2(0, 1),
	direction_states.LEFT: Vector2(-1, 0),
	direction_states.RIGHT: Vector2(1, 0),
	direction_states.UP_LEFT: Vector2(-1, -1).normalized(),
	direction_states.UP_RIGHT: Vector2(1, -1).normalized(),
	direction_states.DOWN_LEFT: Vector2(-1, 1).normalized(),
	direction_states.DOWN_RIGHT: Vector2(1, 1).normalized()
}

var current_move_state := move_states.IDLE:
	set(next_move_state):
		if current_move_state == next_move_state: return
		current_move_state = next_move_state
		current_face_direction = current_face_direction
		if current_move_state == move_states.DASH:
			dash_cooldown_node.start(dash_time)
			player_stats_node.update_stamina(-dash_stamina_consumption)

var current_attack_state := attack_states.READY:
	set(next_attack_state):
		if current_attack_state == next_attack_state: return
		current_attack_state = next_attack_state
		if current_attack_state == attack_states.ATTACK:
			character_specifics_node.regular_attack()

# player node information variables
var is_current_main_player := false

# movement variables
var moving := false
var dashing := false
var dash_stamina_consumption := 35.0
var dash_time := 0.2
var sprinting := false
var sprinting_stamina_consumption := 0.8
var current_move_direction := Vector2.ZERO
var last_move_direction := Vector2.ZERO
const possible_directions: Array[Vector2] = [Vector2(1, 0), Vector2(0.7071, -0.7071), Vector2(0, -1), Vector2(-0.7071, -0.7071),
											 Vector2(-1, 0), Vector2(-0.7071, 0.7071), Vector2(0, 1), Vector2(0.7071, 0.7071)]

var walk_speed := 7000.0

# movement variables (allies)
var ally_direction_ready := true
var ray_cast_obstacles := true

# combat variables
var attacking := false
var attack_direction := Vector2.ZERO

# combat variables (allies)
var ally_attack_ready := true
var ally_enemy_in_attack_area := false
var ally_enemy_nodes_in_attack_area: Array[Node] = []
var ally_target_enemy_node: Node = null

# knockback variables
var taking_knockback := false
var knockback_direction := Vector2.ZERO
var knockback_weight := 0.0

# temporary variables
var temp_distance_to_main_player := 0.0
var temp_move_direction := Vector2.ZERO
var temp_possible_directions: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
var temp_comparator := 0.0

var attack_register := ""

func _ready():
	animation_node.play(animation_strings[0])
	
func _physics_process(delta):
	# movement inputs
	velocity = Input.get_vector("left", "right", "up", "down") * walk_speed * delta

	if velocity == Vector2.ZERO: current_move_state = move_states.IDLE

	match current_move_state:
		move_states.IDLE:
			pass
		move_states.WALK:
			pass
		move_states.DASH:
			velocity += current_move_vectors[current_move_direction_2] * dash_speed * delta * \
									(1 - (dash_time - dash_cooldown_node.get_time_left()) / dash_time)
		move_states.SPRINT:
			if player_stats_node.stamina > 0 && !player_stats_node.stamina_slow_recovery:
				player_stats_node.update_stamina(-sprinting_stamina_consumption)
				velocity *= sprint_multiplier
			else: current_move_state = move_states.WALK
		move_states.KNOCKBACK:
			velocity = knockback_direction * 200 * (1 - (0.4 - knockback_timer_node.get_time_left()) / 0.4) * knockback_weight

	if current_attack_state == attack_states.ATTACK: velocity /= 2

	if attack_register != "" && animation_node.get_frame() == 1: character_specifics_node.call(attack_register)

	move_and_slide()

func _input(_event):
	if current_move_state != move_states.DASH && Input.is_action_just_pressed("dash"): current_move_state = move_states.DASH
	if current_move_state != move_states.DASH && Input.is_action_just_released("dash"): current_move_state = move_states.DASH

func update_nodes():
	player_stats_node = get_node_or_null("PlayerStatsComponent")
	character_specifics_node = get_node_or_null("CharacterSpecifics")
	animation_node = get_node_or_null("CharacterSpecifics/Animation")

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
	temp_ally_speed = ally_speed

	if CombatEntitiesComponent.in_combat && !CombatEntitiesComponent.leaving_combat && temp_distance_to_main_player < 250:
		# distance to target
		temp_comparator = INF
		# evaluate enemy distances
		for enemy in CombatEntitiesComponent.enemy_nodes_in_combat:
			# target enemy with shortest distance
			if position.distance_to(enemy.position) < temp_comparator:
				temp_comparator = position.distance_to(enemy.position)
				ally_target_enemy_node = enemy
		
		if temp_comparator > 200 && temp_comparator > temp_distance_to_main_player:
			navigation_agent_node.target_position = GlobalSettings.current_main_player_node.position
		else:
			navigation_agent_node.target_position = ally_target_enemy_node.position

		current_move_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
		ally_direction_cooldown_node.start(randf_range(0.2, 0.4))
	elif temp_distance_to_main_player < 80:
		current_move_direction = possible_directions[randi() % 8]
		ally_direction_cooldown_node.start(randf_range(0.5, 0.7))
		temp_ally_speed /= 1.5
	else:
		navigation_agent_node.target_position = GlobalSettings.current_main_player_node.position
		current_move_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
		ally_direction_cooldown_node.start(randf_range(0.5, 0.7))

	if temp_distance_to_main_player > 200:
		temp_ally_speed *= (temp_distance_to_main_player / 200)
		if temp_distance_to_main_player > 300:
			temp_ally_speed = ally_speed * 2
	
	if GlobalSettings.current_main_player_node.sprinting && !CombatEntitiesComponent.in_combat && temp_distance_to_main_player > 120 && GlobalSettings.current_main_player_node.moving:
		temp_ally_speed = GlobalSettings.current_main_player_node.speed * sprint_multiplier

	# assume currently facing obstacle
	ray_cast_obstacles = true
	# each possible walk direction
	temp_possible_directions = [0, 1, 2, 3, 4, 5, 6, 7]
	temp_move_direction = current_move_direction

	# while facing obstacles
	while ray_cast_obstacles:
		# distance to target direction
		temp_comparator = INF
		
		# for each possible direction
		for i in temp_possible_directions:
			# if distance to snapped direction is shorter than current distance to snapped direction, set new snapped direction
			if current_move_direction.distance_to(possible_directions[i]) < temp_comparator:
				temp_comparator = current_move_direction.distance_to(possible_directions[i])
				temp_move_direction = possible_directions[i]

		current_move_direction = temp_move_direction

		# check for obstacles
		obstacle_check_node.set_target_position(current_move_direction * 20)
		obstacle_check_node.force_shapecast_update()

		# if facing obstacles
		if obstacle_check_node.is_colliding():
			# remove currently selected direction
			for i in temp_possible_directions:
				if current_move_direction == possible_directions[i]:
					temp_possible_directions.erase(i)
			
			if temp_possible_directions.is_empty():
				for i in 8:
					if current_move_direction.distance_to(possible_directions[i]) < temp_comparator:
						temp_comparator = current_move_direction.distance_to(possible_directions[i])
						temp_move_direction = possible_directions[i]
				current_move_direction = temp_move_direction

				ray_cast_obstacles = false
		else:
			ray_cast_obstacles = false

	velocity = current_move_direction * temp_ally_speed * delta

	last_move_direction = current_move_direction

	choose_animation()

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
		elif attack_direction.y < 0:
			animation_node.play("up_attack")
		else:
			animation_node.play("down_attack")
	else:
		if moving:
			if current_move_direction.x > 0: animation_node.play("right_walk")
			elif current_move_direction.x < 0: animation_node.play("left_walk")
			elif current_move_direction.y < 0: animation_node.play("up_walk")
			else: animation_node.play("down_walk")
		else:
			if abs(last_move_direction.x) >= abs(last_move_direction.y):
				if last_move_direction.x > 0: animation_node.play("right_idle")
				else: animation_node.play("left_idle")
			elif last_move_direction.y < 0: animation_node.play("up_idle")
			else: animation_node.play("down_idle")

func _on_combat_hit_box_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if CombatEntitiesComponent.requesting_entities && self in CombatEntitiesComponent.entities_available && !(self in CombatEntitiesComponent.entities_chosen):
				CombatEntitiesComponent.entities_chosen.push_back(self)
				CombatEntitiesComponent.entities_chosen_count += 1
				if CombatEntitiesComponent.entities_request_count == CombatEntitiesComponent.entities_chosen_count:
					CombatEntitiesComponent.choose_entities()
			elif !is_current_main_player && player_stats_node.alive:
				GlobalSettings.update_main_player(self)

func _on_interaction_area_body_entered(body):
	# npc can be interacted
	if is_current_main_player && body.has_method("area_status"):
		body.area_status(true)
	# enemy is inside attack
	elif !is_current_main_player && body.has_method("choose_player"):
		ally_enemy_nodes_in_attack_area.push_back(body)
		ally_enemy_in_attack_area = true
		
		velocity = Vector2.ZERO
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
	velocity = Vector2.ZERO
	moving = false

	if CombatEntitiesComponent.in_combat && !CombatEntitiesComponent.leaving_combat:
		ally_direction_ready = true
	else:
		if temp_distance_to_main_player < 70:
			ally_pause_timer_node.start(randf_range(1.5, 2))
		elif temp_distance_to_main_player < 100:
			ally_pause_timer_node.start(randf_range(0.7, 0.8))
		else:
			ally_direction_ready = true
	
	choose_animation()

func _on_ally_pause_timer_timeout():
	ally_direction_ready = true

func _on_knockback_timer_timeout():
	taking_knockback = false

func _on_death_timer_timeout():
	animation_node.pause()

func _on_combat_hit_box_area_mouse_entered():
	if CombatEntitiesComponent.requesting_entities:
		GlobalSettings.mouse_in_attack_area = false

func _on_combat_hit_box_area_mouse_exited():
	GlobalSettings.mouse_in_attack_area = true
