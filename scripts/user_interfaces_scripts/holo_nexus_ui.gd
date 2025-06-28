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
	"Life Crystal",
	"Magic Crystal",
	"Reflex Crystal",
	# Special, Blessed, Abyssal
	"Special Crystal",
	"Blessed Crystal",
	"Abyssal Crystal",
	# Star, Prosperity, Love, Nobility
	"Star Crystal",
	"Prosperity Crystal",
	"Love Crystal",
	"Nobility Crystal",
	# Sunlight, Starlight, Moonlight
	"Sunlight Crystal",
	"Starlight Crystal",
	"Moonlight Crystal",
	# Dream, Return, Share and Instant
	"Dream Crystal",
	"Return Crystal",
	"Share Crystal",
	"Instant Crystal",
	# Health, Mana, Defense, Ward, Strength, Intelligence, Speed, Agility
	"Health Crystal",
	"Mana Crystal",
	"Defense Crystal",
	"Ward Crystal",
	"Strength Crystal",
	"Intelligence Crystal",
	"Speed Crystal",
	"Agility Crystal",
	# Clear
	"Clear Crystal",
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
	"Teleports player to any unlocked node.",
	"Teleports player to any current ally node.",
	"Teleports player to any node.",
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

var inventory_quantity_labels: Array[Label] = []

@onready var nexus: Node2D = get_parent()

@onready var inventory_ui: MarginContainer = %InventoryMargin
@onready var character_selector_node: Control = %CharacterSelector

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
		
		# define button properties
		character_button.get_node(^"CharacterName").text = stats.CHARACTER_NAME
		character_button.get_node(^"Level").text = str(stats.level).pad_zeros(3)
		character_button.pressed.connect(_on_character_selector_button_pressed.bind(character_button.get_index()))
		character_button.mouse_entered.connect(_on_button_mouse_entered)
		character_button.mouse_exited.connect(_on_button_mouse_exited)

		# hide current character
		if nexus.current_stats == stats:
			character_button.hide()

	character_selector_node.hide()

	var inventory_button_load: PackedScene = load("res://user_interfaces/user_interfaces_resources/holo_nexus_ui/nexus_inventory_button.tscn")

	# populate nexus inventory ui
	for index in Inventory.nexus_inventory.size():
		if Inventory.nexus_inventory[index] <= 0: continue
		
		# instantiate inventory button
		var inventory_button: Button = inventory_button_load.instantiate()
		%InventoryVBoxContainer.add_child(inventory_button)
		
		# define button properties
		inventory_button.name = str(index)
		inventory_button.get_node(^"ItemName").text = ITEM_NAMES[index]
		inventory_button.get_node(^"Quantity").text = str(Inventory.nexus_inventory[index])
		inventory_button.pressed.connect(_on_nexus_inventory_item_pressed.bind(index))
		inventory_button.mouse_entered.connect(_on_button_mouse_entered)
		inventory_button.mouse_exited.connect(_on_button_mouse_exited)

	'''
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
			%DescriptionsTextAreaLabel.text = "Requires " + KEY_DESCRIPTIONS[nexus.KEY_ATLAS_POSITIONS.find(node_atlas_position)] + " Crystal to Unlock."
		elif nexus.ABILITY_ATLAS_POSITIONS.has(node_atlas_position):
			%DescriptionsTextAreaLabel.text = "Unlock " + "[Ability Name]" + "."
	else:
		%DescriptionsTextAreaLabel.text = "Gain " + node_quality_string + " " + STATS_DESCRIPTIONS[nexus.STATS_ATLAS_POSITIONS.find(node_atlas_position)] + "."

	%Options.show()
	%DescriptionsMargin.show()

func hide_all() -> void:
	%Options.hide()
	inventory_ui.hide()
	%DescriptionsMargin.hide()

func update_inventory_buttons() -> void:
	for button in %InventoryVBoxContainer.get_children():
		var index: int = int(button.name)

		if Inventory.nexus_inventory[index] == 0:
			button.hide()
		elif ITEM_COMPATIBLES[index] & (1 << nexus.current_stats.last_node):
			if index < 14 and nexus.current_stats.last_node in nexus.current_stats.unlocked_nodes:
				button.modulate = Color(0.3, 0.3, 0.3, 1)
			elif index > 16 and nexus.current_stats.last_node not in nexus.current_stats.unlocked_nodes:
				button.modulate = Color(0.3, 0.3, 0.3, 1)
			else:
				button.modulate = Color(1, 1, 1, 1)
		else:
			button.modulate = Color(0.3, 0.3, 0.3, 1)

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
	%DescriptionsTextAreaLabel.text = ITEM_DESCRIPTIONS[extra_arg_0]
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
