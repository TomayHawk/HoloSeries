extends CanvasLayer

@onready var options_node := %OptionsMargin
@onready var settings_node := %SettingsMargin
@onready var stats_node := %StatsMargin

@onready var screen_resolution_option_button_node := %ScreenResolutionOptionButton

@onready var stats_label_nodes := %StatsMarginGridContainer.get_children()
@onready var stats_left_button_node := %StatsLeftButton
@onready var stats_right_button_node := %StatsRightButton


var player_stats_nodes: Array[Node] = []
var current_stats := -1

var settings := {
	"full_screen": false,
	"resolution": Vector2i(1280, 720),
	"window_position": false, ## ### need to update
	"master_volume": 0.0,
	"music_volume": 0.0,
	"language": 0, ## ### use enum
	"zoom_sensitivity": 1.0,
	"screen_shake_intensity": 1.0
}

func _ready():
	hide()
	settings_node.hide()
	stats_node.hide()
	
	%MasterVolumeHSlider.value = AudioServer.get_bus_volume_db(0)
	%MusicVolumeHSlider.value = AudioServer.get_bus_volume_db(1)

	const resolution_options: Array[Vector2i] = [Vector2i(640, 480), Vector2i(800, 600), Vector2i(1024, 768), Vector2i(1280, 720),
												 Vector2i(1280, 800), Vector2i(1280, 960), Vector2i(1280, 1024), Vector2i(1366, 768),
												 Vector2i(1440, 900), Vector2i(1600, 900), Vector2i(1600, 1200), Vector2i(1680, 1050),
												 Vector2i(1920, 1080), Vector2i(1920, 1200), Vector2i(2560, 1080), Vector2i(2560, 1440),
												 Vector2i(3200, 1800), Vector2i(3440, 1440), Vector2i(3840, 1600), Vector2i(3840, 2160),
												 Vector2i(5120, 2160), Vector2i(5120, 2880), Vector2i(7680, 4320)]

	var resolution_max := DisplayServer.screen_get_size()
	var resolution_current := DisplayServer.window_get_size()

	for resolution in resolution_options:
		if (resolution.x <= resolution_max.x) and (resolution.y <= resolution_max.y):
			screen_resolution_option_button_node.add_item(str(resolution.x) + " x " + str(resolution.y))
			if resolution == resolution_current:
				screen_resolution_option_button_node.selected = screen_resolution_option_button_node.get_item_count() - 1

func update_player_stats_nodes():
	stats_label_nodes[1].text = player_stats_nodes[current_stats].get_parent().character_specifics_node.character_name
	stats_label_nodes[3].text = str(round(player_stats_nodes[current_stats].level))
	stats_label_nodes[5].text = str(round(player_stats_nodes[current_stats].health)) + " / " + str(round(player_stats_nodes[current_stats].max_health))
	stats_label_nodes[7].text = str(round(player_stats_nodes[current_stats].mana)) + " / " + str(round(player_stats_nodes[current_stats].max_mana))
	stats_label_nodes[9].text = str(round(player_stats_nodes[current_stats].stamina)) + " / " + str(round(player_stats_nodes[current_stats].max_stamina))
	stats_label_nodes[11].text = str(round(player_stats_nodes[current_stats].defence))
	stats_label_nodes[13].text = str(round(player_stats_nodes[current_stats].ward))
	stats_label_nodes[15].text = str(round(player_stats_nodes[current_stats].strength))
	stats_label_nodes[17].text = str(round(player_stats_nodes[current_stats].intelligence))
	stats_label_nodes[19].text = str(round(player_stats_nodes[current_stats].speed))
	stats_label_nodes[21].text = str(round(player_stats_nodes[current_stats].agility))
	stats_label_nodes[23].text = str(round(player_stats_nodes[current_stats].crit_chance * 100)) + "%"
	stats_label_nodes[25].text = str(round(player_stats_nodes[current_stats].crit_damage * 100)) + "%"

func _on_resume_pressed():
	GlobalSettings.esc_input()

func _on_characters_pressed():
	options_node.hide()
	stats_node.show()

	player_stats_nodes.clear()
	for player_node in GlobalSettings.party_node.get_children() + GlobalSettings.standby_node.get_children():
		player_stats_nodes.push_back(player_node.player_stats_node)

	current_stats = GlobalSettings.current_main_player_node.player_stats_node.party_index
	_on_left_button_pressed()
	_on_right_button_pressed()

func _on_holo_nexus_pressed():
	print("nexus")
	GlobalSettings.nexus(true)

func _on_inventory_pressed():
	pass

func _on_settings_pressed():
	options_node.hide()
	settings_node.show()

func _on_full_screen_check_button_toggled(toggled):
	if toggled == null:
		%FullScreenCheckButton.button_pressed = !settings["full_screen"]
		return
	settings["full_screen"] = !settings["full_screen"]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings["full_screen"] else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_option_button_item_selected(index):
	var resolution_max = DisplayServer.screen_get_size()
	var resolution_dimensions = screen_resolution_option_button_node.get_item_text(index).split(" x ")
	resolution_dimensions = Vector2i(int(resolution_dimensions[0]), int(resolution_dimensions[1]))

	if (resolution_dimensions.x == resolution_max.x) and (resolution_dimensions.y == resolution_max.y):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		settings["full_screen"] = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		settings["full_screen"] = false
		DisplayServer.window_set_size(resolution_dimensions)
		DisplayServer.window_set_position((resolution_max - resolution_dimensions) / 2)

func _on_master_volume_h_slider_value_changed(value):
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_music_volume_h_slider_value_changed(value):
	AudioServer.set_bus_volume_db(1, linear_to_db(value))

func _on_left_button_pressed():
	if current_stats != 0:
		current_stats -= 1
		update_player_stats_nodes()
		stats_right_button_node.modulate.a = 1.0
		stats_right_button_node.disabled = false
	if current_stats == 0:
		stats_left_button_node.modulate.a = 0.0
		stats_left_button_node.disabled = true

func _on_right_button_pressed():
	if current_stats != player_stats_nodes.size() - 1:
		current_stats += 1
		update_player_stats_nodes()
		stats_left_button_node.modulate.a = 1.0
		stats_left_button_node.disabled = false
	if current_stats == player_stats_nodes.size() - 1:
		stats_right_button_node.modulate.a = 0.0
		stats_right_button_node.disabled = true

func _on_exit_game_pressed():
	pass # Replace with function body.
