extends CanvasLayer

# HOLONEXUS UI

# ..............................................................................

#region CONSTANTS

const stats_descriptions: Array[String] = ["Health", "Mana", "Defense", "Ward", "Attack", "Intelligence", "Speed", "Agility"]
const key_descriptions: Array[String] = ["Star", "Prosperity", "Love", "Nobility"]
const ability_descriptions: Array[String] = ["", "", "", "", "", "", "", "", "", ""]

#endregion

# ..............................................................................

#region VARIABLES

var inventory_quantity_labels: Array[Label] = []

@onready var nexus: Node2D = get_parent()

@onready var inventory_ui: MarginContainer = %InventoryMargin
@onready var descriptions_ui: MarginContainer = %DescriptionsMargin
@onready var character_selector_node: Control = %CharacterSelector

# TODO: optimize this
@onready var inventory_options_valid_node_atlas_positions := [
	[[nexus.STATS_ATLAS_POSITIONS[0], nexus.STATS_ATLAS_POSITIONS[2], nexus.STATS_ATLAS_POSITIONS[4]], "Unlocks HP, DEF and ATK nodes.", &"attempt_unlock"],
	[[nexus.STATS_ATLAS_POSITIONS[1], nexus.STATS_ATLAS_POSITIONS[3], nexus.STATS_ATLAS_POSITIONS[5]], "Unlocks MP, WRD and INT nodes.", &"attempt_unlock"],
	[[nexus.STATS_ATLAS_POSITIONS[6], nexus.STATS_ATLAS_POSITIONS[7]], "Unlocks SPD and AGI nodes.", &"attempt_unlock"],
	[[nexus.ABILITY_ATLAS_POSITIONS[0]], "Unlocks Skill nodes.", &"attempt_unlock"],
	[[nexus.ABILITY_ATLAS_POSITIONS[1]], "Unlocks White Magic nodes.", &"attempt_unlock"],
	[[nexus.ABILITY_ATLAS_POSITIONS[2]], "Unlocks Black Magic nodes.", &"attempt_unlock"],
	[[nexus.KEY_ATLAS_POSITIONS[0]], "Unlocks Diamond Key nodes.", &"attempt_unlock"],
	[[nexus.KEY_ATLAS_POSITIONS[1]], "Unlocks Clover Key nodes.", &"attempt_unlock"],
	[[nexus.KEY_ATLAS_POSITIONS[2]], "Unlocks Heart Key nodes.", &"attempt_unlock"],
	[[nexus.KEY_ATLAS_POSITIONS[3]], "Unlocks Spade Key nodes.", &"attempt_unlock"],
	[[nexus.ABILITY_ATLAS_POSITIONS[0]], "Unlocks any Skill node.", &"attempt_unlock"],
	[[nexus.ABILITY_ATLAS_POSITIONS[1]], "Unlocks any White Magic node.", &"attempt_unlock"],
	[[nexus.ABILITY_ATLAS_POSITIONS[2]], "Unlocks any Black Magic node.", &"attempt_unlock"],
	[nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION], "Unlocks any one node.", &"attempt_unlock"],
	[nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION], "Teleports player to any unlocked node.", &"teleport", "return"],
	[nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION], "Teleports player to any current ally node.", &"teleport", "ally"],
	[nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION], "Teleports player to any node.", &"teleport", "any"],
	[[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into an HP node.", &"convert", nexus.STATS_ATLAS_POSITIONS[0]],
	[[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into an MP node.", &"convert", nexus.STATS_ATLAS_POSITIONS[1]],
	[[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into a DEF node.", &"convert", nexus.STATS_ATLAS_POSITIONS[2]],
	[[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into a WRD node.", &"convert", nexus.STATS_ATLAS_POSITIONS[3]],
	[[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into an ATK node.", &"convert", nexus.STATS_ATLAS_POSITIONS[4]],
	[[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into an INT node.", &"convert", nexus.STATS_ATLAS_POSITIONS[5]],
	[[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into a SPD node.", &"convert", nexus.STATS_ATLAS_POSITIONS[6]],
	[[nexus.EMPTY_ATLAS_POSITION], "Converts an empty node into an AGI node.", &"convert", nexus.STATS_ATLAS_POSITIONS[7]],
	[nexus.STATS_ATLAS_POSITIONS.duplicate(), "Converts a stats node into an empty node.", &"convert", nexus.EMPTY_ATLAS_POSITION],
]

#endregion

# ..............................................................................

#region READY

func _ready() -> void:
	show()

	var character_button_load: PackedScene = load("res://user_interfaces/user_interfaces_resources/holo_nexus_ui/nexus_button.tscn")
	
	for stats in nexus.character_stats:
		# instantiate character button
		var character_button: Button = character_button_load.instantiate()
		%CharacterSelectorVBoxContainer.add_child(character_button)
		character_button.get_node(^"CharacterName").text = stats.CHARACTER_NAME
		character_button.get_node(^"Level").text = str(stats.level).pad_zeros(3)
		character_button.pressed.connect(_on_character_selector_button_pressed.bind(character_button.get_index()))

		# hide current player
		if nexus.current_stats == stats:
			character_button.hide()

	character_selector_node.hide()

	'''
	for i in 26:
		inventory_quantity_labels.append(%InventoryVBoxContainer.get_children()[i].get_node_or_null(^"Label2"))
		inventory_quantity_labels[i].text = str(Inventory.nexus_inventory[i])
	
	hide_all()
	call_deferred(&"update_nexus_ui")
	call_deferred(&"update_inventory_buttons")
	'''

#endregion

# ..............................................................................

#region UI UPDATES

func update_nexus_ui():
	var node_quality_string = str(Global.nexus_qualities[nexus.current_stats.last_node])
	var node_atlas_position = nexus.nexus_nodes[nexus.current_stats.last_node].texture.region.position

	if node_quality_string == "0":
		if node_atlas_position == nexus.EMPTY_ATLAS_POSITION:
			%DescriptionsTextAreaLabel.text = "Empty Node."
		elif node_atlas_position == nexus.NULL_ATLAS_POSITION:
			%DescriptionsTextAreaLabel.text = "Null Node."
		elif nexus.KEY_ATLAS_POSITIONS.has(node_atlas_position):
			%DescriptionsTextAreaLabel.text = "Requires " + key_descriptions[nexus.KEY_ATLAS_POSITIONS.find(node_atlas_position)] + " Crystal to Unlock."
		elif nexus.ABILITY_ATLAS_POSITIONS.has(node_atlas_position):
			%DescriptionsTextAreaLabel.text = "Unlock " + "[Ability Name]" + "."
	else:
		%DescriptionsTextAreaLabel.text = "Gain " + node_quality_string + " " + stats_descriptions[nexus.STATS_ATLAS_POSITIONS.find(node_atlas_position)] + "."

	%Options.show()
	descriptions_ui.show()

func hide_all():
	%Options.hide()
	inventory_ui.hide()
	descriptions_ui.hide()

func _on_unlock_pressed():
	if nexus.nexus_player.velocity == Vector2.ZERO:
		if nexus.current_stats.last_node in nexus.unlockable_nodes:
			nexus.unlock_node()

func _on_upgrade_pressed():
	pass # Replace with function body.

func _on_awaken_pressed():
	pass # Replace with function body.

func _on_items_pressed():
	update_inventory_buttons()
	%Options.hide()
	inventory_ui.show()

func _on_use_item_pressed():
	%Options.show()

func _on_cancel_pressed():
	%Options.show()

# nexus inventory button signals
func _on_nexus_inventory_item_pressed(extra_arg_0):
	%DescriptionsTextAreaLabel.text = inventory_options_valid_node_atlas_positions[extra_arg_0][1]
	# if player is not moving and inventory is not empty
	if nexus.nexus_player.velocity == Vector2.ZERO and Inventory.nexus_inventory[extra_arg_0] != 0 and %InventoryVBoxContainer.get_children()[extra_arg_0].modulate == Color(1, 1, 1, 1):
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
			%InventoryVBoxContainer.get_children()[i].hide()
		elif nexus.nexus_nodes[nexus.current_stats.last_node].texture.region.position in inventory_options_valid_node_atlas_positions[i][0]:
			if i < 14 and nexus.current_stats.last_node in nexus.current_stats.unlocked_nodes:
				%InventoryVBoxContainer.get_children()[i].modulate = Color(0.3, 0.3, 0.3, 1)
			elif i > 16 and nexus.current_stats.last_node not in nexus.current_stats.unlocked_nodes:
				%InventoryVBoxContainer.get_children()[i].modulate = Color(0.3, 0.3, 0.3, 1)
			else:
				%InventoryVBoxContainer.get_children()[i].modulate = Color(1, 1, 1, 1)
		else:
			%InventoryVBoxContainer.get_children()[i].modulate = Color(0.3, 0.3, 0.3, 1)

func attempt_unlock() -> bool:
	if nexus.current_stats.last_node in nexus.unlockable_nodes:
		nexus.unlock_node()
		return true
	return false

func teleport(type):
	var valid = false

	if type == "return":
		if nexus.current_stats.last_node in nexus.current_stats.unlocked_nodes:
			valid = true
	elif type == "ally":
		for player_index in nexus.character_stats:
			if player_index != nexus.current_stats and nexus.current_stats.last_node in nexus.current_stats.unlocked_nodes:
				valid = true
	elif type == "any":
		valid = true
	
	if valid:
		pass

func convert(target_type_position):
	nexus.nodes_converted[nexus.current_stats].append([nexus.current_stats.last_node, target_type_position])
	if nexus.nexus_nodes[nexus.current_stats.last_node].texture.region.position == nexus.EMPTY_ATLAS_POSITION:
		nexus.nodes_converted[nexus.current_stats].back().append(0)
	else:
		for i in nexus.STATS_ATLAS_POSITIONS.size():
			if nexus.nexus_nodes[nexus.current_stats.last_node].texture.region.position == nexus.STATS_ATLAS_POSITIONS[i]:
				nexus.nodes_converted[nexus.current_stats].back().append(nexus.CONVERTED_QUALITIES[i])
				break

	nexus.nexus_nodes[nexus.current_stats.last_node].texture.region.position = target_type_position
	if nexus.current_stats.last_node in nexus.unlockable_nodes:
		nexus.unlock_node()

func _on_button_mouse_entered():
	Inputs.zoom_inputs_enabled = false

func _on_button_mouse_exited():
	Inputs.zoom_inputs_enabled = true

func _on_scroll_container_gui_input(_event):
	pass

func _on_character_selector_button_pressed(node_index: int) -> void:
	%CharacterSelectorVBoxContainer.get_child(node_index).hide()
	%CharacterSelectorVBoxContainer.get_child(nexus.current_index).show()

	nexus.update_nexus_player(node_index)
