extends Area2D

## currently only masking "Enemies" layer,
## should add a function to change/add other entity layers

# returns all nodes of a specific entity group in the AOE area
func area_of_effect(entity_group: StringName):
	var entities_in_area: Array[Node] = []
	
	for entity in get_overlapping_bodies():
		if entity.is_in_group(entity_group):
			entities_in_area.push_back(entity)
	
	return entities_in_area
