extends Node

@onready var ability_node := get_parent()
var velocity := Vector2.ZERO

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	if ability_node.move_and_collide(velocity * delta) != null: ability_node.projectile_collision(velocity.normalized())

func initiate_projectile(set_position, set_direction, set_speed):
	ability_node.position = set_position
	velocity = set_direction * set_speed
	set_physics_process(true)
