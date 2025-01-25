extends Node2D

var onscreen_time: float = 1.0
var offscreen_time: float = 1.0

func start_timer(new_onscreen_time: float, new_offscreen_time: float):
	onscreen_time = new_onscreen_time
	offscreen_time = new_offscreen_time
	%DespawnTimer.set_wait_time(new_onscreen_time)
	%DespawnTimer.start()

func _on_visible_on_screen_enabler_2d_screen_entered():
	%DespawnTimer.set_wait_time(onscreen_time)

func _on_visible_on_screen_enabler_2d_screen_exited():
	onscreen_time = %DespawnTimer.time_left
	%DespawnTimer.set_wait_time(offscreen_time)

func _on_despawn_timer_timeout():
	get_parent().despawn_timeout()
