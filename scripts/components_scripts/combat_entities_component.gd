extends Node

var damage_display_node = null

var temp_types = []
var output_amount = 0.0

func physical_damage_calculator(input_damage, origin_entity_stats_node, target_entity_stats_node):
	temp_types.clear()
	
	# base damage 
	output_amount = input_damage + (origin_entity_stats_node.strength * 2) + (input_damage * origin_entity_stats_node.strength * 0.05)

	# crit chance
	if randf() < origin_entity_stats_node.crit_chance:
		output_amount *= (1 + origin_entity_stats_node.crit_damage)
		temp_types.push_back("critical")

	# damage reduction
	output_amount *= origin_entity_stats_node.level / (target_entity_stats_node.level + (origin_entity_stats_node.level * (1 + (target_entity_stats_node.defence * 1.0 / 1500))))

	# randomizer
	output_amount = output_amount * randf_range(0.97, 1.03) + randf_range( - input_damage / 10, input_damage / 10)

	# clamp
	output_amount = clamp(output_amount, 0, 99999)

	# max 25% miss if not critical
	if temp_types.is_empty()&&randf() < (target_entity_stats_node.agility / 1028):
		output_amount = 0

	return [output_amount, temp_types]

func magic_damage_calculator(input_damage, origin_entity_stats_node, target_entity_stats_node):
	temp_types.clear()
	
	##### planning to have a different calculation
	# base damage 
	output_amount = input_damage + (origin_entity_stats_node.intelligence * 2) + (input_damage * origin_entity_stats_node.intelligence * 0.05)

	# crit chance
	if randf() < origin_entity_stats_node.crit_chance:
		output_amount *= (1 + origin_entity_stats_node.crit_damage)
		temp_types.push_back("critical")

	# damage reduction
	output_amount *= origin_entity_stats_node.level / (target_entity_stats_node.level + (origin_entity_stats_node.level * (1 + (target_entity_stats_node.shield * 1.0 / 1500))))

	# randomizer
	output_amount = output_amount * randf_range(0.97, 1.03) + randf_range( - input_damage / 10, input_damage / 10)

	# clamp
	output_amount = clamp(output_amount, 0, 99999)

	# max 25% miss if not critical
	if temp_types.is_empty()&&randf() < (target_entity_stats_node.speed / 1028):
		output_amount = 0

	return [output_amount, temp_types]

func magic_heal_calculator(input_amount, origin_entity_stats_node):
	# base damage 
	output_amount = input_amount * (1 + (origin_entity_stats_node.intelligence * 0.05))

	# randomizer
	output_amount = output_amount * randf_range(0.97, 1.03) + randf_range( - input_amount / 10, input_amount / 10)

	# clamp
	output_amount = clamp(output_amount, 0, 99999)

	return output_amount

func damage_display(value, display_position, types):
	var display = Label.new()
	display.global_position = display_position
	display.text = str(value)
	display.z_index = 5
	display.label_settings = LabelSettings.new()

	var color = "#FFF"
	if types.has("player_damage"):
		color = "#B22"
	elif types.has("heal"):
		color = "#3E3"

	if types.has("critical"):
		color = "#FB0"
	elif value == 0:
		display.text = "Miss"
		color = "#FFF8"

	display.label_settings.font_color = color
	display.label_settings.font_size = 9
	display.label_settings.outline_color = "#000"
	display.label_settings.outline_size = 1
	
	if damage_display_node != null:
		damage_display_node.call_deferred("add_child", display)
	
	await display.resized
	display.pivot_offset = Vector2(display.size / 2)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(display, "position:y", display.position.y - 24, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(display, "position:y", display.position.y - 16, 0.25).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(display, "scale", Vector2(0.75, 0.75), 0.25).set_ease(Tween.EASE_IN).set_delay(0.25)

	await tween.finished
	display.queue_free()
