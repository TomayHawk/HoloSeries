extends Node2D

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
	var character_node: Node = load("res://entities/players/character_base/akirose.tscn").instantiate()
	if Players.party_node.get_children().size() < 4 and Players.standby_node.get_children().size() == 0:
		var player_node: Node = load("res://entities/players/player_base.tscn").instantiate()
		Players.party_node.add_child(player_node)
		player_node.add_child(character_node)
		player_node.character_node = character_node
		
		character_node.party_index = Players.party_node.get_children().size() - 1
		player_node.position = Players.main_player_node.position + (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
		
		# TODO: make function for this
		Combat.ui.character_name_label_nodes[character_node.party_index].text = character_node.character_name
		Combat.ui.players_info_nodes[character_node.party_index].show()
		Combat.ui.ultimate_progress_bar_nodes[character_node.party_index].show()
		Combat.ui.shield_progress_bar_nodes[character_node.party_index].show()
	else:
		Players.standby_node.add_child(character_node)
		character_node.party_index = -1

	character_node.level = 1
	character_node.base_health = 396.0
	character_node.base_mana = 26.0
	character_node.base_stamina = 100.0
	character_node.base_defense = 11.0
	character_node.base_ward = 11.0
	character_node.base_strength = 14.0
	character_node.base_intelligence = 12.0
	character_node.base_speed = 0.0
	character_node.base_agility = 0.0
	character_node.base_crit_chance = 0.05
	character_node.base_crit_damage = 0.60

	# TODO: nexus

	character_node.update_stats()

	if character_node.party_index == -1:
		Combat.ui.update_character_selector()
