extends Node

signal entities_request_ended(entity_nodes: Array[EntityBase])

enum Type {
	PLAYERS = 1 << 0,
	PLAYERS_ALLIES = 1 << 1,
	PLAYERS_ALIVE = 1 << 2,
	PLAYERS_DEAD = 1 << 3,
	ENEMIES = 1 << 4,
	ENEMIES_IN_COMBAT = 1 << 5,
	ENEMIES_ON_SCREEN = 1 << 6,
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

const ENTITY_LIMIT: int = 200

var entities_of_type: Dictionary[Type, Callable] = {
	Type.PLAYERS: func() -> Array[Node]:
		return Players.party_node.get_children(),
	Type.PLAYERS_ALLIES: func() -> Array[Node]:
		return Players.party_node.get_children().filter(func(node: Node) -> bool: return not node.is_main_player),
	Type.PLAYERS_ALIVE: func() -> Array[Node]:
		return Players.party_node.get_children().filter(func(node: Node) -> bool: return node.character_node.alive),
	Type.PLAYERS_DEAD: func() -> Array[Node]:
		return Players.party_node.get_children().filter(func(node: Node) -> bool: return not node.character_node.alive),
	Type.ENEMIES: func() -> Array[Node]:
		return Global.tree.current_scene.get_node(^"Enemies").get_children(),
	Type.ENEMIES_IN_COMBAT: func() -> Array[Node]:
		return Combat.enemy_nodes_in_combat,
	Type.ENEMIES_ON_SCREEN: func() -> Array[Node]: # TODO: should not use groups
		return Global.tree.current_scene.get_node(^"Enemies").get_children().filter(func(node: Node) -> bool: return node.is_in_group("enemies_on_screen")),
}

var effect_resources: Dictionary[Status, Resource] = {
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

var requesting_entities: bool = false
var entities_requested_count: int = 0
var entities_available: Array[Node] = []
var entities_chosen: Array[EntityBase] = []

func target_entity_by_stats(stat_name: String, candidate_nodes: Array[Node], get_max: bool, for_request: bool) -> EntityBase:
	var target_entity_node: EntityBase = null
	var best_quality: float = - INF if get_max else INF

	for entity_node in candidate_nodes:
		if not is_instance_valid(entity_node): continue
		var entity_stat: float = entity_node.character_node.get(stat_name) if entity_node is PlayerBase \
				else entity_node.enemy_stats_node.get(stat_name)
		if (get_max and entity_stat > best_quality) or (not get_max and entity_stat < best_quality):
			target_entity_node = entity_node
			best_quality = entity_stat
	
	if for_request:
		choose_entity(target_entity_node)
	
	return target_entity_node

func target_entity_by_distance(origin_position: Vector2, candidate_nodes: Array[Node], get_max: bool, for_request: bool) -> EntityBase:
	var target_entity_node: EntityBase = null
	var best_distance: float = - INF if get_max else INF

	for entity_node in candidate_nodes:
		if not is_instance_valid(entity_node): continue
		var temp_distance = origin_position.distance_to(entity_node.position)
		if (get_max and temp_distance > best_distance) or (not get_max and temp_distance < best_distance):
			target_entity_node = entity_node
			best_distance = temp_distance

	if for_request:
		choose_entity(target_entity_node)

	return target_entity_node

func request_entities(request_types: Array[Type], request_count: int = 1) -> void:
	# append available entities
	for request_type in request_types:
		entities_available += entities_of_type[request_type].call()

	# cancel request if insufficient candidates
	if entities_available.size() < request_count:
		entities_request_ended.emit([] as Array[EntityBase])
		entities_available.clear()
		return
	
	# choose locked or nearest entity if suitable
	if request_count == 1 and Combat.locked_enemy_node in entities_available:
		entities_request_ended.emit([Combat.locked_enemy_node] as Array[EntityBase])
		entities_available.clear()
		return
	
	# set new variables
	requesting_entities = true
	entities_requested_count = request_count

	# highlight available entities
	for entity_node in entities_available:
		if not is_instance_valid(entity_node): continue
		if entity_node is PlayerBase and not entity_node.has_node(^"PlayerHighlight"):
			entity_node.add_child(load("res://entities/entities_indicators/player_highlight.tscn").instantiate()) # TODO: need to scale in size
		elif entity_node is EnemyBase and not entity_node.has_node(^"EnemyHighlight"):
			entity_node.add_child(load("res://entities/entities_indicators/enemy_highlight.tscn").instantiate()) # TODO: need to scale in size

func choose_entity(entity_node: EntityBase) -> void:
	if not requesting_entities or not entity_node in entities_available or entity_node in entities_chosen: return
	entities_chosen.append(entity_node)
	if entities_chosen.size() == entities_requested_count:
		end_entities_request()

func end_entities_request() -> void:
	# emit signals
	entities_request_ended.emit(entities_chosen)
	
	# remove entity highlights
	for node in entities_available:
		if not is_instance_valid(node): continue
		if node is PlayerBase and node.has_node(^"PlayerHighlight"):
			node.get_node(^"PlayerHighlight").free()
		elif node is EntityBase and node.has_node(^"EnemyHighlight"):
			node.get_node(^"EnemyHighlight").free()
	
	# reset variables
	requesting_entities = false
	entities_requested_count = 0
	entities_available.clear()
	entities_chosen.clear()

func add_enemy_to_scene(enemy_load: Resource, entity_position: Vector2) -> EnemyBase:
	var enemies_node = Global.tree.current_scene.get_node(^"Enemies")
	if enemies_node.get_child_count() > ENTITY_LIMIT: return null
	var enemy_instance: EnemyBase = enemy_load.instantiate()
	enemy_instance.position = entity_position + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 25
	enemies_node.add_child(enemy_instance)
	return enemy_instance

func toggle_entities_movements(can_move: bool) -> void:
	# toggle players movements
	for player_node in Players.party_node.get_children():
		if not player_node.character_node.alive:
			continue
		player_node.set_physics_process(can_move)
		if not can_move:
			player_node.update_velocity(Vector2.ZERO)
		
	# toggle enemies movements
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		enemy_node.set_physics_process(can_move)
		if not can_move:
			enemy_node.enemy_stats_node.play("idle")
