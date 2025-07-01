extends Area2D

# ABILITIES COMPONENT: AREA OF EFFECT

# collision mask values:
# 1 = players
# 2 = enemies
# 3 = players and enemies

# ..............................................................................

#region FUNCTIONS

# trigger AOE and return entities in the area
func area_of_effect(collision_masks: int) -> Array[EntityBase]:
	# set collision mask layers
	collision_mask = collision_masks
	
	# enable and update collisions
	$CollisionShape2D.disabled = false
	await Global.get_tree().physics_frame
	
	# get overlapping (alive) entities
	var entities: Array[EntityBase] = []
	for entity in get_overlapping_bodies():
		if entity.stats.alive:
			entities.append(entity)
	
	# disable collisions
	$CollisionShape2D.disabled = true
	
	# return entities
	return entities

#endregion

# ..............................................................................
