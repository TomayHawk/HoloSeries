extends CanvasLayer

@onready var control_node := $Control
@onready var combat_options_2_node := $Control/CombatOptions2
@onready var character_selector_node := $CharacterSelector
@onready var combat_options_2_modes := $Control/CombatOptions2/ScrollContainer/MarginContainer.get_children()
@onready var players_info_nodes := $Control/CharacterInfos/VBoxContainer.get_children()
@onready var players_progress_bar_nodes := $Control/CharacterInfos/Control.get_children()
@onready var temp_character_selector_player_container_node := $CharacterSelector/MarginContainer/MarginContainer/ScrollContainer/VBoxContainer
@onready var character_selector_player_nodes := $CharacterSelector/MarginContainer/MarginContainer/ScrollContainer/VBoxContainer.get_children()

@onready var abilities_load: Array[Resource] = [load("res://entities/abilities/fireball.tscn"),
												load("res://entities/abilities/regen.tscn"),
												load("res://entities/abilities/heal.tscn")]

var tween

var character_name_label_nodes: Array[Node] = []
var players_health_label_nodes: Array[Node] = []
var players_mana_label_nodes: Array[Node] = []
var character_selector_name_nodes: Array[Node] = []
var character_selector_level_nodes: Array[Node] = []
var character_selector_health_nodes: Array[Node] = []
var character_selector_mana_nodes: Array[Node] = []

