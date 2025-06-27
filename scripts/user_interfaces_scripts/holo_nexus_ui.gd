extends CanvasLayer

# HOLONEXUS UI

# ..............................................................................

#region CONSTANTS

const stats_descriptions: Array[String] = ["Health", "Mana", "Defense", "Ward", "Strength", "Intelligence", "Speed", "Agility"]
const key_descriptions: Array[String] = ["Star", "Prosperity", "Love", "Nobility"]
const ability_descriptions: Array[String] = ["", "", "", "", "", "", "", "", "", ""]

const item_descriptions: Array[String] = [
	"Unlocks HP, DEF and STR nodes.",				# Life Crystal
	"Unlocks MP, WRD and INT nodes.", 				# Magic Crystal
	"Unlocks SPD and AGI nodes.",					# Reflex Crystal
	"Unlocks Skill nodes.",							# Talent Crystal
	"Unlocks White Magic nodes.",					# Blessed Crystal
	"Unlocks Black Magic nodes.",					# Abyssal Crystal
	"Unlocks Diamond Key nodes.",					# Star Crystal
	"Unlocks Clover Key nodes.",					# Prosperity Crystal
	"Unlocks Heart Key nodes.",						# Love Crystal
	"Unlocks Spade Key nodes.",						# Nobility Crystal
	"Unlocks any Skill node.",						# Sunlight Crystal
	"Unlocks any White Magic node.",				# Starlight Crystal
	"Unlocks any Black Magic node.",				# Moonlight Crystal
	"Unlocks any one node.",						# Dream Crystal
	"Teleports player to any unlocked node.",		# Return Crystal
	"Teleports player to any current ally node.",	# Share Crystal
	"Teleports player to any node.",				# Instant Crystal
	"Converts an empty node into an HP node.",		# Health Crystal
	"Converts an empty node into an MP node.",		# Mana Crystal
	"Converts an empty node into a DEF node.",		# Defense Crystal
	"Converts an empty node into a WRD node.",		# Ward Crystal
	"Converts an empty node into an STR node.",		# Strength Crystal
	"Converts an empty node into an INT node.",		# Intelligence Crystal
	"Converts an empty node into a SPD node.",		# Speed Crystal
	"Converts an empty node into an AGI node.",		# Agility Crystal
	"Converts a stats node into an empty node.",	# Clear Crystal
]

#endregion

# ..............................................................................

#region VARIABLES

var inventory_quantity_labels: Array[Label] = []

@onready var nexus: Node2D = get_parent()

@onready var inventory_ui: MarginContainer = %InventoryMargin
@onready var descriptions_ui: MarginContainer = %DescriptionsMargin
@onready var character_selector_node: Control = %CharacterSelector

# TODO: optimize this
@onready var item_type_compatibilities : Array[Array] = [
	[nexus.STATS_ATLAS_POSITIONS[0], nexus.STATS_ATLAS_POSITIONS[2], nexus.STATS_ATLAS_POSITIONS[4]], # HP, DEF, STR
	[nexus.STATS_ATLAS_POSITIONS[1], nexus.STATS_ATLAS_POSITIONS[3], nexus.STATS_ATLAS_POSITIONS[5]], # MP, WRD, INT
	[nexus.STATS_ATLAS_POSITIONS[6], nexus.STATS_ATLAS_POSITIONS[7]], # SPD, AGI
	[nexus.ABILITY_ATLAS_POSITIONS[0]], # Skill
	[nexus.ABILITY_ATLAS_POSITIONS[1]], # White Magic
	[nexus.ABILITY_ATLAS_POSITIONS[2]], # Black Magic
	[nexus.KEY_ATLAS_POSITIONS[0]], # Diamond Key
	[nexus.KEY_ATLAS_POSITIONS[1]], # Clover Key
	[nexus.KEY_ATLAS_POSITIONS[2]], # Heart Key
	[nexus.KEY_ATLAS_POSITIONS[3]], # Spade Key
	[nexus.ABILITY_ATLAS_POSITIONS[0]], # Skill
	[nexus.ABILITY_ATLAS_POSITIONS[1]], # White Magic
	[nexus.ABILITY_ATLAS_POSITIONS[2]], # Black Magic
	[nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION]],
	[nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION]],
	[nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION]],
	[nexus.STATS_ATLAS_POSITIONS.duplicate() + nexus.ABILITY_ATLAS_POSITIONS.duplicate() + nexus.KEY_ATLAS_POSITIONS.duplicate() + [nexus.EMPTY_ATLAS_POSITION]],
	[nexus.EMPTY_ATLAS_POSITION],
	[nexus.EMPTY_ATLAS_POSITION],
	[nexus.EMPTY_ATLAS_POSITION],
	[nexus.EMPTY_ATLAS_POSITION],
	[nexus.EMPTY_ATLAS_POSITION],
	[nexus.EMPTY_ATLAS_POSITION],
	[nexus.EMPTY_ATLAS_POSITION],
	[nexus.EMPTY_ATLAS_POSITION],
	nexus.STATS_ATLAS_POSITIONS.duplicate(),
]

