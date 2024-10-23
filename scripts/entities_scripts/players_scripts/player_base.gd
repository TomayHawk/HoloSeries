extends CharacterBody2D

@onready var player_stats_node := get_node_or_null("PlayerStatsComponent")
@onready var character_specifics_node := get_node_or_null("CharacterSpecifics")
@onready var animation_node := get_node_or_null("CharacterSpecifics/Animation")
@onready var player_ally_node := %PlayerAlly
@onready var attack_shape_node := %AttackShape
@onready var dash_timer_node := %DashTimer
@onready var knockback_timer_node := %KnockbackTimer
@onready var death_timer_node := %DeathTimer

# player variables
var is_current_main_player := false
var walk_speed := 7000.0
var dash_multiplier := 4.25
var dash_time := 0.2
var dash_stamina_consumption := 35.0
var sprint_multiplier := 1.25
var sprinting_stamina_consumption := 0.8
var attack_direction := Vector2.ZERO
var attack_register := ""
var knockback_direction := Vector2.ZERO
var knockback_weight := 0.0

enum Direction {UP, DOWN, LEFT, RIGHT, UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT}

var directions := {
	Direction.UP: [Direction.UP, Vector2(0, -1), "up_idle", "up_walk", "up_attack"],
	Direction.DOWN: [Direction.DOWN, Vector2(0, 1), "down_idle", "down_walk", "down_attack"],
	Direction.LEFT: [Direction.LEFT, Vector2(-1, 0), "left_idle", "left_walk", "left_attack"],
	Direction.RIGHT: [Direction.RIGHT, Vector2(1, 0), "right_idle", "right_walk", "right_attack"],
	Direction.UP_LEFT: [Direction.LEFT, Vector2(-1, -1).normalized(), "left_idle", "left_walk", "left_attack"],
	Direction.UP_RIGHT: [Direction.RIGHT, Vector2(1, -1).normalized(), "left_idle", "left_walk", "left_attack"],
	Direction.DOWN_LEFT: [Direction.LEFT, Vector2(-1, 1).normalized(), "right_idle", "right_walk", "right_attack"],
	Direction.DOWN_RIGHT: [Direction.RIGHT, Vector2(1, 1).normalized(), "right_idle", "right_walk", "right_attack"],
	Vector2(0, -1): Direction.UP,
	Vector2(0, 1): Direction.DOWN,
	Vector2(-1, 0): Direction.LEFT,
	Vector2(1, 0): Direction.RIGHT,
	Vector2(-1, -1).normalized(): Direction.UP_LEFT,
	Vector2(1, -1).normalized(): Direction.UP_RIGHT,
	Vector2(-1, 1).normalized(): Direction.DOWN_LEFT,
	Vector2(1, 1).normalized(): Direction.DOWN_RIGHT
}

var current_face_direction := Direction.UP:
	set(next_direction):
		if !player_stats_node.alive: return
		current_face_direction = next_direction
		if current_move_state == MoveState.KNOCKBACK: return
		elif current_attack_state == AttackState.ATTACK:
			print(attack_face_direction)
			animation_node.play(directions[attack_face_direction][4])
		elif current_move_state == MoveState.IDLE: animation_node.play(directions[current_face_direction][2])
		else: animation_node.play(directions[current_face_direction][3])
var attack_face_direction := Direction.UP

var current_move_direction := Direction.UP:
	set(next_direction):
		if !player_stats_node.alive: return
		current_move_direction = next_direction
		if current_move_state == MoveState.IDLE: current_move_state = MoveState.WALK
		current_face_direction = directions[current_move_direction][0]

enum MoveState {IDLE, WALK, DASH, SPRINT, KNOCKBACK}
var current_move_state := MoveState.IDLE:
	set(next_move_state):
		if !player_stats_node.alive: return
		current_move_state = next_move_state
		current_face_direction = current_face_direction
		if current_move_state != MoveState.DASH: return
		dash_timer_node.start(dash_time)
		player_stats_node.update_stamina(-dash_stamina_consumption)

