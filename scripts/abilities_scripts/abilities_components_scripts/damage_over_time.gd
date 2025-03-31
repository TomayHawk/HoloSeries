extends Timer

var intervals_left: int = 1

# sets DOT intervals and interval times, then starts interval timer
func initiate_dot(intervals: int, interval_wait_time: float) -> void:
	intervals_left = intervals
	set_wait_time(interval_wait_time)
	start()

# when timer runs out, triggers parent ability's DOT function,
# then restarts interval timer until 0 intervals remain
func _on_timer_timeout() -> void:
	intervals_left -= 1
	get_parent().trigger_dot()
	if intervals_left == 0:
		stop()
		get_parent().finish_dot()
