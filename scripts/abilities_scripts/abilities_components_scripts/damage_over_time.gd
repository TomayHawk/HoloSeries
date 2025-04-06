extends Timer

# triggers DOT every interval_wait_time until intervals == 0
var intervals_left: int = 1

func initiate_dot(intervals: int, interval_wait_time: float) -> void:
	intervals_left = intervals
	start(interval_wait_time)

func _on_timer_timeout() -> void:
	intervals_left -= 1
	get_parent().trigger_dot()
	if intervals_left == 0:
		get_parent().finish_dot()
		stop()