enum AttackState {READY, ATTACK, WAIT}
var current_attack_state := AttackState.READY:
	set(next_attack_state):
		if !player_stats_node.alive or current_attack_state == next_attack_state: return
		current_attack_state = next_attack_state
		if current_attack_state != AttackState.ATTACK: return
		character_specifics_node.regular_attack()
		print(attack_face_direction)
		attack_face_direction = Direction.UP if attack_direction.y < 0 else Direction.DOWN
		if abs(attack_direction.x) < abs(attack_direction.y): return
		attack_face_direction = Direction.LEFT if attack_direction.x < 0 else Direction.RIGHT
		current_face_direction = current_face_direction

# PlayerAlly
@onready var obstacle_check_node := %ObstacleCheck
@onready var navigation_agent_node := %NavigationAgent2D
@onready var ally_move_cooldown_node := %AllyMoveCooldown

var ally_can_move := true
var ally_can_attack := true
var ally_in_attack_position := true

var target_enemy_node: Node = null
var enemy_nodes_in_attack_area: Array[Node] = []

var distance_to_main_player := 200.0
var temp_comparator := INF
var enemy_direction := Vector2.ZERO

'''
#####
var ally_speed := 6000.0

var ally_direction_ready := true
var ray_cast_obstacles := true

# combat variables (allies)
var ally_attack_ready := true

# temporary variables
var temp_ally_speed := 6000.0

var temp_move_direction := Vector2.ZERO
var temp_possible_directions: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
'''

func _ready():
	animation_node.play(directions[current_face_direction][2])
	
func _physics_process(delta):
	if is_current_main_player:
		velocity = Input.get_vector("left", "right", "up", "down")
	else:
		distance_to_main_player = position.distance_to(GlobalSettings.current_main_player_node.position)

		# if ally in combat
		if ally_in_attack_position and distance_to_main_player < 250:
			# pause movement
			current_move_state = MoveState.IDLE
			velocity = Vector2.ZERO

			# target enemy with lowest health
			temp_comparator = INF
			for enemy_node in enemy_nodes_in_attack_area:
				if enemy_node.base_enemy_node.health < temp_comparator:
					temp_comparator = enemy_node.base_enemy_node.health
					target_enemy_node = enemy_node
			
			# attack if able
			if ally_can_attack:
				current_attack_state = AttackState.ATTACK ## ### might have to change
			# else face towards enemy
			else:
				enemy_direction = (target_enemy_node.position - position).normalized()
				if abs(enemy_direction.x) < abs(enemy_direction.y):
					if enemy_direction.y < 0:
						current_face_direction = Direction.UP
					else:
						current_face_direction = Direction.DOWN
				elif enemy_direction.x < 0:
					current_face_direction = Direction.LEFT
				else:
					current_face_direction = Direction.RIGHT

		# if ally can move
		elif ally_direction_ready and !attacking:
			ally_direction_ready = false
			# moving = true
			temp_ally_speed = ally_speed

			if CombatEntitiesComponent.in_combat and !CombatEntitiesComponent.leaving_combat and distance_to_main_player < 250:
				# distance to target
				temp_comparator = INF
				# evaluate enemy distances
				for enemy in CombatEntitiesComponent.enemy_nodes_in_combat:
					# target enemy with shortest distance
					if position.distance_to(enemy.position) < temp_comparator:
						temp_comparator = position.distance_to(enemy.position)
						ally_target_enemy_node = enemy
				
				if temp_comparator > 200 and temp_comparator > distance_to_main_player:
					navigation_agent_node.target_position = GlobalSettings.current_main_position
				else:
					navigation_agent_node.target_position = ally_target_enemy_node.position

				current_move_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
				ally_direction_cooldown_node.start(randf_range(0.2, 0.4))
			elif distance_to_main_player < 80:
				current_move_direction = possible_directions[randi() % 8]
				ally_direction_cooldown_node.start(randf_range(0.5, 0.7))
				temp_ally_speed /= 1.5
			else:
				navigation_agent_node.target_position = GlobalSettings.current_main_position
				current_move_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
				ally_direction_cooldown_node.start(randf_range(0.5, 0.7))

			if distance_to_main_player > 200:
				temp_ally_speed *= (distance_to_main_player / 200)
				if distance_to_main_player > 300:
					temp_ally_speed = ally_speed * 2
			
			if GlobalSettings.current_main_sprinting and !CombatEntitiesComponent.in_combat and distance_to_main_player > 120 and GlobalSettings.current_main_moving:
				temp_ally_speed = GlobalSettings.current_main_speed * sprint_multiplier

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

			current_move_direction = directions[velocity]

			current_face_direction = current_face_direction

	# update states and animations
	if velocity == Vector2.ZERO:
		if current_move_state not in [MoveState.IDLE, MoveState.KNOCKBACK]:
			current_move_state = MoveState.IDLE
	elif current_move_direction != directions[velocity] or current_move_state == MoveState.IDLE:
		current_move_direction = directions[velocity]
	
	# update velocity
	velocity *= walk_speed * delta

	match current_move_state:
		MoveState.KNOCKBACK:
			velocity = knockback_direction * 200 * (1 - (0.4 - knockback_timer_node.get_time_left()) / 0.4) * knockback_weight
		MoveState.DASH:
			velocity *= dash_multiplier * (1 - (dash_time - dash_timer_node.get_time_left()) / dash_time)
		MoveState.SPRINT:
			velocity *= sprint_multiplier
			player_stats_node.update_stamina(-sprinting_stamina_consumption)

	if current_attack_state == AttackState.ATTACK:
		velocity /= 2

	# attack register if attacking
	if attack_register != "" and animation_node.get_frame() == 1:
		character_specifics_node.call(attack_register)

	# move
	move_and_slide()

