extends Area2D

var item_type: int = -1
var item_id: int = -1

var nearby_players: Array[PlayerBase] = []
var target_player: PlayerBase = null
var multiplier: float = 1.0
var increment: float = 0.1

func _ready() -> void:
	set_physics_process(false)

func _physics_process(_delta: float) -> void:
	global_position += (target_player.global_position - global_position).normalized() * multiplier
	multiplier = clamp(multiplier + increment, 1.0, 10.0)

func instantiate_item(base_position: Vector2, texture_path: StringName, type: int, id: int) -> void:
	global_position = base_position + Vector2(15 * randf_range(-1.0, 1.0), 15 * randf_range(-1.0, 1.0))
	Combat.lootable_items_node.add_child(self)
	$Sprite2D.texture = load(texture_path)
	item_type = type
	item_id = id

func player_entered(player: PlayerBase) -> void:
	if not nearby_players.has(player):
		nearby_players.append(player)
	
	if not target_player:
		target_player = player
		set_physics_process(true)

func player_exited(player: PlayerBase) -> void:
	nearby_players.erase(player)

	if nearby_players.is_empty():
		set_physics_process(false)
		target_player = null
		multiplier = 1.0
	else:
		var least_distance: float = INF
		for nearby_player in nearby_players:
			var temp_distance: float = global_position.distance_squared_to(target_player.global_position)
			if temp_distance < least_distance:
				target_player = nearby_player
				least_distance = temp_distance

func _on_body_entered(body: Node2D) -> void:
	Inventory.add_item(item_type, item_id)
	body.stats.update_shield(10.0) # TODO: temporary code
	body.stats.update_ultimate_gauge(10.0) # TODO: temporary code
	queue_free()
