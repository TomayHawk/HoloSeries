extends Node2D

@onready var tree := get_tree()
@onready var root := get_tree().root
@onready var party_node := %Party
@onready var standby_node := %Standby
@onready var camera_node := %Camera2D
@onready var global_bgm_node := %GlobalBgmPlayer

var current_save := {
	# global variables
	"save_index": 0,
	"inventory": [999, 99, 99, 99, 999, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	"current_main_character_index": 4,
	
	# load variables #!#!# probably don't need to be here
	"current_scene_path": "res://scenes/world_scene_1.tscn",
	"unlocked_characters": [0, 1, 2, 4],
	"party": [0, 4, 2],
	"current_main_player_position": Vector2(0, 0),
	"character_levels": [0, 0, 0, 0, 0],
	"character_experiences": [0.0, 0.0, 0.0, 0.0, 0.0],

	"combat_inventory": [999, 99, 99, 99, 999, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	
	"nexus": {
		"randomized_atlas_positions": [],
		"randomized_qualities": [],
		"last_nodes": [167, 154, 333, 0, 132],
		"unlocked": [[135, 167, 182], [139, 154, 170], [284, 333, 364], [], [100, 132, 147]],
		"converted": [[[]], [[]], [[]], [[]], [[]]], # [node, type, quality],
		"nexus_inventory": [0, 2, 4, 6, 8, 0, 1, 3, 5, 7, 1, 11, 111, 9, 99, 999, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1],
		"stats": [[0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0]],
		#!#!# remove below
		"unlockables": [[151, 199], [171, 138], [301, 316, 348], [], [116, 164]]
		#!#!#
	}
}

enum Scene {MAIN_MENU, WORLD_SCENE_1, WORLD_SCENE_2, DUNGEON_SCENE_1, NEXUS}
var scene := Scene.MAIN_MENU

enum UiState {MAIN_MENU, MAIN_MENU_SAVES, MAIN_MENU_SETTINGS, WORLD, COMBAT_OPTIONS_2, REQUESTING_ENTITIES, DIALOGUE, OPTIONS, SETTINGS, STATS_SETTINGS, NEXUS, NEXUS_INVENTORY}
var ui_state := UiState.MAIN_MENU

var current_main_player_node: Node = null

#!#!# var can_attack := false

# nexus variables
var nexus_node: Node = null
var nexus_character_selector_node: Node = null

#!#!# remove below
# settings variables
var mouse_in_attack_area := true
var combat_inputs_available := false
var nexus_inputs_available := false

func _ready():
	for i in 100:
		current_save["inventory"].push_back(0)
	set_physics_process(false)

func _input(_event):
	if Input.is_action_just_pressed("action"):
		if mouse_in_attack_area and !CombatEntitiesComponent.requesting_entities and current_main_player_node != null:
			current_main_player_node.current_attack_state = current_main_player_node.AttackState.ATTACK
	elif Input.is_action_just_pressed("esc"): esc_input()
	elif Input.is_action_just_pressed("full_screen"): GameOptions._on_full_screen_check_button_toggled(null)
	elif Input.is_action_just_pressed("scroll_up"): camera_node.zoom_input(1.5, 1)
	elif Input.is_action_just_pressed("scroll_down"): camera_node.zoom_input(0.5, -1)
	elif combat_inputs_available:
		if Input.is_action_just_pressed("display_combat_UI"): combat_ui_display()
		elif Input.is_action_just_pressed("tab"): CombatUi.character_selector_node.show()
		elif Input.is_action_just_released("tab"): CombatUi.character_selector_node.hide()
	elif nexus_inputs_available:
		if Input.is_action_just_pressed("tab"): nexus_character_selector_node.show()
		elif Input.is_action_just_released("tab"): nexus_character_selector_node.hide()

# esc inputs
func esc_input():
	if scene == Scene.NEXUS:
		if nexus_node.nexus_ui_node.inventory_node.visible:
			ui_state = UiState.NEXUS_INVENTORY
		else:
			ui_state = UiState.NEXUS
	elif CombatEntitiesComponent.requesting_entities:
		ui_state = UiState.REQUESTING_ENTITIES
	elif CombatUi.combat_options_2_node.visible:
		ui_state = UiState.COMBAT_OPTIONS_2
	elif tree.paused:
		if current_save["save_index"] == -1:
			ui_state = UiState.MAIN_MENU_SETTINGS
		elif GameOptions.settings_node.visible:
			ui_state = UiState.SETTINGS
		elif GameOptions.stats_node.visible:
			ui_state = UiState.STATS_SETTINGS
		else:
			ui_state = UiState.OPTIONS
	elif current_save["save_index"] != -1:
		ui_state = UiState.WORLD
	
	match ui_state:
		UiState.MAIN_MENU:
			GameOptions.show()
			GameOptions.options_node.hide()
			GameOptions.settings_node.show()
			tree.current_scene.main_menu_options_node.hide()
			ui_state = UiState.MAIN_MENU_SETTINGS
		UiState.MAIN_MENU_SAVES:
			tree.current_scene.saves_menu_node.hide()
			tree.current_scene.options_menu_node.show()
			tree.current_scene.main_menu_options_node.show()
			ui_state = UiState.MAIN_MENU
		UiState.MAIN_MENU_SETTINGS:
			GameOptions.hide()
			GameOptions.options_node.show()
			GameOptions.settings_node.hide()
			tree.current_scene.main_menu_options_node.show()
			ui_state = UiState.MAIN_MENU
		UiState.WORLD:
			GameOptions.show()
			CombatUi.hide()
			CombatUi.character_selector_node.hide()
			tree.paused = true
			combat_inputs_available = false
			ui_state = UiState.OPTIONS
		UiState.COMBAT_OPTIONS_2:
			CombatUi.hide_combat_options_2()
			ui_state = UiState.WORLD
		UiState.REQUESTING_ENTITIES:
			CombatEntitiesComponent.empty_entities_request()
			ui_state = UiState.WORLD if CombatUi.combat_options_2_node.visible else UiState.COMBAT_OPTIONS_2
		UiState.DIALOGUE:
			pass
		UiState.OPTIONS:
			GameOptions.hide()
			CombatUi.show()
			tree.paused = false
			combat_inputs_available = true
			ui_state = UiState.WORLD
		UiState.SETTINGS:
			GameOptions.settings_node.hide()
			GameOptions.options_node.show()
			ui_state = UiState.OPTIONS
		UiState.STATS_SETTINGS:
			GameOptions.stats_node.hide()
			GameOptions.options_node.show()
			ui_state = UiState.OPTIONS
		UiState.NEXUS:
			nexus(false)
		UiState.NEXUS_INVENTORY:
			nexus_node.nexus_ui_node.inventory_node.hide()
			nexus_node.nexus_ui_node.update_nexus_ui()
			ui_state = UiState.NEXUS

# change scene (called from last scenes)
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

# change scene (called from new scenes)
func new_scene(next_scene, camera_limits):
	camera_node.new_limits(camera_limits)
	party_node.reparent(next_scene)

# update controlling character
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
	GameOptions.visible = !to_nexus
	CombatUi.visible = !to_nexus
	TextBox.visible = !to_nexus
	combat_inputs_available = !to_nexus
	nexus_inputs_available = to_nexus

	if to_nexus:
		root.add_child(load("res://user_interfaces/holo_nexus.tscn").instantiate())
		scene = Scene.NEXUS
		ui_state = UiState.NEXUS
	else:
		nexus_node.call_deferred("exit_nexus")
		scene = Scene.WORLD_SCENE_1 ## ### NEED TO CHANGE
		ui_state = UiState.WORLD
		
func start_bgm(bgm_path):
	if global_bgm_node.stream.resource_path != bgm_path:
		var temp_global_bgm_node := global_bgm_node
		temp_global_bgm_node.name = "TempGlobalBgmPlayer"
		var tween_1 := temp_global_bgm_node.create_tween()
		tween_1.tween_property(temp_global_bgm_node, "volume_db", -80, 3.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

		global_bgm_node = AudioStreamPlayer.new()
		add_child(global_bgm_node)
		global_bgm_node.stream = load(bgm_path)
		global_bgm_node.bus = "Music"
		global_bgm_node.volume_db = -80
		global_bgm_node.play()
		var tween_2 := global_bgm_node.create_tween()
		tween_2.tween_property(global_bgm_node, "volume_db", AudioServer.get_bus_volume_db(1), 4.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

		await tween_2.finished
		temp_global_bgm_node.queue_free()

# display combat ui
func combat_ui_display():
	if !CombatEntitiesComponent.in_combat and current_save["save_index"] != -1:
		if CombatUi.control_node.modulate.a != 1.0: CombatUi.control_node.modulate.a = 1.0
		elif CombatEntitiesComponent.leaving_combat_timer_node.is_stopped(): CombatUi.control_node.modulate.a = 0.0
