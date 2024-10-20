extends Node2D

@onready var player_node := get_parent()

@onready var navigation_agent_node := %NavigationAgent2D
@onready var obstacle_check_node := %ObstacleCheck

# timer nodes
@onready var ally_direction_cooldown_node := %AllyDirectionCooldown
@onready var ally_pause_timer_node := %AllyPauseTimer

var ally_speed := 6000.0

var ally_direction_ready := true
var ray_cast_obstacles := true

# combat variables (allies)
var ally_attack_ready := true
var ally_enemy_in_attack_area := false
var ally_enemy_nodes_in_attack_area: Array[Node] = []
var ally_target_enemy_node: Node = null

# temporary variables
var temp_ally_speed := 6000.0
var temp_distance_to_main_player := 0.0
var temp_move_direction := Vector2.ZERO
var temp_possible_directions: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
var temp_comparator := 0.0

'''
func _physics_process(delta):
	temp_distance_to_main_player = position.distance_to(GlobalSettings.current_main_player_node.position)

	# if ally in combat
	if CombatEntitiesComponent.in_combat and ally_enemy_in_attack_area and temp_distance_to_main_player < 250:
		player_node.current_move_state = player_node.MoveState.WALK
		player_node.velocity = Vector2.ZERO

		# target health
		temp_comparator = INF
		# determine enemy health
		for enemy in ally_enemy_nodes_in_attack_area:
			# target enemy with lowest health
			if enemy.base_enemy_node.health < temp_comparator:
				temp_comparator = enemy.base_enemy_node.health
				ally_target_enemy_node = enemy
		
		last_move_direction = (ally_target_enemy_node.position - position).normalized()
		if ally_attack_ready: attack()

		choose_animation()
	# if ally can move
	elif ally_direction_ready and !attacking: ally_movement(delta)


func ally_movement(delta):
	ally_direction_ready = false
	moving = true
	temp_ally_speed = ally_speed

	if CombatEntitiesComponent.in_combat and !CombatEntitiesComponent.leaving_combat and temp_distance_to_main_player < 250:
		# distance to target
		temp_comparator = INF
		# evaluate enemy distances
		for enemy in CombatEntitiesComponent.enemy_nodes_in_combat:
			# target enemy with shortest distance
			if position.distance_to(enemy.position) < temp_comparator:
				temp_comparator = position.distance_to(enemy.position)
				ally_target_enemy_node = enemy
		
		if temp_comparator > 200 and temp_comparator > temp_distance_to_main_player:
			navigation_agent_node.target_position = GlobalSettings.current_main_player_node.position
		else:
			navigation_agent_node.target_position = ally_target_enemy_node.position

		current_move_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
		ally_direction_cooldown_node.start(randf_range(0.2, 0.4))
	elif temp_distance_to_main_player < 80:
		current_move_direction = possible_directions[randi() % 8]
		ally_direction_cooldown_node.start(randf_range(0.5, 0.7))
		temp_ally_speed /= 1.5
	else:
		navigation_agent_node.target_position = GlobalSettings.current_main_player_node.position
		current_move_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
		ally_direction_cooldown_node.start(randf_range(0.5, 0.7))

	if temp_distance_to_main_player > 200:
		temp_ally_speed *= (temp_distance_to_main_player / 200)
		if temp_distance_to_main_player > 300:
			temp_ally_speed = ally_speed * 2
	
	if GlobalSettings.current_main_player_node.sprinting and !CombatEntitiesComponent.in_combat and temp_distance_to_main_player > 120 and GlobalSettings.current_main_player_node.moving:
		temp_ally_speed = GlobalSettings.current_main_player_node.speed * sprint_multiplier

	# assume currently facing obstacle
	ray_cast_obstacles = true
	# each possible walk direction
	temp_possible_directions = [0, 1, 2, 3, 4, 5, 6, 7]
	temp_move_direction = current_move_direction

	# while facing obstacles
	while ray_cast_obstacles:
		# distance to target direction
		temp_comparator = INF
		
		# for each possible direction
		for i in temp_possible_directions:
			# if distance to snapped direction is shorter than current distance to snapped direction, set new snapped direction
			if current_move_direction.distance_to(possible_directions[i]) < temp_comparator:
				temp_comparator = current_move_direction.distance_to(possible_directions[i])
				temp_move_direction = possible_directions[i]

		current_move_direction = temp_move_direction

		# check for obstacles
		obstacle_check_node.set_target_position(current_move_direction * 20)
		obstacle_check_node.force_shapecast_update()

		# if facing obstacles
		if obstacle_check_node.is_colliding():
			# remove currently selected direction
			for i in temp_possible_directions:
				if current_move_direction == possible_directions[i]:
					temp_possible_directions.erase(i)
			
			if temp_possible_directions.is_empty():
				for i in 8:
					if current_move_direction.distance_to(possible_directions[i]) < temp_comparator:
						temp_comparator = current_move_direction.distance_to(possible_directions[i])
						temp_move_direction = possible_directions[i]
				current_move_direction = temp_move_direction

				ray_cast_obstacles = false
		else:
			ray_cast_obstacles = false

	player_node.velocity = current_move_direction * temp_ally_speed * delta

	last_move_direction = current_move_direction

	choose_animation()

func choose_animation():
	if attacking:
		if abs(attack_direction.x) >= abs(attack_direction.y):
			if attack_direction.x > 0:
				animation_node.play("right_attack")
			else:
				animation_node.play("left_attack")
		elif attack_direction.y < 0:
			animation_node.play("up_attack")
		else:
			animation_node.play("down_attack")
	else:
		if moving:
			if current_move_direction.x > 0: animation_node.play("right_walk")
			elif current_move_direction.x < 0: animation_node.play("left_walk")
			elif current_move_direction.y < 0: animation_node.play("up_walk")
			else: animation_node.play("down_walk")
		else:
			if abs(last_move_direction.x) >= abs(last_move_direction.y):
				if last_move_direction.x > 0: animation_node.play("right_idle")
				else: animation_node.play("left_idle")
			elif last_move_direction.y < 0: animation_node.play("up_idle")
			else: animation_node.play("down_idle")

func _on_interaction_area_body_entered(body):
	if body.has_method("choose_player"):
		ally_enemy_nodes_in_attack_area.push_back(body)
		ally_enemy_in_attack_area = true
		
		player_node.velocity = Vector2.ZERO
		moving = false
		ally_direction_ready = true

func _on_interaction_area_body_exited(body):
	if body.has_method("choose_player"):
		ally_enemy_nodes_in_attack_area.erase(body)
		if ally_enemy_nodes_in_attack_area.is_empty(): ally_enemy_in_attack_area = false

func _on_ally_attack_cooldown_timeout():
	ally_attack_ready = true

func _on_ally_direction_cooldown_timeout():
	player_node.velocity = Vector2.ZERO
	moving = false

	if CombatEntitiesComponent.in_combat and !CombatEntitiesComponent.leaving_combat:
		ally_direction_ready = true
	else:
		if temp_distance_to_main_player < 70:
			ally_pause_timer_node.start(randf_range(1.5, 2))
		elif temp_distance_to_main_player < 100:
			ally_pause_timer_node.start(randf_range(0.7, 0.8))
		else:
			ally_direction_ready = true
	
	choose_animation()

func _on_ally_pause_timer_timeout():
	ally_direction_ready = true
'''
