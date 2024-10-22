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
var enemy_nodes_in_attack_area := []

func _ready():
	animation_node.play(directions[current_face_direction][2])
	
func _physics_process(delta):
	if is_current_main_player:
		velocity = Input.get_vector("left", "right", "up", "down")
	else:
		pass

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

	if body.has_method("choose_player"):
		enemy_nodes_in_attack_area.push_back(body)
		current_move_state = MoveState.IDLE
		velocity = Vector2.ZERO
		ally_in_attack_position = true
		ally_can_move = true

func _on_interaction_area_body_exited(body):
	if is_current_main_player:
		if body.is_in_group("npcs"):
			body.interaction_area(false)

	if body.has_method("choose_player"):
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
	elif position.distance_to(GlobalSettings.current_main_player_node.position) < 70:
		ally_move_cooldown_node.start(randf_range(1.5, 2))
	elif position.distance_to(GlobalSettings.current_main_player_node.position) < 100:
		ally_move_cooldown_node.start(randf_range(0.7, 0.8))
	else:
		ally_can_move = true

func _on_ally_attack_cooldown_timeout():
	ally_can_attack = true
