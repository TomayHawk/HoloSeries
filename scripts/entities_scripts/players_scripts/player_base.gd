extends CharacterBody2D

@onready var player_stats_node := get_node_or_null("PlayerStatsComponent")
@onready var character_specifics_node := get_node_or_null("CharacterSpecifics")
@onready var animation_node := get_node_or_null("CharacterSpecifics/Animation")
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
	Vector2(0, 0): Direction.UP,
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
		if current_move_state == MoveState.IDLE: velocity = Vector2.ZERO
		if current_move_state != MoveState.DASH: return
		dash_timer_node.start(dash_time)
		player_stats_node.update_stamina(-dash_stamina_consumption)

enum AttackState {READY, ATTACK}
var current_attack_state := AttackState.READY:
	set(next_attack_state):
		if !player_stats_node.alive or current_attack_state == next_attack_state: return
		current_attack_state = next_attack_state
		if current_attack_state != AttackState.ATTACK: return
		character_specifics_node.regular_attack()
		attack_face_direction = Direction.UP if attack_direction.y < 0 else Direction.DOWN
		if abs(attack_direction.x) < abs(attack_direction.y): return
		attack_face_direction = Direction.LEFT if attack_direction.x < 0 else Direction.RIGHT
		current_face_direction = current_face_direction

# PlayerAlly
@onready var obstacle_check_node := %ObstacleCheck
@onready var navigation_agent_node := %NavigationAgent2D
@onready var ally_move_cooldown_node := %AllyMoveCooldown

var distance_to_main_player := 200.0
var ally_can_move := true
var temp_comparator := INF
var possible_directions: Array[Vector2] = [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, -1).normalized(), Vector2(1, -1).normalized(), Vector2(-1, 1).normalized(), Vector2(1, 1).normalized()]
var temp_direction := Vector2.ZERO
var snapped_direction := Vector2.ZERO

var enemy_nodes_in_attack_area: Array[Node] = []
var ally_can_attack := true
var target_enemy_node: Node = null
var ally_in_attack_position := false

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

			# target enemy with lowest health
			temp_comparator = INF
			for enemy_node in enemy_nodes_in_attack_area:
				if enemy_node.base_enemy_node.health < temp_comparator:
					temp_comparator = enemy_node.base_enemy_node.health
					target_enemy_node = enemy_node
			
			# attack if able
			if current_attack_state == AttackState.READY:
				current_attack_state = AttackState.ATTACK ## ### might have to change
			# else face towards enemy
			else:
				temp_direction = (target_enemy_node.position - position).normalized()
				if abs(temp_direction.x) < abs(temp_direction.y):
					if temp_direction.y < 0:
						current_face_direction = Direction.UP
					else:
						current_face_direction = Direction.DOWN
				elif temp_direction.x < 0:
					current_face_direction = Direction.LEFT
				else:
					current_face_direction = Direction.RIGHT
		# if ally can move
		elif ally_can_move and current_attack_state == AttackState.READY:
			ally_can_move = false

			if CombatEntitiesComponent.in_combat and !CombatEntitiesComponent.leaving_combat and distance_to_main_player < 250:
				# target enemy with shortest distance
				temp_comparator = INF
				for enemy_node in CombatEntitiesComponent.enemy_nodes_in_combat:
					if position.distance_to(enemy_node.position) < temp_comparator:
						temp_comparator = position.distance_to(enemy_node.position)
						target_enemy_node = enemy_node
				
				if temp_comparator > 200:
					navigation_agent_node.target_position = GlobalSettings.current_main_player_node.position
				else:
					navigation_agent_node.target_position = target_enemy_node.position

				temp_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
				ally_move_cooldown_node.start(randf_range(0.2, 0.4))
			elif distance_to_main_player < 80:
				temp_direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
				ally_move_cooldown_node.start(randf_range(0.5, 0.7))
				pass ## ### velocity /= 1.5
			else:
				navigation_agent_node.target_position = GlobalSettings.current_main_player_node.position
				temp_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
				ally_move_cooldown_node.start(randf_range(0.5, 0.7))

			if distance_to_main_player > 200:
				pass ## ### velocity *= (distance_to_main_player / 200)
				if distance_to_main_player > 300:
					pass ## ### velocity *= 2
			
			if GlobalSettings.current_main_player_node.current_move_state == MoveState.SPRINT and !CombatEntitiesComponent.in_combat and distance_to_main_player > 120:
				current_move_state = MoveState.SPRINT
			
			# snap to 8-way
			possible_directions = [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, -1).normalized(), Vector2(1, -1).normalized(), Vector2(-1, 1).normalized(), Vector2(1, 1).normalized()]
			for direction in possible_directions:
				if temp_direction.distance_to(direction) < 0.390180645:
					snapped_direction = direction
					break

			# check for obstacles
			while true:
				obstacle_check_node.set_target_position(snapped_direction * 8)
				obstacle_check_node.force_shapecast_update()

				if obstacle_check_node.is_colliding():
					possible_directions.erase(snapped_direction)
					if possible_directions.is_empty():
						current_move_state = MoveState.IDLE
						velocity = snapped_direction
						current_move_direction = directions[velocity]
						break
					# find next closest direction
					temp_comparator = INF
					for direction in possible_directions:
						if temp_direction.distance_to(direction) < temp_comparator:
							temp_comparator = temp_direction.distance_to(direction)
							snapped_direction = direction
				else:
					velocity = snapped_direction
					current_move_direction = directions[velocity]
					break
		else:
			##### need to fix this
			velocity = velocity.normalized()
			possible_directions = [Vector2(-1, -1).normalized(), Vector2(1, -1).normalized(), Vector2(-1, 1).normalized(), Vector2(1, 1).normalized()]
			for direction in possible_directions:
				if velocity.distance_to(direction) < 0.390180645:
					velocity = direction
					##### print("this")
					break

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
	if !is_current_main_player: return
	
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

	if CombatEntitiesComponent.in_combat and !CombatEntitiesComponent.leaving_combat:
		ally_can_move = true
	elif distance_to_main_player < 70:
		ally_move_cooldown_node.start(randf_range(1.5, 2))
	elif distance_to_main_player < 100:
		ally_move_cooldown_node.start(randf_range(0.7, 0.8))
	else:
		ally_can_move = true

func _on_ally_attack_cooldown_timeout():
	current_attack_state = AttackState.READY ## ### need to change CharacterSpecifics and Attacks for Allies
