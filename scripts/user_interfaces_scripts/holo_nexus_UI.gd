extends CanvasLayer

@onready var nexus := get_parent()
@onready var nexus_player := nexus.get_node("NexusPlayer")

@onready var nexus_character_selector_node := $NexusCharacterSelector

@onready var nexus_character_selector_player_nodes := nexus_character_selector_node.get_node("MarginContainer/MarginContainer/ScrollContainer/VBoxContainer").get_children()

var nexus_character_selector_name_nodes: Array[Node] = []
var nexus_character_selector_level_nodes: Array[Node] = []

var nexus_character_selector_origin_player_nodes: Array[Node] = []
var nexus_character_selector_character_indices: Array[int] = []

@onready var nexus_inventory_options_valid_node_atlas_positions := {
	0: [[nexus.stats_node_atlas_position[0],nexus.stats_node_atlas_position[2],nexus.stats_node_atlas_position[4]],nexus, "unlock_node"],
	1: [[nexus.stats_node_atlas_position[1],nexus.stats_node_atlas_position[3],nexus.stats_node_atlas_position[5]],nexus, "unlock_node"],
	2: [[nexus.stats_node_atlas_position[6],nexus.stats_node_atlas_position[7]],nexus, "unlock_node"],
	3: [[nexus.ability_node_atlas_position[0]],nexus, "unlock_node"],
	4: [[nexus.ability_node_atlas_position[1]],nexus, "unlock_node"],
	5: [[nexus.ability_node_atlas_position[2]],nexus, "unlock_node"],
	6: [[nexus.key_node_atlas_position[0]],nexus, "unlock_node"],
	7: [[nexus.key_node_atlas_position[1]],nexus, "unlock_node"],
	8: [[nexus.key_node_atlas_position[2]],nexus, "unlock_node"],
	9: [[nexus.key_node_atlas_position[3]],nexus, "unlock_node"],
	10: [nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position],nexus, "unlock_node"],
	11: [[nexus.ability_node_atlas_position[0]],nexus, "unlock_node"],
	12: [[nexus.ability_node_atlas_position[1]],nexus, "unlock_node"],
	13: [[nexus.ability_node_atlas_position[2]],nexus, "unlock_node"],
	14: [nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position],nexus, "unlock_node"],
	15: [nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position],self, "ally_teleport"],
	16: [nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position],self, "any_teleport"],
	17: [[nexus.empty_node_atlas_position],self, "check_node_is_locked"],
	18: [[nexus.empty_node_atlas_position],self, "check_node_is_locked"],
	19: [[nexus.empty_node_atlas_position],self, "check_node_is_locked"],
	20: [[nexus.empty_node_atlas_position],self, "check_node_is_locked"],
	21: [[nexus.empty_node_atlas_position],self, "check_node_is_locked"],
	22: [[nexus.empty_node_atlas_position],self, "check_node_is_locked"],
	23: [[nexus.empty_node_atlas_position],self, "check_node_is_locked"],
	24: [[nexus.empty_node_atlas_position],self, "check_node_is_locked"],
	25: [nexus.stats_node_atlas_position.duplicate(), self, "check_node_is_locked"]
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

# nexus inventory button signals
func _on_nexus_inventory_item_pressed(extra_arg_0):
	# if player is not moving and inventory is not empty
	if nexus_player.velocity == Vector2.ZERO&&GlobalSettings.nexus_inventory[extra_arg_0] == 0: # #### should be > 0 instead of == 0
		# if item is valid for current node type
		if nexus.nexus_nodes[nexus.last_node[nexus.current_nexus_player]].texture.region.position in nexus_inventory_options_valid_node_atlas_positions[extra_arg_0][0]:
			# call appropriate function
			nexus_inventory_options_valid_node_atlas_positions[extra_arg_0][1].call(nexus_inventory_options_valid_node_atlas_positions[extra_arg_0][2])

func ally_teleport():
	pass

func any_teleport():
	pass

func check_node_is_locked():
	pass
	'''
	if nexus.last_node[nexus.current_nexus_player]:
		return true
	'''