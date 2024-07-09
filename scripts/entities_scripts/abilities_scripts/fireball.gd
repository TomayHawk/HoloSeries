extends CharacterBody2D

@onready var caster_node = GlobalSettings.current_main_player_node
@onready var time_left_node = $TimeLeft

var speed = 180
var damage = -50
##### need to add stats multipliers

var move_direction = Vector2.ZERO
var nodes_in_blast_area = []

func _ready():
	GlobalSettings.request_entities(self, "initiate_fireball", 1, "all_enemies_on_screen")
	if GlobalSettings.entities_available.size() == 0: queue_free()

	# disabled while selecting target
	hide()
	set_physics_process(false)
	$AnimatedSprite2D.play("shoot")
	
	# if alt is pressed, auto-aim closest enemy
	if Input.is_action_pressed("alt")&&GlobalSettings.entities_available.size() != 0:
		var temp_distance = INF
		var selected_enemy = null

		for entity_node in GlobalSettings.entities_available:
			if position.distance_to(entity_node.position) < temp_distance:
				temp_distance = position.distance_to(entity_node.position)
				selected_enemy = entity_node
			
		GlobalSettings.entities_chosen.push_back(selected_enemy)
		GlobalSettings.choose_entities()

func _physics_process(delta):
	# blast on collision
	var collision_information = move_and_collide(velocity * delta)
	if collision_information != null: area_impact()

# run after entity selection with GlobalSettings.choose_entities()
func initiate_fireball(chosen_node):
	# check mana sufficiency
	if caster_node.player_stats_node.mana < 10:
		queue_free()
	else:
		caster_node.player_stats_node.update_mana( - 10)

		# set position, move direction and velocity
		position = caster_node.position + Vector2(0, -7)
		move_direction = (chosen_node.position - position).normalized()
		velocity = move_direction * speed

		# begin despawn timer
		time_left_node.start()
		show()
		set_physics_process(true)

# blast
func area_impact():
	# deal damage to each enemy in blast radius
	for enemy_node in nodes_in_blast_area:
		enemy_node.enemy_stats_node.update_health(damage, "normal_combat_damage", move_direction, 0.5)
	queue_free()

func _on_blast_radius_body_entered(body):
	nodes_in_blast_area.push_back(body)

func _on_blast_radius_body_exited(body):
	nodes_in_blast_area.erase(body)

func _on_visible_on_screen_enabler_2d_screen_exited():
	time_left_node.set_wait_time(0.5)

func _on_time_left_timeout():
	queue_free()