func _input(_event):
	if Input.is_action_just_pressed("dash") and player_stats_node.stamina > 25.0 and !player_stats_node.stamina_slow_recovery:
		current_move_state = MoveState.DASH
	elif Input.is_action_just_released("dash") and current_move_state == MoveState.DASH:
		current_move_state = MoveState.WALK

func update_nodes():
	player_stats_node = get_node_or_null("PlayerStatsComponent")
	character_specifics_node = get_node_or_null("CharacterSpecifics")
	animation_node = get_node_or_null("CharacterSpecifics/Animation")

func _on_combat_hit_box_area_input_event(_viewport, _event, _shape_idx):
	if Input.is_action_just_pressed("action"):
		CombatEntitiesComponent.choose_entity(self, !is_current_main_player, player_stats_node.alive)

func _on_combat_hit_box_area_mouse_entered():
	if CombatEntitiesComponent.requesting_entities:
		GlobalSettings.mouse_in_attack_area = false

func _on_combat_hit_box_area_mouse_exited():
	GlobalSettings.mouse_in_attack_area = true

func _on_interaction_area_body_entered(body):
	if is_current_main_player:
		if body.is_in_group("npcs"):
			body.interaction_area(true)

	if body.is_in_group("enemies"):
		enemy_nodes_in_attack_area.push_back(body)
		current_move_state = MoveState.IDLE
		velocity = Vector2.ZERO
		ally_in_attack_position = true
		ally_can_move = true

func _on_interaction_area_body_exited(body):
	if is_current_main_player:
		if body.is_in_group("npcs"):
			body.interaction_area(false)

	if body.is_in_group("enemies"):
		enemy_nodes_in_attack_area.erase(body)
		if enemy_nodes_in_attack_area.is_empty():
			ally_in_attack_position = false

func _on_attack_timer_timeout():
	current_attack_state = AttackState.READY

func _on_knockback_timer_timeout():
	if Input.get_vector("left", "right", "up", "down") != Vector2.ZERO:
		current_move_state = MoveState.WALK
	else:
		current_move_state = MoveState.IDLE

func _on_dash_timer_timeout():
	if Input.is_action_pressed("dash"):
		current_move_state = MoveState.SPRINT
	else:
		current_move_state = MoveState.WALK

func _on_death_timer_timeout():
	animation_node.pause()

# PlayerAlly
func _on_ally_move_cooldown_timeout():
	current_move_state = MoveState.IDLE
	velocity = Vector2.ZERO

	if CombatEntitiesComponent.in_combat and !CombatEntitiesComponent.leaving_combat:
		ally_can_move = true
	elif distance_to_main_player < 70:
		ally_move_cooldown_node.start(randf_range(1.5, 2))
	elif distance_to_main_player < 100:
		ally_move_cooldown_node.start(randf_range(0.7, 0.8))
	else:
		ally_can_move = true

func _on_ally_attack_cooldown_timeout():
	ally_can_attack = true
