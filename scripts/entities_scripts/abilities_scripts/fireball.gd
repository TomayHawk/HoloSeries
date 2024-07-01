extends CharacterBody2D

@onready var animation_node = $AnimatedSprite2D

@export var damage = 50
@export var speed = 250

var current_player
var move_direction

func _ready():
	animation_node.play("shoot")
	current_player = GlobalSettings.party_player_nodes[GlobalSettings.current_main_player_index]
	move_direction = current_player.move_direction
	
	var nearest_enemy = find_nearest_enemy()
	if nearest_enemy:
		# Calculate the direction to the nearest enemy
		var direction = (nearest_enemy.global_position - current_player.position).normalized()
		velocity = direction * speed
		print("Nearest enemy found at position: ", nearest_enemy.global_position)
	elif move_direction != Vector2.ZERO: # shoot at player default facing direction
		velocity = move_direction * speed
	else: # shoot at player attack direction?? when current player is not moving
		print(current_player.last_move_direction)
		velocity = current_player.last_move_direction * speed

func _physics_process(_delta):
	move_and_slide()

func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()

func _on_checker_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(0, damage)
	queue_free()

func find_nearest_enemy():
	var nearest_enemy = null
	var shortest_distance = INF
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = current_player.position.distance_to(enemy.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			nearest_enemy = enemy
		#print("Enemy position: ", enemy.global_position, " Distance: ", distance)
	return nearest_enemy
