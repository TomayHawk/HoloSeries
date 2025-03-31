extends Node

var velocity := Vector2.ZERO

# initially disables physics process
func _ready() -> void:
	set_physics_process(false)

# when physics process is enabled, moves in direction
func _physics_process(delta: float) -> void:
	get_parent().position += velocity * delta

# sets projectile velocity, then enables physics process
func initiate_projectile(direction: Vector2, speed: float) -> void:
	velocity = direction * speed
	set_physics_process(true)
