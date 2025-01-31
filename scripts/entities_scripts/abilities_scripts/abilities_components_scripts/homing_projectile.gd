extends Area2D

var target_lost: bool = false
var target_node: Node = null
var speed: float = 100.0

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if target_node == null || target_lost:
		get_parent().position += speed * Vector2.RIGHT.rotated(rotation) * delta
		return
	
	look_at(target_node.global_position)
	position = position.move_toward(target_node.global_position, speed * delta)
	
func initiate_homing_projectile(target: Node, initial_direction: Vector2, set_speed: float) -> void:
	target_node = target
	#initial_direction
	speed = set_speed
	set_physics_process(true)

func _on_area_2d_body_entered(body) -> void:
	if target_node == null:
		initiate_homing_projectile(body)

func _on_area_2d_body_exited(body) -> void:
	if target_node == body:
		set_physics_process(false)
