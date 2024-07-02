extends Node

# screen size status
var currently_full_screen = false

# scene variables
@onready var current_scene_node = get_parent().get_child(1)

# player variables
'''
0 = Sora
1 = AZKi
'''
var global_unlocked_players = [true, true, false, false]
@onready var player_animations_load = [load("res://resources/player_animations/sora_animation.tscn"),
									   load("res://resources/player_animations/azki_animation.tscn")]
var party_player_nodes = []
var current_main_player_node = null
var default_max_health = [9999, 999, 999, 10]
var default_max_mana = [999, 99, 99, 0]
var default_max_stamina = [100, 100, 100, 100]
var default_defence = []
var default_
############# create dictionary for each character

# combat UI variable
var combat_ui_node = null

# combat variables
var in_combat = false
var enemies_in_combat = []

"""
scene spawn locations
0 = Plains Spawn (S)
1 = Plains Spawn (N)
2 = Forest Spawn (S)
3 = Forest Spawn (N)
4 = Dungeon Spawn (S)
"""
var spawn_positions = [Vector2.ZERO, Vector2(0, -247), Vector2(0, 341), Vector2(31, -103), Vector2(0, 53)]
var next_spawn_position = Vector2.ZERO

var settings_node = null
var game_paused = false

# nexus variables
# [player][node]
var unlocked_nodes = [[135, 167, 182], [], [], [], [], [], [], [], [], []]
var unlocked_ability_nodes = [[], [], [], [], [], [], [], [], [], []]
var unlocked_stats_nodes = [[], [], [], [], [], [], [], [], [], []]
var nexus_not_randomized = true

# entities requests
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
	if Input.is_action_just_pressed("display_combat_UI"): if combat_ui_node != null: combat_ui_node.combat_ui_control_display()

# global inputs
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
		requesting_entities = false
		entities_available.clear()
	elif !game_paused&&settings_able:
		combat_ui_node.hide()
		options_node.hide()
		settings_node.show()
		get_tree().paused = true
		game_paused = true
		in_settings = true
	elif settings_able:
		settings_node.hide()
		combat_ui_node.show()
		options_node.show()
		get_tree().paused = false
		game_paused = false
		in_settings = false

# change scene (called from scenes)
func change_scene(next_scene_path, spawn_number):
	get_tree().call_deferred("change_scene_to_file", next_scene_path)
	# used for spawning at next _ready()
	if spawn_number != null:
		next_spawn_position = spawn_positions[spawn_number]

func update_nodes():
	current_scene_node = get_parent().get_child(1)
	settings_node = current_scene_node.get_node_or_null("Settings")
	combat_ui_node = current_scene_node.get_node_or_null("CombatUI")
	for player in party_player_nodes: player.player_stats_component.combat_ui_node = combat_ui_node

func update_main_player(next_main_player):
	current_main_player_node.get_node(“Camera2D”).reparent(party_player_nodes[next_main_player])
	current_main_player_node.get_node("Camera2D").position = Vector2.ZERO
	current_main_player_node.is_current_main_player = false
	party_player_nodes[next_main_player].is_current_main_player = true
	current_main_player_node = party_player_nodes[next_main_player]

func enter_combat():
	if !in_combat:
		in_combat = true
		if $LeavingCombat.is_stopped():
			# fade in combat UI
			combat_ui_node.combat_ui_control_tween(1)
			##### begin combat bgm
		else:
			$LeavingCombat.stop()

func attempt_leave_combat():
	if in_combat && $LeavingCombat.is_stopped():
		$LeavingCombat.start(2)

func request_entities(origin_node, target_command, request_count, request_entity_type):
	entities_request_origin_node = origin_node
	entities_request_target_command_string = target_command
	entities_request_count = request_count
	entities_chosen_count = 0
	
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
		entities_available = enemies_in_combat.duplicate()
	elif request_entity_type == "all_entities_in_combat":
		entities_available = party_player_nodes.duplicate()
		for enemy in enemies_in_combat:
			entities_available.push_back(enemy)
	elif request_entity_type == "all_enemies_on_screen":	
		pass
	elif request_entity_type == "all_entities_on_screen":
		pass	
		
	for entity in entities_available:
		if entity.has_method(): ##### need grouping
			entity.add_child()
		elif entity.has_method():
			entity.add_child()

func choose_entities():
	requesting_entities = false
	entities_available.clear()
	entities_request_origin_node.call(entities_request_target_command_string, entities_chosen)

func _on_combat_leave_cooldown_timeout():
	if enemies_in_combat.is_empty(): leave_combat()
	if !in_combat:
		# fade out cmobat UI
		combat_ui_node.combat_ui_control_tween(0)
		##### return to scene bgm

func update_stats(_player):
	print("player")
	pass
	# add stats to base stats

	# add health
	##### global_unlocked_stats[player][0] * 10

	# add defence
	##### global_unlocked_stats[player][1] * 20
