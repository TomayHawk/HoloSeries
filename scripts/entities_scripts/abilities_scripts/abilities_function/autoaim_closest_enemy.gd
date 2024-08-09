static func auto_aim(position):
	var temp_distance = INF
	var selected_enemy = null

	for entity_node in GlobalSettings.entities_available:
		if position.distance_to(entity_node.position) < temp_distance:
			temp_distance = position.distance_to(entity_node.position)
			selected_enemy = entity_node
			
	GlobalSettings.entities_chosen.push_back(selected_enemy)
	GlobalSettings.choose_entities()
	return selected_enemy	
