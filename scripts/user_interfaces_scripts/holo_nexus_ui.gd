extends CanvasLayer

# HOLONEXUS UI

# ..............................................................................

#region CONSTANTS

const STATS_DESCRIPTIONS: Array[String] = [
	"Health",
	"Mana",
	"Defense",
	"Ward",
	"Strength",
	"Intelligence",
	"Speed",
	"Agility",
]

const KEY_DESCRIPTIONS: Array[String] = [
	"Star",
	"Prosperity",
	"Love",
	"Nobility",
]

const ABILITY_DESCRIPTIONS: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
]

const ITEM_NAMES: Array[String] = [
	# Life, Magic and Reflex
	"Life",
	"Magic",
	"Reflex",
	# Special, Blessed, Abyssal
	"Special",
	"Blessed",
	"Abyssal",
	# Star, Prosperity, Love, Nobility
	"Star",
	"Prosperity",
	"Love",
	"Nobility",
	# Sunlight, Starlight, Moonlight
	"Sunlight",
	"Starlight",
	"Moonlight",
	# Dream, Return, Share and Instant
	"Dream",
	"Return",
	"Share",
	"Instant",
	# Health, Mana, Defense, Ward, Strength, Intelligence, Speed, Agility
	"Health",
	"Mana",
	"Defense",
	"Ward",
	"Strength",
	"Intelligence",
	"Speed",
	"Agility",
	# Clear
	"Clear",
]

const ITEM_DESCRIPTIONS: Array[String] = [
	# Life, Magic and Reflex
	"Unlocks HP, DEF and STR nodes.",
	"Unlocks MP, WRD and INT nodes.",
	"Unlocks SPD and AGI nodes.",
	# Special, Blessed, Abyssal
	"Unlocks Special nodes.",
	"Unlocks White Magic nodes.",
	"Unlocks Black Magic nodes.",
	# Star, Prosperity, Love, Nobility
	"Unlocks Diamond Key nodes.",
	"Unlocks Clover Key nodes.",
	"Unlocks Heart Key nodes.",
	"Unlocks Spade Key nodes.",
	# Sunlight, Starlight, Moonlight
	"Unlocks any Special node.",
	"Unlocks any White Magic node.",
	"Unlocks any Black Magic node.",
	# Dream, Return, Share and Instant
	"Unlocks any one node.",
	"Teleports this character to any of their unlocked nodes.",
	"Teleports this character to any other character.",
	"Teleports this character to any node.",
	# Health, Mana, Defense, Ward, Strength, Intelligence, Speed, Agility
	"Converts an empty node into an HP node.",
	"Converts an empty node into an MP node.",
	"Converts an empty node into a DEF node.",
	"Converts an empty node into a WRD node.",
	"Converts an empty node into an STR node.",
	"Converts an empty node into an INT node.",
	"Converts an empty node into a SPD node.",
	"Converts an empty node into an AGI node.",
	# Clear
	"Converts a stats node into an empty node.",
]

# -1: null
# 0: empty
# 1-8: HP, MP, DEF, WRD, STR, INT, SPD, AGI
# 9-11: special, white magic, black magic
# 12-15: diamond, clover, heart, spade

const ITEM_COMPATIBLES : Array[int] = [
	# Life, Magic and Reflex
	(1 << 1) | (1 << 3) | (1 << 5),
	(1 << 2) | (1 << 4) | (1 << 6),
	(1 << 7) | (1 << 8),
	# Special, Blessed, Abyssal
	1 << 9,
	1 << 10,
	1 << 11,
	# Star, Prosperity, Love, Nobility
	1 << 12,
	1 << 13,
	1 << 14,
	1 << 15,
	# Sunlight, Starlight, Moonlight
	1 << 9,
	1 << 10,
	1 << 11,
	# Dream, Return, Share and Instant - all non-null types
	0xFFFF,
	0xFFFF,
	0xFFFF,
	0xFFFF,
	# Health, Mana, Defense, Ward, Strength, Intelligence, Speed, Agility
	1 << 0,
	1 << 0,
	1 << 0,
	1 << 0,
	1 << 0,
	1 << 0,
	1 << 0,
	1 << 0,
	# Clear
	(1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7) | (1 << 8),
]

#endregion

# ..............................................................................

#region VARIABLES

var button_focused: bool = false
var inventory_quantity_labels: Array[Label] = []

@onready var nexus: Node2D = get_parent()

@onready var options_ui: Control = %Options
@onready var inventory_ui: MarginContainer = %InventoryMargin
@onready var character_selector_node: Control = %CharacterSelector

#endregion

