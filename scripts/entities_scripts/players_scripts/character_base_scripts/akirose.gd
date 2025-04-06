extends PlayerStats

const character_name: String = "Aki Rosenthal"
const character_index: int = 3

const basic_damage: float = 13.0
const ultimate_damage: float = 100.0
var dash_attack: bool = false

func ally_process() -> void:
	var player_node: CharacterBody2D = get_parent()
	var distance_to_main_player := player_node.position.distance_to(Players.main_player_node.position)

	# if ally in combat
	if player_node.ally_in_attack_position and distance_to_main_player < 250:
		# pause movement
		player_node.update_velocity(Vector2.ZERO)

		# target enemy with lowest health
		var target_enemy_node: Node = null
		var enemy_health := INF
		for enemy_node in player_node.enemy_nodes_in_attack_area:
			if enemy_node.enemy_stats_node.health < enemy_health:
				enemy_health = enemy_node.enemy_stats_node.health
				target_enemy_node = enemy_node
		
		# attack if able
		if player_node.attack_state == player_node.AttackState.READY: # TODO: might have to change
			player_node.set_attack_state(player_node.AttackState.ATTACK)
		# else face towards enemy
		else:
			var enemy_direction = (target_enemy_node.position - player_node.position).normalized()
			if abs(enemy_direction.x) < abs(enemy_direction.y):
				if enemy_direction.y < 0:
					player_node.set_move_direction(player_node.Directions.UP)
				else:
					player_node.set_move_direction(player_node.Directions.DOWN)
			elif enemy_direction.x < 0:
				player_node.set_move_direction(player_node.Directions.LEFT)
			else:
				player_node.set_move_direction(player_node.Directions.RIGHT)
	# if ally can move
	elif player_node.ally_can_move and player_node.attack_state != player_node.AttackState.ATTACK:
		var target_direction := Vector2.ZERO
		player_node.ally_can_move = false

		if Combat.in_combat() and not Combat.leaving_combat() and distance_to_main_player < 250:
			# TODO: move this somewhere else
			# target enemy with shortest distance
			var target_enemy_node: Node = null
			var enemy_distance := INF
			for enemy_node in Combat.enemy_nodes_in_combat.duplicate():
				if player_node.position.distance_to(enemy_node.position) < enemy_distance:
					enemy_distance = player_node.position.distance_to(enemy_node.position)
					target_enemy_node = enemy_node
			
			if enemy_distance > 200:
				player_node.get_node(^"NavigationAgent2D").target_position = Players.main_player_node.position
			else:
				player_node.get_node(^"NavigationAgent2D").target_position = target_enemy_node.position

			target_direction = to_local(player_node.get_node(^"NavigationAgent2D").get_next_path_position()).normalized()
			player_node.get_node(^"AllyMoveCooldown").start(randf_range(0.2, 0.4))
		elif distance_to_main_player < 80:
			target_direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
			player_node.get_node(^"AllyMoveCooldown").start(randf_range(0.5, 0.7))
			pass # TODO: velocity /= 1.5
		else:
			player_node.get_node(^"NavigationAgent2D").target_position = Players.main_player_node.position
			target_direction = to_local(player_node.get_node(^"NavigationAgent2D").get_next_path_position()).normalized()
			player_node.get_node(^"AllyMoveCooldown").start(randf_range(0.5, 0.7))

		if distance_to_main_player > 200:
			pass # TODO: velocity *= (distance_to_main_player / 200)
			if distance_to_main_player > 300:
				pass # TODO: velocity *= 2
		
		if Players.main_player_node.move_state == player_node.MoveState.SPRINT and not Combat.in_combat() and distance_to_main_player > 120:
			player_node.set_move_state(player_node.MoveState.SPRINT)
		
		var snapped_direction := Vector2.ZERO

		# snap to 8-way
		var possible_directions: Array[Vector2] = [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0), Vector2(-0.70710678, -0.70710678), Vector2(0.70710678, -0.70710678), Vector2(-0.70710678, 0.70710678), Vector2(0.70710678, 0.70710678)]
		for direction in possible_directions:
			if target_direction.distance_to(direction) < 0.390180645:
				snapped_direction = direction
				break

		# check for obstacles
		while true:
			player_node.get_node(^"ObstacleCheck").set_target_position(snapped_direction * 8)
			player_node.get_node(^"ObstacleCheck").force_shapecast_update()

			if player_node.get_node(^"ObstacleCheck").is_colliding():
				possible_directions.erase(snapped_direction)
				if possible_directions.is_empty():
					player_node.update_velocity(Vector2.ZERO)
					player_node.set_move_direction(player_node.VECTOR_TO_DIRECTION[snapped_direction])
					player_node.update_velocity(snapped_direction)
					break
				# find next closest direction
				var distance_to_direction := INF
				for direction in possible_directions:
					if target_direction.distance_to(direction) < distance_to_direction:
						distance_to_direction = target_direction.distance_to(direction)
						snapped_direction = direction
			else:
				player_node.set_move_state(player_node.MoveState.WALK)
				player_node.set_move_direction(player_node.VECTOR_TO_DIRECTION[snapped_direction])
				player_node.update_velocity(snapped_direction)
				break
	else:
		# TODO: need to fix this
		var possible_directions: Array[Vector2] = [Vector2(-0.70710678, -0.70710678), Vector2(0.70710678, -0.70710678), Vector2(-0.70710678, 0.70710678), Vector2(0.70710678, 0.70710678)]
		for direction in possible_directions:
			if player_node.velocity.normalized().distance_to(direction) < 0.390180645:
				player_node.update_velocity(direction)
				break

