extends Node2D

var onscreen_time: float = 1.0
var offscreen_time: float = 1.0

# sets onscreen and offscreen timers,
# then starts the onscreen timer
func start_timer(new_onscreen_time: float, new_offscreen_time: float):
	onscreen_time = new_onscreen_time
	offscreen_time = new_offscreen_time
	%DespawnTimer.set_wait_time(onscreen_time)
	%DespawnTimer.start()

# when parent ability re-enters screen,
# resumes onscreen timer
func _on_visible_on_screen_enabler_2d_screen_entered():
	%DespawnTimer.set_wait_time(onscreen_time)

# when parent ability leaves screen,
# pauses onscreen timer and starts the offscreen timer
func _on_visible_on_screen_enabler_2d_screen_exited():
	onscreen_time = %DespawnTimer.time_left
	%DespawnTimer.set_wait_time(offscreen_time)

# when either onscreen or offscreen timer runs out,
# goes to parent ability's despawn function
func _on_despawn_timer_timeout():
	get_parent().despawn_timeout()
