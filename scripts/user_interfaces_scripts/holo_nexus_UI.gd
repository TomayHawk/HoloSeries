extends CanvasLayer

@onready var nexus := get_parent()
@onready var nexus_player := nexus.get_node("NexusPlayer")

@onready var options_node := $Control/Options

@onready var inventory_node := $Control/NexusInventory
@onready var inventory_items_nodes := $Control/NexusInventory/MarginContainer/ScrollContainer/VBoxContainer.get_children()

@onready var descriptions_node := $Control/DescriptionsContainer
@onready var descriptions_label_node := $Control/DescriptionsContainer/MarginContainer/HBoxContainer/TextArea

@onready var character_selector_node := $NexusCharacterSelector
@onready var character_selector_player_nodes := $NexusCharacterSelector/MarginContainer/MarginContainer/ScrollContainer/VBoxContainer.get_children()

var character_selector_name_nodes: Array[Node] = []
var character_selector_level_nodes: Array[Node] = []

var character_selector_origin_player_nodes: Array[Node] = []
var character_selector_character_indices: Array[int] = []

var inventory_items_quantity_label: Array[Node] = []

@onready var inventory_options_valid_node_atlas_positions := {
	0: [[nexus.stats_node_atlas_position[0], nexus.stats_node_atlas_position[2], nexus.stats_node_atlas_position[4]], "Unlocks HP, DEF and ATK nodes.", "attempt_unlock"],
	1: [[nexus.stats_node_atlas_position[1], nexus.stats_node_atlas_position[3], nexus.stats_node_atlas_position[5]], "Unlocks MP, SHD and INT nodes.", "attempt_unlock"],
	2: [[nexus.stats_node_atlas_position[6], nexus.stats_node_atlas_position[7]], "Unlocks SPD and AGI nodes.", "attempt_unlock"],
	3: [[nexus.ability_node_atlas_position[0]], "Unlocks Skill nodes.", "attempt_unlock"],
	4: [[nexus.ability_node_atlas_position[1]], "Unlocks White Magic nodes.", "attempt_unlock"],
	5: [[nexus.ability_node_atlas_position[2]], "Unlocks Black Magic nodes.", "attempt_unlock"],
	6: [[nexus.key_node_atlas_position[0]], "Unlocks Diamond Key nodes.", "attempt_unlock"],
	7: [[nexus.key_node_atlas_position[1]], "Unlocks Clover Key nodes.", "attempt_unlock"],
	8: [[nexus.key_node_atlas_position[2]], "Unlocks Heart Key nodes.", "attempt_unlock"],
	9: [[nexus.key_node_atlas_position[3]], "Unlocks Spade Key nodes.", "attempt_unlock"],
	10: [[nexus.ability_node_atlas_position[0]], "Unlocks any Skill node.", "attempt_unlock"],
	11: [[nexus.ability_node_atlas_position[1]], "Unlocks any White Magic node.", "attempt_unlock"],
	12: [[nexus.ability_node_atlas_position[2]], "Unlocks any Black Magic node.", "attempt_unlock"],
	13: [nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position], "Unlocks any one node.", "attempt_unlock"],
	14: [nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position], "Teleports player to any unlocked node.", "teleport", "return"],
	15: [nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position], "Teleports player to any current ally node.", "teleport", "ally"],
	16: [nexus.stats_node_atlas_position.duplicate() + nexus.ability_node_atlas_position.duplicate() + nexus.key_node_atlas_position.duplicate() + [nexus.empty_node_atlas_position], "Teleports player to any node.", "teleport", "any"],
	17: [[nexus.empty_node_atlas_position], "Converts an empty node into an HP node.", "convert", nexus.stats_node_atlas_position[0]],
	18: [[nexus.empty_node_atlas_position], "Converts an empty node into an MP node.", "convert", nexus.stats_node_atlas_position[1]],
	19: [[nexus.empty_node_atlas_position], "Converts an empty node into a DEF node.", "convert", nexus.stats_node_atlas_position[2]],
	20: [[nexus.empty_node_atlas_position], "Converts an empty node into a SHD node.", "convert", nexus.stats_node_atlas_position[3]],
	21: [[nexus.empty_node_atlas_position], "Converts an empty node into an ATK node.", "convert", nexus.stats_node_atlas_position[4]],
	22: [[nexus.empty_node_atlas_position], "Converts an empty node into an INT node.", "convert", nexus.stats_node_atlas_position[5]],
	23: [[nexus.empty_node_atlas_position], "Converts an empty node into a SPD node.", "convert", nexus.stats_node_atlas_position[6]],
	24: [[nexus.empty_node_atlas_position], "Converts an empty node into an AGI node.", "convert", nexus.stats_node_atlas_position[7]],
	25: [nexus.stats_node_atlas_position.duplicate(), "Converts a stats node into an empty node.", "convert", nexus.empty_node_atlas_position]
}

const stats_type_description := ["Health Point", "Mana Point", "Defence", "Shield", "Attack", "Intelligence", "Speed", "Agility"]
const key_type_description := ["Star", "Prosperity", "Love", "Nobility"]
const ability_type_description := ["", "", "", "", "", "", "", "", "", ""]

