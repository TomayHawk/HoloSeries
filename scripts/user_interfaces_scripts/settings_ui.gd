extends CanvasLayer

func _ready():
	# set resolution options
	const resolution_options: Array[Vector2i] = [
			Vector2i(640, 480), Vector2i(800, 600), Vector2i(1024, 768), Vector2i(1280, 720),
			Vector2i(1280, 800), Vector2i(1280, 960), Vector2i(1280, 1024), Vector2i(1366, 768),
			Vector2i(1440, 900), Vector2i(1600, 900), Vector2i(1600, 1200), Vector2i(1680, 1050),
			Vector2i(1920, 1080), Vector2i(1920, 1200), Vector2i(2560, 1080), Vector2i(2560, 1440),
			Vector2i(3200, 1800), Vector2i(3440, 1440), Vector2i(3840, 1600), Vector2i(3840, 2160),
			Vector2i(5120, 2160), Vector2i(5120, 2880), Vector2i(7680, 4320)
	]

	var max_x: int = DisplayServer.screen_get_size().x
	var max_y: int = DisplayServer.screen_get_size().y

	for resolution in resolution_options:
		if (resolution.x <= max_x) and (resolution.y <= max_y):
			%ResolutionOptionButton.add_item(str(resolution.x) + " x " + str(resolution.y))
	
	# update full screen status
	%FullScreenCheckButton.set_pressed(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

	# update selected resolution option
	var current_x: int = DisplayServer.window_get_size().x
	var current_y: int = DisplayServer.window_get_size().y
	
	for index in %ResolutionOptionButton.get_item_count():
		var resolution: PackedStringArray = %ResolutionOptionButton.get_item_text(index).split(" x ")
		
		if int(resolution[0]) == current_x and int(resolution[1]) == current_y:
			%ResolutionOptionButton.selected = index
			break
		
		if int(resolution[0]) > current_x and int(resolution[1]) > current_y:
			%ResolutionOptionButton.selected = -1
			break

	# update volume sliders
	%MasterVolumeHSlider.set_value(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Master"))))
	%MusicVolumeHSlider.set_value(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"BGM"))))

func _input(event: InputEvent) -> void:
	# ignore all unrelated inputs
	if not event.is_action(&"esc"):
		return
	
	Inputs.accept_event()

	if Input.is_action_just_pressed(&"esc"):
		exit_ui()

# ..............................................................................

# SIGNALS

func exit_ui() -> void:
	Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")
	queue_free()

# SETTINGS

func _on_full_screen_check_button_toggled(toggled_on: bool) -> void:
	Settings.toggle_fullscreen(toggled_on)

func _on_resolution_option_button_item_selected(index: int) -> void:
	var resolution_dimensions: PackedStringArray = %ResolutionOptionButton.get_item_text(index).split(" x ")
	Settings.set_resolution(Vector2i(resolution_dimensions[0].to_int(), resolution_dimensions[1].to_int()))

func _on_master_volume_h_slider_value_changed(value: float) -> void:
	Settings.set_master_volume(linear_to_db(value))

func _on_music_volume_h_slider_value_changed(value: float) -> void:
	Settings.set_music_volume(linear_to_db(value))
