extends Area2D

# COMPLETE

# return nodes in AOE area
# 1 = Players
# 2 = Enemies
# 3 = Players and Enemies
func area_of_effect(collision_masks: int) -> Array[EntityBase]:
	collision_mask = collision_masks
	$CollisionShape2D.set_deferred(&"disabled", false)
	await Global.tree.physics_frame
	await Global.tree.physics_frame
	var entity_nodes: Array[EntityBase] = []
	print(collision_mask)
	print(get_overlapping_bodies())
	for entity_node in get_overlapping_bodies():
		if ((entity_node is PlayerBase and entity_node.character_node and entity_node.character_node.alive) or
				(entity_node is EnemyBase and entity_node.enemy_stats_node and entity_node.enemy_stats_node.alive)):
			entity_nodes.push_back(entity_node)
	$CollisionShape2D.set_deferred(&"disabled", true)
	return entity_nodes
