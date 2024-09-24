extends Node2D

@onready var ability_node := get_parent()
@onready var despawn_timer_node := $DespawnTimer

var temp_time_left := 1.0
var offscreen_time_left := 1.0

func start_timer(set_time_left: float, set_offscreen_time_left: float):
	temp_time_left = set_time_left
	offscreen_time_left = set_offscreen_time_left
	despawn_timer_node.set_wait_time(set_time_left)
	despawn_timer_node.start()

func _on_visible_on_screen_enabler_2d_screen_entered():
	despawn_timer_node.set_wait_time(temp_time_left)

func _on_visible_on_screen_enabler_2d_screen_exited():
	temp_time_left = despawn_timer_node.time_left
	despawn_timer_node.set_wait_time(offscreen_time_left)

func _on_despawn_timer_timeout():
	ability_node.despawn_timeout()
