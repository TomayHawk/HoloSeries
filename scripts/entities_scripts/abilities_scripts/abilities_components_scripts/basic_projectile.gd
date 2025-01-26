extends Node

var velocity := Vector2.ZERO

# initially disables physics processing
func _ready():
	set_physics_process(false)

# when physics processing is enabled,
# parent ability moves and checks for collision
# when collision is detected,
# goes to parent ability's projectile collision function
func _physics_process(delta: float):
	if get_parent().move_and_collide(velocity * delta) != null:
		get_parent().projectile_collision(velocity.normalized())

# sets projectile velocity (direction and speed),
# then enables physics processing
func initiate_projectile(direction: Vector2, speed: float):
	velocity = direction * speed
	set_physics_process(true)
