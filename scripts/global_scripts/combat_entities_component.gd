extends Node

@onready var entity_highlights_paths := ["res://resources/entity_highlights/enemy_highlight.tscn",
										"res://resources/entity_highlights/enemy_marker.tscn",
										"res://resources/entity_highlights/entity_highlight.tscn",
										"res://resources/entity_highlights/entity_marker.tscn",
										"res://resources/entity_highlights/invalid_highlight.tscn",
										"res://resources/entity_highlights/invalid_marker.tscn",
										"res://resources/entity_highlights/player_highlight.tscn",
										"res://resources/entity_highlights/player_marker.tscn"]

var damage_display_node: Node = null

var temp_types: Array[String] = []
var output_amount := 0.0

var counter := 0
var sign_indicator := 1
var compared_quality := 0.0
var comparing_qualities: Array[int] = []
var target_entity_node: Node = null

var in_combat := false
var leaving_combat := false
@onready var leaving_combat_timer_node := $LeavingCombatTimer

var enemy_nodes_in_combat: Array[Node] = []
var locked_enemy_node: Node = null
var requesting_entities := false
var entities_request_origin_node: Node = null
var entities_request_target_command_string := ""
var entities_request_count := 0
var entities_available: Array[Node] = []
var entities_chosen: Array[Node] = []
var entities_chosen_count := 0
var abilities_node: Node = null

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
	output_amount = output_amount * randf_range(0.97, 1.03) + randf_range(-input_damage / 10, input_damage / 10)

	# clamp
	output_amount = clamp(output_amount, 0, 99999)

	# max 25% miss if not critical
	if temp_types.is_empty() && randf() < (target_entity_stats_node.agility / 1028):
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
	output_amount = output_amount * randf_range(0.97, 1.03) + randf_range(-input_damage / 10, input_damage / 10)
	# clamp
	output_amount = clamp(output_amount, 0, 99999)

	# max 25% miss if not critical
	if temp_types.is_empty() && randf() < (target_entity_stats_node.speed / 1028):
		temp_types.push_back("miss")
		output_amount = 0

	return [output_amount, temp_types]

func magic_heal_calculator(input_amount, origin_entity_stats_node):
	# base damage 
	output_amount = input_amount * (1 + (origin_entity_stats_node.intelligence * 0.05))

	# randomizer
	output_amount = output_amount * randf_range(0.97, 1.03) + randf_range(-input_amount / 10, input_amount / 10)

	# clamp
	output_amount = clamp(output_amount, 0, 99999)

	return output_amount

func damage_display(value, display_position, types):
	if types.has("hidden"):
		return

	var display = Label.new()
	display.global_position = display_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
	display.text = str(abs(value))
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

func target_entity(type, origin_node):
	comparing_qualities.clear()
	compared_quality = INF
	sign_indicator = 1
	target_entity_node = null

	# choose closest entity
	if type == "distance_least":
		for entity_node in entities_available:
			if origin_node.position.distance_to(entity_node.position) < compared_quality:
				compared_quality = origin_node.position.distance_to(entity_node.position)
				target_entity_node = entity_node

		entities_chosen.push_back(target_entity_node)
		choose_entities()
		return

	# fix "most" to "least" with negative signs (positive number -> negative number)
	if type == "health_most":
		type = "health"
		compared_quality = 0.0
		sign_indicator = -1

	# create array for all available node qualities
	for entity_node in entities_available:
		if entity_node.is_in_group("party"):
			comparing_qualities.push_back(sign_indicator * entity_node.player_stats_node.get(type))
		else:
			comparing_qualities.push_back(sign_indicator * entity_node.enemy_stats_node.get(type))

	# choose entity with least of chosen quality
	counter = 0
	for entity_quality in comparing_qualities:
		if entity_quality < compared_quality:
			compared_quality = entity_quality
			target_entity_node = entities_available[counter]
		counter += 1

	# choose entities if fulfilled required number
	entities_chosen.push_back(target_entity_node)
	entities_chosen_count += 1
	if entities_request_count == entities_chosen_count:
		choose_entities()

