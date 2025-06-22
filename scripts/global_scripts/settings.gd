extends Node

# ..............................................................................

# CONFIGURATION

func _init() -> void:
	const SETTINGS_PATH: String = "user://settings.cfg"
	const DEFAULT_SETTINGS: Dictionary[String, Dictionary] = {
		"display": {
			"window_mode": DisplayServer.WINDOW_MODE_WINDOWED,
			"resolution": Vector2i(1280, 720),
			"window_position": Vector2i(640, 360),
		},
		"audio": {
			"master_volume": 0.0,
			"music_volume": 0.0,
		},
		"save": {
			"last_save": 1,
		},
		"input": {
			"sprint_hold": false,
		},
	}

	var config: ConfigFile = ConfigFile.new()

	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)
	else:
		for section in DEFAULT_SETTINGS:
			for key in DEFAULT_SETTINGS[section]:
				config.set_value(section, key, DEFAULT_SETTINGS[section][key])

		config.save(SETTINGS_PATH)
	
	DisplayServer.window_set_mode(config.get_value(
			"display", "window_mode", DEFAULT_SETTINGS["display"]["window_mode"]))
	DisplayServer.window_set_size(config.get_value(
			"display", "resolution", DEFAULT_SETTINGS["display"]["resolution"]))
	DisplayServer.window_set_position(config.get_value(
			"display", "window_position", DEFAULT_SETTINGS["display"]["window_position"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), linear_to_db(config.get_value(
			"audio", "master_volume", DEFAULT_SETTINGS["audio"]["master_volume"])))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"BGM"), linear_to_db(config.get_value(
			"audio", "music_volume", DEFAULT_SETTINGS["audio"]["music_volume"])))

	await tree_entered
	
	Inputs.sprint_hold = config.get_value(
			"input", "sprint_hold", DEFAULT_SETTINGS["input"]["sprint_hold"])

# ..............................................................................

# DISPLAY

func toggle_fullscreen(toggled_on: bool) -> void:
	# toggle between fullscreen and windowed mode
	var next_mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED

	# update window mode
	DisplayServer.window_set_mode(next_mode)
	update_setting("display", "window_mode", DisplayServer.window_get_mode())

	# center window if windowed
	if next_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_position((DisplayServer.screen_get_size() - DisplayServer.window_get_size()) / 2)
		update_setting("display", "window_position", DisplayServer.window_get_position())

func set_resolution(next_resolution: Vector2i) -> void:
	# update resolution
	DisplayServer.window_set_size(next_resolution)
	update_setting("display", "resolution", DisplayServer.window_get_size())
	
	# center window if windowed
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_position((DisplayServer.screen_get_size() - next_resolution) / 2)
		update_setting("display", "window_position", DisplayServer.window_get_position())

# ..............................................................................

# AUDIO

func set_master_volume(db_value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), db_value)
	update_setting("audio", "master_volume", db_to_linear(db_value))

func set_music_volume(db_value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"BGM"), db_value)
	update_setting("audio", "music_volume", db_to_linear(db_value))

func update_setting(section: String, key: String, value: Variant) -> void:
	# Update a specific setting in the configuration file
	var config: ConfigFile = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value(section, key, value)
	config.save("user://settings.cfg")

# ..............................................................................

# EXIT

# Save settings on exit
func _exit_tree() -> void:
	var config: ConfigFile = ConfigFile.new()

	# Load existing settings if they exist
	const SETTINGS_PATH: String = "user://settings.cfg"
	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)
	
	# display
	config.set_value("display", "window_mode", DisplayServer.window_get_mode())
	config.set_value("display", "resolution", DisplayServer.window_get_size())
	config.set_value("display", "window_position", DisplayServer.window_get_position())
	
	# audio
	config.set_value("audio", "master_volume", db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Master"))))
	config.set_value("audio", "music_volume", db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"BGM"))))

	# input
	config.set_value("input", "sprint_hold", Inputs.sprint_hold)

	# save
	config.save("user://settings.cfg")
