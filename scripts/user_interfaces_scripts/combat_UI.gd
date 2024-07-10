extends CanvasLayer

@onready var control_node = $Control
@onready var combat_options_2_node = $Control/CombatOptions2
@onready var character_selector_node = $CharacterSelector

@onready var combat_options_2_modes = [$Control/CombatOptions2/ScrollContainer/MarginContainer/SpecialVBoxContainer,
									   $Control/CombatOptions2/ScrollContainer/MarginContainer/SkillVBoxContainer,
							  		   $Control/CombatOptions2/ScrollContainer/MarginContainer/BuffVBoxContainer,
									   $Control/CombatOptions2/ScrollContainer/MarginContainer/DebuffVBoxContainer,
									   $Control/CombatOptions2/ScrollContainer/MarginContainer/WhiteVBoxContainer,
									   $Control/CombatOptions2/ScrollContainer/MarginContainer/BlackVBoxContainer,
									   $Control/CombatOptions2/ScrollContainer/MarginContainer/SummonVBoxContainer,
									   $Control/CombatOptions2/ScrollContainer/MarginContainer/ItemsGridContainer]

@onready var players_info_nodes = [$Control/CharacterInfos/VBoxContainer/Character1,
								   $Control/CharacterInfos/VBoxContainer/Character2,
								   $Control/CharacterInfos/VBoxContainer/Character3,
								   $Control/CharacterInfos/VBoxContainer/Character4]

@onready var players_progress_bar_nodes = [$Control/CharacterInfos/Control/ProgressBar1,
										  $Control/CharacterInfos/Control/ProgressBar2,
										  $Control/CharacterInfos/Control/ProgressBar3,
										  $Control/CharacterInfos/Control/ProgressBar4]

@onready var character_name_label_nodes = [players_info_nodes[0].get_node("HBoxContainer/CharacterName1"),
										   players_info_nodes[1].get_node("HBoxContainer/CharacterName2"),
										   players_info_nodes[2].get_node("HBoxContainer/CharacterName3"),
										   players_info_nodes[3].get_node("HBoxContainer/CharacterName4")]

@onready var players_health_label_nodes = [players_info_nodes[0].get_node("HBoxContainer/MarginContainer/HealthAmount"),
										   players_info_nodes[1].get_node("HBoxContainer/MarginContainer/HealthAmount"),
										   players_info_nodes[2].get_node("HBoxContainer/MarginContainer/HealthAmount"),
										   players_info_nodes[3].get_node("HBoxContainer/MarginContainer/HealthAmount")]

@onready var players_mana_label_nodes = [players_info_nodes[0].get_node("HBoxContainer/MarginContainer2/ManaAmount"),
										 players_info_nodes[1].get_node("HBoxContainer/MarginContainer2/ManaAmount"),
										 players_info_nodes[2].get_node("HBoxContainer/MarginContainer2/ManaAmount"),
										 players_info_nodes[3].get_node("HBoxContainer/MarginContainer2/ManaAmount")]

@onready var character_selector_player_nodes = [$CharacterSelector/MarginContainer/MarginContainer/ScrollContainer/VBoxContainer/Character1,
												$CharacterSelector/MarginContainer/MarginContainer/ScrollContainer/VBoxContainer/Character2,
												$CharacterSelector/MarginContainer/MarginContainer/ScrollContainer/VBoxContainer/Character3,
												$CharacterSelector/MarginContainer/MarginContainer/ScrollContainer/VBoxContainer/Character4]

@onready var character_selector_character_name_nodes = [character_selector_player_nodes[0].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/CharacterName"),
														character_selector_player_nodes[1].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/CharacterName"),
														character_selector_player_nodes[2].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/CharacterName"),
														character_selector_player_nodes[3].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/CharacterName")]

@onready var character_selector_level_label_nodes = [character_selector_player_nodes[0].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Level"),
													 character_selector_player_nodes[1].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Level"),
													 character_selector_player_nodes[2].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Level"),
													 character_selector_player_nodes[3].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Level")]

@onready var character_selector_health_label_nodes = [character_selector_player_nodes[0].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer/HealthAmount"),
													  character_selector_player_nodes[1].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer/HealthAmount"),
													  character_selector_player_nodes[2].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer/HealthAmount"),
													  character_selector_player_nodes[3].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer/HealthAmount")]

@onready var character_selector_mana_label_nodes = [character_selector_player_nodes[0].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer2/ManaAmount"),
													character_selector_player_nodes[1].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer2/ManaAmount"),
													character_selector_player_nodes[2].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer2/ManaAmount"),
													character_selector_player_nodes[3].get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer2/ManaAmount")]

@onready var abilities_load = [load("res://entities/abilities/fireball.tscn"),
							   load("res://entities/abilities/regen.tscn"),
							   load("res://entities/abilities/heal.tscn")]

var tween

func _ready():
	control_node.modulate = Color.TRANSPARENT
	hide_character_selector()
	combat_options_2_node.hide()

# CombatUI health text update
func update_health_label(party_index, health):
	players_health_label_nodes[party_index].text = str(floor(health))

func update_mana_label(party_index, mana):
	players_mana_label_nodes[party_index].text = str(floor(mana))

# CombatUI control visibility animation
func combat_ui_control_tween(target_visibility_value):
	tween = get_tree().create_tween()
	await tween.tween_property(control_node, "modulate:a", target_visibility_value, 0.2).finished

func hide_character_selector():
	character_selector_node.hide()
	for character in character_selector_player_nodes:
		character.hide()

func update_character_selector():
	for button in character_selector_player_nodes:
		button.hide()

	var i = 0
	for player in GlobalSettings.standby_player_nodes:
		character_selector_player_nodes[i].show()
		character_selector_character_name_nodes[i].text = player.character_specifics_node.character_name
		character_selector_level_label_nodes[i].text = "Lvl " + str(player.player_stats_node.level)
		character_selector_health_label_nodes[i].text = str(player.player_stats_node.health)
		character_selector_mana_label_nodes[i].text = str(player.player_stats_node.mana)
		i += 1

func button_pressed():
	GlobalSettings.empty_entities_request()

# CombatOptions1 (Basic Attack)
func _on_attack_pressed():
	hide_combat_options_2()

# CombatOptions1
func _on_combat_options_1_pressed(extra_arg_0):
	if combat_options_2_node.visible&&combat_options_2_modes[extra_arg_0].visible:
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

	if chosen_player_node.position.distance_to(GlobalSettings.current_main_player_node.position) > 80:
		chosen_player_node._on_entities_detection_area_body_exited(GlobalSettings.current_main_player_node)

func use_reset_button():
	for player in GlobalSettings.party_player_nodes:
		if !player.player_stats_node.alive:
			player.player_stats_node.revive()
			player.player_stats_node.update_health(player.player_stats_node.max_health, ["break_limit"], Vector2.ZERO, 0.0)

func use_temp_kill_item(chosen_player_node):
	chosen_player_node.player_stats_node.update_health( - 99999, ["break_limit"], Vector2.ZERO, 0.0)

func _on_control_mouse_entered():
	GlobalSettings.mouse_in_attack_area = false

func _on_control_mouse_exited():
	GlobalSettings.mouse_in_attack_area = true

func _on_character_1_pressed():
	GlobalSettings.standby_player_nodes.push_back(GlobalSettings.current_main_player_node)
	GlobalSettings.standby_player_nodes[0] # #############

func _on_character_2_pressed():
	pass # Replace with function body.

func _on_character_3_pressed():
	pass # Replace with function body.

func _on_character_4_pressed():
	pass # Replace with function body.