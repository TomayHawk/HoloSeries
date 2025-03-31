extends Area2D

func _ready():
	set_collision_values([], [[2, true]]) # masks enemies

# TODO: can put this somewhere else, maybe Combat
# sets collision layers and masks
func set_collision_values(layers: Array[Array], masks: Array[Array]) -> void:
	# TODO: could move this to Combat
	for layer in layers:
		set_collision_layer_value(layer[0], layer[1])
	for mask in masks:
		set_collision_mask_value(mask[0], mask[1])

# scales AOE area
func scale_aoe_area(x: int, y: int) -> void:
	$CollisionShape2D.scale = Vector2(x, y)

# returns all nodes of a specific entity group in the AOE area
func area_of_effect(entity_group: StringName) -> Array[Node2D]:
	var entities_in_area: Array[Node2D] = []
	
	for entity in get_overlapping_bodies():
		if entity.is_in_group(entity_group):
			entities_in_area.push_back(entity)
	
	return entities_in_area
