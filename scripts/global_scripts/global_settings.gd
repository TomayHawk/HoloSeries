extends Node2D

@onready var game_options_node := $GameOptions
@onready var combat_ui_node := $CombatUI
@onready var text_box_node := $TextBox
@onready var party_node := $Party
@onready var standby_node := $Standby
@onready var camera_node := $Camera2D
@onready var audio_stream_player_node := $AudioStreamPlayer

@onready var combat_ui_control_node := $CombatUI/Control
@onready var combat_ui_combat_options_2_node := $CombatUI/Control/CombatOptions2
@onready var combat_ui_character_selector_node := $CombatUI/CharacterSelector

const scene_paths := {
	"world_scene_1": "res://scenes/world_scene_1.tscn",
	"world_scene_2": "res://scenes/world_scene_2.tscn",
	"dungeon_scene_1": "res://scenes/dungeon_scene_1.tscn"
}

const background_music_paths := {
	"beach_bgm": "res://music/asmarafulldemo.mp3",
	"dungeon_bgm": "res://music/shunkandemo3.mp3"
}

const nexus_path := "res://user_interfaces/holo_nexus.tscn"

const camera_limits: Array[Array] = [[-10000000, -10000000, 10000000, 10000000], [-10000000, -10000000, 10000000, 10000000], [-10000000, -10000000, 10000000, 10000000], [-679, -592, 681, 592]] # [[-208, -288, 224, 64], [-640, -352, 640, 352], [-576, -144, 128, 80], [-679, -592, 681, 592]]

# settings variables
var currently_full_screen := false
var current_main_player_node: Node = null

var target_zoom := Vector2(1.0, 1.0)
var zoom_interval := 0.0
var can_zoom := true
var game_paused := false
var can_attempt_attack := false
var mouse_in_attack_area := true
var combat_inputs_available := false
var nexus_inputs_available := false

# spawn positions and camera limits
const spawn_positions: Array[Vector2] = [Vector2.ZERO, Vector2(0, -247), Vector2(0, 341), Vector2(31, -103), Vector2(0, 53)]

"""
scene spawn locations
0 = Plains Spawn (S)
1 = Plains Spawn (N)
2 = Forest Spawn (S)
3 = Forest Spawn (N)
4 = Dungeon Spawn (S)
"""

# player variables
var standby_character_indices := []

var unlocked_characters := []
var character_levels := []
var character_experiences := []

# nexus variables
var on_nexus := false
var nexus_character_selector_node: Node = null
var nexus_stats := [[0, 0, 0, 0, 0, 0, 0, 0],
					[0, 0, 0, 0, 0, 0, 0, 0],
					[0, 0, 0, 0, 0, 0, 0, 0],
					[0, 0, 0, 0, 0, 0, 0, 0],
					[0, 0, 0, 0, 0, 0, 0, 0]]
var nexus_not_randomized := true
var nexus_randomized_atlas_positions := []
var nexus_last_nodes := []
var nexus_unlocked := [[], [], [], [], []]
var nexus_unlockables := [[], [], [], [], []]
var nexus_quality := []
var nexus_converted := [[], [], [], [], []]
var nexus_converted_type := [[], [], [], [], []]
var nexus_converted_quality := [[], [], [], [], []]

# inventory
var inventory := []
var nexus_inventory := []

# save
var current_save := -1

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	if target_zoom.x != camera_node.zoom.x:
		zoom_interval += delta * 0.1
		camera_node.zoom = camera_node.zoom.lerp(target_zoom, zoom_interval)
	else:
		zoom_interval = 0.0
		set_physics_process(false)

func _input(_event):
	if Input.is_action_just_pressed("action") && mouse_in_attack_area && !CombatEntitiesComponent.requesting_entities:
		can_attempt_attack = true
		await get_tree().process_frame
		can_attempt_attack = false
	elif Input.is_action_just_pressed("esc"): esc_input()
	elif Input.is_action_just_pressed("full_screen"): full_screen_toggle()
	elif Input.is_action_just_pressed("scroll_up") && can_zoom:
		if camera_node.zoom.x < 1.5:
			target_zoom = clamp(target_zoom + Vector2(0.05, 0.05), Vector2(0.8, 0.8), Vector2(1.4, 1.4))
			set_physics_process(true)
	elif Input.is_action_just_pressed("scroll_down") && can_zoom:
		if camera_node.zoom.x > 0.5:
			target_zoom = clamp(target_zoom - Vector2(0.05, 0.05), Vector2(0.8, 0.8), Vector2(1.4, 1.4))
			set_physics_process(true)
	elif combat_inputs_available:
		if Input.is_action_just_pressed("display_combat_UI"): combat_ui_display()
		elif Input.is_action_just_pressed("tab"): combat_ui_character_selector_node.show()
		elif Input.is_action_just_released("tab"): combat_ui_character_selector_node.hide()
	elif nexus_inputs_available:
		if Input.is_action_just_pressed("tab"): nexus_character_selector_node.show()
		elif Input.is_action_just_released("tab"): nexus_character_selector_node.hide()

# full screen inputs
func full_screen_toggle():
	if !currently_full_screen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		currently_full_screen = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		currently_full_screen = false

