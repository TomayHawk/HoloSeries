extends CanvasLayer

@onready var nexus_node = get_parent()

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

func _on_unlock_pressed():
	nexus_node.unlock_node()

func update_character_selector():
	for button in nexus_character_selector_player_nodes:
		button.hide()

	var i = 0
	for player in GlobalSettings.party_player_nodes:
		nexus_character_selector_player_nodes[i].show()
		nexus_character_selector_name_nodes[i].text = player.character_specifics_node.character_name
		nexus_character_selector_level_nodes[i].text = "Lvl " + str(player.player_stats_node.level).pad_zeros(3)
		i += 1
	for player in GlobalSettings.standby_player_nodes:
		nexus_character_selector_player_nodes[i].show()
		nexus_character_selector_name_nodes[i].text = player.character_specifics_node.character_name
		nexus_character_selector_level_nodes[i].text = "Lvl " + str(player.player_stats_node.level).pad_zeros(3)
		i += 1

func _on_nexus_character_selector_button_pressed(extra_arg_0: int):
	print(extra_arg_0)
