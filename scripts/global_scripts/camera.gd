extends Camera2D

# MAIN CAMERA

# ..............................................................................

@onready var timer_node := $ShakeTimer

const BASE_ZOOM := Vector2(1.0, 1.0)

var zooming := false
var can_zoom := true
var target_zoom := BASE_ZOOM
var zoom_weight := 0.0

var i := 0
var shaking := false
var screen_shake_intervals := 3
var screen_shake_intensity := 30

# ..............................................................................

func _ready():
	$CanvasLayer/ColorRect.hide()
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
			if not shaking: set_physics_process(false)

func _input(event: InputEvent) -> void:
	if not (event.is_action(&"scroll_up") or event.is_action(&"scroll_down")):
		return

	if Input.is_action_just_pressed(&"scroll_up"):
		if Inputs.action_inputs_enabled: Inputs.accept_event()
		Players.camera.zoom_input(1)
	elif Input.is_action_just_pressed(&"scroll_down"):
		if Inputs.action_inputs_enabled: Inputs.accept_event()
		Players.camera.zoom_input(-1)

# ..............................................................................

func toggle_black_screen(toggled: bool) -> void:
	# initialize color rect
	var color_rect: ColorRect = $CanvasLayer/ColorRect
	color_rect.show()
	color_rect.color.a = 0.0 if toggled else 1.0
	
	# tween color rect
	var tween: Tween = create_tween()
	tween.tween_property(color_rect, "color:a",
			1.0 if toggled else 0.0, 0.2).set_ease(Tween.EASE_OUT)
	
	# wait for tween to finish
	await tween.finished
	
	# hide color rect accordingly
	if not toggled:
		color_rect.hide()

# TODO: shouldn't need this function
func update_camera(next_parent, temp_can_zoom, next_zoom):
	new_parent(next_parent)
	force_zoom(next_zoom)
	
	can_zoom = temp_can_zoom

func new_parent(next_parent):
	force_zoom(target_zoom)
	reparent(next_parent)
	position = Vector2.ZERO

func force_zoom(new_zoom: Vector2) -> void:
	target_zoom = new_zoom
	zoom = new_zoom

func new_limits(next_limits):
	limit_left = next_limits[0]
	limit_top = next_limits[1]
	limit_right = next_limits[2]
	limit_bottom = next_limits[3]
	

func screen_shake(duration, intervals, intensity, camera_speed, pause_game):
	if pause_game:
		Global.get_tree().paused = true
	shaking = true
	screen_shake_intervals = intervals
	screen_shake_intensity = intensity
	position_smoothing_speed = camera_speed
	timer_node.set_wait_time(duration)
	timer_node.start()
	set_physics_process(true)

func zoom_input(direction: int) -> void:
	if not can_zoom: return
	target_zoom = clamp(target_zoom + (Vector2(0.05, 0.05) * direction), Vector2(0.8, 0.8), Vector2(1.4, 1.4))
	if zoom != target_zoom:
		set_physics_process(true)
		zooming = true

func _on_timer_timeout():
	if not zooming: set_physics_process(false)
	if Global.get_tree().paused:
		Global.get_tree().paused = false
	position_smoothing_speed = 5
	position = Vector2.ZERO
	shaking = false
