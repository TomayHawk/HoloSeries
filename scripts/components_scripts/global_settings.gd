extends Node2D

var currently_full_screen = false

var current_scene_node = null

var current_main_player_node = null

@onready var party_node = $Party
@onready var game_options_node = $GameOptions
@onready var combat_ui_node = $CombatUI
@onready var combat_ui_control_node = $CombatUI/Control
@onready var combat_ui_combat_options_2_node = $CombatUI/Control/CombatOptions2
@onready var combat_ui_character_selector_node = $CombatUI/CharacterSelector
@onready var text_box_node = $TextBox
@onready var camera_node = $Camera2D
@onready var leaving_combat_timer_node = $LeavingCombatTimer

@onready var base_player_path = "res://entities/player.tscn"

@onready var scene_paths = ["res://scenes/world_scene_1.tscn",
						   "res://scenes/world_scene_2.tscn",
						   "res://scenes/dungeon_scene_1.tscn"]

@onready var character_names = ["Tokino Sora",
								 "AZKi",
								 "Roboco",
								 "Aki Rosenthal",
								  "Himemori Luna"]

@onready var character_animations_paths = ["res://entities/character_specifics/sora.tscn",
										   "res://entities/character_specifics/azki.tscn",
										   "res://entities/character_specifics/roboco.tscn",
										   "res://entities/character_specifics/akirose.tscn",
										   "res://entities/character_specifics/luna.tscn"]

@onready var entity_highlights_paths = ["res://resources/entity_highlights/enemy_highlight.tscn",
										"res://resources/entity_highlights/enemy_marker.tscn",
										"res://resources/entity_highlights/entity_highlight.tscn",
										"res://resources/entity_highlights/entity_marker.tscn",
										"res://resources/entity_highlights/invalid_highlight.tscn",
										"res://resources/entity_highlights/invalid_marker.tscn",
										"res://resources/entity_highlights/player_highlight.tscn",
										"res://resources/entity_highlights/player_marker.tscn"]

# settings variables
var game_paused = false
var player_can_attack = false
var mouse_in_attack_area = true

# spawn positions and camera limits
var spawn_positions = [Vector2.ZERO, Vector2(0, -247), Vector2(0, 341), Vector2(31, -103), Vector2(0, 53)]
var camera_limits = []

"""
scene spawn locations
0 = Plains Spawn (S)
1 = Plains Spawn (N)
2 = Forest Spawn (S)
3 = Forest Spawn (N)
4 = Dungeon Spawn (S)
"""

# player variables
var party_player_character_index = [0, 4, 3, - 1]
var party_player_nodes = []

var unlocked_players = [true, true, true, true, true]

# nexus variables
var on_nexus = false
var unlocked_nodes = [[135, 167, 182], [], [], [], [], [], [], [], [], []]
var unlocked_ability_nodes = [[], [], [], [], [], [], [], [], [], []]
var unlocked_stats_nodes = [[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0]]
var nexus_not_randomized = true

# combat variables
var in_combat = false
var leaving_combat = false
var abilities_node = null
var damage_display_node = null
var enemy_nodes_in_combat = []
var locked_enemy_node = null

# entities request variables
var requesting_entities = false
var entities_request_origin_node = null
var entities_request_target_command_string = ""
var entities_request_count = 0
var entities_available = []
var entities_chosen_count = 0
var entities_chosen = []

func _input(_event):
	if Input.is_action_just_pressed("action")&&mouse_in_attack_area&&!requesting_entities:
		player_can_attack = true
		call_deferred("reset_action_availability")
	elif Input.is_action_just_pressed("display_combat_UI"): combat_ui_display()
	elif Input.is_action_just_pressed("esc"): esc_input()
	elif Input.is_action_just_pressed("full_screen"): full_screen_toggle()
	elif Input.is_action_just_pressed("tab"): character_selector_display()
	elif Input.is_action_just_released("tab"): character_selector_display()

func reset_action_availability():
	player_can_attack = false

func character_selector_display():
	if combat_ui_character_selector_node.is_visible():
		combat_ui_character_selector_node.hide()
	else:
		combat_ui_character_selector_node.show()

func update_nodes(scene_node):
	current_scene_node = scene_node
	abilities_node = current_scene_node.get_node_or_null("Abilities")
	damage_display_node = current_scene_node.get_node_or_null("DamageDisplay")

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
		on_nexus = false
		camera_node.reparent(current_main_player_node)
		camera_node.position = Vector2.ZERO
		get_tree().root.get_node("HoloNexus").call_deferred("exit_nexus")
	elif requesting_entities:
		empty_entities_request()
	elif combat_ui_character_selector_node.is_visible():
		combat_ui_character_selector_node.hide()
	elif combat_ui_combat_options_2_node.is_visible():
		combat_ui_node.hide_combat_options_2()
	elif game_paused:
		game_options_node.hide()
		combat_ui_node.show()
		get_tree().paused = false
		game_paused = false
	else:
		game_options_node.show()
		combat_ui_node.hide()
		get_tree().paused = true
		game_paused = true

