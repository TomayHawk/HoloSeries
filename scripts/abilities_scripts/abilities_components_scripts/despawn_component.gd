extends VisibleOnScreenNotifier2D

# ABILITIES COMPONENT: DAMAGE OVER TIME

# ..............................................................................

#region VARIABLES

var on_screen_time: float = 5.0
var off_screen_time: float = 1.0

#endregion

# ..............................................................................

#region FUNCTIONS

# connect signals on ready
func _ready() -> void:
	$Timer.timeout.connect(get_parent().despawn_timeout)

# set and start despawn timer
func set_despawn_requirements(on_screen: float, off_screen: float) -> void:
	on_screen_time = on_screen
	off_screen_time = off_screen
	$Timer.start(on_screen)

# resume on screen timer when on screen
func _on_screen_entered() -> void:
	$Timer.start(on_screen_time)

# start off screen timer when off screen
func _on_screen_exited() -> void:
	on_screen_time = $Timer.time_left
	$Timer.start(off_screen_time)

#endregion

# ..............................................................................
