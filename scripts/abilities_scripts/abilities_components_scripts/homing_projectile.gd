extends Area2D

@onready var ability_node: Node = get_parent()

var target_lost: bool = false
var target_node: Node = null
var speed: float = 100.0

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not target_node or target_lost:
		ability_node.position += speed * Vector2.RIGHT.rotated(ability_node.rotation) * delta
		return
	
	ability_node.look_at(target_node.global_position)
	ability_node.position = ability_node.position.move_toward(target_node.global_position, speed * delta)
	
func initiate_homing_projectile(entity_node: EntityBase) -> void:
	$CollisionShape2D.set_deferred(&"disabled", false)
	target_node = entity_node
	speed = ability_node.homing_projectile_speed()
	ability_node.look_at(target_node.global_position)
	set_physics_process(true)

func _on_body_exited(body: Node2D) -> void:
	if body == target_node:
		target_lost = true
