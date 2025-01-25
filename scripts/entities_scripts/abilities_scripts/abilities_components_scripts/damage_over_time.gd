extends Timer

var intervals_left: int = 1

func start_timer(intervals: int, interval_wait_time: float):
	intervals_left = intervals
	set_wait_time(interval_wait_time)

func _on_timer_timeout():
	intervals_left -= 1
	get_parent().trigger_dot()
	if intervals_left == 0: get_parent().queue_free()
