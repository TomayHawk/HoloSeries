extends Node2D

@onready var tree := get_tree()
@onready var root := get_tree().root

@onready var game_options_node := %GameOptionsUI
@onready var combat_ui_node := %CombatUI
@onready var text_box_node := %TextBoxUI
@onready var party_node := %Party
@onready var standby_node := %Standby
@onready var camera_node := %Camera2D
@onready var audio_stream_player_node := %AudioStreamPlayer

@onready var combat_ui_control_node := %CombatUI/CombatUIControl
@onready var combat_ui_combat_options_2_node := %CombatUI/CombatUIControl/CombatOptions2
@onready var combat_ui_character_selector_node := %CombatUI/CharacterSelector

const nexus_path := "res://user_interfaces/holo_nexus.tscn"

enum EscState {MAIN_MENU, MAIN_MENU_SAVES, MAIN_MENU_SETTINGS, WORLD, COMBAT_OPTIONS_2, REQUESTING_ENTITIES, DIALOGUE, OPTIONS, SETTINGS, STATS_SETTINGS, NEXUS, NEXUS_INVENTORY}
var esc_state := EscState.MAIN_MENU

# settings variables
var full_screen := false
var current_main_player_node: Node = null

var attempt_attack := false
var mouse_in_attack_area := true
var combat_inputs_available := false
var nexus_inputs_available := false

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
var nexus_node: Node = null
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
var inventory := [999, 99, 99, 99, 999]
var combat_inventory := [123, 45, 6, 78, 999]
var nexus_inventory := []

# save
var current_save := -1

func _ready():
	for i in 100:
		inventory.push_back(0)
	set_physics_process(false)

func _input(_event):
	if Input.is_action_just_pressed("action"):
		if mouse_in_attack_area and !CombatEntitiesComponent.requesting_entities and current_main_player_node != null:
			current_main_player_node.current_attack_state = current_main_player_node.AttackState.ATTACK
	elif Input.is_action_just_pressed("esc"): esc_input()
	elif Input.is_action_just_pressed("full_screen"): full_screen_toggle()
	elif Input.is_action_just_pressed("scroll_up"): camera_node.zoom_input(1.5, 1)
	elif Input.is_action_just_pressed("scroll_down"): camera_node.zoom_input(0.5, -1)
	elif combat_inputs_available:
		if Input.is_action_just_pressed("display_combat_UI"): combat_ui_display()
		elif Input.is_action_just_pressed("tab"): combat_ui_character_selector_node.show()
		elif Input.is_action_just_released("tab"): combat_ui_character_selector_node.hide()
	elif nexus_inputs_available:
		if Input.is_action_just_pressed("tab"): nexus_character_selector_node.show()
		elif Input.is_action_just_released("tab"): nexus_character_selector_node.hide()

# full screen inputs
func full_screen_toggle():
	full_screen = !full_screen
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if full_screen else DisplayServer.WINDOW_MODE_WINDOWED)

# esc inputs
func esc_input():
	if on_nexus:
		if nexus_node.nexus_ui_node.inventory_node.visible:
			esc_state = EscState.NEXUS_INVENTORY
		else:
			esc_state = EscState.NEXUS
	elif CombatEntitiesComponent.requesting_entities:
		esc_state = EscState.REQUESTING_ENTITIES
	elif combat_ui_combat_options_2_node.visible:
		esc_state = EscState.COMBAT_OPTIONS_2
	elif tree.paused:
		if current_save == -1:
			esc_state = EscState.MAIN_MENU_SETTINGS
		elif game_options_node.settings_node.visible:
			esc_state = EscState.SETTINGS
		elif game_options_node.stats_node.visible:
			esc_state = EscState.STATS_SETTINGS
		else:
			esc_state = EscState.OPTIONS
	elif current_save != -1:
		esc_state = EscState.WORLD

	print(esc_state)
	
	match esc_state:
		EscState.MAIN_MENU:
			game_options_node.show()
			game_options_node.options_node.hide()
			game_options_node.settings_node.show()
			tree.current_scene.main_menu_options_node.hide()
			esc_state = EscState.MAIN_MENU_SETTINGS
		EscState.MAIN_MENU_SAVES:
			tree.current_scene.saves_menu_node.hide()
			tree.current_scene.options_menu_node.show()
			tree.current_scene.main_menu_options_node.show()
			esc_state = EscState.MAIN_MENU
		EscState.MAIN_MENU_SETTINGS:
			game_options_node.hide()
			game_options_node.options_node.show()
			game_options_node.settings_node.hide()
			tree.current_scene.main_menu_options_node.show()
			esc_state = EscState.MAIN_MENU
		EscState.WORLD:
			game_options_node.show()
			combat_ui_node.hide()
			combat_ui_character_selector_node.hide()
			tree.paused = true
			combat_inputs_available = false
			esc_state = EscState.OPTIONS
		EscState.COMBAT_OPTIONS_2:
			combat_ui_node.hide_combat_options_2()
			esc_state = EscState.WORLD
		EscState.REQUESTING_ENTITIES:
			CombatEntitiesComponent.empty_entities_request()
			esc_state = EscState.WORLD if combat_ui_combat_options_2_node.visible else EscState.COMBAT_OPTIONS_2
		EscState.DIALOGUE:
			pass
		EscState.OPTIONS:
			game_options_node.hide()
			combat_ui_node.show()
			tree.paused = false
			combat_inputs_available = true
			esc_state = EscState.WORLD
		EscState.SETTINGS:
			game_options_node.settings_node.hide()
			game_options_node.options_node.show()
			esc_state = EscState.OPTIONS
		EscState.STATS_SETTINGS:
			game_options_node.stats_node.hide()
			game_options_node.options_node.show()
			esc_state = EscState.OPTIONS
		EscState.NEXUS:
			nexus(false)
		EscState.NEXUS_INVENTORY:
			nexus_node.nexus_ui_node.inventory_node.hide()
			nexus_node.nexus_ui_node.update_nexus_ui()
			esc_state = EscState.NEXUS