func _ready():
	for i in 4:
		character_name_label_nodes.push_back(players_info_nodes[i].get_node("HBoxContainer/CharacterName"))
		players_health_label_nodes.push_back(players_info_nodes[i].get_node("HBoxContainer/MarginContainer/HealthAmount"))
		players_mana_label_nodes.push_back(players_info_nodes[i].get_node("HBoxContainer/MarginContainer2/ManaAmount"))
		character_selector_name_nodes.push_back(character_selector_player_nodes[i].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/CharacterName"))
		character_selector_level_nodes.push_back(character_selector_player_nodes[i].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Level"))
		character_selector_health_nodes.push_back(character_selector_player_nodes[i].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer/HealthAmount"))
		character_selector_mana_nodes.push_back(character_selector_player_nodes[i].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer2/ManaAmount"))

	control_node.modulate = Color.TRANSPARENT
	combat_options_2_node.hide()
	
	character_selector_node.hide()

	for button in character_selector_player_nodes:
		button.hide()

# CombatUI health text update
func update_health_label(party_index, health):
	players_health_label_nodes[party_index].text = str(floor(health))

func update_mana_label(party_index, mana):
	players_mana_label_nodes[party_index].text = str(floor(mana))

# CombatUI control visibility animation
func combat_ui_control_tween(target_visibility_value):
	tween = get_tree().create_tween()
	await tween.tween_property(control_node, "modulate:a", target_visibility_value, 0.2).finished

func update_character_selector():
	for button in character_selector_player_nodes:
		button.hide()

	var i = 0
	for player in GlobalSettings.standby_player_nodes:
		character_selector_player_nodes[i].show()
		character_selector_name_nodes[i].text = player.character_specifics_node.character_name
		character_selector_level_nodes[i].text = "Lvl " + str(player.player_stats_node.level).pad_zeros(3)
		character_selector_health_nodes[i].text = str(floor(player.player_stats_node.health))
		character_selector_mana_nodes[i].text = str(floor(player.player_stats_node.mana))
		i += 1

func button_pressed():
	GlobalSettings.empty_entities_request()

# CombatOptions1 (Basic Attack)
func _on_attack_pressed():
	hide_combat_options_2()

# CombatOptions1
func _on_combat_options_1_pressed(extra_arg_0):
	if combat_options_2_node.visible && combat_options_2_modes[extra_arg_0].visible:
		hide_combat_options_2()
	else:
		hide_combat_options_2()
		combat_options_2_node.show()
		combat_options_2_modes[extra_arg_0].show()

func hide_combat_options_2():
	combat_options_2_node.hide()
	for mode in combat_options_2_modes:
		mode.hide()

# CombatOptions2	
'''
0: Fireball
1: Regen
'''
# create ability nodes
func instantiate_ability(ability_index):
	# create and add ability instance to abilities node
	GlobalSettings.abilities_node.add_child(abilities_load[ability_index].instantiate())

# request entities for items (target_command, request_count, request_entity_type)
func request_entities(extra_arg_0, extra_arg_1, extra_arg_2):
	GlobalSettings.request_entities(self, extra_arg_0, extra_arg_1, extra_arg_2)

# use items
func use_potion(chosen_player_node):
	chosen_player_node.player_stats_node.update_health(200, [], Vector2.ZERO, 0.0)

func use_max_potion():
	for player in GlobalSettings.party_player_nodes:
		if player.player_stats_node.alive:
			player.player_stats_node.update_health(99999, ["break_limit"], Vector2.ZERO, 0.0)

func use_phoenix_burger(chosen_player_node):
	chosen_player_node.player_stats_node.revive()
	chosen_player_node.player_stats_node.update_health(chosen_player_node.player_stats_node.max_health * 0.25, ["break_limit"], Vector2.ZERO, 0.0)

func use_reset_button():
	for player in GlobalSettings.party_player_nodes:
		if !player.player_stats_node.alive:
			player.player_stats_node.revive()
			player.player_stats_node.update_health(player.player_stats_node.max_health, ["break_limit"], Vector2.ZERO, 0.0)

func use_temp_kill_item(chosen_player_node):
	chosen_player_node.player_stats_node.update_health(-99999, ["break_limit"], Vector2.ZERO, 0.0)

func _on_control_mouse_entered():
	print("enter")
	GlobalSettings.mouse_in_attack_area = false
	GlobalSettings.mouse_in_zoom_area = false

func _on_control_mouse_exited():
	print("exit")
	GlobalSettings.mouse_in_attack_area = true
	GlobalSettings.mouse_in_zoom_area = true

func _on_character_selector_button_pressed(extra_arg_0):
	var i = 0
	var temp_position = Vector2.ZERO
	
	for party_character_index in GlobalSettings.party_player_character_index:
		if GlobalSettings.current_main_player_node.character_specifics_node.character_index == party_character_index:
			break
		i += 1

	GlobalSettings.party_player_character_index[i] = GlobalSettings.standby_player_nodes[extra_arg_0].character_specifics_node.character_index

	GlobalSettings.current_main_player_node.set_physics_process(false)
	GlobalSettings.current_main_player_node.hide()
	GlobalSettings.current_main_player_node.reparent(GlobalSettings.standby_node)
	GlobalSettings.standby_player_nodes.push_back(GlobalSettings.current_main_player_node)
	GlobalSettings.party_player_nodes.erase(GlobalSettings.current_main_player_node)

	temp_position = GlobalSettings.current_main_player_node.position + Vector2(0, 0.01)
	
	GlobalSettings.current_main_player_node.position = Vector2(2000000, 2000000)

	GlobalSettings.update_main_player(GlobalSettings.standby_player_nodes[extra_arg_0])

	GlobalSettings.current_main_player_node.position = temp_position

	GlobalSettings.standby_player_nodes.erase(GlobalSettings.current_main_player_node)

	GlobalSettings.current_main_player_node.set_physics_process(true)
	GlobalSettings.current_main_player_node.show()
	GlobalSettings.current_main_player_node.reparent(GlobalSettings.party_node)
	GlobalSettings.party_player_nodes.insert(i, GlobalSettings.current_main_player_node)

	GlobalSettings.current_main_player_node.player_stats_node.update_stats()
	character_name_label_nodes[GlobalSettings.current_main_player_node.player_stats_node.party_index].text = GlobalSettings.current_main_player_node.character_specifics_node.character_name
	update_character_selector()
