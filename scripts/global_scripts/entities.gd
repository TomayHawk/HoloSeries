extends Node

# ..............................................................................

#region SIGNALS

signal entities_request_ended(entities: Array[EntityBase])

#endregion

# ..............................................................................

#region CONSTANTS

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

#endregion

# ..............................................................................

#region VARIABLES

# ENTITY FILTERS

var entities_of_type: Dictionary[Type, Callable] = {
	Type.PLAYERS: func() -> Array[EntityBase]:
		return type_entities_array(Players.get_children()),
	Type.PLAYERS_ALLIES: func() -> Array[EntityBase]:
		return type_entities_array(Players.get_children().filter(func(node: Node) -> bool: return not node.is_main_player)),
	Type.PLAYERS_ALIVE: func() -> Array[EntityBase]:
		return type_entities_array(Players.get_children().filter(func(node: Node) -> bool: return node.stats.alive)),
	Type.PLAYERS_DEAD: func() -> Array[EntityBase]:
		return type_entities_array(Players.get_children().filter(func(node: Node) -> bool: return not node.stats.alive)),
	Type.ENEMIES: func() -> Array[EntityBase]:
		return all_enemies(),
	Type.ENEMIES_IN_COMBAT: func() -> Array[EntityBase]:
		return Combat.enemies_in_combat,
	Type.ENEMIES_ON_SCREEN: func() -> Array[EntityBase]:
		return all_enemies().filter(func(node: Node) -> bool: return node.stats.entity_types & Type.ENEMIES_ON_SCREEN),
}

# EFFECTS RESOURCES

var effects_resources: Dictionary[Status, Resource] = {
	Status.BERSERK: preload("res://scripts/effects_scripts/berserk.gd"),
	Status.BLINDNESS: preload("res://scripts/effects_scripts/blindness.gd"),
	Status.CHARM: preload("res://scripts/effects_scripts/charm.gd"),
	Status.CONFUSE: preload("res://scripts/effects_scripts/confuse.gd"),
	Status.COUNTER: preload("res://scripts/effects_scripts/counter.gd"),
	Status.DOOM: preload("res://scripts/effects_scripts/doom.gd"),
	Status.INVINCIBLE: preload("res://scripts/effects_scripts/invincible.gd"),
	Status.INVISIBLE: preload("res://scripts/effects_scripts/invisible.gd"),
	Status.PETRIFICATION: preload("res://scripts/effects_scripts/petrification.gd"),
	Status.POISON: preload("res://scripts/effects_scripts/poison.gd"),
	Status.REFLECT: preload("res://scripts/effects_scripts/reflect.gd"),
	Status.REGEN: preload("res://scripts/effects_scripts/regen.gd"),
	Status.SECOND_CHANCE: preload("res://scripts/effects_scripts/second_chance.gd"),
	Status.SILENCE: preload("res://scripts/effects_scripts/silence.gd"),
	Status.SLEEP: preload("res://scripts/effects_scripts/sleep.gd"),
	Status.STAT_CHANGE: preload("res://scripts/effects_scripts/stat_change.gd"),
	Status.STUN: preload("res://scripts/effects_scripts/stun.gd"),
	Status.TAUNT: preload("res://scripts/effects_scripts/taunt.gd"),
}

# ENTITIES REQUESTS VARIABLES

var requesting_entities: bool = false
var entities_requested_count: int = 0
var entities_available: Array[EntityBase] = []
var entities_chosen: Array[EntityBase] = []

@onready var abilities_node: Node = $Abilities
@onready var lootable_items_node: Node = $LootableItems

#endregion

# ..............................................................................

#region ENTITIES FILTERS

func target_entity_by_quality(candidates: Array[EntityBase], get_quality: Callable, get_max: bool) -> EntityBase:
	var best_entity: EntityBase = null
	var best_quality: float = -INF if get_max else INF

	for entity in candidates:
		if not is_instance_valid(entity): continue
		var quality = get_quality.call(entity)
		if (get_max and quality > best_quality) or (not get_max and quality < best_quality):
			best_entity = entity
			best_quality = quality

	return best_entity

# target entity by stats
func target_entity_by_stats(candidates: Array[EntityBase], stat_name: StringName, get_max: bool) -> EntityBase:
	return target_entity_by_quality(candidates, func(entity): return entity.stats.get(stat_name), get_max)

# target entity by distance
func target_entity_by_distance(candidates: Array[EntityBase], origin: Vector2, get_max: bool) -> EntityBase:
	return target_entity_by_quality(candidates, func(entity): return origin.distance_squared_to(entity.position), get_max)

# convert Array into Array[EntityBase]
func type_entities_array(entities: Array) -> Array[EntityBase]:
	var entity_base_array: Array[EntityBase] = []
	
	for entity in entities:
		if entity and is_instance_valid(entity) and entity is EntityBase:
			entity_base_array.append(entity)
	
	return entity_base_array

# return all enemies in the current scene enemies node
func all_enemies() -> Array[EntityBase]:
	if not get_tree().current_scene: return []
	
	var enemies_node = get_tree().current_scene.get_node_or_null(^"Enemies")
	if not enemies_node: return []
	
	return type_entities_array(get_tree().current_scene.get_node(^"Enemies").get_children())

#endregion

# ..............................................................................

#region ENTITIES REQUESTS

func request_entities(request_types: int, request_count: int = 1) -> void:
	# append available entities
	for type in Type.values():
		if request_types & type:
			entities_available += entities_of_type[type].call()

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
	for entity in entities_available:
		if not is_instance_valid(entity): continue
		if entity is PlayerBase and not entity.has_node(^"PlayerHighlight"):
			entity.add_child(load("res://entities/entities_indicators/player_highlight.tscn").instantiate()) # TODO: need to scale in size
		elif entity is EnemyBase and not entity.has_node(^"EnemyHighlight"):
			entity.add_child(load("res://entities/entities_indicators/enemy_highlight.tscn").instantiate()) # TODO: need to scale in size

func choose_entity(entity: EntityBase) -> void:
	if requesting_entities and entity in entities_available:
		entities_chosen.append(entity)
		entities_available.erase(entity)
		if entities_chosen.size() == entities_requested_count:
			end_entities_request()

func end_entities_request() -> void:
	# emit signals
	entities_request_ended.emit(entities_chosen)
	
	# remove entity highlights
	for node in entities_chosen + entities_available:
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

#endregion

# ..............................................................................

#region MISCELLANEOUS

# add an enemy to the current scene enemies node
func add_enemy_to_scene(enemy_load: Resource, entity_position: Vector2, position_range: float) -> EnemyBase:
	if not get_tree().current_scene: return null
	
	# get enemies node and check entity limit
	var enemies_node = get_tree().current_scene.get_node(^"Enemies")
	if enemies_node.get_child_count() > ENTITY_LIMIT: return null
	
	# create enemy instance and set position
	var enemy_instance: EnemyBase = enemy_load.instantiate()
	enemy_instance.position = entity_position + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * position_range
	enemies_node.add_child(enemy_instance)
	
	# return enemy instance
	return enemy_instance

# toggle players and enemies process
func toggle_entities_process(toggled: bool) -> void:
	for entity in Players.get_children() + all_enemies():
		entity.toggle_process(toggled)

# toggle players process on text box dialogues
func toggle_text_box_process(toggled: bool) -> void:
	for player in Players.get_children():
		player.toggle_text_box_process(toggled)

#endregion

# ..............................................................................
