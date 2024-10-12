extends Node2D

@onready var ability_node := get_parent()
var target_node: Node = null
var attraction := 600

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	##### should increase
	ability_node.apply_central_impulse((target_node.position - ability_node.position).normalized() * attraction * delta)

func initiate_homing_projectile(node):
	set_physics_process(true)
	target_node = node

func _on_area_2d_body_entered(body):
	if target_node == null:
		initiate_homing_projectile(body)

func _on_area_2d_body_exited(body):
	if target_node == body:
		set_physics_process(false)
