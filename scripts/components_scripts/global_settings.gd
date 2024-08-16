extends Node2D

var currently_full_screen := false

var current_scene_node: Node = null

var current_main_player_node: Node = null

@onready var party_node := $Party
@onready var standby_node := $Standby
@onready var game_options_node := $GameOptions
@onready var combat_ui_node := $CombatUI
@onready var combat_ui_control_node := $CombatUI/Control
@onready var combat_ui_combat_options_2_node := $CombatUI/Control/CombatOptions2
@onready var combat_ui_character_selector_node := $CombatUI/CharacterSelector
@onready var text_box_node := $TextBox
@onready var camera_node := $Camera2D
@onready var leaving_combat_timer_node := $LeavingCombatTimer

@onready var scene_paths := ["res://scenes/world_scene_1.tscn",
						   "res://scenes/world_scene_2.tscn",
						   "res://scenes/dungeon_scene_1.tscn"]

@onready var entity_highlights_paths := ["res://resources/entity_highlights/enemy_highlight.tscn",
										"res://resources/entity_highlights/enemy_marker.tscn",
										"res://resources/entity_highlights/entity_highlight.tscn",
										"res://resources/entity_highlights/entity_marker.tscn",
										"res://resources/entity_highlights/invalid_highlight.tscn",
										"res://resources/entity_highlights/invalid_marker.tscn",
										"res://resources/entity_highlights/player_highlight.tscn",
										"res://resources/entity_highlights/player_marker.tscn"]


@onready var nexus_path := "res://user_interfaces/holo_nexus.tscn"

# settings variables
@onready var current_camera_node := $Camera2D
var target_zoom := Vector2(1.0, 1.0)
var zoom_interval := 0.0
var mouse_in_zoom_area := false
var game_paused := false
var player_can_attack := false
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

var unlocked_characters := []
var character_levels := []
var character_experiences := []

# nexus variables
var nexus_camera_node: Node = null
var on_nexus := false
var nexus_character_selector_node: Node = null
# HP, MP, DEF, SHD, ATK, INT, SPD, AGI
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

# combat variables
var in_combat := false
var leaving_combat := false
var abilities_node: Node = null
var enemy_nodes_in_combat: Array[Node] = []
var locked_enemy_node: Node = null

# entities request variables
var requesting_entities := false
var entities_request_origin_node: Node = null
var entities_request_target_command_string := ""
var entities_request_count := 0
var entities_available: Array[Node] = []
var entities_chosen_count := 0
var entities_chosen: Array[Node] = []

# inventory
var inventory := []
var nexus_inventory := []

# save
var current_save := -1

func _ready():
	set_physics_process(false)
	game_options_node.hide()
	text_box_node.hide()

func _physics_process(delta):
	if target_zoom.x != current_camera_node.zoom.x:
		zoom_interval += delta * 0.1
		current_camera_node.zoom = current_camera_node.zoom.lerp(target_zoom, zoom_interval)
	else:
		zoom_interval = 0.0
		set_physics_process(false)

func _input(_event):
	if Input.is_action_just_pressed("action") && mouse_in_attack_area && !requesting_entities:
		player_can_attack = true
		call_deferred("reset_action_availability")
	elif Input.is_action_just_pressed("esc"): esc_input()
	elif Input.is_action_just_pressed("full_screen"): full_screen_toggle()
	elif Input.is_action_just_pressed("scroll_up") && mouse_in_zoom_area:
		if current_camera_node.zoom.x < 1.5:
			target_zoom = clamp(target_zoom + Vector2(0.05, 0.05), Vector2(0.5, 0.5), Vector2(1.5, 1.5))
			set_physics_process(true)
	elif Input.is_action_just_pressed("scroll_down") && mouse_in_zoom_area:
		if current_camera_node.zoom.x > 0.5:
			target_zoom = clamp(target_zoom - Vector2(0.05, 0.05), Vector2(0.5, 0.5), Vector2(1.5, 1.5))
			set_physics_process(true)
	elif combat_inputs_available:
		if Input.is_action_just_pressed("display_combat_UI"): combat_ui_display()
		elif Input.is_action_just_pressed("tab"): combat_ui_character_selector_node.show()
		elif Input.is_action_just_released("tab"): combat_ui_character_selector_node.hide()
	elif nexus_inputs_available:
		if Input.is_action_just_pressed("tab"): nexus_character_selector_node.show()
		elif Input.is_action_just_released("tab"): nexus_character_selector_node.hide()

func reset_action_availability():
	player_can_attack = false

func update_nodes(scene_node):
	current_scene_node = scene_node
	abilities_node = current_scene_node.get_node_or_null("Abilities")
	CombatEntitiesComponent.damage_display_node = current_scene_node.get_node_or_null("DamageDisplay")

	party_node.reparent(current_scene_node)

# toggle full screen
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
		get_tree().paused = false
		show()
		combat_ui_node.show()
		current_scene_node.show()
		on_nexus = false
		game_paused = false
		combat_inputs_available = true
		nexus_inputs_available = false
		get_tree().root.get_node("HoloNexus").call_deferred("exit_nexus")

	elif requesting_entities:
		empty_entities_request()
	elif combat_ui_character_selector_node.visible:
		combat_ui_character_selector_node.hide()
	elif combat_ui_combat_options_2_node.visible:
		combat_ui_node.hide_combat_options_2()
	elif game_paused:
		game_options_node.hide()
		combat_ui_node.show()
		get_tree().paused = false
		combat_inputs_available = true
		game_paused = false
	else:
		game_options_node.show()
		combat_ui_node.hide()
		get_tree().paused = true
		combat_inputs_available = false
		game_paused = true