# esc inputs
func esc_input():
	if on_nexus:
		if get_tree().root.get_node("HoloNexus").nexus_ui_node.inventory_node.visible:
			get_tree().root.get_node("HoloNexus").nexus_ui_node.inventory_node.hide()
			get_tree().root.get_node("HoloNexus").nexus_ui_node.update_nexus_ui()
			return
		nexus(false)
	elif CombatEntitiesComponent.requesting_entities:
		CombatEntitiesComponent.empty_entities_request()
	elif combat_ui_combat_options_2_node.visible:
		combat_ui_node.hide_combat_options_2()
	elif game_paused:
		if game_options_node.settings_node.visible:
			game_options_node.settings_node.hide()
			game_options_node.options_node.show()
			if current_save == -1:
				get_parent().get_node("MainMenu").main_menu_options_node.show()
				esc_input()
		elif game_options_node.stats_node.visible:
			game_options_node.stats_node.hide()
			game_options_node.options_node.show()
			if current_save == -1:
				get_parent().get_node("MainMenu").main_menu_options_node.show()
				esc_input()
		else:
			game_options_node.hide()
			combat_ui_node.show()
			get_tree().paused = false
			combat_inputs_available = true
			game_paused = false
	elif current_save != -1:
		game_options_node.show()
		combat_ui_node.hide()
		combat_ui_character_selector_node.hide()
		get_tree().paused = true
		combat_inputs_available = false
		game_paused = true

# change scene (called from scenes)
func change_scene(next_scene, scene_index, spawn_index, bgm):
	for node in CombatEntitiesComponent.damage_display_node.get_children() + CombatEntitiesComponent.abilities_node.get_children():
		node.queue_free()

	party_node.call_deferred("reparent", self)
	get_tree().call_deferred("change_scene_to_file", scene_paths[next_scene])

	current_main_player_node.position = spawn_positions[spawn_index]

	for player_node in party_node.get_children(): if player_node != current_main_player_node:
		player_node.position = spawn_positions[spawn_index] + (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
	
	CombatEntitiesComponent.leave_combat()

	start_bgm(bgm)

	update_camera(current_main_player_node, true, target_zoom, scene_index)

	await get_tree().process_frame
	await get_tree().process_frame
	
	party_node.reparent(get_tree().current_scene)

func update_main_player(next_main_player_node):
	current_main_player_node.is_current_main_player = false
	current_main_player_node = next_main_player_node
	current_main_player_node.is_current_main_player = true
	update_camera(current_main_player_node, can_zoom, target_zoom, -1)
	CombatEntitiesComponent.empty_entities_request()

func update_camera(next_camera_parent, temp_can_zoom, camera_zoom, scene):
	camera_node.reparent(next_camera_parent)
	camera_node.position_smoothing_enabled = false
	camera_node.position = Vector2.ZERO
	
	camera_node.zoom = camera_zoom
	target_zoom = camera_zoom
	can_zoom = temp_can_zoom

	if scene != -1:
		camera_node.limit_left = camera_limits[scene][0]
		camera_node.limit_top = camera_limits[scene][1]
		camera_node.limit_right = camera_limits[scene][2]
		camera_node.limit_bottom = camera_limits[scene][3]
	
	await get_tree().process_frame
	camera_node.position_smoothing_enabled = true
	
func nexus(to_nexus):
	game_paused = to_nexus
	get_tree().paused = to_nexus
	visible = !to_nexus
	get_tree().current_scene.visible = !to_nexus
	game_options_node.visible = !to_nexus
	combat_ui_node.visible = !to_nexus
	text_box_node.visible = !to_nexus
	on_nexus = to_nexus
	combat_inputs_available = !to_nexus
	nexus_inputs_available = to_nexus

	if to_nexus:
		get_tree().root.add_child(load(nexus_path).instantiate())
	else:
		get_tree().root.get_node("HoloNexus").call_deferred("exit_nexus")
		
func start_bgm(bgm):
	if audio_stream_player_node.stream.resource_path != background_music_paths[bgm]:
		var temp_audio_stream_player_node := audio_stream_player_node
		temp_audio_stream_player_node.name = "TempAudioStreamPlayer"
		var tween_1 := temp_audio_stream_player_node.create_tween()
		tween_1.tween_property(temp_audio_stream_player_node, "volume_db", -80, 3.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

		audio_stream_player_node = AudioStreamPlayer.new()
		add_child(audio_stream_player_node)
		audio_stream_player_node.stream = load(background_music_paths[bgm])
		audio_stream_player_node.bus = "Music"
		audio_stream_player_node.volume_db = -80
		audio_stream_player_node.play()
		var tween_2 := audio_stream_player_node.create_tween()
		tween_2.tween_property(audio_stream_player_node, "volume_db", AudioServer.get_bus_volume_db(1), 4.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

		await tween_2.finished
		temp_audio_stream_player_node.queue_free()

# display combat ui
func combat_ui_display():
	if !CombatEntitiesComponent.in_combat && current_save != -1:
		if combat_ui_control_node.modulate.a != 1.0: combat_ui_control_node.modulate.a = 1.0
		elif CombatEntitiesComponent.leaving_combat_timer_node.is_stopped(): combat_ui_control_node.modulate.a = 0.0
