extends CharacterBody2D

# node variables
@onready var player_stats_node := get_node("PlayerStatsComponent")
@onready var attack_shape_node := $AttackShape
@onready var navigation_agent_node := $NavigationAgent2D
@onready var obstacle_check_node := $ObstacleCheck

@onready var character_specifics_node := get_node("CharacterSpecifics")
@onready var animation_node := get_node("CharacterSpecifics/Animation")

# timer nodes
@onready var attack_cooldown_node := $AttackCooldown
@onready var dash_cooldown_node := $DashCooldown
@onready var death_timer_node := $DeathTimer

# speed variables
var speed := 7000.0
var dash_speed := 30000.0
const sprint_multiplier := 1.25

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
# movement variables (player)


# combat variables
var attacking := false
var attack_direction := Vector2.ZERO
# combat variables (player)

# knockback variables
var taking_knockback := false
var knockback_direction := Vector2.ZERO
var knockback_weight := 0.0
	
func _physics_process(_delta):
	# if player
	if is_current_main_player:
		# attack
		if !attacking && GlobalSettings.can_attempt_attack:
			pass
			##### attack()

		# dash / sprint
		if player_stats_node.stamina > 0 && !player_stats_node.stamina_slow_recovery:
			# dash
			if Input.is_action_just_pressed("dash") && !dashing:
				player_stats_node.update_stamina(-dash_stamina_consumption)
				##### dash()
			# sprint
			elif Input.is_action_pressed("dash"):
				player_stats_node.update_stamina(-sprinting_stamina_consumption)
				sprinting = true
			elif sprinting:
				sprinting = false
		else: sprinting = false

		##### player_movement(delta)

	if taking_knockback:
		velocity = knockback_direction * 200 * (1 - (0.4 - $KnockbackTimer.get_time_left()) / 0.4) * knockback_weight

	move_and_slide()

func movement(delta):
	# movement inputs
	current_move_direction = Input.get_vector("left", "right", "up", "down")
	velocity = current_move_direction * speed * delta
	
	if velocity != Vector2.ZERO:
		moving = true
		last_move_direction = current_move_direction
	else: moving = false

	##### choose_animation()

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

func _on_combat_hit_box_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if GlobalSettings.requesting_entities && self in GlobalSettings.entities_available && !(self in GlobalSettings.entities_chosen):
				GlobalSettings.entities_chosen.push_back(self)
				GlobalSettings.entities_chosen_count += 1
				if GlobalSettings.entities_request_count == GlobalSettings.entities_chosen_count:
					GlobalSettings.choose_entities()

func _on_interaction_area_body_entered(body):
	# npc can be interacted
	if body.has_method("area_status"):
		body.area_status(true)

func _on_interaction_area_body_exited(body):
	# npc cannot be interacted
	if body.has_method("area_status"):
		body.area_status(false)

func _on_attack_cooldown_timeout():
	attacking = false
	last_move_direction = attack_direction
	##### choose_animation()