#endregion

# ..............................................................................

#region READY

func _ready() -> void:
	show()

	var character_button_load: PackedScene = load("res://user_interfaces/user_interfaces_resources/holo_nexus_ui/nexus_button.tscn")
	
	# populate character selector
	for stats in nexus.character_stats:
		# instantiate character button
		var character_button: Button = character_button_load.instantiate()
		%CharacterSelectorVBoxContainer.add_child(character_button)
		character_button.get_node(^"CharacterName").text = stats.CHARACTER_NAME
		character_button.get_node(^"Level").text = str(stats.level).pad_zeros(3)
		character_button.pressed.connect(_on_character_selector_button_pressed.bind(character_button.get_index()))
		character_button.mouse_entered.connect(_on_button_mouse_entered)
		character_button.mouse_exited.connect(_on_button_mouse_exited)

		# hide current character
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

func update_nexus_ui() -> void:
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

func update_inventory_buttons() -> void:
	for i in 26:
		if Inventory.nexus_inventory[i] == 0:
			%InventoryVBoxContainer.get_children()[i].hide()
		elif nexus.nexus_nodes[nexus.current_stats.last_node].texture.region.position in item_type_compatibilities[i]:
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

func teleport(type) -> void:
	var valid = false

	if type == 0:
		if nexus.current_stats.last_node in nexus.current_stats.unlocked_nodes:
			valid = true
	elif type == 1:
		for player_index in nexus.character_stats:
			if player_index != nexus.current_stats and nexus.current_stats.last_node in nexus.current_stats.unlocked_nodes:
				valid = true
	elif type == 2:
		valid = true
	
	if valid:
		pass

# TODO: need to fix from Vector2 to int
func stats_convert(target_type_position) -> void:
	print(target_type_position)

	'''
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
	'''

# ..............................................................................

#region OPTIONS SIGNALS

func _on_unlock_pressed() -> void:
	if nexus.nexus_player.velocity == Vector2.ZERO:
		if nexus.current_stats.last_node in nexus.unlockable_nodes:
			nexus.unlock_node()

func _on_upgrade_pressed() -> void:
	pass

func _on_awaken_pressed() -> void:
	pass

func _on_items_pressed() -> void:
	update_inventory_buttons()
	%Options.hide()
	inventory_ui.show()

#endregion

# ..............................................................................

#region INVENTORY SIGNALS

# nexus inventory button signals
func _on_nexus_inventory_item_pressed(extra_arg_0) -> void:
	%DescriptionsTextAreaLabel.text = item_descriptions[extra_arg_0]
	# if player is not moving and inventory is not empty
	if nexus.nexus_player.velocity == Vector2.ZERO and Inventory.nexus_inventory[extra_arg_0] != 0 and %InventoryVBoxContainer.get_children()[extra_arg_0].modulate == Color(1, 1, 1, 1):
		# wait for double click
		# call appropriate function

		if extra_arg_0 < 14:
			attempt_unlock()
		elif extra_arg_0 < 17:
			teleport(extra_arg_0 - 14)
		elif extra_arg_0 < 25:
			stats_convert(extra_arg_0 - 16)
		else:
			stats_convert(0)

		update_inventory_buttons()

# ..............................................................................

#region CHARACTER SELECTOR SIGNALS

func _on_character_selector_button_pressed(node_index: int) -> void:
	%CharacterSelectorVBoxContainer.get_child(node_index).hide()
	%CharacterSelectorVBoxContainer.get_child(nexus.current_index).show()

	nexus.update_nexus_player(node_index)

#endregion

# ..............................................................................

#region BUTTON SIGNALS

func _on_button_mouse_entered() -> void:
	Inputs.zoom_inputs_enabled = false

func _on_button_mouse_exited() -> void:
	Inputs.zoom_inputs_enabled = true

#endregion

# ..............................................................................
