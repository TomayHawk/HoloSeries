extends Timer

@onready var ability_node := get_parent()
var intervals_left := 1

func start_timer(intervals: int, interval_wait_time: float):
	intervals_left = intervals
	set_wait_time(interval_wait_time)

func _on_timer_timeout():
	intervals_left -= 1
	ability_node.trigger_dot()
	if intervals_left == 0: ability_node.queue_free()
