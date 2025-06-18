extends Area2D

# return nodes in AOE area
# 1 = Players
# 2 = Enemies
# 3 = Players and Enemies
func area_of_effect(collision_masks: int) -> Array[EntityBase]:
	collision_mask = collision_masks
	$CollisionShape2D.set_deferred(&"disabled", false)
	await Global.get_tree().physics_frame
	await Global.get_tree().physics_frame
	var entity_nodes: Array[EntityBase] = []
	for entity_node in get_overlapping_bodies():
		if ((entity_node is PlayerBase and entity_node.character and entity_node.character.alive) or
				(entity_node is EnemyBase and entity_node.stats and entity_node.stats.alive)):
			entity_nodes.append(entity_node)
	$CollisionShape2D.set_deferred(&"disabled", true)
	return entity_nodes
