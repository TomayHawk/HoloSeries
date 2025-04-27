extends Area2D

var item_type: int = -1
var item_id: int = -1

var nearby_player_nodes: Array[PlayerBase] = []
var target_player_node: PlayerBase = null
var multiplier: float = 1.0
var increment: float = 0.1

func _ready() -> void:
	set_physics_process(false)

func _physics_process(_delta: float) -> void:
	global_position += (target_player_node.global_position - global_position).normalized() * multiplier
	multiplier = clamp(multiplier + increment, 1.0, 10.0)

func instantiate_item(base_position: Vector2, texture_path: StringName, type: int, id: int) -> void:
	global_position = base_position + Vector2(15 * randf_range(-1, 1), 15 * randf_range(-1, 1))
	Combat.lootable_items_node.add_child(self)
	$Sprite2D.texture = load(texture_path)
	item_type = type
	item_id = id

func _on_body_entered(_body: Node2D) -> void:
	Inventory.add_item(item_type, item_id)
	queue_free()
