class_name CharacterBase extends AnimatedSprite2D

signal attack_frame()

var stats: PlayerStats = null

var max_ally_distance: float = 250.0
var basic_damage: float = 10.0
var ultimate_damage: float = 100.0

func _ready() -> void:
	set_physics_process(false)

# PlayerAlly physics process
func _physics_process(_delta: float) -> void:
	var base: PlayerBase = get_parent()
	var ally_distance: float = base.position.distance_to(Players.main_player_node.position)

	# attempt to perform action
	var action_success: bool = false
	if base.action_state == base.ActionState.READY and not base.action_queue.is_empty():
		action_success = base.action_queue[0][0].callv(base.action_queue[0][1])
	
	if action_success:
		base.action_queue.remove_at(0)
	# if ally in attack range
	elif base.in_attack_range and ally_distance < max_ally_distance:
		# pause movement
		base.update_velocity(Vector2.ZERO)

		# target enemy with lowest health # TODO: this should be dynamic
		var target_enemy_node: EnemyBase = null
		var lowest_health: float = INF
		for enemy_node in base.get_node(^"AttackRange").get_overlapping_bodies():
			if enemy_node.stats.health < lowest_health:
				lowest_health = enemy_node.stats.health
				target_enemy_node = enemy_node
		
		# attack if able
		if base.action_state == base.ActionState.READY:
			base.set_action_state(base.ActionState.ACTION)
			action()
		# else face towards enemy
		else:
			var enemy_direction = (target_enemy_node.position - base.position).normalized()
			if abs(enemy_direction.x) < abs(enemy_direction.y):
				if enemy_direction.y < 0:
					base.set_move_direction(base.Directions.UP)
				else:
					base.set_move_direction(base.Directions.DOWN)
			elif enemy_direction.x < 0:
				base.set_move_direction(base.Directions.LEFT)
			else:
				base.set_move_direction(base.Directions.RIGHT)
	# if ally can move
	elif base.can_move and base.attack_state != base.AttackState.ATTACK:
		var target_direction := Vector2.ZERO
		base.can_move = false

		if Combat.in_combat() and ally_distance < max_ally_distance:
			# TODO: move this somewhere else
			# target enemy with shortest distance
			var target_enemy_node: Node = null
			var enemy_distance := INF
			for enemy_node in Combat.enemy_nodes_in_combat.duplicate():
				if base.position.distance_to(enemy_node.position) < enemy_distance:
					enemy_distance = base.position.distance_to(enemy_node.position)
					target_enemy_node = enemy_node
			
			if enemy_distance > 200:
				base.get_node(^"NavigationAgent2D").target_position = Players.main_player_node.position
			else:
				base.get_node(^"NavigationAgent2D").target_position = target_enemy_node.position

			target_direction = to_local(base.get_node(^"NavigationAgent2D").get_next_path_position()).normalized()
			base.get_node(^"AllyMoveCooldown").start(randf_range(0.2, 0.4))
		elif ally_distance < 80:
			target_direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
			base.get_node(^"AllyMoveCooldown").start(randf_range(0.5, 0.7))
			pass # TODO: velocity /= 1.5
		else:
			base.get_node(^"NavigationAgent2D").target_position = Players.main_player_node.position
			target_direction = to_local(base.get_node(^"NavigationAgent2D").get_next_path_position()).normalized()
			base.get_node(^"AllyMoveCooldown").start(randf_range(0.5, 0.7))

		if ally_distance > 200:
			pass # TODO: velocity *= (ally_distance / 200)
			if ally_distance > 300:
				pass # TODO: velocity *= 2
		
		if Players.main_player_node.move_state == base.MoveState.SPRINT and Combat.not_in_combat() and ally_distance > 120:
			base.set_move_state(base.MoveState.SPRINT)
		
		# snaps a given vector to the nearest cardinal or intercardinal vector
		var snapped_angle = round(target_direction.angle() / (PI / 4)) * (PI / 4)
		target_direction = Vector2(cos(snapped_angle), sin(snapped_angle)).normalized()

		# check for obstacles
		while true:
			base.get_node(^"ObstacleCheck").set_target_position(target_direction * 8)
			base.get_node(^"ObstacleCheck").force_shapecast_update()

			const VECTOR_TO_DIRECTION: Dictionary[Vector2, Directions] = {
				Vector2(0.0, -1.0): Directions.UP,
				Vector2(0.0, 1.0): Directions.DOWN,
				Vector2(-1.0, 0.0): Directions.LEFT,
				Vector2(1.0, 0.0): Directions.RIGHT,
				Vector2(-0.70710678, -0.70710678): Directions.UP_LEFT,
				Vector2(0.70710678, -0.70710678): Directions.UP_RIGHT,
				Vector2(-0.70710678, 0.70710678): Directions.DOWN_LEFT,
				Vector2(0.70710678, 0.70710678): Directions.DOWN_RIGHT,
			}

			if base.get_node(^"ObstacleCheck").is_colliding():
				possible_directions.erase(snap_vector)
				if possible_directions.is_empty():
					base.update_velocity(Vector2.ZERO)
					base.set_move_direction(VECTOR_TO_DIRECTION[snap_vector])
					base.update_velocity(snap_vector)
					break
				# find next closest direction
				var distance_to_direction := INF
				for direction in possible_directions:
					if target_direction.distance_to(direction) < distance_to_direction:
						distance_to_direction = target_direction.distance_to(direction)
						snap_vector = direction
			else:
				base.set_move_state(base.MoveState.WALK)
				base.set_move_direction(VECTOR_TO_DIRECTION[snap_vector])
				base.update_velocity(snap_vector)
				break
	else:
		# TODO: need to fix this
		var possible_directions: Array[Vector2] = [Vector2(-0.70710678, -0.70710678), Vector2(0.70710678, -0.70710678), Vector2(-0.70710678, 0.70710678), Vector2(0.70710678, 0.70710678)]
		for direction in possible_directions:
			if base.velocity.normalized().distance_to(direction) < 0.390180645:
				base.update_velocity(direction)
				break

	move_and_slide()

