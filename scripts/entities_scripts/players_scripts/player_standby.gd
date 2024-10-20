extends Node2D

@onready var player_stats_node := get_node_or_null("PlayerStatsComponent")
@onready var character_specifics_node := get_node_or_null("CharacterSpecifics")
@onready var attack_shape_node := %AttackShape
@onready var knockback_timer_node := %KnockbackTimer
@onready var death_timer_node := %DeathTimer

var walk_speed := 0.0
var dash_speed := 0.0
var dash_stamina_consumption := 0.0
var sprinting_stamina_consumption := 0.0
var dash_time := 0.0
var knockback_direction := Vector2.ZERO
var knockback_weight := 0.0

func update_nodes():
	player_stats_node = get_node_or_null("PlayerStatsComponent")
	character_specifics_node = get_node_or_null("CharacterSpecifics")
