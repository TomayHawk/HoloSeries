extends CanvasLayer

@onready var nexus := get_parent()
@onready var nexus_player := get_parent().get_node(^"NexusPlayer")

@onready var options_node := %Options

@onready var inventory_node := %InventoryMargin
@onready var inventory_items_nodes := %InventoryVBoxContainer.get_children()

@onready var descriptions_node := %DescriptionsMargin
@onready var descriptions_label_node := %DescriptionsTextAreaLabel

@onready var character_selector_node := %CharacterSelector
@onready var character_selector_player_nodes := %CharacterSelectorVBoxContainer.get_children()

var character_selector_name_labels: Array[Label] = []
var character_selector_level_labels: Array[Label] = []

var character_selector_character_indices: Array[int] = []

var inventory_quantity_labels: Array[Label] = []

@onready var inventory_options_valid_node_atlas_positions := {
	0: [[nexus.STATS_ATLAS_POSITIONS[0], nexus.STATS_ATLAS_POSITIONS[2], nexus.STATS_ATLAS_POSITIONS[4]], "Unlocks HP, DEF and ATK nodes.", &"attempt_unlock"],
	1: [[nexus.STATS_ATLAS_POSITIONS[1], nexus.STATS_ATLAS_POSITIONS[3], nexus.STATS_ATLAS_POSITIONS[5]], "Unlocks MP, WRD and INT nodes.", &"attempt_unlock"],
	2: [[nexus.STATS_ATLAS_POSITIONS[6], nexus.STATS_ATLAS_POSITIONS[7]], "Unlocks SPD and AGI nodes.", &"attempt_unlock"],
	3: [[nexus.ABILITY_ATLAS_POSITIONS[0]], "Unlocks Skill nodes.", &"attempt_unlock"],
	4: [[nexus.ABILITY_ATLAS_POSITIONS[1]], "Unlocks White Magic nodes.", &"attempt_unlock"],
	5: [[nexus.ABILITY_ATLAS_POSITIONS[2]], "Unlocks Black Magic nodes.", &"attempt_unlock"],
	6: [[nexus.KEY_ATLAS_POSITIONS[0]], "Unlocks Diamond Key nodes.", &"attempt_unlock"],
	7: [[nexus.KEY_ATLAS_POSITIONS[1]], "Unlocks Clover Key nodes.", &"attempt_unlock"],
	8: [[nexus.KEY_ATLAS_POSITIONS[2]], "Unlocks Heart Key nodes.", &"attempt_unlock"],
	9: [[nexus.KEY_ATLAS_POSITIONS[3]], "Unlocks Spade Key nodes.", &"attempt_unlock"],
	10: [[nexus.ABILITY_ATLAS_POSITIONS[0]], "Unlocks any Skill node.", &"attempt_unlock"],
	11: [[nexus.ABILITY_ATLAS_POSITIONS[1]], "Unlocks any White Magic node.", &"attempt_unlock"],
	12: [[nexus.ABILITY_ATLAS_POSITIONS[2]], "Unlocks any Black Magic node.", &"attempt_unlock"],
	13: [nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION], "Unlocks any one node.", &"attempt_unlock"],
	14: [nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION], "Teleports player to any unlocked node.", &"teleport", "return"],
	15: [nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION], "Teleports player to any current ally node.", &"teleport", "ally"],
	16: [nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION], "Teleports player to any node.", &"teleport", "any"],
	17: [[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into an HP node.", &"convert", nexus.STATS_ATLAS_POSITIONS[0]],
	18: [[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into an MP node.", &"convert", nexus.STATS_ATLAS_POSITIONS[1]],
	19: [[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into a DEF node.", &"convert", nexus.STATS_ATLAS_POSITIONS[2]],
	20: [[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into a WRD node.", &"convert", nexus.STATS_ATLAS_POSITIONS[3]],
	21: [[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into an ATK node.", &"convert", nexus.STATS_ATLAS_POSITIONS[4]],
	22: [[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into an INT node.", &"convert", nexus.STATS_ATLAS_POSITIONS[5]],
	23: [[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into a SPD node.", &"convert", nexus.STATS_ATLAS_POSITIONS[6]],
	24: [[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into an AGI node.", &"convert", nexus.STATS_ATLAS_POSITIONS[7]],
	25: [nexus.STATS_ATLAS_POSITIONS.duplicate(), "Converts a stats node into an empty node.", &"convert", nexus.EMPTY_ATLAS_POSITION]
}

const stats_type_description := ["Health Point", "Mana Point", "Defense", "Ward", "Attack", "Intelligence", "Speed", "Agility"]
const key_type_description := ["Star", "Prosperity", "Love", "Nobility"]
const ability_type_description := ["", "", "", "", "", "", "", "", "", ""]

func _ready():
	for i in 6:
		character_selector_name_labels.append(character_selector_player_nodes[i].get_node_or_null(^"MarginContainer/HBoxContainer/HBoxContainer/CharacterName"))
		character_selector_level_labels.append(character_selector_player_nodes[i].get_node_or_null(^"MarginContainer/HBoxContainer/HBoxContainer/Level"))
	
	for i in 26:
		inventory_quantity_labels.append(inventory_items_nodes[i].get_node_or_null(^"Label2"))
		inventory_quantity_labels[i].text = str(Inventory.nexus_inventory[i])
	
	hide_all()
	character_selector_node.hide()
	call_deferred(&"update_character_selector")
	call_deferred(&"update_nexus_ui")
	call_deferred(&"update_inventory_buttons")

func update_nexus_ui():
	var node_quality_string = str(Global.nexus_qualities[nexus.last_nodes[nexus.current_stats]])
	var node_atlas_position = nexus.nexus_nodes[nexus.last_nodes[nexus.current_stats]].texture.region.position

	if node_quality_string == "0":
		if node_atlas_position == nexus.EMPTY_ATLAS_POSITION:
			descriptions_label_node.text = "Empty Node."
		elif node_atlas_position == nexus.NULL_ATLAS_POSITION:
			descriptions_label_node.text = "Null Node."
		elif nexus.KEY_ATLAS_POSITIONS.has(node_atlas_position):
			descriptions_label_node.text = "Requires " + key_type_description[nexus.KEY_ATLAS_POSITIONS.find(node_atlas_position)] + " Crystal to Unlock."
		elif nexus.ABILITY_ATLAS_POSITIONS.has(node_atlas_position):
			descriptions_label_node.text = "Unlock " + "[Ability Name]" + "."
	else:
		descriptions_label_node.text = "Gain " + node_quality_string + " " + stats_type_description[nexus.STATS_ATLAS_POSITIONS.find(node_atlas_position)] + "."

	options_node.show()
	descriptions_node.show()

func hide_all():
	options_node.hide()
	descriptions_node.hide()
	inventory_node.hide()

func update_character_selector():
	for button in character_selector_player_nodes:
		button.hide()

	var i = 0
	# TODO: remove this -> character_selector_origin_player_nodes.clear()
	character_selector_character_indices.clear()

	for player in Players.get_children() + Players.standby_node.get_children():
		var character = player if not player is PlayerBase else player.stats
		if character.CHARACTER_INDEX != nexus_player.CHARACTER_INDEX:
			character_selector_player_nodes[i].show()
			character_selector_name_labels[i].text = character.CHARACTER_NAME
			character_selector_level_labels[i].text = "Lvl " + str(character.level).pad_zeros(3)
			# TODO: remove this -> character_selector_origin_player_nodes.append(player)
			character_selector_character_indices.append(character.CHARACTER_INDEX)
			i += 1

func _on_unlock_pressed():
	if nexus_player.velocity == Vector2.ZERO:
		nexus.unlock_node()

func _on_upgrade_pressed():
	pass # Replace with function body.

func _on_awaken_pressed():
	pass # Replace with function body.

func _on_items_pressed():
	update_inventory_buttons()
	options_node.hide()
	inventory_node.show()

func _on_use_item_pressed():
	options_node.show()

func _on_cancel_pressed():
	options_node.show()

# nexus inventory button signals
func _on_nexus_inventory_item_pressed(extra_arg_0):
	descriptions_label_node.text = inventory_options_valid_node_atlas_positions[extra_arg_0][1]
	# if player is not moving and inventory is not empty
	if nexus_player.velocity == Vector2.ZERO and Inventory.nexus_inventory[extra_arg_0] != 0 and inventory_items_nodes[extra_arg_0].modulate == Color(1, 1, 1, 1):
		# wait for double click
		# call appropriate function
		if inventory_options_valid_node_atlas_positions[extra_arg_0][2] == &"attempt_unlock":
			call(&"attempt_unlock")
		else:
			call(inventory_options_valid_node_atlas_positions[extra_arg_0][2], inventory_options_valid_node_atlas_positions[extra_arg_0][3])
			
		update_inventory_buttons()

func update_inventory_buttons():
	for i in 26:
		if Inventory.nexus_inventory[i] == 0:
			inventory_items_nodes[i].hide()
		elif nexus.nexus_nodes[nexus.last_nodes[nexus.current_stats]].texture.region.position in inventory_options_valid_node_atlas_positions[i][0]:
			if i < 14 and nexus.last_nodes[nexus.current_stats] in nexus.nodes_unlocked[nexus.current_stats]:
				inventory_items_nodes[i].modulate = Color(0.3, 0.3, 0.3, 1)
			elif i > 16 and nexus.last_nodes[nexus.current_stats] not in nexus.nodes_unlocked[nexus.current_stats]:
				inventory_items_nodes[i].modulate = Color(0.3, 0.3, 0.3, 1)
			else:
				inventory_items_nodes[i].modulate = Color(1, 1, 1, 1)
		else:
			inventory_items_nodes[i].modulate = Color(0.3, 0.3, 0.3, 1)

func attempt_unlock():
	nexus.unlock_node()

func teleport(type):
	var valid = false

	if type == "return":
		if nexus.last_nodes[nexus.current_stats] in nexus.nodes_unlocked[nexus.current_stats]:
			valid = true
	elif type == "ally":
		for player_index in nexus.nodes_unlocked.size():
			if player_index != nexus.current_stats and nexus.last_nodes[nexus.current_stats] in nexus.nodes_unlocked[player_index]:
				valid = true
	elif type == "any":
		valid = true
	
	if valid:
		pass

func convert(target_type_position):
	nexus.nodes_converted[nexus.current_stats].append([nexus.last_nodes[nexus.current_stats], target_type_position])
	if nexus.nexus_nodes[nexus.last_nodes[nexus.current_stats]].texture.region.position == nexus.EMPTY_ATLAS_POSITION:
		nexus.nodes_converted[nexus.current_stats].back().append(0)
	else:
		for i in nexus.STATS_ATLAS_POSITIONS.size():
			if nexus.nexus_nodes[nexus.last_nodes[nexus.current_stats]].texture.region.position == nexus.STATS_ATLAS_POSITIONS[i]:
				nexus.nodes_converted[nexus.current_stats].back().append(nexus.CONVERTED_QUALITIES[i])
				break

	nexus.nexus_nodes[nexus.last_nodes[nexus.current_stats]].texture.region.position = target_type_position
	nexus.unlock_node()

func _on_button_mouse_entered():
	Inputs.zoom_inputs_enabled = false

func _on_button_mouse_exited():
	Inputs.zoom_inputs_enabled = true

func _on_scroll_container_gui_input(_event):
	pass

func _on_character_selector_button_pressed(extra_arg_0):
	nexus.update_nexus_player(character_selector_character_indices[extra_arg_0])
	update_character_selector()
