extends Node2D

@onready var ability_node: Node = get_parent()
var target_node: Node = null
var velocity: Vector2 = Vector2(1, 1)
var speed: float = 100.0
var homing_strength: int = 20

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	# Get the direction to the target
	var direction = (target_node.global_position - global_position).normalized()
	
	# Adjust the current velocity to home in on the target
	var current_velocity = velocity.normalized()
	current_velocity = current_velocity.lerp(direction, homing_strength * delta)
	
	# Apply movement to the projectile
	velocity = current_velocity * speed * delta
	ability_node.move_and_collide(velocity)
	
	# Optionally, rotate the projectile to face the direction of movement
	ability_node.rotation = velocity.angle()

func initiate_homing_projectile(node):
	velocity = ability_node.get_node("BasicProjectile").velocity
	speed = velocity.x / velocity.normalized().x
	set_physics_process(true)
	target_node = node

func _on_area_2d_body_entered(body):
	if target_node == null:
		initiate_homing_projectile(body)

func _on_area_2d_body_exited(body):
	if target_node == body:
		set_physics_process(false)
