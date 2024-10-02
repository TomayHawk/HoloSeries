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

@onready var scene_paths := ["res://scenes/world_scene_1.tscn",
						   "res://scenes/world_scene_2.tscn",
						   "res://scenes/dungeon_scene_1.tscn"]

@onready var background_music_path := {
	"beach_bgm": "res://music/asmarafulldemo.mp3",
	"dungeon_bgm": "res://music/shunkandemo3.mp3"
}

@onready var nexus_path := "res://user_interfaces/holo_nexus.tscn"

# settings variables
@onready var current_camera_node := $Camera2D

var currently_full_screen := false
var current_scene_node: Node = null
var current_main_player_node: Node = null

var target_zoom := Vector2(1.0, 1.0)
var zoom_interval := 0.0
var mouse_in_zoom_area := false
var game_paused := false
var can_attempt_attack := false
var mouse_in_attack_area := true
var combat_inputs_available := false
var nexus_inputs_available := false

# spawn positions and camera limits
const spawn_positions: Array[Vector2] = [Vector2.ZERO, Vector2(0, -247), Vector2(0, 341), Vector2(31, -103), Vector2(0, 53)]
var camera_limits: Array[Rect2] = []

"""
scene spawn locations
0 = Plains Spawn (S)
1 = Plains Spawn (N)
2 = Forest Spawn (S)
3 = Forest Spawn (N)
4 = Dungeon Spawn (S)
"""

# player variables
var party_player_nodes: Array[Node] = []
var standby_player_nodes: Array[Node] = []
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
	if target_zoom.x != current_camera_node.zoom.x:
		zoom_interval += delta * 0.1
		current_camera_node.zoom = current_camera_node.zoom.lerp(target_zoom, zoom_interval)
	else:
		zoom_interval = 0.0
		set_physics_process(false)

func _input(_event):
	if Input.is_action_just_pressed("action") && mouse_in_attack_area && !CombatEntitiesComponent.requesting_entities:
		can_attempt_attack = true
		call_deferred("reset_action_availability")
	elif Input.is_action_just_pressed("esc"): esc_input()
	elif Input.is_action_just_pressed("full_screen"): full_screen_toggle()
	elif Input.is_action_just_pressed("scroll_up") && mouse_in_zoom_area:
		if current_camera_node.zoom.x < 1.5:
			target_zoom = clamp(target_zoom + Vector2(0.05, 0.05), Vector2(0.8, 0.8), Vector2(1.4, 1.4))
			set_physics_process(true)
	elif Input.is_action_just_pressed("scroll_down") && mouse_in_zoom_area:
		if current_camera_node.zoom.x > 0.5:
			target_zoom = clamp(target_zoom - Vector2(0.05, 0.05), Vector2(0.8, 0.8), Vector2(1.4, 1.4))
			set_physics_process(true)
	elif combat_inputs_available:
		if Input.is_action_just_pressed("display_combat_UI"): combat_ui_display()
		elif Input.is_action_just_pressed("tab"): combat_ui_character_selector_node.show()
		elif Input.is_action_just_released("tab"): combat_ui_character_selector_node.hide()
	elif nexus_inputs_available:
		if Input.is_action_just_pressed("tab"): nexus_character_selector_node.show()
		elif Input.is_action_just_released("tab"): nexus_character_selector_node.hide()

func reset_action_availability():
	can_attempt_attack = false

func update_nodes(type, extra_arg_0):
	match type:
		"update_main_player":
			current_main_player_node.is_current_main_player = false
			current_main_player_node = extra_arg_0
			current_main_player_node.is_current_main_player = true
			camera_node.reparent(current_main_player_node)
			camera_node.position = Vector2.ZERO
			CombatEntitiesComponent.empty_entities_request()
		"change_scene":
			current_scene_node = extra_arg_0
			CombatEntitiesComponent.abilities_node = current_scene_node.get_node_or_null("Abilities")
			##### damage display can stay in global settings instead of each scene	
			CombatEntitiesComponent.damage_display_node = current_scene_node.get_node_or_null("DamageDisplay")
			##### party node can stay in GlobalSettings
			party_node.reparent(current_scene_node)
		"enter_nexus":
			pass
		"exit_nexus":
			camera_node.reparent(current_main_player_node)
			current_camera_node = camera_node
			camera_node.position = Vector2.ZERO
			camera_node.zoom = Vector2(1.0, 1.0)
			target_zoom = Vector2(1.0, 1.0)

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
		pause_game(false, "in_nexus")
		on_nexus = false
		combat_inputs_available = true
		nexus_inputs_available = false
		get_tree().root.get_node("HoloNexus").call_deferred("exit_nexus")
	elif CombatEntitiesComponent.requesting_entities:
		CombatEntitiesComponent.empty_entities_request()
	elif combat_ui_character_selector_node.visible:
		combat_ui_character_selector_node.hide()
	elif combat_ui_combat_options_2_node.visible:
		combat_ui_node.hide_combat_options_2()
	elif game_paused:
		if game_options_node.settings_node.visible:
			game_options_node.settings_node.hide()
			game_options_node.options_node.show()
			if GlobalSettings.current_save == -1:
				get_parent().get_node("MainMenu").main_menu_options_node.show()
				esc_input()
		else:
			game_options_node.hide()
			combat_ui_node.show()
			get_tree().paused = false
			combat_inputs_available = true
			game_paused = false
	elif GlobalSettings.current_save != -1:
		game_options_node.show()
		combat_ui_node.hide()
		get_tree().paused = true
		combat_inputs_available = false
		game_paused = true

func pause_game(to_pause, type):
	game_paused = to_pause
	get_tree().paused = to_pause
	visible = !to_pause
	current_scene_node.visible = !to_pause
	game_options_node.visible = !to_pause
	combat_ui_node.visible = !to_pause
	text_box_node.visible = !to_pause
	
	match type:
		"in_scene":
			pass
		"in_dialogue":
			pass
		"in_cutscene":
			pass
		"in_settings":
			pass
		"in_nexus":
			game_options_node.visible = false
		
# change scene (called from scenes)
func change_scene(next_scene_index, spawn_index, bgm):
	party_node.call_deferred("reparent", self)
	
	get_tree().call_deferred("change_scene_to_file", scene_paths[next_scene_index])

	current_main_player_node.position = spawn_positions[spawn_index]

	for player_node in party_player_nodes: if player_node != current_main_player_node:
		player_node.position = spawn_positions[spawn_index] + (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
	
	mouse_in_zoom_area = true
	CombatEntitiesComponent.leave_combat()

	if audio_stream_player_node.stream.resource_path != background_music_path[bgm]:
		audio_stream_player_node.stream = load(background_music_path[bgm])
		audio_stream_player_node.play()

# display combat ui
func combat_ui_display():
	if !CombatEntitiesComponent.in_combat && GlobalSettings.current_save != -1:
		if combat_ui_control_node.modulate.a != 1.0: combat_ui_control_node.modulate.a = 1.0
		elif CombatEntitiesComponent.leaving_combat_timer_node.is_stopped(): combat_ui_control_node.modulate.a = 0.0