# ..............................................................................

#region READY

func _ready() -> void:
	const NEXUS_RESOURCES_PATH: String = \
			"res://user_interfaces/user_interfaces_resources/holo_nexus_ui/"

	var character_button_load: PackedScene = \
			load(NEXUS_RESOURCES_PATH + "nexus_button.tscn")
	
	# populate character selector
	for stats in nexus.character_stats:
		# instantiate character button
		var character_button: Button = character_button_load.instantiate()
		%CharacterSelectorVBoxContainer.add_child(character_button)
		
		# initialize button texts
		character_button.get_node(^"CharacterName").text = stats.CHARACTER_NAME
		character_button.get_node(^"Level").text = str(stats.level).pad_zeros(3)
		
		# initialize button signals
		character_button.pressed.connect(
				_on_character_selector_button_pressed.bind(character_button.get_index()))
		character_button.mouse_entered.connect(_on_button_mouse_entered)
		character_button.mouse_exited.connect(_on_button_mouse_exited)

		# hide current character
		if nexus.current_stats == stats:
			character_button.hide()

	character_selector_node.hide()

	var inventory_button_load: PackedScene = \
			load(NEXUS_RESOURCES_PATH + "nexus_inventory_button.tscn")

	# populate nexus inventory ui
	for index in Inventory.nexus_inventory.size():
		if Inventory.nexus_inventory[index] <= 0: continue
		
		# instantiate inventory button
		var inventory_button: Button = inventory_button_load.instantiate()
		%InventoryVBoxContainer.add_child(inventory_button)
		
		# initialize button name and texts
		inventory_button.name = str(index)
		inventory_button.get_node(^"ItemName").text = ITEM_NAMES[index] + " Crystal"
		inventory_button.get_node(^"Quantity").text = str(Inventory.nexus_inventory[index])
		
		# initialize button signals
		inventory_button.pressed.connect(
				_on_nexus_inventory_item_pressed.bind(index))
		inventory_button.mouse_entered.connect(_on_button_mouse_entered)
		inventory_button.mouse_exited.connect(_on_button_mouse_exited)

	update_nexus_ui.call_deferred()

#endregion

# ..............................................................................

#region UI UPDATES

func update_nexus_ui() -> void:
	update_options()
	update_inventory_ui()
	update_descriptions()

	show()
	options_ui.show()
	%DescriptionsMargin.show()
	inventory_ui.hide()

func update_options() -> void:
	var current_type: int = Global.nexus_types[nexus.current_stats.last_node]
	var current_type_flag: int = 1 << current_type
	var can_unlock: bool = false

	nexus.item_on_hold = -1

	# update unlock button
	if nexus.current_stats.last_node in nexus.unlockable_nodes:
		if current_type == 0:
			can_unlock = true
		else:
			for item_index in Inventory.nexus_inventory.size():
				# check only basic unlocking items
				if item_index >= 10:
					break

				# check item quantity and compatibility with current node type
				if Inventory.nexus_inventory[item_index] > 0 and \
						ITEM_COMPATIBLES[item_index] & current_type_flag:
					nexus.item_on_hold = item_index
					can_unlock = true
					break

	%Unlock.disabled = not can_unlock
	%Unlock.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_unlock else Color(0.3, 0.3, 0.3, 1.0)

func update_inventory_ui() -> void:
	button_focused = false

	var node_index: int = nexus.current_stats.last_node
	var node_unlocked: bool = node_index in nexus.current_stats.unlocked_nodes
	var node_unlockable: bool = node_index in nexus.unlockable_nodes

	for button in %InventoryVBoxContainer.get_children():
		var item_index: int = int(button.name)

		# free button if item quantity is zero
		if Inventory.nexus_inventory[item_index] <= 0:
			button.queue_free()
			continue

		# update and modulate button based on compatibility and node state
		var button_valid: bool = (
				ITEM_COMPATIBLES[item_index] & (1 << Global.nexus_types[node_index])
				and ((item_index <= 13 and not node_unlocked)
				or (item_index <= 16)
				or (item_index >= 17 and (node_unlocked or node_unlockable)))
		)

		button.disabled = not button_valid
		button.modulate = Color(1.0, 1.0, 1.0, 1.0) if button_valid else Color(0.3, 0.3, 0.3, 1.0)

