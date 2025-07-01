extends Timer

# ABILITIES COMPONENT: DAMAGE OVER TIME

# ..............................................................................

#region VARIABLES

signal finish_dot

var count: int = 1

#endregion

# ..............................................................................

#region FUNCTIONS

func initiate_dot(intervals: int, interval: float) -> void:
	count = intervals
	
	# connect signals
	var ability: Node = get_parent()
	timeout.connect(ability.trigger_dot())
	finish_dot.connect(ability.finish_dot())
	
	# start timer
	start(interval)

func _on_timer_timeout() -> void:
	count -= 1

	if count <= 0:
		finish_dot.emit()
		stop()

#endregion

# ..............................................................................
