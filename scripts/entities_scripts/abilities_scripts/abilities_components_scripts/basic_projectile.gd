extends Node

@onready var ability_node: Node = get_parent()
var velocity := Vector2.ZERO

func _ready():
	set_physics_process(false)

func _physics_process(delta: float):
	if ability_node.move_and_collide(velocity * delta) != null:
		ability_node.projectile_collision(velocity.normalized())

func initiate_projectile(new_position: Vector2, new_direction: Vector2, new_speed: float):
	ability_node.position = new_position
	velocity = new_direction * new_speed
	set_physics_process(true)