func update_descriptions() -> void:
	var current_index: int = nexus.current_stats.last_node
	var current_type: int = Global.nexus_types[current_index]
	var current_quality_string: String = str(Global.nexus_qualities[current_index])

	# if the node is converted, get its type and quality string
	if current_index in nexus.converted_nodes:
		for temp_node in nexus.current_stats.converted_nodes:
			# skip until the matching node is found
			if temp_node.x != current_index: continue
			
			# update current type and quality string
			current_type = temp_node.y
			current_quality_string = \
					"0" if current_type == 0 else str(nexus.CONVERTED_QUALITIES[current_type - 1])
			
			break
	
	var description: String = ""

	if current_type <= -1:
		description = "Null Node."
	elif current_type == 0:
		description = "Empty Node."
	elif current_type <= 8:
		description = "Gain " + current_quality_string + " " + STATS_DESCRIPTIONS[current_type - 1] + "."
	elif current_type <= 11:
		description = "Unlock " + "[Ability Name]" + "."
	elif current_type <= 15:
		description = "Requires a " + KEY_DESCRIPTIONS[current_type - 12] + " Key to Unlock."

	%DescriptionsTextAreaLabel.text = description

func hide_all() -> void:
	hide()
	options_ui.hide()
	inventory_ui.hide()
	%DescriptionsMargin.hide()

func attempt_unlock() -> bool:
	if nexus.current_stats.last_node in nexus.unlockable_nodes:
		nexus.unlock_node()
		return true
	return false

# TODO: incomplete
func teleport(type: int) -> bool:
	var valid = false

	match type:
		0: # teleport to any unlocked node
			if nexus.current_stats.last_node in nexus.current_stats.unlocked_nodes:
				valid = true
		1: # teleport to any ally node
			for stats in nexus.character_stats:
				if stats == nexus.current_stats and nexus.current_stats.last_node in stats.unlocked_nodes:
					valid = true
		2: # teleport to any node
			valid = true

	if valid:
		pass
	
	return valid

func stats_convert(type: int) -> bool:
	var node_index: int = nexus.current_stats.last_node

	nexus.current_stats.converted_nodes.append(Vector2i(node_index, type))

	nexus.nexus_nodes[node_index].texture.region.position = \
			nexus.EMPTY_ATLAS_POSITION if type == 0 else nexus.STATS_ATLAS_POSITIONS[type - 1]

	nexus.unlock_node()

	return true

# ..............................................................................

#region OPTIONS SIGNALS

func _on_unlock_pressed() -> void:
	var item_index: int = nexus.item_on_hold

	if item_index >= 0:
		Inventory.nexus_inventory[item_index] -= 1
		%InventoryVBoxContainer.get_node(NodePath(str(item_index) + "/Quantity")
				).text = str(Inventory.nexus_inventory[item_index])
	
	nexus.unlock_node()
	update_options()

func _on_upgrade_pressed() -> void:
	pass

func _on_awaken_pressed() -> void:
	pass

func _on_items_pressed() -> void:
	inventory_ui.show()
	options_ui.hide()

#endregion

# ..............................................................................

#region INVENTORY SIGNALS

# nexus inventory button signals
func _on_nexus_inventory_item_pressed(extra_arg_0: int) -> void:
	if not button_focused:
		%DescriptionsTextAreaLabel.text = ITEM_DESCRIPTIONS[extra_arg_0]
		button_focused = true
		return
	
	# TODO: change this and confirmation buttons

	button_focused = false

	# if player has item, attempt to use it
	if Inventory.nexus_inventory[extra_arg_0] > 0:
		var item_used: bool = false

		if extra_arg_0 < 14:
			item_used = attempt_unlock()
		elif extra_arg_0 < 17:
			item_used = teleport(extra_arg_0 - 14)
		elif extra_arg_0 < 25:
			item_used = stats_convert(extra_arg_0 - 16)
		else:
			item_used = stats_convert(0)
		
		if not item_used: return

		Inventory.nexus_inventory[extra_arg_0] -= 1
		%InventoryVBoxContainer.get_node(NodePath(str(extra_arg_0) + "/Quantity")
				).text = str(Inventory.nexus_inventory[extra_arg_0])

		update_options()
		update_inventory_ui()

# ..............................................................................

#region CHARACTER SELECTOR SIGNALS

func _on_character_selector_button_pressed(node_index: int) -> void:
	nexus.update_nexus_player(node_index)	
	%CharacterSelectorVBoxContainer.get_child(node_index).hide()
	%CharacterSelectorVBoxContainer.get_child(nexus.current_index).show()

#endregion

# ..............................................................................

#region BUTTON SIGNALS

func _on_button_mouse_entered() -> void:
	Inputs.zoom_inputs_enabled = false

func _on_button_mouse_exited() -> void:
	Inputs.zoom_inputs_enabled = true

#endregion

# ..............................................................................
