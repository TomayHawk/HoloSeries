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
var ally_speed := 6000.0
var temp_ally_speed := 6000.0
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

# temporary variables
var temp_distance_to_main_player := 0.0
var temp_move_direction := Vector2.ZERO
var temp_possible_directions: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
var temp_comparator := 0.0

func _ready():
	animation_node.play("front_idle")

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
			if current_move_direction.x > 0: animation_node.pla("right_walk")
			elif current_move_direction.x < 0: animation_node.play("left_walk")
			elif current_move_direction.y > 0: animation_node.play("front_walk")
			else: animation_node.play("back_walk")
		else:
			if abs(last_move_direction.x) >= abs(last_move_direction.y):
				if last_move_direction.x > 0: animation_node.play("right_idle")
				else: animation_node.play("left_idle")
			elif last_move_direction.y > 0: animation_node.play("front_idle")
			else: animation_node.play("back_idle")

func _on_attack_cooldown_timeout():
	attacking = false
	last_move_direction = attack_direction
	choose_animation()

func _on_dash_cooldown_timeout():
	dashing = false

func _on_knockback_timer_timeout():
	taking_knockback = false

func _on_death_timer_timeout():
	animation_node.pause()

func _on_combat_hit_box_area_mouse_entered():
	if GlobalSettings.requesting_entities:
		GlobalSettings.mouse_in_attack_area = false

func _on_combat_hit_box_area_mouse_exited():
	GlobalSettings.mouse_in_attack_area = true



##### need dynamic signals
