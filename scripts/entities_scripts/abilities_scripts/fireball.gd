extends CharacterBody2D

@onready var caster_node = GlobalSettings.current_main_player_node
@onready var animation_node = $AnimatedSprite2D
@onready var blast_radius_node = $BlastRadius
@onready var time_left_node = $TimeLeft

var damage = 50
var speed = 120

var move_direction = Vector2.ZERO
var nodes_in_blast_area = []

func _ready():
	hide()
	set_physics_process(false)
	animation_node.play("shoot")
	GlobalSettings.request_entities(self, "initiate_fireball", 1, "all_enemies_on_screen")

func _physics_process(delta):
	var collision_information = move_and_collide(velocity * delta)
	if collision_information != null: area_impact()

func initiate_fireball(chosen_nodes):
	set_physics_process(true)
	position = caster_node.position + Vector2(0, -7)

	move_direction = (chosen_nodes[0].position - position).normalized()
	velocity = move_direction * speed

	caster_node.player_stats_node.update_mana_bar( - 10)
	
	show()
	time_left_node.start()
	GlobalSettings.empty_entities_request()

func area_impact():
	for enemy_node in nodes_in_blast_area:
		enemy_node.take_damage(caster_node, damage)
	queue_free()

func _on_blast_radius_body_entered(body):
	nodes_in_blast_area.push_back(body)

func _on_blast_radius_body_exited(body):
	nodes_in_blast_area.erase(body)

func _on_visible_on_screen_enabler_2d_screen_exited():
	time_left_node.set_wait_time(0.5)

func _on_time_left_timeout():

	queue_free()