func start_game():
	# instantiate WorldScene1
	get_tree().call_deferred("change_scene_to_file", scene_paths[0])

	# add party members
	party_player_nodes.push_back(load(base_player_path).instantiate())
	party_player_nodes.push_back(load(base_player_path).instantiate())

	# add animation nodes
	party_player_nodes[0].add_child(load(character_animations_paths[0]).instantiate())
	party_player_nodes[1].add_child(load(character_animations_paths[1]).instantiate())

	party_node.add_child(party_player_nodes[0])
	party_node.add_child(party_player_nodes[1])

	##### not working
	party_player_nodes[0].player_stats_node.update_stats()
	party_player_nodes[1].player_stats_node.update_stats()

	current_main_player_node = party_player_nodes[0]
	camera_node.reparent(current_main_player_node)
	update_main_player(current_main_player_node)

	party_player_nodes[0].position = spawn_positions[0]
	party_player_nodes[1]._on_outer_entities_detection_area_body_exited(party_player_nodes[0])

# change scene (called from scenes)
func change_scene(next_scene_index, spawn_index):
	party_node.call_deferred("reparent", GlobalSettings)
	
	get_tree().call_deferred("change_scene_to_file", scene_paths[next_scene_index])

	current_main_player_node.position = spawn_positions[spawn_index]

	for player_node in party_player_nodes: if player_node != current_main_player_node:
		player_node.position = spawn_positions[spawn_index] + (15 * Vector2(randf_range( - 1, 1), randf_range( - 1, 1)))
	
	leave_combat()

func update_main_player(next_main_player_node):
	current_main_player_node.is_current_main_player = false

	current_main_player_node = next_main_player_node

	current_main_player_node.is_current_main_player = true
	camera_node.reparent(current_main_player_node)
	camera_node.position = Vector2.ZERO

	empty_entities_request()

func update_party_player(_next_party_player_node):
	pass

func enter_combat():
	if !in_combat||leaving_combat:
		in_combat = true
		leaving_combat = false
		if leaving_combat_timer_node.is_stopped():
			# fade in combat UI
			combat_ui_node.combat_ui_control_tween(1)
			##### begin combat bgm
		else:
			leaving_combat_timer_node.stop()

func attempt_leave_combat():
	if in_combat&&leaving_combat_timer_node.is_stopped():
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
	elif request_entity_type == "all_entities_on_screen":
		entities_available = party_player_nodes.duplicate() + current_scene_node.get_node("Enemies").get_children().duplicate()

	for entity in entities_available:
		if entity.has_method("ally_movement"): # #### need grouping
			entity.add_child(load(entity_highlights_paths[6]).instantiate())
		elif entity.has_method("choose_player"):
			entity.add_child(load(entity_highlights_paths[0]).instantiate())

	if (entities_request_count == 1)&&(locked_enemy_node != null)&&(locked_enemy_node in entities_available):
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
	
	if entities_request_origin_node != null&&entities_request_origin_node.get_parent() == abilities_node&&entities_chosen.size() != entities_request_count:
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

# display combat ui
func combat_ui_display():
	if !in_combat:
		if combat_ui_control_node.modulate.a != 1.0: combat_ui_control_node.modulate.a = 1.0
		elif leaving_combat_timer_node.is_stopped(): combat_ui_control_node.modulate.a = 0.0

func damage_display(value, display_position, types):
	var display = Label.new()
	display.global_position = display_position
	display.text = str(value)
	display.z_index = 5
	display.label_settings = LabelSettings.new()

	var color = "#FFF"
	if types.has("player_damage"):
		color = "#B22"
	elif types.has("heal"):
		color = "#3E3"

	if value == 0:
		color = "#FFF8"

	display.label_settings.font_color = color
	display.label_settings.font_size = 9
	display.label_settings.outline_color = "#000"
	display.label_settings.outline_size = 1
	
	if damage_display_node != null:
		damage_display_node.call_deferred("add_child", display)
	
	await display.resized
	display.pivot_offset = Vector2(display.size / 2)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(display, "position:y", display.position.y - 24, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(display, "position:y", display.position.y - 16, 0.25).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(display, "scale", Vector2(0.75, 0.75), 0.25).set_ease(Tween.EASE_IN).set_delay(0.25)

	await tween.finished
	display.queue_free()

func _on_leaving_combat_timer_timeout():
	if enemy_nodes_in_combat.is_empty():
		leave_combat()
