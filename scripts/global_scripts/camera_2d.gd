extends Camera2D

@onready var timer_node := %ShakeTimer

const camera_limits: Array[Array] = [[-10000000, -10000000, 10000000, 10000000],
									 [-10000000, -10000000, 10000000, 10000000],
									 [-10000000, -10000000, 10000000, 10000000],
									 [-679, -592, 681, 592]]

# [[-208, -288, 224, 64], [-640, -352, 640, 352], [-576, -144, 128, 80], [-679, -592, 681, 592]]

var zooming := false
var can_zoom := true
var target_zoom := Vector2(1.0, 1.0)
var zoom_weight := 0.0

var i := 0
var shaking := false
var screen_shake_intervals := 3
var screen_shake_intensity := 30

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	if shaking:
		if i == 0:
			position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * screen_shake_intensity
			i = screen_shake_intervals
		i -= 1
	
	if zooming:
		if target_zoom.x != zoom.x:
			zoom_weight += delta * 0.1
			zoom = zoom.lerp(target_zoom, zoom_weight)
			if abs(target_zoom.x - zoom.x) < 0.000001:
				zoom = target_zoom
		else:
			zooming = false
			zoom_weight = 0.0
			if !shaking: set_physics_process(false)

func update_camera(next_camera_parent, temp_can_zoom, camera_zoom, scene):
	reparent(next_camera_parent)
	position_smoothing_enabled = false
	position = Vector2.ZERO
	
	zoom = camera_zoom
	target_zoom = camera_zoom
	can_zoom = temp_can_zoom

	if scene != -1:
		limit_left = camera_limits[scene][0]
		limit_top = camera_limits[scene][1]
		limit_right = camera_limits[scene][2]
		limit_bottom = camera_limits[scene][3]

	await GlobalSettings.tree.process_frame
	position_smoothing_enabled = true

func screen_shake(duration, intervals, intensity, camera_speed, pause_game):
	if pause_game:
		GlobalSettings.tree.paused = true
	shaking = true
	screen_shake_intervals = intervals
	screen_shake_intensity = intensity
	position_smoothing_speed = camera_speed
	timer_node.set_wait_time(duration)
	timer_node.start()
	set_physics_process(true)

func zoom_input(zoom_limit, value_sign):
	if can_zoom and zoom.x * value_sign < zoom_limit * value_sign:
		zooming = true
		target_zoom = clamp(target_zoom + (Vector2(0.05, 0.05) * value_sign), Vector2(0.8, 0.8), Vector2(1.4, 1.4))
		set_physics_process(true)

func _on_timer_timeout():
	if !zooming: set_physics_process(false)
	if GlobalSettings.tree.paused:
		GlobalSettings.tree.paused = false
	position_smoothing_speed = 5
	position = Vector2.ZERO
	shaking = false