func enter_combat():
	if !in_combat || leaving_combat:
		in_combat = true
		leaving_combat = false
		if leaving_combat_timer_node.is_stopped():
			# fade in combat UI
			GlobalSettings.combat_ui_node.combat_ui_control_tween(1)
			##### begin combat bgm
		else:
			leaving_combat_timer_node.stop()

func attempt_leave_combat():
	if in_combat && leaving_combat_timer_node.is_stopped():
		leaving_combat = true
		leaving_combat_timer_node.start(2)

func leave_combat():
	in_combat = false
	leaving_combat = false
	leaving_combat_timer_node.stop()
	enemy_nodes_in_combat.clear()
	GlobalSettings.combat_ui_node.combat_ui_control_tween(0)
	locked_enemy_node = null

func request_entities(origin_node, target_command, request_count, request_entity_type):
	empty_entities_request()
	requesting_entities = true
	entities_request_origin_node = origin_node
	entities_request_target_command_string = target_command
	entities_request_count = request_count

	entities_available = get_tree().get_nodes_in_group(request_entity_type)

	if request_entity_type == "party_players":
		entities_available = GlobalSettings.party_player_nodes.duplicate()
	elif request_entity_type == "ally_players":
		entities_available = GlobalSettings.party_player_nodes.duplicate()
		entities_available.erase(GlobalSettings.current_main_player_node)
	elif request_entity_type == "players_alive":
		for player in GlobalSettings.party_player_nodes:
			if player.player_stats_node.alive:
				entities_available.push_back(player)
	elif request_entity_type == "players_dead":
		for player in GlobalSettings.party_player_nodes:
			if !player.player_stats_node.alive:
				entities_available.push_back(player)
	elif request_entity_type == "enemies_in_combat":
		entities_available = enemy_nodes_in_combat.duplicate()
	elif request_entity_type == "all_entities_in_combat":
		entities_available = GlobalSettings.party_player_nodes.duplicate() + enemy_nodes_in_combat.duplicate()
	elif request_entity_type == "all_enemies_on_screen":
		entities_available = GlobalSettings.current_scene_node.get_node("Enemies").get_children().duplicate()
	elif request_entity_type == "all_entities_on_screen":
		entities_available = GlobalSettings.party_player_nodes.duplicate() + GlobalSettings.current_scene_node.get_node("Enemies").get_children().duplicate()

	for entity in entities_available:
		if entity.has_method("ally_movement"): # #### need grouping
			entity.add_child(load(entity_highlights_paths[6]).instantiate())
		elif entity.has_method("choose_player"):
			entity.add_child(load(entity_highlights_paths[0]).instantiate())

	if (entities_request_count == 1) && (locked_enemy_node != null) && (locked_enemy_node in entities_available):
		entities_chosen.push_back(locked_enemy_node)
		choose_entities()

func choose_entities():
	if entities_chosen.size() == 1:
		entities_request_origin_node.call(entities_request_target_command_string, entities_chosen.duplicate()[0])
	else:
		entities_request_origin_node.call(entities_request_target_command_string, entities_chosen.duplicate())
	empty_entities_request()

func empty_entities_request():
	requesting_entities = false
	
	if entities_request_origin_node != null && entities_request_origin_node.get_parent() == abilities_node && entities_chosen.size() != entities_request_count:
		entities_request_origin_node.queue_free()

	for entity in entities_available:
		if is_instance_valid(entity):
			if entity.has_method("ally_movement"): # #### need grouping
				entity.remove_child(entity.get_node("PlayerHighlight"))
			elif entity.has_method("choose_player"):
				entity.remove_child(entity.get_node("EnemyHighlight"))

	entities_request_count = 0
	entities_available.clear()
	entities_chosen_count = 0
	entities_chosen.clear()

func _on_leaving_combat_timer_timeout():
	if enemy_nodes_in_combat.is_empty():
		leave_combat()
