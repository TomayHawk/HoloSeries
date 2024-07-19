extends CanvasLayer

@onready var nexus := get_parent()
@onready var nexus_player := nexus.get_node("NexusPlayer")

@onready var nexus_character_selector_node := $NexusCharacterSelector

@onready var nexus_character_selector_player_nodes := nexus_character_selector_node.get_node("MarginContainer/MarginContainer/ScrollContainer/VBoxContainer").get_children()

var nexus_character_selector_name_nodes: Array[Node] = []
var nexus_character_selector_level_nodes: Array[Node] = []
var nexus_character_selector_origin_player_nodes: Array[Node] = []
var nexus_character_selector_character_indices: Array[int] = []

###########################################
@onready var nexus_inventory_options_valid_atlas_positions := {
	0: [nexus.stats_node_atlas_position[0],nexus.stats_node_atlas_position[2],nexus.stats_node_atlas_position[4]],
	1: [nexus.stats_node_atlas_position[1],nexus.stats_node_atlas_position[3],nexus.stats_node_atlas_position[5]],
	2: [nexus.stats_node_atlas_position[6],nexus.stats_node_atlas_position[7]],
	3: [nexus.ability_node_atlas_position[0]],
	4: [nexus.ability_node_atlas_position[1]],
	5: [nexus.ability_node_atlas_position[2]],
	6: [nexus.key_node_atlas_position[0]],
	7: [nexus.key_node_atlas_position[1]],
	8: [nexus.key_node_atlas_position[2]],
	9: [nexus.key_node_atlas_position[3]],
	10: nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position],
	11: [nexus.ability_node_atlas_position[0]],
	12: [nexus.ability_node_atlas_position[1]],
	13: [nexus.ability_node_atlas_position[2]],
	14: nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position],
	15: nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position],
	16: nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position],
	17: [nexus.empty_node_atlas_position],
	18: [nexus.empty_node_atlas_position],
	19: [nexus.empty_node_atlas_position],
	20: [nexus.empty_node_atlas_position],
	21: [nexus.empty_node_atlas_position],
	22: [nexus.empty_node_atlas_position],
	23: [nexus.empty_node_atlas_position],
	24: [nexus.empty_node_atlas_position],
	25: [nexus.stats_node_atlas_position.duplicate()]
}

func _ready():
	for i in 6:
		nexus_character_selector_name_nodes.push_back(nexus_character_selector_player_nodes[i].get_node("MarginContainer/HBoxContainer/HBoxContainer/CharacterName"))
		nexus_character_selector_level_nodes.push_back(nexus_character_selector_player_nodes[i].get_node("MarginContainer/HBoxContainer/HBoxContainer/Level"))

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
	if GlobalSettings.nexus_inventory[extra_arg_0] == 0:
		print(nexus_inventory_options_valid_atlas_positions[extra_arg_0])
		if nexus.nexus_nodes[nexus.last_node[nexus.current_nexus_player]].texture.region.position in nexus_inventory_options_valid_atlas_positions[extra_arg_0]:
			print("true")
