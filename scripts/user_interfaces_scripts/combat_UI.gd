extends CanvasLayer

@onready var players_health_label_nodes = [$Control/CharacterInfos/VBoxContainer/Character1/HBoxContainer/MarginContainer/HealthAmount,
										  $Control/CharacterInfos/VBoxContainer/Character2/HBoxContainer/MarginContainer/HealthAmount,
										  $Control/CharacterInfos/VBoxContainer/Character3/HBoxContainer/MarginContainer/HealthAmount,
										  $Control/CharacterInfos/VBoxContainer/Character4/HBoxContainer/MarginContainer/HealthAmount]

@onready var combat_options_2_node = $Control/CombatOptions2

@onready var combat_options_2_modes = [$Control/CombatOptions2/MarginContainer/SkillsVBoxContainer,
							  		   $Control/CombatOptions2/MarginContainer/WhiteVBoxContainer,
									   $Control/CombatOptions2/MarginContainer/BlackVBoxContainer,
									   $Control/CombatOptions2/MarginContainer/ItemsVBoxContainer]

@onready var players_button_nodes = [$Control/CharacterInfos/VBoxContainer/Character1/HBoxContainer/Button,
									 $Control/CharacterInfos/VBoxContainer/Character2/HBoxContainer/Button,
									 $Control/CharacterInfos/VBoxContainer/Character3/HBoxContainer/Button,
									 $Control/CharacterInfos/VBoxContainer/Character4/HBoxContainer/Button]

func _ready():
	$Control/CombatOptions2.hide()
	for button_node in players_button_nodes:
		button_node.disabled = true

	$Control.modulate = Color.TRANSPARENT

func _process(_delta):
	#if Input.is_action_just_pressed("attack")&&:
	pass

func health_UI_update(player):
	players_health_label_nodes[player].text = str(PartyStatsComponent.health[player])

# CombatOptions1

# attack button
func _on_attack_button_up():
	pass

func _on_attack_button_down():
	pass

func _on_attack_pressed():
	hide_combat_options_2()

# skill button
func _on_skills_button_up():
	pass

func _on_skills_button_down():
	pass

func _on_skills_pressed():
	if combat_options_2_node.visible&&combat_options_2_modes[0].visible: hide_combat_options_2()
	else:
		hide_combat_options_2()
		combat_options_2_node.show()
		combat_options_2_modes[0].show()

# white magic button
func _on_white_magic_button_up():
	pass

func _on_white_magic_button_down():
	pass

func _on_white_magic_pressed():
	if combat_options_2_node.visible&&combat_options_2_modes[1].visible: hide_combat_options_2()
	else:
		hide_combat_options_2()
		combat_options_2_node.show()
		combat_options_2_modes[1].show()

# black magic button
func _on_black_magic_button_up():
	pass

func _on_black_magic_button_down():
	pass

func _on_black_magic_pressed():
	if combat_options_2_node.visible&&combat_options_2_modes[2].visible: hide_combat_options_2()
	else:
		hide_combat_options_2()
		combat_options_2_node.show()
		combat_options_2_modes[2].show()

# items button
func _on_items_button_up():
	pass

func _on_items_button_down():
	pass

func _on_items_pressed():
	if combat_options_2_node.visible&&combat_options_2_modes[3].visible:
		hide_combat_options_2()
		print("visible")
	else:
		hide_combat_options_2()
		combat_options_2_node.show()
		combat_options_2_modes[3].show()

# CombatOptions2
func choose_combat_options_2_mode(show_mode):
	combat_options_2_modes[show_mode].show()

func hide_combat_options_2():
	combat_options_2_node.hide()
	for i in 4:
		combat_options_2_modes[i].hide()

func _on_protect_pressed():
	pass

##### temporary kamikaze for tests
func _on_doom_pressed():
	for i in PartyStatsComponent.active_players: PartyStatsComponent.health[i] = 0

# consume potion
func _on_potion_pressed():
	PartyStatsComponent.health[0] += 5
	hide_combat_options_2()

func _on_x_potion_pressed():
	PartyStatsComponent.health[0] += 200
	hide_combat_options_2()

func _on_phoenix_feather_pressed():
	PartyStatsComponent.alive[0] = true
	PartyStatsComponent.health[0] = PartyStatsComponent.max_health[0] * 0.5
	PartyStatsComponent.players[0].set_physics_process(true)
	PartyStatsComponent.players[0]._on_entities_detection_area_body_exited(PartyStatsComponent.players[GlobalSettings.current_main_player])