func start_game(save_data_node, save_file):
	save_data_node.load(save_file)
	combat_ui_node.update_character_selector()
	combat_inputs_available = true
	mouse_in_zoom_area = true

# change scene (called from scenes)
func change_scene(next_scene_index, spawn_index):
	party_node.call_deferred("reparent", GlobalSettings)
	
	get_tree().call_deferred("change_scene_to_file", scene_paths[next_scene_index])

	current_main_player_node.position = spawn_positions[spawn_index]

	for player_node in party_player_nodes: if player_node != current_main_player_node:
		player_node.position = spawn_positions[spawn_index] + (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
	
	mouse_in_zoom_area = true
	leave_combat()

# display combat ui
func combat_ui_display():
	if !in_combat:
		if combat_ui_control_node.modulate.a != 1.0: combat_ui_control_node.modulate.a = 1.0
		elif leaving_combat_timer_node.is_stopped(): combat_ui_control_node.modulate.a = 0.0

func update_main_player(next_main_player_node):
	current_main_player_node.is_current_main_player = false

	current_main_player_node = next_main_player_node

	current_main_player_node.is_current_main_player = true
	camera_node.reparent(current_main_player_node)
	camera_node.position = Vector2.ZERO

	empty_entities_request()

func update_camera_node():
	current_camera_node = camera_node
	camera_node.position = Vector2.ZERO
	camera_node.zoom = Vector2(1.0, 1.0)
	target_zoom = Vector2(1.0, 1.0)

func display_nexus():
	on_nexus = true
	get_tree().paused = true
	get_tree().root.add_child(load(nexus_path).instantiate())
	
	current_scene_node.hide()
	game_options_node.hide()
	combat_ui_node.hide()
	text_box_node.hide()
	hide()

func enter_combat():
	if !in_combat || leaving_combat:
		in_combat = true
		leaving_combat = false
		if leaving_combat_timer_node.is_stopped():
			# fade in combat UI
			combat_ui_node.combat_ui_control_tween(1)
			##### begin combat bgm
		else:
			leaving_combat_timer_node.stop()

func attempt_leave_combat():
	if in_combat && leaving_combat_timer_node.is_stopped():
		leaving_combat = true
		leaving_combat_timer_node.start(2)

func leave_combat():
	in_combat = false
	leaving_combat = false
	leaving_combat_timer_node.stop()
	enemy_nodes_in_combat.clear()
	combat_ui_node.combat_ui_control_tween(0)
	locked_enemy_node = null

func request_entities(origin_node, target_command, request_count, request_entity_type):
	empty_entities_request()
	requesting_entities = true
	entities_request_origin_node = origin_node
	entities_request_target_command_string = target_command
	entities_request_count = request_count

	entities_available = get_tree().get_nodes_in_group(request_entity_type)

	if request_entity_type == "party_players":
		entities_available = party_player_nodes.duplicate()
	elif request_entity_type == "ally_players":
		entities_available = party_player_nodes.duplicate()
		entities_available.erase(current_main_player_node)
	elif request_entity_type == "players_alive":
		for player in party_player_nodes:
			if player.player_stats_node.alive:
				entities_available.push_back(player)
	elif request_entity_type == "players_dead":
		for player in party_player_nodes:
			if !player.player_stats_node.alive:
				entities_available.push_back(player)
	elif request_entity_type == "enemies_in_combat":
		entities_available = enemy_nodes_in_combat.duplicate()
	elif request_entity_type == "all_entities_in_combat":
		entities_available = party_player_nodes.duplicate() + enemy_nodes_in_combat.duplicate()
	elif request_entity_type == "all_enemies_on_screen":
		entities_available = current_scene_node.get_node("Enemies").get_children().duplicate()
		print(entities_available)
	elif request_entity_type == "all_entities_on_screen":
		entities_available = party_player_nodes.duplicate() + current_scene_node.get_node("Enemies").get_children().duplicate()

	for entity in entities_available:
		if entity.has_method("ally_movement"): # #### need grouping
			entity.add_child(load(entity_highlights_paths[6]).instantiate())
		elif entity.has_method("choose_player"):
			entity.add_child(load(entity_highlights_paths[0]).instantiate())

	if (entities_request_count == 1) && (locked_enemy_node != null) && (locked_enemy_node in entities_available):
		entities_chosen.push_back(locked_enemy_node)
		choose_entities()

func choose_entities():
	if entities_chosen.size() == 1:
		entities_request_origin_node.call(entities_request_target_command_string, entities_chosen.duplicate()[0])
	else:
		entities_request_origin_node.call(entities_request_target_command_string, entities_chosen.duplicate())
	empty_entities_request()

func empty_entities_request():
	requesting_entities = false
	
	if entities_request_origin_node != null && entities_request_origin_node.get_parent() == abilities_node && entities_chosen.size() != entities_request_count:
		entities_request_origin_node.queue_free()

	for entity in entities_available:
		if is_instance_valid(entity):
			if entity.has_method("ally_movement"): # #### need grouping
				entity.remove_child(entity.get_node("PlayerHighlight"))
			elif entity.has_method("choose_player"):
				entity.remove_child(entity.get_node("EnemyHighlight"))

	entities_request_count = 0
	entities_available.clear()
	entities_chosen_count = 0
	entities_chosen.clear()

func _on_leaving_combat_timer_timeout():
	if enemy_nodes_in_combat.is_empty():
		leave_combat()
