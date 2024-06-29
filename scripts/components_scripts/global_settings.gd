extends Node

# screen size status
var currently_full_screen = false

# scene information
@onready var current_scene_node = get_parent().get_child(2)
var current_scene_path = "res://scenes/main_menu.tscn"

# current team
var active_players = 1
var players = [null, null, null, null]

# current player
var current_main_player = 0

# combat UI nodes
var combat_UI_node = null
var combat_UI_control_node = null
var combat_options_2_node = null

# combat status
var in_combat = false
var enemies_in_combat = []

var tween

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

var options_node = null
var game_paused = false

var settings_node = null
var settings_able = true

var in_settings = false

# nexus variables
var on_nexus = false
var global_unlocked_players = [true, true, false, false]
# [player][node]
var global_unlocked_nodes = [[135, 167, 182], [], [], [], [], [], [], [], [], []]
var global_unlocked_ability_nodes = [[], [], [], [], [], [], [], [], [], []]
var nexus_not_randomized = true

func _process(_delta):
	if Input.is_action_just_pressed("full_screen"): full_screen_toggle()
	if Input.is_action_just_pressed("esc"): esc_input()
	if Input.is_action_just_pressed("display_combat_UI"): display_combat_UI()

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
	if !game_paused&&settings_able:
		combat_UI_node.hide()
		options_node.hide()
		settings_node.show()
		get_tree().paused = true
		game_paused = true
		in_settings = true
	elif settings_able:
		settings_node.hide()
		combat_UI_node.show()
		options_node.show()
		get_tree().paused = false
		game_paused = false
		in_settings = false

# display combat UI
func display_combat_UI():
	if combat_UI_control_node != null&&!in_combat:
		if combat_UI_control_node.modulate.a != 1.0: combat_UI_control_node.modulate.a = 1.0
		elif $CombatLeaveCooldown.is_stopped(): combat_UI_control_node.modulate.a = 0.0

func display_nexus():
	if !in_combat:
		if on_nexus:
			on_nexus = false
			# #### current_scene_node = get_parent().get_child(2)
		else:
			on_nexus = true

# change scene (called from scenes)
func change_scene(next_scene_path, spawn_number):
	get_tree().call_deferred("change_scene_to_file", next_scene_path)
	# used for spawning at next _ready()
	if spawn_number != null:
		next_spawn_position = spawn_positions[spawn_number]

func update_nodes():
	# update scene node
	current_scene_node = get_parent().get_child(2)

	# update options node
	options_node = current_scene_node.get_node_or_null("Options")

	# update settings node
	settings_node = current_scene_node.get_node_or_null("Settings")

	# update combat UI nodes
	combat_UI_node = current_scene_node.get_node_or_null("CombatUI")
	combat_UI_control_node = current_scene_node.get_node_or_null("CombatUI/Control")

	PartyStatsComponent.combat_UI_node = combat_UI_node
	
	update_player_nodes()

func update_player_nodes():
	# update player nodes
	players[0] = current_scene_node.get_node_or_null("Player1")
	players[1] = current_scene_node.get_node_or_null("Player2")
	players[2] = current_scene_node.get_node_or_null("Player3")
	players[3] = current_scene_node.get_node_or_null("Player4")

	# get number of active players
	active_players = 4
	for i in 4: if players[i] == null: active_players -= 1

	PartyStatsComponent.update_nodes()

func update_main_player(next_main_player):
	players[current_main_player].get_node("Camera2D").reparent(players[next_main_player])
	players[current_main_player].current_main = false
	players[next_main_player].current_main = true
	current_main_player = next_main_player
	players[current_main_player].get_node("Camera2D").position = Vector2.ZERO

func enter_combat():
	if !in_combat:
		in_combat = true
		if $CombatLeaveCooldown.is_stopped():
			# fade in combat UI
			tween = get_tree().create_tween()
			await tween.tween_property(combat_UI_control_node, "modulate:a", 1, 0.2).finished
			##### begin combat bgm
		else:
			$CombatLeaveCooldown.stop()

func leave_combat():
	if in_combat:
		in_combat = false
		if $CombatLeaveCooldown.is_stopped():
			$CombatLeaveCooldown.set_wait_time(2)
			$CombatLeaveCooldown.start()

func _on_combat_leave_cooldown_timeout():
	if enemies_in_combat.is_empty(): leave_combat()
	if !in_combat:
		# fade out cmobat UI
		tween = get_tree().create_tween()
		await tween.tween_property(combat_UI_control_node, "modulate:a", 0, 0.2).finished
		##### return to scene bgm

func update_stats(_player):
	print("player")
	pass
	# add stats to base stats

	# add health
	##### global_unlocked_stats[player][0] * 10

	# add defence
	##### global_unlocked_stats[player][1] * 20