# change scene (called from scenes)
func change_scene(next_scene_path, spawn_position, bgm_path):
	CombatEntitiesComponent.clear_entities(true, true, true)

	party_node.call_deferred("reparent", self)
	tree.call_deferred("change_scene_to_file", next_scene_path)

	current_main_player_node.position = spawn_position

	for player_node in party_node.get_children(): if player_node != current_main_player_node:
		player_node.position = spawn_position + (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
	
	CombatEntitiesComponent.empty_entities_request()
	CombatEntitiesComponent.leave_combat()

	start_bgm(bgm_path)

	camera_node.update_camera(current_main_player_node, true, camera_node.target_zoom)

func new_scene(current_scene, camera_limits):
	camera_node.limit_left = camera_limits[0]
	camera_node.limit_top = camera_limits[1]
	camera_node.limit_right = camera_limits[2]
	camera_node.limit_bottom = camera_limits[3]

	party_node.reparent(current_scene)

func update_main_player(next_main_player_node):
	current_main_player_node.is_current_main_player = false
	current_main_player_node = next_main_player_node
	current_main_player_node.is_current_main_player = true
	camera_node.update_camera(current_main_player_node, camera_node.can_zoom, camera_node.target_zoom)
	CombatEntitiesComponent.empty_entities_request()
	
func nexus(to_nexus):
	tree.paused = to_nexus
	visible = !to_nexus
	tree.current_scene.visible = !to_nexus
	game_options_node.visible = !to_nexus
	combat_ui_node.visible = !to_nexus
	text_box_node.visible = !to_nexus
	on_nexus = to_nexus
	combat_inputs_available = !to_nexus
	nexus_inputs_available = to_nexus

	if to_nexus:
		root.add_child(load(nexus_path).instantiate())
		esc_state = EscState.NEXUS
	else:
		nexus_node.call_deferred("exit_nexus")
		esc_state = EscState.WORLD
		
func start_bgm(bgm_path):
	if audio_stream_player_node.stream.resource_path != bgm_path:
		var temp_audio_stream_player_node := audio_stream_player_node
		temp_audio_stream_player_node.name = "TempAudioStreamPlayer"
		var tween_1 := temp_audio_stream_player_node.create_tween()
		tween_1.tween_property(temp_audio_stream_player_node, "volume_db", -80, 3.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

		audio_stream_player_node = AudioStreamPlayer.new()
		add_child(audio_stream_player_node)
		audio_stream_player_node.stream = load(bgm_path)
		audio_stream_player_node.bus = "Music"
		audio_stream_player_node.volume_db = -80
		audio_stream_player_node.play()
		var tween_2 := audio_stream_player_node.create_tween()
		tween_2.tween_property(audio_stream_player_node, "volume_db", AudioServer.get_bus_volume_db(1), 4.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

		await tween_2.finished
		temp_audio_stream_player_node.queue_free()

# display combat ui
func combat_ui_display():
	if !CombatEntitiesComponent.in_combat and current_save != -1:
		if combat_ui_control_node.modulate.a != 1.0: combat_ui_control_node.modulate.a = 1.0
		elif CombatEntitiesComponent.leaving_combat_timer_node.is_stopped(): combat_ui_control_node.modulate.a = 0.0
