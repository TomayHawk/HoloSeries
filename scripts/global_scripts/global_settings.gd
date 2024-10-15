extends Node2D

@onready var tree := get_tree()
@onready var root := get_tree().root

@onready var game_options_node := %GameOptionsUI
@onready var combat_ui_node := %CombatUI
@onready var text_box_node := %TextBoxUI
@onready var party_node := %Party
@onready var standby_node := %Standby
@onready var pick_up_items := %PickUpItems
@onready var camera_node := %Camera2D
@onready var audio_stream_player_node := %AudioStreamPlayer

@onready var combat_ui_control_node := %CombatUI/CombatUIControl
@onready var combat_ui_combat_options_2_node := %CombatUI/CombatUIControl/CombatOptions2
@onready var combat_ui_character_selector_node := %CombatUI/CharacterSelector

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

# settings variables
var currently_full_screen := false
var current_main_player_node: Node = null

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
var base_item_load := load("res://entities/items/base_item.tscn")
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
		if mouse_in_attack_area && !CombatEntitiesComponent.requesting_entities:
			can_attempt_attack = true
			await tree.process_frame
			can_attempt_attack = false
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
	if !currently_full_screen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		currently_full_screen = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		currently_full_screen = false

# esc inputs
func esc_input():
	if on_nexus:
		if nexus_node.nexus_ui_node.inventory_node.visible:
			nexus_node.nexus_ui_node.inventory_node.hide()
			nexus_node.nexus_ui_node.update_nexus_ui()
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
				tree.current_scene.main_menu_options_node.show()
				esc_input()
		elif game_options_node.stats_node.visible:
			game_options_node.stats_node.hide()
			game_options_node.options_node.show()
			if current_save == -1:
				tree.current_scene.main_menu_options_node.show()
				esc_input()
		else:
			game_options_node.hide()
			combat_ui_node.show()
			tree.paused = false
			combat_inputs_available = true
			game_paused = false
	elif current_save != -1:
		game_options_node.show()
		combat_ui_node.hide()
		combat_ui_character_selector_node.hide()
		tree.paused = true
		combat_inputs_available = false
		game_paused = true

# change scene (called from scenes)
func change_scene(next_scene, scene_index, spawn_index, bgm):
	for node in CombatEntitiesComponent.damage_display_node.get_children() + CombatEntitiesComponent.abilities_node.get_children():
		node.queue_free()

	party_node.call_deferred("reparent", self)
	tree.call_deferred("change_scene_to_file", scene_paths[next_scene])

	current_main_player_node.position = spawn_positions[spawn_index]

	for player_node in party_node.get_children(): if player_node != current_main_player_node:
		player_node.position = spawn_positions[spawn_index] + (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
	
	CombatEntitiesComponent.empty_entities_request()
	CombatEntitiesComponent.leave_combat()

	start_bgm(bgm)

	camera_node.update_camera(current_main_player_node, true, camera_node.target_zoom, scene_index)

	await tree.process_frame
	await tree.process_frame
	
	party_node.reparent(tree.current_scene)

func update_main_player(next_main_player_node):
	current_main_player_node.is_current_main_player = false
	current_main_player_node = next_main_player_node
	current_main_player_node.is_current_main_player = true
	camera_node.update_camera(current_main_player_node, camera_node.can_zoom, camera_node.target_zoom, -1)
	CombatEntitiesComponent.empty_entities_request()
	
func nexus(to_nexus):
	game_paused = to_nexus
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
	else:
		nexus_node.call_deferred("exit_nexus")
		
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