'''
	var possible_directions: Array[Vector2] = [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0), Vector2(-0.70710678, -0.70710678), Vector2(0.70710678, -0.70710678), Vector2(-0.70710678, 0.70710678), Vector2(0.70710678, 0.70710678)]
	var snap_vector: Vector2 = base.snap_vector(target_direction)

	# check for obstacles
	while true:
		base.get_node(^"ObstacleCheck").set_target_position(snap_vector * 8)
		base.get_node(^"ObstacleCheck").force_shapecast_update()

		const VECTOR_TO_DIRECTION: Dictionary[Vector2, Directions] = {
			Vector2(0.0, -1.0): Directions.UP,
			Vector2(0.0, 1.0): Directions.DOWN,
			Vector2(-1.0, 0.0): Directions.LEFT,
			Vector2(1.0, 0.0): Directions.RIGHT,
			Vector2(-0.70710678, -0.70710678): Directions.UP_LEFT,
			Vector2(0.70710678, -0.70710678): Directions.UP_RIGHT,
			Vector2(-0.70710678, 0.70710678): Directions.DOWN_LEFT,
			Vector2(0.70710678, 0.70710678): Directions.DOWN_RIGHT,
		}

		if base.get_node(^"ObstacleCheck").is_colliding():
			possible_directions.erase(snap_vector)
			if possible_directions.is_empty():
				base.update_velocity(Vector2.ZERO)
				base.set_move_direction(VECTOR_TO_DIRECTION[snap_vector])
				base.update_velocity(snap_vector)
				break
			# find next closest direction
			var distance_to_direction := INF
			for direction in possible_directions:
				if target_direction.distance_to(direction) < distance_to_direction:
					distance_to_direction = target_direction.distance_to(direction)
					snap_vector = direction
		else:
			base.set_move_state(base.MoveState.WALK)
			base.set_move_direction(VECTOR_TO_DIRECTION[snap_vector])
			base.update_velocity(snap_vector)
			break
else:
	# TODO: need to fix this
	var possible_directions: Array[Vector2] = [Vector2(-0.70710678, -0.70710678), Vector2(0.70710678, -0.70710678), Vector2(-0.70710678, 0.70710678), Vector2(0.70710678, 0.70710678)]
	for direction in possible_directions:
		if base.velocity.normalized().distance_to(direction) < 0.390180645:
			base.update_velocity(direction)
			break
'''

func update_nodes():
	super ()
	if get_parent() is PlayerBase:
		Combat.ui.name_labels[node_index].text = CHARACTER_NAME
	else:
		Combat.ui.standby_name_labels[node_index].text = CHARACTER_NAME

func basic_attack():
	if ultimate_gauge == max_ultimate_gauge:
		ultimate_attack()
		return

	if get_parent().is_main_player: get_parent().attack_vector = (get_global_mouse_position() - get_parent().position).normalized()
	else:
		var temp_enemy_health = INF
		for enemy_node in get_parent().enemy_nodes_in_attack_area:
			if enemy_node.enemy_stats_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.enemy_stats_node.health
				get_parent().attack_vector = (enemy_node.position - get_parent().position).normalized()
		get_parent().can_attack = false
		$AllyAttackCooldown.start(randf_range(2, 3))

	if get_parent().move_state == get_parent().MoveState.DASH:
		dash_attack = true
	
	$AttackShape.set_target_position(get_parent().attack_vector * 20)

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
				enemy_body.dealt_knockback(get_parent().attack_vector, knockback_weight)
		Players.camera_node.screen_shake(0.1, 1, 30, 5, true)

func ultimate_attack():
	update_ultimate_gauge(-100)

	if get_parent().is_main_player: get_parent().attack_vector = (get_global_mouse_position() - get_parent().position).normalized()
	else:
		var temp_enemy_health = INF
		for enemy_node in get_parent().enemy_nodes_in_attack_area:
			if enemy_node.enemy_stats_node.health < temp_enemy_health:
				temp_enemy_health = enemy_node.enemy_stats_node.health
				get_parent().attack_vector = (enemy_node.position - get_parent().position).normalized()
		get_parent().can_attack = false
		$AllyAttackCooldown.start(randf_range(2, 3))
	
	if get_parent().move_state == get_parent().MoveState.DASH:
		dash_attack = true
	
	$AttackShape.set_target_position(get_parent().attack_vector * 20)

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
				enemy_body.dealt_knockback(get_parent().attack_vector, knockback_weight)
		Players.camera_node.screen_shake(0.3, 10, 30, 100, true)

func _on_attack_area_body_exited(body: Node2D) -> void:
	if get_parent() is PlayerBase:
		get_parent().enemy_nodes_in_attack_area.erase(body)
		if get_parent().enemy_nodes_in_attack_area.is_empty():
			get_parent().in_attack_range = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if get_parent() is PlayerBase:
		get_parent().enemy_nodes_in_attack_area.push_back(body)
		get_parent().in_attack_range = true
		get_parent().can_move = true

func _on_attack_timer_timeout() -> void:
	if not get_parent() is PlayerBase: return
	get_parent().set_attack_state(get_parent().AttackState.READY)

func _on_ally_attack_cooldown_timeout() -> void:
	if not get_parent() is PlayerBase: return
	get_parent().set_attack_state(get_parent().AttackState.READY) # TODO: need to change CharacterBase and Attacks for Allies