func update_nodes():
	super ()
	if get_parent() is PlayerBase:
		Combat.ui.name_labels[node_index].text = character_name
	else:
		Combat.ui.standby_name_labels[node_index].text = character_name

func basic_attack():
	if ultimate_gauge == max_ultimate_gauge:
		ultimate_attack()
		return

	if get_parent().is_main_player: get_parent().attack_direction = (get_global_mouse_position() - get_parent().position).normalized()
	else:
		var temp_enemy_health = INF
		for enemy_node in get_parent().enemy_nodes_in_attack_area:
			if enemy_node.enemy_stats_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.enemy_stats_node.health
				get_parent().attack_direction = (enemy_node.position - get_parent().position).normalized()
		get_parent().ally_can_attack = false
		$AllyAttackCooldown.start(randf_range(2, 3))

	if get_parent().move_state == get_parent().MoveState.DASH:
		dash_attack = true
	
	$AttackShape.set_target_position(get_parent().attack_direction * 20)

	$AttackTimer.start(0.5)

	$AttackShape.force_shapecast_update()

	connect(&"frame_changed", Callable(self, "basic_attack_register"))
	
func basic_attack_register():
	if frame != 1: return
	disconnect(&"frame_changed", Callable(self, "basic_attack_register"))
	var temp_damage: float = basic_damage
	var enemy_body = null
	var knockback_weight = 1.0

	if dash_attack:
		temp_damage *= 1.5
		knockback_weight = 1.5
		dash_attack = false
	
	if $AttackShape.is_colliding():
		for collision_index in $AttackShape.get_collision_count():
			enemy_body = $AttackShape.get_collider(collision_index).get_parent() # TODO: null instance bug need fix
			if Damage.combat_damage(temp_damage,
					Damage.DamageTypes.ENEMY_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
					self, enemy_body.enemy_stats_node):
				enemy_body.dealt_knockback(get_parent().attack_direction, knockback_weight)
		Players.camera_node.screen_shake(0.1, 1, 30, 5, true)

func ultimate_attack():
	update_ultimate_gauge(-100)

	if get_parent().is_main_player: get_parent().attack_direction = (get_global_mouse_position() - get_parent().position).normalized()
	else:
		var temp_enemy_health = INF
		for enemy_node in get_parent().enemy_nodes_in_attack_area:
			if enemy_node.enemy_stats_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.enemy_stats_node.health
				get_parent().attack_direction = (enemy_node.position - get_parent().position).normalized()
		get_parent().ally_can_attack = false
		$AllyAttackCooldown.start(randf_range(2, 3))
	
	if get_parent().move_state == get_parent().MoveState.DASH:
		dash_attack = true
	
	$AttackShape.set_target_position(get_parent().attack_direction * 20)

	$AttackTimer.start(0.5)
	$AttackShape.force_shapecast_update()

	connect(&"frame_changed", Callable(self, "ultimate_attack_register"))
	
func ultimate_attack_register():
	if frame != 1: return
	disconnect(&"frame_changed", Callable(self, "ultimate_attack_register"))
	var temp_damage: float = ultimate_damage
	var enemy_body = null
	var knockback_weight = 2.0
	if dash_attack:
		temp_damage *= 1.5
		knockback_weight = 3.0
		dash_attack = false

	if $AttackShape.is_colliding():
		for collision_index in $AttackShape.get_collision_count():
			enemy_body = $AttackShape.get_collider(collision_index).get_parent()
			if Damage.combat_damage(temp_damage,
					Damage.DamageTypes.ENEMY_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
					self, enemy_body.enemy_stats_node):
				enemy_body.dealt_knockback(get_parent().attack_direction, knockback_weight)
		Players.camera_node.screen_shake(0.3, 10, 30, 100, true)

func _on_attack_area_body_exited(body: Node2D) -> void:
	if get_parent() is PlayerBase:
		get_parent().enemy_nodes_in_attack_area.erase(body)
		if get_parent().enemy_nodes_in_attack_area.is_empty():
			get_parent().ally_in_attack_position = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if get_parent() is PlayerBase:
		get_parent().enemy_nodes_in_attack_area.push_back(body)
		get_parent().ally_in_attack_position = true
		get_parent().ally_can_move = true

func _on_attack_timer_timeout() -> void:
	if not get_parent() is PlayerBase: return
	get_parent().set_attack_state(get_parent().AttackState.READY)

func _on_ally_attack_cooldown_timeout() -> void:
	if not get_parent() is PlayerBase: return
	get_parent().set_attack_state(get_parent().AttackState.READY) # TODO: need to change CharacterBase and Attacks for Allies
