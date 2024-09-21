extends Timer

@onready var ability_node := get_parent()

var temp_time_left := 1.0
var offscreen_time_left := 0.5

func start_timer(set_time_left, set_offscreen_time_left):
	temp_time_left = set_time_left
	offscreen_time_left = set_offscreen_time_left
	set_wait_time(set_time_left)
	start()

func _on_visible_on_screen_enabler_2d_screen_entered():
	set_wait_time(temp_time_left)

func _on_visible_on_screen_enabler_2d_screen_exited():
	temp_time_left = time_left
	set_wait_time(offscreen_time_left)

func _on_timer_timeout():
	ability_node.despawn_timeout()
