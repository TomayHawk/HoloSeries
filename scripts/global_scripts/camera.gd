extends Camera2D

# MAIN CAMERA

# ..............................................................................

#region SIGNALS

signal screen_shake_ended

#endregion

# ..............................................................................

#region CONSTANTS

const MIN_ZOOM: Vector2 = Vector2(0.8, 0.8)
const MAX_ZOOM: Vector2 = Vector2(1.4, 1.4)
const ZOOM_STEP: Vector2 = Vector2(0.05, 0.05)

#endregion

# ..............................................................................

#region VARIABLES

# camera zoom
var target_zoom: Vector2 = Vector2(1.0, 1.0)
var zoom_weight: float = 0.0

# screen shake
var shake_counter: int = 0
var shake_interval: int = 0
var shake_cooldown: int = 0
var shake_intensity: int = 0

#endregion

# ..............................................................................

#region READY

func _ready() -> void:
	$CanvasLayer.hide()
	set_process(false)
	set_physics_process(false)

#endregion

# ..............................................................................

#region PROCESS

var count := 0

# process zoom
func _process(delta: float) -> void:
	zoom = zoom.lerp(target_zoom, zoom_weight)
	zoom_weight += delta * 0.1

	count += 1

	# end zoom accordingly
	if zoom.is_equal_approx(target_zoom):
		end_zoom()
		count = 0

# process screen shake
func _physics_process(_delta: float) -> void:
	shake_cooldown += 1
	
	if shake_cooldown >= shake_interval:
		position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
		shake_counter -= 1
		shake_cooldown = 0

		# end screen shake accordingly
		if shake_counter <= 0:
			end_screen_shake()

#endregion

# ..............................................................................

#region INPUTS

func _input(event: InputEvent) -> void:
	# ignore all unrelated inputs
	if not (event.is_action(&"scroll_up") or event.is_action(&"scroll_down")): return

	# check if zoom inputs are enabled
	if not Inputs.zoom_inputs_enabled: return
	
	# prevent input propogation
	Inputs.accept_event()

	# zoom in or out
	if Input.is_action_just_pressed(&"scroll_up"):
		update_zoom(1)
	elif Input.is_action_just_pressed(&"scroll_down"):
		update_zoom(-1)

#endregion

# ..............................................................................

#region UPDATE CAMERA

func update_camera(next_parent: Node, next_zoom: Vector2 = target_zoom) -> void:
	reparent(next_parent)
	force_zoom(next_zoom)
	end_screen_shake()

func update_camera_limits(next_limits: Array[int]) -> void:
	limit_left = next_limits[0]
	limit_top = next_limits[1]
	limit_right = next_limits[2]
	limit_bottom = next_limits[3]

#endregion

# ..............................................................................

#region BLACK SCREEN

# toggle black screen
func toggle_black_screen(toggled: bool) -> void:
	$CanvasLayer.show()
	$CanvasLayer/ColorRect.color.a = 0.0 if toggled else 1.0
	
	# tween color rect
	var tween: Tween = create_tween()
	tween.tween_property($CanvasLayer/ColorRect, "color:a",
			1.0 if toggled else 0.0, 0.2 if toggled else 0.4).set_ease(Tween.EASE_OUT)
	
	# wait for tween to finish
	await tween.finished
	
	# hide color rect accordingly
	if not toggled:
		$CanvasLayer.hide()

#endregion

# ..............................................................................

#region ZOOM

func update_zoom(direction: int) -> void:
	target_zoom = clamp(target_zoom + (ZOOM_STEP * direction), MIN_ZOOM, MAX_ZOOM)
	set_process(true)

func force_zoom(new_zoom: Vector2) -> void:
	target_zoom = new_zoom
	end_zoom()

func end_zoom() -> void:
	target_zoom = target_zoom.clamp(MIN_ZOOM, MAX_ZOOM)
	zoom_weight = 0.0
	set_process(false)

#endregion

# ..............................................................................

#region SCREEN SHAKE

# initiate screen shake
func screen_shake(counter: int, interval: int, intensity: int, camera_speed: float, pause: bool = true) -> void:
	shake_counter = counter
	shake_interval = interval
	shake_cooldown = 0
	shake_intensity = intensity
	position_smoothing_speed = camera_speed
	set_physics_process(true)
	Entities.toggle_entities_process(!pause) # TODO: incomplete implementation

	await screen_shake_ended

# end screen shake
func end_screen_shake() -> void:
	position = Vector2.ZERO
	shake_counter = 0
	shake_interval = 0
	shake_cooldown = 0
	shake_intensity = 0
	position_smoothing_speed = 5.0
	set_physics_process(false)
	Entities.toggle_entities_process(true) # TODO: incomplete implementation
	screen_shake_ended.emit()

#endregion

# ..............................................................................
