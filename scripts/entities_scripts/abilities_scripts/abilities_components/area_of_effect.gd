extends Area2D

@onready var ability_node := get_parent()
var entities_in_area: Array[Node] = []

func area_of_effect(entity_type: String):
	entities_in_area.clear()
	
	for entity in get_overlapping_bodies():
		if entity.is_in_group(entity_type):
			entities_in_area.push_back(entity)
	
	return entities_in_area
