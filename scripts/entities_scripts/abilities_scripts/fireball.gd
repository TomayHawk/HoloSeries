extends CharacterBody2D

@onready var caster_node = GlobalSettings.current_main_player_node
@onready var animation_node = $AnimatedSprite2D
@onready var blast_radius_node = $BlastRadius
@onready var time_left_node = $TimeLeft

@export var damage = 50
@export var speed = 10000

var move_direction = Vector2.ZERO
var collision_information = null
var nodes_in_blast_area = []

func _ready():
	position = caster_node.position + Vector2(0, 7)
	animation_node.play("shoot")

	GlobalSettings.request_entities(self, "initiate_fireball", 1, "all_enemies_on_screen")

	set_physics_process(false)
	hide()

func _physics_process(delta):
	print("hi")
	collision_information = move_and_collide(velocity * delta)
	if collision_information != null: area_impact()

func initiate_fireball(chosen_nodes):
	move_direction = (chosen_nodes[0].position - position).normalized()
	velocity = move_direction * speed

	show()
	set_physics_process(true)

func area_impact():
	for enemy_node in nodes_in_blast_area:
		enemy_node.take_damage(caster_node, damage)
	queue_free()

func _on_blast_radius_body_entered(body):
	nodes_in_blast_area.push_back(body)

func _on_blast_radius_body_exited(body):
	nodes_in_blast_area.erase(body)

func _on_visible_on_screen_enabler_2d_screen_exited():
	time_left_node.time_left(0.5)

func _on_time_left_timeout():
	queue_free()
