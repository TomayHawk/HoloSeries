extends Camera2D

@onready var timer_node := $Timer

var i := 0
var screen_shake_intervals := 3
var screen_shake_intensity := 30

func _ready():
    set_physics_process(false)

func _physics_process(_delta):
    if i == 0:
        position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * screen_shake_intensity
        i = screen_shake_intervals
    i -= 1

func screen_shake(duration, intervals, intensity, pause_game):
    if pause_game:
        get_tree().paused = true
        GlobalSettings.combat_inputs_available = false
    screen_shake_intervals = intervals
    screen_shake_intensity = intensity
    timer_node.set_wait_time(duration)
    timer_node.start()
    set_physics_process(true)

func _on_timer_timeout():
    set_physics_process(false)
    if get_tree().paused:
        get_tree().paused = false
    position = Vector2.ZERO