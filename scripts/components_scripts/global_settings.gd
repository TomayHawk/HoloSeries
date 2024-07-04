extends Node

var currently_full_screen = false

var current_scene_node = null

var current_main_player_node = null

@onready var party_node = $Party
@onready var game_options_node = $GameOptions
@onready var combat_ui_node = $CombatUI
@onready var combat_ui_control_node = $CombatUI/Control
@onready var text_box_node = $TextBox
@onready var camera_node = $Camera2D
@onready var leaving_combat_timer_node = $LeavingCombatTimer

@onready var base_player_path = "res://entities/player.tscn"

@onready var scene_paths = ["res://scenes/world_scene_1.tscn",
						   "res://scenes/world_scene_2.tscn",
						   "res://scenes/dungeon_scene_1.tscn"]

@onready var player_animations_paths = ["res://resources/player_animations/sora_animation.tscn",
										"res://resources/player_animations/azki_animation.tscn"]

# settings variables
var game_paused = false

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
var unlocked_players = [true, true, false, false]
var party_player_nodes = []
var default_max_health = [9999, 999, 999, 10]
var default_max_mana = [999, 99, 99, 0]
var default_max_stamina = [100, 100, 100, 100]

'''
character index
0 = Sora
1 = AZKi
'''

# nexus variables
var unlocked_nodes = [[135, 167, 182], [], [], [], [], [], [], [], [], []]
var unlocked_ability_nodes = [[], [], [], [], [], [], [], [], [], []]
var unlocked_stats_nodes = [[], [], [], [], [], [], [], [], [], []]
var nexus_not_randomized = true

# combat variables
var in_combat = false
var abilities_node = null
var enemy_nodes_in_combat = []

# entities request variables
var requesting_entities = false
var entities_request_origin_node = null
var entities_request_target_command_string = ""
var entities_request_count = 0
var entities_available = []
var entities_chosen_count = 0
var entities_chosen = []

func _process(_delta):
	if Input.is_action_just_pressed("full_screen"): full_screen_toggle()
	if Input.is_action_just_pressed("esc"): esc_input()
	if Input.is_action_just_pressed("display_combat_UI"): combat_ui_display()

func update_nodes(scene_node):
	current_scene_node = scene_node
	abilities_node = current_scene_node.get_node_or_null("Abilities")

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
	if requesting_entities:
		empty_entities_request()
	elif game_paused:
		game_options_node.hide()
		combat_ui_node.show()
		current_scene_node.paused = true
		game_paused = true
	else:
		game_options_node.show()
		combat_ui_node.hide()
		current_scene_node.paused = false
		game_paused = false

func start_game():
	get_tree().call_deferred("change_scene_to_file", scene_paths[0])

	party_player_nodes.clear()

	party_player_nodes.push_back(load(base_player_path).instantiate())
	party_player_nodes.push_back(load(base_player_path).instantiate())

	# add animation nodes
	party_player_nodes[0].add_child(load(player_animations_paths[0]).instantiate())
	party_player_nodes[1].add_child(load(player_animations_paths[1]).instantiate())

	party_node.add_child(party_player_nodes[0])
	party_node.add_child(party_player_nodes[1])

	party_player_nodes[0].player_index = 0
	party_player_nodes[1].player_index = 1

	party_player_nodes[0].position = spawn_positions[0]
	party_player_nodes[1].position = spawn_positions[0] + (15 * Vector2(randf_range( - 1, 1), randf_range( - 1, 1)))

	current_main_player_node = party_player_nodes[0]
	camera_node.reparent(current_main_player_node)

	update_main_player(current_main_player_node)

# change scene (called from scenes)
func change_scene(next_scene_index, spawn_index):
	get_tree().call_deferred("change_scene_to_file", scene_paths[next_scene_index])

	current_main_player_node.position = spawn_positions[spawn_index]

	for player_node in party_player_nodes: if player_node != current_main_player_node:
		player_node.position = spawn_positions[spawn_index] + (15 * Vector2(randf_range( - 1, 1), randf_range( - 1, 1)))

func update_main_player(next_main_player_node):
	current_main_player_node.is_current_main_player = false

	current_main_player_node = next_main_player_node

	current_main_player_node.is_current_main_player = true
	camera_node.reparent(current_main_player_node)
	camera_node.position = Vector2.ZERO

	empty_entities_request()

func enter_combat():
	if !in_combat:
		in_combat = true
		if leaving_combat_timer_node.is_stopped():
			# fade in combat UI
			combat_ui_node.combat_ui_control_tween(1)
			##### begin combat bgm
		else:
			leaving_combat_timer_node.stop()

func attempt_leave_combat():
	if in_combat&&leaving_combat_timer_node.is_stopped():
		leaving_combat_timer_node.start(2)

func request_entities(origin_node, target_command, request_count, request_entity_type):
	entities_request_origin_node = origin_node
	entities_request_target_command_string = target_command
	entities_request_count = request_count

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
		entities_available = party_player_nodes.duplicate() + entities_available.duplicate()
	elif request_entity_type == "all_enemies_on_screen":
		pass
	elif request_entity_type == "all_entities_on_screen":
		pass
		
	for entity in entities_available:
		if entity.has_method(): # #### need grouping
			pass # ############### entity.add_child()
		elif entity.has_method():
			pass # ############### entity.add_child()

func choose_entities():
	entities_request_origin_node.call(entities_request_target_command_string, entities_chosen)
	empty_entities_request()

func empty_entities_request():
	requesting_entities = false
	entities_request_count = 0
	entities_available.clear()
	entities_chosen_count = 0
	entities_chosen.clear()

# display combat ui
func combat_ui_display():
	if !GlobalSettings.in_combat:
		if combat_ui_control_node.modulate.a != 1.0: combat_ui_control_node.modulate.a = 1.0
		elif leaving_combat_timer_node.is_stopped(): combat_ui_control_node.modulate.a = 0.0

func _on_leaving_combat_timer_timeout():
	if enemy_nodes_in_combat.is_empty():
		combat_ui_node.combat_ui_control_tween(0)
