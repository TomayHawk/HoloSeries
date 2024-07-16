extends CanvasLayer

@onready var nexus = get_parent()
@onready var nexus_player = nexus.get_node("NexusPlayer")

@onready var nexus_character_selector_node = $NexusCharacterSelector

@onready var nexus_character_selector_player_nodes = [nexus_character_selector_node.get_node("MarginContainer/MarginContainer/ScrollContainer/VBoxContainer/Character1"),
													  nexus_character_selector_node.get_node("MarginContainer/MarginContainer/ScrollContainer/VBoxContainer/Character2"),
													  nexus_character_selector_node.get_node("MarginContainer/MarginContainer/ScrollContainer/VBoxContainer/Character3"),
													  nexus_character_selector_node.get_node("MarginContainer/MarginContainer/ScrollContainer/VBoxContainer/Character4"),
													  nexus_character_selector_node.get_node("MarginContainer/MarginContainer/ScrollContainer/VBoxContainer/Character5"),
													  nexus_character_selector_node.get_node("MarginContainer/MarginContainer/ScrollContainer/VBoxContainer/Character6")]

@onready var nexus_character_selector_name_nodes = [nexus_character_selector_player_nodes[0].get_node("MarginContainer/HBoxContainer/HBoxContainer/CharacterName"),
													nexus_character_selector_player_nodes[1].get_node("MarginContainer/HBoxContainer/HBoxContainer/CharacterName"),
													nexus_character_selector_player_nodes[2].get_node("MarginContainer/HBoxContainer/HBoxContainer/CharacterName"),
													nexus_character_selector_player_nodes[3].get_node("MarginContainer/HBoxContainer/HBoxContainer/CharacterName"),
													nexus_character_selector_player_nodes[4].get_node("MarginContainer/HBoxContainer/HBoxContainer/CharacterName"),
													nexus_character_selector_player_nodes[5].get_node("MarginContainer/HBoxContainer/HBoxContainer/CharacterName")]

@onready var nexus_character_selector_level_nodes = [nexus_character_selector_player_nodes[0].get_node("MarginContainer/HBoxContainer/HBoxContainer/Level"),
													 nexus_character_selector_player_nodes[1].get_node("MarginContainer/HBoxContainer/HBoxContainer/Level"),
													 nexus_character_selector_player_nodes[2].get_node("MarginContainer/HBoxContainer/HBoxContainer/Level"),
													 nexus_character_selector_player_nodes[3].get_node("MarginContainer/HBoxContainer/HBoxContainer/Level"),
													 nexus_character_selector_player_nodes[4].get_node("MarginContainer/HBoxContainer/HBoxContainer/Level"),
													 nexus_character_selector_player_nodes[5].get_node("MarginContainer/HBoxContainer/HBoxContainer/Level")]

var nexus_character_selector_origin_player_nodes = []
var nexus_character_selector_character_indices = []

func _on_unlock_pressed():
	if nexus_player.velocity == Vector2.ZERO:
		nexus.unlock_node()

func update_character_selector():
	for button in nexus_character_selector_player_nodes:
		button.hide()

	var i = 0
	nexus_character_selector_origin_player_nodes.clear()
	nexus_character_selector_character_indices.clear()

	for player in GlobalSettings.party_player_nodes:
		if player.character_specifics_node.character_index != nexus_player.character_index:
			nexus_character_selector_player_nodes[i].show()
			nexus_character_selector_name_nodes[i].text = player.character_specifics_node.character_name
			nexus_character_selector_level_nodes[i].text = "Lvl " + str(player.player_stats_node.level).pad_zeros(3)
			nexus_character_selector_origin_player_nodes.push_back(player)
			nexus_character_selector_character_indices.push_back(player.character_specifics_node.character_index)
			i += 1
	for player in GlobalSettings.standby_player_nodes:
		nexus_character_selector_player_nodes[i].show()
		nexus_character_selector_name_nodes[i].text = player.character_specifics_node.character_name
		nexus_character_selector_level_nodes[i].text = "Lvl " + str(player.player_stats_node.level).pad_zeros(3)
		i += 1

func _on_nexus_character_selector_button_pressed(extra_arg_0):
	print(nexus_character_selector_origin_player_nodes[extra_arg_0])
	print(nexus_player.character_index[extra_arg_0])
	nexus_player.update_nexus_player(extra_arg_0)

func _on_nexus_inventory_item_pressed(extra_arg_0):
	if GlobalSettings.nexus_inventory[extra_arg_0] > 0:
		var temp_position = nexus.last_node[nexus.current_nexus_player].texture.region.position
		if temp_position == nexus.empty_node_atlas_position:
			if extra_arg_0 in [10, 14, 15, 16]:
				pass
			elif extra_arg_0 in [17, 18, 19, 20, 21, 22, 23, 24]:
				pass
		elif temp_position in nexus.stats_node_atlas_position:
			if extra_arg_0 == 25:
				pass
			else:
				pass
