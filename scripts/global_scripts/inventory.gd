extends Node

# inventories
var consumables_inventory: PackedInt32Array = []
var materials_inventory: PackedInt32Array = []
var weapons_inventory: PackedInt32Array = []
var armors_inventory: PackedInt32Array = []
var accessories_inventory: PackedInt32Array = []
var nexus_inventory: PackedInt32Array = []
var key_inventory: PackedInt32Array = []

var consumables_resources: Array[Resource] = [
	load("res://scripts/items_scripts/potion.gd"),
	load("res://scripts/items_scripts/max_potion.gd"),
	load("res://scripts/items_scripts/phoenix_burger.gd"),
	load("res://scripts/items_scripts/reset_button.gd"),
	load("res://scripts/items_scripts/temp_kill_item.gd"),
]

func use_consumable(index: int, is_main_player: bool = true) -> void: # TODO
	if is_main_player and Entities.requesting_entities:
		return
	
	var item: Resource = consumables_resources[index].new()
	#var combat_ui_button_node = Combat.ui.items_grid_container_node.get_node(item.button_name.replace(" ", ""))
	
	if consumables_inventory[index] <= 0:
		#if combat_ui_button_node:
		#	combat_ui_button_node.queue_free()
		return

	var request_count = item.request_count
	var chosen_nodes: Array[EntityBase] = []

	if request_count != 0:
		if is_main_player:
			Entities.request_entities(item.request_types, request_count)
			chosen_nodes = await Entities.entities_request_ended
		else:
			chosen_nodes = Entities.ally_request_entities()
	
	if chosen_nodes.size() != request_count:
		return

	consumables_inventory[index] -= 1
	item.use_item(chosen_nodes)

	#if consumables_inventory[index] == 0:
	#	combat_ui_button_node.queue_free()
	#else:
	#	combat_ui_button_node.get_node(&"Quantity").text = str(consumables_inventory[index])

func change_weapon(_character_node: Node, _index: int) -> void:
	pass

func change_armor(_character_node: Node, _index: int) -> void:
	pass

func change_accessories(_character_node: Node, _index: int) -> void:
	pass
