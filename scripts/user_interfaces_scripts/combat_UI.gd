extends CanvasLayer

@onready var control_node = $Control
@onready var combat_options_2_node = $Control/CombatOptions2

@onready var combat_options_2_modes = [$Control/CombatOptions2/MarginContainer/SpecialVBoxContainer,
									   $Control/CombatOptions2/MarginContainer/SkillVBoxContainer,
							  		   $Control/CombatOptions2/MarginContainer/BuffVBoxContainer,
									   $Control/CombatOptions2/MarginContainer/DebuffVBoxContainer,
									   $Control/CombatOptions2/MarginContainer/WhiteVBoxContainer,
									   $Control/CombatOptions2/MarginContainer/BlackVBoxContainer,
									   $Control/CombatOptions2/MarginContainer/SummonVBoxContainer,
									   $Control/CombatOptions2/MarginContainer/ItemsVBoxContainer]

@onready var players_button_nodes = [$Control/CharacterInfos/VBoxContainer/Character1/HBoxContainer/Button,
									 $Control/CharacterInfos/VBoxContainer/Character2/HBoxContainer/Button,
									 $Control/CharacterInfos/VBoxContainer/Character3/HBoxContainer/Button,
									 $Control/CharacterInfos/VBoxContainer/Character4/HBoxContainer/Button]

@onready var players_health_label_nodes = [$Control/CharacterInfos/VBoxContainer/Character1/HBoxContainer/MarginContainer/HealthAmount,
										  $Control/CharacterInfos/VBoxContainer/Character2/HBoxContainer/MarginContainer/HealthAmount,
										  $Control/CharacterInfos/VBoxContainer/Character3/HBoxContainer/MarginContainer/HealthAmount,
										  $Control/CharacterInfos/VBoxContainer/Character4/HBoxContainer/MarginContainer/HealthAmount]

@onready var players_mana_label_nodes = [$Control/CharacterInfos/VBoxContainer/Character1/HBoxContainer/MarginContainer2/ManaAmount,
										  $Control/CharacterInfos/VBoxContainer/Character2/HBoxContainer/MarginContainer2/ManaAmount,
										  $Control/CharacterInfos/VBoxContainer/Character3/HBoxContainer/MarginContainer2/ManaAmount,
										  $Control/CharacterInfos/VBoxContainer/Character4/HBoxContainer/MarginContainer2/ManaAmount]

@onready var abilities_load = [load("res://entities/abilities/fireball.tscn"),
							   load("res://entities/abilities/regen.tscn"),
							   load("res://entities/abilities/heal.tscn")]

var tween

func _ready():
	control_node.modulate = Color.TRANSPARENT
	combat_options_2_node.hide()
	for button_node in players_button_nodes:
		button_node.disabled = true

# CombatUI health text update
func update_health_label(party_index, health):
	players_health_label_nodes[party_index].text = str(floor(health))

func update_mana_label(party_index, mana):
	players_mana_label_nodes[party_index].text = str(floor(mana))

# CombatUI control visibility animation
func combat_ui_control_tween(target_visibility_value):
	tween = get_tree().create_tween()
	await tween.tween_property(control_node, "modulate:a", target_visibility_value, 0.2).finished

# CombatOptions1 (Basic Attack)
func _on_attack_pressed():
	hide_combat_options_2()
	GlobalSettings.empty_entities_request()

# CombatOptions1
func _on_combat_options_1_pressed(extra_arg_0):
	GlobalSettings.empty_entities_request()
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
	GlobalSettings.empty_entities_request()
	# create and add ability instance to abilities node
	GlobalSettings.abilities_node.add_child(abilities_load[ability_index].instantiate())

# request entities for items (target_command, request_count, request_entity_type)
func request_entities(extra_arg_0, extra_arg_1, extra_arg_2):
	GlobalSettings.request_entities(self, extra_arg_0, extra_arg_1, extra_arg_2)

# use items
func use_potion(chosen_player_node):
	chosen_player_node.player_stats_node.update_health(Vector2.ZERO, 0.0, 200)

func use_max_potion():
	GlobalSettings.empty_entities_request()
	for player in GlobalSettings.party_player_nodes:
		if player.player_stats_node.alive:
			player.player_stats_node.update_health(Vector2.ZERO, 0.0, 99999)

func use_phoenix_burger(chosen_player_node):
	chosen_player_node.player_stats_node.revive()
	chosen_player_node.player_stats_node.update_health(Vector2.ZERO, 0.0, chosen_player_node.player_stats_node.max_health * 0.25)

	if chosen_player_node.position.distance_to(GlobalSettings.current_main_player_node.position) > 80:
		chosen_player_node._on_entities_detection_area_body_exited(GlobalSettings.current_main_player_node)

func use_reset_button():
	GlobalSettings.empty_entities_request()
	for player in GlobalSettings.party_player_nodes:
		if !player.player_stats_node.alive:
			player.player_stats_node.revive()
			player.player_stats_node.update_health(Vector2.ZERO, 0.0, player.player_stats_node.max_health)

func use_temp_kill_item(chosen_player_node):
	chosen_player_node.player_stats_node.update_health(Vector2.ZERO, 0.0, -99999)
