extends Node

@onready var ability_node := get_parent()
@onready var caster_node := get_parent().caster_node
@onready var speed_multiplier: float = 1 + (get_parent().caster_node.player_stats_node.intelligence / 1000) + (get_parent().caster_node.player_stats_node.speed / 256)
@onready var time_left_node := $TimeLeft

var offscreen_time_left := 0.5

##### set in Godot
func _ready():
	set_physics_process(false)

func _physics_process(delta):
	if move_and_collide(velocity * delta) != null: ability_node.projectile_collision()

func initiate_projectile(set_position, set_direction, set_speed, set_time_left, set_offscreen_time_left):
	position = set_position
	velocity = set_direction * set_speed * speed_multiplier
	time_left_node.set_wait_time(set_time_left)
	time_left_node.start()
	offscreen_time_left = set_offscreen_time_left
	set_physics_process(true)	

func _on_visible_on_screen_enabler_2d_screen_exited():
	time_left_node.set_wait_time(offscreen_time_left)

func _on_time_left_timeout():
	ability_node.queue_free()
