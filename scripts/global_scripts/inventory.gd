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
	load("res://scripts/items_scripts/consumables_scripts/potion.gd"),
	load("res://scripts/items_scripts/consumables_scripts/max_potion.gd"),
	load("res://scripts/items_scripts/consumables_scripts/phoenix_burger.gd"),
	load("res://scripts/items_scripts/consumables_scripts/reset_button.gd"),
	load("res://scripts/items_scripts/consumables_scripts/temp_kill_item.gd"),
]

func use_consumable(origin_node: EntityBase, index: int) -> void: # TODO
	if origin_node.is_main_player and Entities.requesting_entities: return
	
	var item: Resource = consumables_resources[index].new()
	var combat_ui_button_node = Combat.ui.items_grid_container_node.get_node(item.button_name.replace(" ", ""))
	
	if consumables_inventory[index] <= 0:
		if combat_ui_button_node:
			combat_ui_button_node.queue_free()
		return

	if item.request_count != 0:
		if origin_node.is_main_player:
			Entities.request_entities(origin_node, item.request_types, item.request_count)
			#await signal
		else:
			Entities.ally_request_entities()
		
		if Entities.chosen_entities.size() != item.request_count:
			return
	
	consumables_inventory[index] -= 1
	item.use_item(Entities.chosen_entities)

	if consumables_inventory[index] == 0:
		combat_ui_button_node.queue_free()
	else:
		combat_ui_button_node.get_node(&"Quantity").text = str(consumables_inventory[index])

func change_weapon(_character_node: Node, _index: int) -> void:
	pass

func change_armor(_character_node: Node, _index: int) -> void:
	pass

func change_accessories(_character_node: Node, _index: int) -> void:
	pass
