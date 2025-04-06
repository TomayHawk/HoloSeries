extends VisibleOnScreenNotifier2D

var on_screen_time: float = 5.0
var off_screen_time: float = 1.0

# start onscreen timer
func initiate_timers(new_on_screen_time: float = 5.0, new_off_screen_time: float = 1.0) -> void:
	$Timer.start(new_on_screen_time)
	on_screen_time = new_on_screen_time
	off_screen_time = new_off_screen_time

# resume on screen timer when on screen
func _on_screen_entered() -> void:
	$Timer.start(on_screen_time)

# start off screen timer when off screen
func _on_screen_exited() -> void:
	on_screen_time = $Timer.time_left
	$Timer.start(off_screen_time)

# despawn trigger
func _on_timer_timeout() -> void:
	get_parent().despawn_timeout()
