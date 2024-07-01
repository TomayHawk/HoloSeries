extends CanvasLayer

@onready var combat_leave_cooldown_node = GlobalSettings.get_node("CombatLeaveCooldown")
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

@onready var abilities_node = get_parent().get_node("Abilities")
@onready var abilities_load = [load("res://entities/abilities/fireball.tscn"),
							   load("res://entities/abilities/regen.tscn")]

@onready var players_health_label_nodes = [$Control/CharacterInfos/VBoxContainer/Character1/HBoxContainer/MarginContainer/HealthAmount,
										  $Control/CharacterInfos/VBoxContainer/Character2/HBoxContainer/MarginContainer/HealthAmount,
										  $Control/CharacterInfos/VBoxContainer/Character3/HBoxContainer/MarginContainer/HealthAmount,
										  $Control/CharacterInfos/VBoxContainer/Character4/HBoxContainer/MarginContainer/HealthAmount]

var tween

var chosen_ability = null
var choosing_player = false
var choosing_enemy = false

func _ready():
	$Control.modulate = Color.TRANSPARENT
	$Control/CombatOptions2.hide()
	for button_node in players_button_nodes:
		button_node.disabled = true
	choosing_player = false
	choosing_enemy = false

func health_ui_update(player_index):
	players_health_label_nodes[player_index].text = str(GlobalSettings.players[player_index].player_stats_node.health)

# display combat ui
func combat_ui_control_display():
	if !GlobalSettings.in_combat:
		if control_node.modulate.a != 1.0: control_node.modulate.a = 1.0
		elif combat_leave_cooldown_node.is_stopped(): control_node.modulate.a = 0.0

# CombatUI control
func combat_ui_control_tween(target_visibility_value):
	tween = get_tree().create_tween()
	await tween.tween_property(control_node, "modulate:a", target_visibility_value, 0.2).finished

# CombatOptions1
func _on_attack_pressed():
	choosing_player = false
	choosing_enemy = false

func _on_combat_options_1_pressed(extra_arg_0):
	if combat_options_2_node.visible&&combat_options_2_modes[extra_arg_0].visible: hide_combat_options_2()
	else:
		hide_combat_options_2()
		combat_options_2_node.show()
		combat_options_2_modes[extra_arg_0].show()
	choosing_player = false
	choosing_enemy = false

func hide_combat_options_2():
	combat_options_2_node.hide()
	for mode_index in 8:
		combat_options_2_modes[mode_index].hide()

# CombatOptions2	
'''
0: Fireball
1: Regen
'''
func instantiate_ability(ability_index):
	var instance = abilities_load[ability_index].instantiate() # create ability instance
	abilities_node.add_child(instance) # add ability instance to abilities node
	instance.position = GlobalSettings.players[GlobalSettings.current_main_player].position # determine instance spawn position
	hide_combat_options_2()

func request_player(extra_arg_0):
	chosen_ability = extra_arg_0
	choosing_player = true
	hide_combat_options_2()

func request_enemy(extra_arg_0):
	chosen_ability = extra_arg_0
	choosing_enemy = true
	hide_combat_options_2()

func choose_player(chosen_player_node):
	call(chosen_ability, chosen_player_node)
	choosing_player = false

func choose_enemy(chosen_enemy_node):
	call(chosen_ability, chosen_enemy_node)
	choosing_enemy = false

func regen():
	abilities_node.start_regen()

# use items
func use_potion(chosen_player_node):
	chosen_player_node.player_stats_node.health += 25

func use_max_potion():
	for player in GlobalSettings.players:
		if player.player_stats_node.alive:
			player.player_stats_node.health = player.player_stats_node.max_health
	hide_combat_options_2()

func use_phoenix_feather(chosen_player_node):
	if !chosen_player_node.player_stats_node.alive:
		chosen_player_node.player_stats_node.alive = true
		chosen_player_node.player_stats_node.health = chosen_player_node.player_stats_node.max_health * 0.5
		chosen_player_node.set_physics_process(true)
		################# if !PartyStatsComponent.players[0].check_other_player_distance():
			############# 	PartyStatsComponent.players[0]._on_entities_detection_area_body_exited(PartyStatsComponent.players[GlobalSettings.current_main_player])

func use_kfp_family_bucket():
	for player in GlobalSettings.players:
		if !player.player_stats_node.alive:
			player.player_stats_node.alive = true
			player.player_stats_node.health = player.player_stats_node.max_health
			player.set_physics_process(true)
	hide_combat_options_2()