func _ready():
	for i in 6:
		character_selector_name_nodes.push_back(character_selector_player_nodes[i].get_node("MarginContainer/HBoxContainer/HBoxContainer/CharacterName"))
		character_selector_level_nodes.push_back(character_selector_player_nodes[i].get_node("MarginContainer/HBoxContainer/HBoxContainer/Level"))
	
	for i in 26:
		inventory_items_quantity_label.push_back(inventory_items_nodes[i].get_node("Label2"))
		inventory_items_quantity_label[i].text = str(GlobalSettings.nexus_inventory[i])
	
	call_deferred("update_inventory_buttons")
	call_deferred("update_nexus_ui")
	character_selector_node.hide()
	hide_all()

func _input(event):
	if event is InputEventMouseButton && event.is_double_click():
		print("double click ", event.is_double_click())


func update_nexus_ui():
	var node_quality_string = str(nexus.nodes_quality[nexus.last_nodes[nexus.current_nexus_player]])
	var node_atlas_position = nexus.nexus_nodes[nexus.last_nodes[nexus.current_nexus_player]].texture.region.position

	if node_quality_string == "0":
		if node_atlas_position == nexus.empty_node_atlas_position:
			descriptions_label_node.text = "Empty Node."
		elif node_atlas_position == nexus.null_node_atlas_position:
			descriptions_label_node.text = "Null Node."
		elif nexus.key_node_atlas_position.has(node_atlas_position):
			descriptions_label_node.text = "Requires " + key_type_description[nexus.key_node_atlas_position.find(node_atlas_position)] + " Crystal to Unlock."
		elif nexus.ability_node_atlas_position.has(node_atlas_position):
			descriptions_label_node.text = "Unlock " + "[Ability Name]" + "."
	else:
		descriptions_label_node.text = "Gain " + node_quality_string + " " + stats_type_description[nexus.stats_node_atlas_position.find(node_atlas_position)] + "."

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
	character_selector_origin_player_nodes.clear()
	character_selector_character_indices.clear()

	for player in GlobalSettings.party_node.get_children() + GlobalSettings.standby_node.get_children():
		if player.character_specifics_node.character_index != nexus_player.character_index:
			character_selector_player_nodes[i].show()
			character_selector_name_nodes[i].text = player.character_specifics_node.character_name
			character_selector_level_nodes[i].text = "Lvl " + str(player.player_stats_node.level).pad_zeros(3)
			character_selector_origin_player_nodes.push_back(player)
			character_selector_character_indices.push_back(player.character_specifics_node.character_index)
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
	if nexus_player.velocity == Vector2.ZERO && GlobalSettings.nexus_inventory[extra_arg_0] != 0 && inventory_items_nodes[extra_arg_0].modulate == Color(1, 1, 1, 1):
		# wait for double click

		# call appropriate function
		if inventory_options_valid_node_atlas_positions[extra_arg_0][2] == "attempt_unlock":
			call("attempt_unlock")
		else:
			call(inventory_options_valid_node_atlas_positions[extra_arg_0][2], inventory_options_valid_node_atlas_positions[extra_arg_0][3])
			
		update_inventory_buttons()

func update_inventory_buttons():
	for i in 26:
		if GlobalSettings.nexus_inventory[i] == 0:
			inventory_items_nodes[i].hide()
		elif nexus.nexus_nodes[nexus.last_nodes[nexus.current_nexus_player]].texture.region.position in inventory_options_valid_node_atlas_positions[i][0]:
			if i < 14 && nexus.last_nodes[nexus.current_nexus_player] in nexus.nodes_unlocked[nexus.current_nexus_player]:
				inventory_items_nodes[i].modulate = Color(0.3, 0.3, 0.3, 1)
			elif i > 16 || i == 14 && nexus.last_nodes[nexus.current_nexus_player] not in nexus.nodes_unlocked[nexus.current_nexus_player]:
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
		if nexus.last_nodes[nexus.current_nexus_player] in nexus.nodes_unlocked[nexus.current_nexus_player]:
			valid = true
	elif type == "ally":
		for player_index in nexus.nodes_unlocked.size():
			if player_index != nexus.current_nexus_player && nexus.last_nodes[nexus.current_nexus_player] in nexus.nodes_unlocked[player_index]:
				valid = true
	elif type == "any":
		valid = true
	
	if valid:
		pass

func convert(target_type_position):
	nexus.nodes_converted_index[nexus.current_nexus_player].push_back(nexus.last_nodes[nexus.current_nexus_player])
	nexus.nodes_converted_type[nexus.current_nexus_player].push_back(target_type_position)
	if nexus.nexus_nodes[nexus.last_nodes[nexus.current_nexus_player]].texture.region.position == nexus.empty_node_atlas_position:
		nexus.nodes_converted_quality[nexus.current_nexus_player].push_back(0)
	else:
		for i in nexus.stats_node_atlas_position.size():
			if nexus.nexus_nodes[nexus.last_nodes[nexus.current_nexus_player]].texture.region.position == nexus.stats_node_atlas_position[i]:
				nexus.nodes_converted_quality[nexus.current_nexus_player].push_back(nexus.converted_stats_qualities[i])
				break

	nexus.nexus_nodes[nexus.last_nodes[nexus.current_nexus_player]].texture.region.position = target_type_position
	nexus.unlock_node()

func _on_button_mouse_entered():
	GlobalSettings.camera_node.can_zoom = false

func _on_button_mouse_exited():
	GlobalSettings.camera_node.can_zoom = true

func _on_scroll_container_gui_input(_event):
	pass

func _on_character_selector_button_pressed(extra_arg_0):
	nexus.update_nexus_player(character_selector_character_indices[extra_arg_0])
	update_character_selector()
