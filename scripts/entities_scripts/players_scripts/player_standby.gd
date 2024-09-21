extends Node2D

@onready var player_stats_node := get_node("PlayerStatsComponent")
@onready var character_specifics_node := get_node("CharacterSpecifics")
@onready var attack_shape_node := $AttackShape
@onready var attack_cooldown_node := $AttackCooldown
@onready var ally_attack_cooldown_node := $AllyAttackCooldown
@onready var death_timer_node := $DeathTimer

var speed := 0.0
var ally_speed := 0.0
var dash_speed := 0.0
var dash_stamina_consumption := 0.0
var sprinting_stamina_consumption := 0.0
var dash_time := 0.0
var taking_knockback := false
var knockback_direction := Vector2.ZERO
var knockback_weight := 0.0

func update_nodes():
	player_stats_node = get_node("PlayerStatsComponent")
	character_specifics_node = get_node("CharacterSpecifics")
