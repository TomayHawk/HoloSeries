extends Node2D

var speed := 0.0
var ally_speed := 0.0
var dash_speed := 0.0
var dash_stamina_consumption := 0.0
var sprinting_stamina_consumption := 0.0
var dash_time := 0.0
var taking_knockback := false
var knockback_direction := Vector2.ZERO
var knockback_weight := 0.0
var animation_node: Node = null
var death_timer_node: Node = null
var attack_cooldown_node: Node = null
var ally_direction_cooldown_node: Node = null
