extends Node

enum Type {
	PLAYERS,
	PLAYERS_MAIN,
	PLAYERS_ALLIES,
	PLAYERS_PARTY,
	PLAYERS_STANDBY,
	PLAYERS_ALIVE,
	PLAYERS_PARTY_ALIVE,
	PLAYERS_STANDBY_ALIVE,
	PLAYERS_DEAD,
	PLAYERS_PARTY_DEAD,
	PLAYERS_STANDBY_DEAD,
	ENEMIES,
	ENEMIES_BASIC,
	ENEMIES_ELITE,
	ENEMIES_BOSSES,
	ENEMIES_IN_COMBAT,
	ENEMIES_ON_SCREEN,
}

enum Status {
	BERSERK = 1 << 0,
	BLINDNESS = 1 << 1,
	CHARM = 1 << 2,
	CONFUSE = 1 << 3,
	COUNTER = 1 << 4,
	DOOM = 1 << 5,
	INVINCIBLE = 1 << 6,
	INVISIBLE = 1 << 7,
	PETRIFICATION = 1 << 8,
	POISON = 1 << 9,
	REFLECT = 1 << 10,
	REGEN = 1 << 11,
	SECOND_CHANCE = 1 << 12,
	SILENCE = 1 << 13,
	SLEEP = 1 << 14,
	STAT_CHANGE = 1 << 15,
	STUN = 1 << 16,
	TAUNT = 1 << 17,
}

var effect_resources := {
	Status.BERSERK: load("res://scripts/effects_scripts/berserk.gd"),
	Status.BLINDNESS: load("res://scripts/effects_scripts/blindness.gd"),
	Status.CHARM: load("res://scripts/effects_scripts/charm.gd"),
	Status.CONFUSE: load("res://scripts/effects_scripts/confuse.gd"),
	Status.COUNTER: load("res://scripts/effects_scripts/counter.gd"),
	Status.DOOM: load("res://scripts/effects_scripts/doom.gd"),
	Status.INVINCIBLE: load("res://scripts/effects_scripts/invincible.gd"),
	Status.INVISIBLE: load("res://scripts/effects_scripts/invisible.gd"),
	Status.PETRIFICATION: load("res://scripts/effects_scripts/petrification.gd"),
	Status.POISON: load("res://scripts/effects_scripts/poison.gd"),
	Status.REFLECT: load("res://scripts/effects_scripts/reflect.gd"),
	Status.REGEN: load("res://scripts/effects_scripts/regen.gd"),
	Status.SECOND_CHANCE: load("res://scripts/effects_scripts/second_chance.gd"),
	Status.SILENCE: load("res://scripts/effects_scripts/silence.gd"),
	Status.SLEEP: load("res://scripts/effects_scripts/sleep.gd"),
	Status.STAT_CHANGE: load("res://scripts/effects_scripts/stat_change.gd"),
	Status.STUN: load("res://scripts/effects_scripts/stun.gd"),
	Status.TAUNT: load("res://scripts/effects_scripts/taunt.gd"),
}

const PLAYER_HIGHLIGHT: PackedScene = preload("res://resources/entity_highlights/player_highlight.tscn")
const ENEMY_HIGHLIGHT: PackedScene = preload("res://resources/entity_highlights/enemy_highlight.tscn")

var entities_of_type: Dictionary[Type, Callable] = {
	Type.PLAYERS_MAIN: func() -> Array[Node]:
		return [Players.main_player_node],
	Type.PLAYERS_ALLIES: func() -> Array[Node]:
		return Players.party_node.get_children().filter(func(node: Node) -> bool: return not node.is_main_player),
	Type.PLAYERS_PARTY: func() -> Array[Node]:
		return Players.party_node.get_children(),
	Type.PLAYERS_PARTY_ALIVE: func() -> Array[Node]:
		return Players.party_node.get_children().filter(func(node: Node) -> bool: return node.character_node.alive),
	Type.PLAYERS_PARTY_DEAD: func() -> Array[Node]:
		return Players.party_node.get_children().filter(func(node: Node) -> bool: return not node.character_node.alive),
	Type.ENEMIES: func() -> Array[Node]:
		return Global.tree.current_scene.get_node(^"Enemies").get_children(),
	Type.ENEMIES_BASIC: func() -> Array[Node]:
		return Global.tree.current_scene.get_node(^"Enemies").get_children().filter(func(node: Node) -> bool: return node is BasicEnemyBase),
	Type.ENEMIES_ELITE: func() -> Array[Node]:
		return Global.tree.current_scene.get_node(^"Enemies").get_children().filter(func(node: Node) -> bool: return node is EliteEnemyBase),
	Type.ENEMIES_BOSSES: func() -> Array[Node]:
		return Global.tree.current_scene.get_node(^"Enemies").get_children().filter(func(node: Node) -> bool: return node is BossEnemyBase),
	Type.ENEMIES_IN_COMBAT: func() -> Array[Node]:
		return Combat.enemy_nodes_in_combat,
	Type.ENEMIES_ON_SCREEN: func() -> Array[Node]: # TODO: should not use groups
		return Global.tree.current_scene.get_node(^"Enemies").get_children().filter(func(node: Node) -> bool: return node.is_in_group("on_screen")),
}

