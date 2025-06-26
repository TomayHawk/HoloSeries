extends AnimatedSprite2D

enum NpcState {
	NEVER_SPOKEN,
	REGULAR,
	SHOP_OPEN,
	SHOP_CLOSED,
	CAN_RECRUIT,
}

var npc_state := NpcState.CAN_RECRUIT

func initiate_dialogue():
	match npc_state:
		NpcState.NEVER_SPOKEN:
			default_dialogue()
		NpcState.SHOP_OPEN:
			pass
		NpcState.SHOP_CLOSED:
			pass
		NpcState.CAN_RECRUIT:
			default_dialogue()
		_:
			default_dialogue()

func default_dialogue():
	var resp_index := 0
	var responses := []

	TextBox.npcDialogue(["Do you want to recruit me?"], ["Yes", "No", "Hell No"])
	
	resp_index = await TextBox.option_selected
	responses = [
		[["Thank You!", "I will join your party."], []],
		[["But Why"], ["Potato Salad", "French Fries"]],
		[["????"], []],
	]
	
	TextBox.npcDialogue(responses[resp_index][0], responses[resp_index][1])
	
	if resp_index == 1:
		resp_index = await TextBox.option_selected
		responses = [
			[["Thank You!", "I will join your party."], []],
			[[], []],
		] # TODO: want textbox fade out animation
		
		TextBox.npcDialogue(responses[resp_index][0], responses[resp_index][1])

	# end dialogue if not recruiting
	if resp_index == 0:
		recruit_player()
		queue_free()

func recruit_player() -> void:
	var character: Node = load("res://entities/players/character/akirose.tscn").instantiate()
	if Players.get_child_count() < 4 and Players.standby_node.get_child_count() == 0:
		var player_node: Node = load("res://entities/players/player_base.tscn").instantiate()
		Players.add_child(player_node)
		player_node.add_child(character)
		player_node.stats = character
		
		character.node_index = Players.get_child_count() - 1 # TODO
		player_node.position = Players.main_player.position + (25 * Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)))
		
		# TODO: make function for this
		Combat.ui.character_name_label_nodes[character.node_index].text = character.CHARACTER_NAME
		Combat.ui.players_info_nodes[character.node_index].show()
		Combat.ui.ultimate_progress_bar_nodes[character.node_index].show()
		Combat.ui.shield_progress_bar_nodes[character.node_index].show()
	else:
		Players.standby_node.add_child(character)
		character.node_index = character.get_index()

	character.level = 1
	character.base_health = 396.0
	character.base_mana = 26.0
	character.base_stamina = 100.0
	character.base_defense = 11.0
	character.base_ward = 11.0
	character.base_strength = 14.0
	character.base_intelligence = 12.0
	character.base_speed = 0.0
	character.base_agility = 0.0
	character.base_crit_chance = 0.05
	character.base_crit_damage = 0.60

	character.last_node = 522
	character.unlocked_nodes = [491, 522, 523]
	Global.nexus_converted_nodes[3] = []

	var standby_button: Button = load("res://user_interfaces/user_interfaces_resources/combat_ui/standby_button.tscn").instantiate()
	Combat.ui.get_node(^"CharacterSelector/MarginContainer/ScrollContainer/CharacterSelectorVBoxContainer").add_child(standby_button)
	standby_button.pressed.connect(Players.switch_standby_character.bind(standby_button.get_index()))
	standby_button.pressed.connect(Combat.ui.button_pressed)
	standby_button.mouse_entered.connect(Combat.ui._on_control_mouse_entered)
	standby_button.mouse_exited.connect(Combat.ui._on_control_mouse_exited)
	
	Combat.ui.standby_name_labels.append(standby_button.get_node(^"Name"))
	Combat.ui.standby_level_labels.append(standby_button.get_node(^"Level"))
	Combat.ui.standby_health_labels.append(standby_button.get_node(^"HealthAmount"))
	Combat.ui.standby_mana_labels.append(standby_button.get_node(^"ManaAmount"))

	# TODO: nexus

	character.update_nodes()

	if character.node_index == -1:
		Combat.ui.update_character_selector()
