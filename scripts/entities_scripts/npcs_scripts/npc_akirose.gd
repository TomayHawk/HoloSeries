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
		] ## ### want textbox fade out animation
		
		TextBox.npcDialogue(responses[resp_index][0], responses[resp_index][1])

	# end dialogue if not recruiting
	if resp_index != 0:
		return

	# recruit character to either party or standby
	if GlobalSettings.party_node.get_children().size() < 4 && GlobalSettings.standby_node.get_children().size() == 0:
		recruit_character(true, "res://entities/players/player_base.tscn", GlobalSettings.party_node, "party_players", GlobalSettings.party_node.get_children().size())
	else:
		recruit_character(false, "res://entities/players/player_standby.tscn", GlobalSettings.standby_node, "standby_players", -1)

func recruit_character(in_party, base_path, parent_node, group_name, party_index):
	var player_node: Node = load(base_path).instantiate()
	player_node.add_child(load("res://entities/players/character_specifics/akirose.tscn").instantiate())
	parent_node.add_child(player_node)
	player_node.player_stats_node.update_stats()
	player_node.add_to_group(group_name)

	#!#!# add nexus data

	if in_party:
		player_node.position = GlobalSettings.current_main_player_node.position + (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))
		CombatUi.character_name_label_nodes[party_index].text = player_node.character_specifics_node.character_name
		CombatUi.players_info_nodes[party_index].show()
		CombatUi.ultimate_progress_bar_nodes[party_index].show()
		CombatUi.shield_progress_bar_nodes[party_index].show()
		GlobalSettings.current_save["party"].push_back()
	else:
		CombatUi.update_character_selector()
		GlobalSettings.current_save["standby"].push_back(player_node.character_specifics_node.character_index)