var entity_stats_of_type: Dictionary[Type, Callable] = {
	Type.PLAYERS: func() -> Array[Node]:
		return entity_stats_of_type[Type.PLAYERS_PARTY].call() + entity_stats_of_type[Type.PLAYERS_STANDBY].call(),
	Type.PLAYERS_MAIN: func() -> Array[Node]:
		return [Players.main_player_node.character_node],
	Type.PLAYERS_ALLIES: func() -> Array[Node]:
		return entity_stats_of_type[Type.PLAYERS_PARTY].call().filter(func(node: Node) -> bool: return not node.get_parent().is_main_player),
	Type.PLAYERS_PARTY: func() -> Array[Node]:
		var entities_stats: Array[Node] = []
		var nodes: Array[Node] = Players.party_node.get_children()
		for player_node in nodes:
			entities_stats.push_back(player_node.character_node)
		return entities_stats,
	Type.PLAYERS_STANDBY: func() -> Array[Node]:
		return Players.standby_node.get_children(),
	Type.PLAYERS_ALIVE: func() -> Array[Node]:
		return entity_stats_of_type[Type.PLAYERS].call().filter(func(node: Node) -> bool: return node.alive),
	Type.PLAYERS_PARTY_ALIVE: func() -> Array[Node]:
		return entity_stats_of_type[Type.PLAYERS_PARTY].call().filter(func(node: Node) -> bool: return node.alive),
	Type.PLAYERS_STANDBY_ALIVE: func() -> Array[Node]:
		return entity_stats_of_type[Type.PLAYERS_STANDBY].call().filter(func(node: Node) -> bool: return node.alive),
	Type.PLAYERS_DEAD: func() -> Array[Node]:
		return entity_stats_of_type[Type.PLAYERS].call().filter(func(node: Node) -> bool: return not node.alive),
	Type.PLAYERS_PARTY_DEAD: func() -> Array[Node]:
		return entity_stats_of_type[Type.PLAYERS_PARTY].call().filter(func(node: Node) -> bool: return not node.alive),
	Type.PLAYERS_STANDBY_DEAD: func() -> Array[Node]:
		return entity_stats_of_type[Type.PLAYERS_STANDBY].call().filter(func(node: Node) -> bool: return not node.alive),
	Type.ENEMIES: func() -> Array[Node]:
		var entities_stats: Array[Node] = []
		var nodes: Array[Node] = Global.tree.current_scene.get_node(^"Enemies").get_children()
		for enemy_node in nodes:
			entities_stats.push_back(enemy_node.base_enemy_node)
		return entities_stats,
	Type.ENEMIES_BASIC: func() -> Array[Node]:
		return entity_stats_of_type[Type.ENEMIES].call().filter(func(node: Node) -> bool: return node.get_parent() is BasicEnemyBase),
	Type.ENEMIES_ELITE: func() -> Array[Node]:
		return entity_stats_of_type[Type.ENEMIES].call().filter(func(node: Node) -> bool: return node.get_parent() is EliteEnemyBase),
	Type.ENEMIES_BOSSES: func() -> Array[Node]:
		return entity_stats_of_type[Type.ENEMIES].call().filter(func(node: Node) -> bool: return node.get_parent() is BossEnemyBase),
	Type.ENEMIES_IN_COMBAT: func() -> Array[Node]: # TODO: consider using enemy variables
		var entities_stats: Array[Node] = []
		for enemy_node in Combat.enemy_nodes_in_combat:
			entities_stats.push_back(enemy_node.base_enemy_node)
		return entities_stats,
	Type.ENEMIES_ON_SCREEN: func() -> Array[Node]: # TODO: should not use groups
		return entity_stats_of_type[Type.ENEMIES].call().filter(func(node: Node) -> bool: return node.get_parent().is_in_group("on_screen")),
}

var requesting_entities: bool = false
var requester_node: Node = null
var entities_requested_count: int = 0
var entities_available: Array[Node] = []
var entities_chosen: Array[Node] = []

# TODO: need to complete implementation
#func target_entity_by_quantity(nodes: Array[Node], quality: Qualities, get_max: bool, for_request: bool = false) -> Node:
#	var target_node: Node = null
#	var best_quality: float = - INF if get_max else INF
#
#	for node: Node in nodes:
#		if not is_instance_valid(node):
#			continue
#		if for_request and not entities_available.has(node):
#			continue
#		if (get_max and node.stats[quality] > best_quality) or (node.stats[quality] < best_quality):
#			target_node = node
#			best_quality = node.stats[quality]
#	
#	if for_request:
#		entities_chosen.append(target_node)
#		target_node = null
#
#	return target_node

func target_entity_by_distance(origin_node: Node, nodes: Array[Node], get_max: bool, for_request: bool = false) -> Node:
	var target_node: Node = null
	var best_quality: float = - INF
	var i: int = 1 if get_max else -1

	for node: Node in nodes:
		if not is_instance_valid(node):
			continue
		if for_request and not entities_available.has(node):
			continue
		var distance = origin_node.position.distance_to(node.position)
		if best_quality < distance * i:
			target_node = node
			best_quality = distance
	
	if for_request:
		entities_chosen.append(target_node)
		target_node = null

	return target_node

func target_entity(type: String, origin_node):
	var comparing_qualities := []
	var compared_quality = INF
	var sign_indicator: int = 1
	var target_entity_node: Node = null
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
			comparing_qualities.push_back(sign_indicator * entity_node.character_node.get(type))
		else:
			comparing_qualities.push_back(sign_indicator * entity_node.base_enemy_node.get(type))
	# choose entity with least of chosen quality
	var counter: int = 0
	for entity_quality in comparing_qualities:
		if entity_quality < compared_quality:
			compared_quality = entity_quality
			target_entity_node = entities_available[counter]
		counter += 1
	# choose entities if fulfilled required number
	entities_chosen.push_back(target_entity_node)
	if entities_requested_count == entities_chosen.size():
		choose_entities()

func request_entities(origin_node: Node, request_types: Array[Type], request_count: int = 1) -> void:
	reset_entity_request()

	# append available entities
	for request_type in request_types:
		entities_available = entities_of_type[request_type].call()

	if entities_available.is_empty():
		if origin_node.is_in_group("abilities"):
			origin_node.ability_request_failed()
		return
	
	# set new variables
	requesting_entities = true
	requester_node = origin_node
	entities_requested_count = request_count

	# highlight available entities
	for node in entities_available:
		if not is_instance_valid(node):
			continue
		if node is PlayerBase and not node.has_node("PlayerHighlight"):
			node.add_child(PLAYER_HIGHLIGHT.instantiate())
		elif node.is_in_group("enemies") and not node.has_node("EnemyHighlight"):
			node.add_child(ENEMY_HIGHLIGHT.instantiate()) # TODO: need to scale in size

	# choose locked enemy when suitable
	if (
			entities_requested_count == 1
			and Combat.locked_enemy_node != null
			and Combat.locked_enemy_node in entities_available
	):
		entities_chosen.append(Combat.locked_enemy_node)
		choose_entities()

func choose_entities() -> void:
	if entities_chosen.size() == 1:
		requester_node.emit_signal("entities_chosen", entities_chosen[0])
	else:
		requester_node.emit_signal("entities_chosen", entities_chosen)
	reset_entity_request(true)

func reset_entity_request(request_succeeded: bool = false) -> void:
	if (
			requester_node != null
			and not request_succeeded
			and requester_node.is_in_group("abilities")
	):
		requester_node.ability_request_failed()
	
	for node in entities_available:
		if not is_instance_valid(node): continue

		if node is PlayerBase and node.has_node("PlayerHighlight"):
			node.get_node(^"PlayerHighlight").queue_free()
		elif node.is_in_group("enemies") and node.has_node("EnemyHighlight"): # TODO: should check for classes like BasicEnemyBase instead
			node.get_node(^"EnemyHighlight").queue_free()
	
	requesting_entities = false
	requester_node = null
	entities_requested_count = 0
	entities_available.clear()
	entities_chosen.clear()

func toggle_movement(can_move):
	# toggle players movements
	for player_node in Players.party_node.get_children():
		# ignore if not alive
		if not player_node.character_node.alive:
			continue

		player_node.set_physics_process(can_move)

		# update animation
		if not can_move:
			player_node.update_velocity(Vector2.ZERO)
		
	# toggle enemies movements
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		enemy_node.set_physics_process(can_move)

		# update animation
		if not can_move:
			enemy_node.animation_node.play("idle")
