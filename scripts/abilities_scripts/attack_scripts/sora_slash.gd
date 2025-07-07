extends ShapeCast2D

func initialize() -> void:
	var player_base: PlayerBase = get_parent().get_parent()
	var action_area: Area2D = get_parent().get_node(^"ActionArea")

	# set action area
	action_area.get_node(^"CollisionShape2D").shape.radius = 20.0

	# update action target variables
	player_base.action_target_types = Entities.Type.ENEMIES
	player_base.action_target_stats = &"health"
	player_base.action_target_get_max = false

	# clear previous action targets to avoid edge cases
	player_base.action_target_candidates.clear()
	player_base.action_target = null

	# await collision shape update
	await Global.get_tree().physics_frame
	await Global.get_tree().physics_frame

	# update action targets
	player_base.action_target_candidates = \
			Entities.type_entities_array(action_area.get_overlapping_bodies().filter(
			func(node): return node.stats.entity_types & player_base.action_target_types))
	player_base.set_action_target()

	player_base.in_action_range = player_base.action_target_candidates.size()

	position = Vector2(0.0, -7.0)

func execute() -> void:
	var player_base: PlayerBase = get_parent().get_parent()

	# begin action
	player_base.action_state = player_base.ActionState.ACTION
	player_base.action_fail_count = 0

	# set action vector based on mouse position or action target
	if player_base.is_main_player:
		player_base.action_vector = (Inputs.get_global_mouse_position() - player_base.position).normalized()

	set_target_position(player_base.action_vector * 20)

	player_base.action_state = player_base.ActionState.ACTION

	force_shapecast_update()
	
	player_base.update_animation()

func resolve() -> void:
	var player_base: PlayerBase = get_parent().get_parent()
	var animation_node: AnimatedSprite2D = player_base.get_node(^"Animation")
	var dash_attack: bool = player_base.move_state == player_base.MoveState.DASH

	if not animation_node.animation in [&"up_attack", &"down_attack", &"left_attack", &"right_attack"]:
		player_base.action_state = player_base.ActionState.READY
		return

	var temp_damage: float = 10.0
	var enemy_body = null
	var knockback_weight = 1.0

	if dash_attack:
		temp_damage *= 1.5
		knockback_weight = 1.5
		dash_attack = false
	
	if is_colliding():
		await Players.camera.screen_shake(5, 1, 10, 10.0)
		for collision_index in get_collision_count():
			enemy_body = get_collider(collision_index).get_parent() # TODO: null instance bug need fix
			if Damage.combat_damage(temp_damage,
					Damage.DamageTypes.ENEMY_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
					player_base.stats, enemy_body.stats):
				enemy_body.knockback(player_base.action_vector, knockback_weight)

func finish() -> void:
	var player_base: PlayerBase = get_parent().get_parent()
	var animation_node: AnimatedSprite2D = player_base.get_node(^"Animation")

	if not animation_node.animation in [&"up_attack", &"down_attack", &"left_attack", &"right_attack"]:
		player_base.action_state = player_base.ActionState.READY
		return

	if player_base.is_main_player:
		player_base.action_state = player_base.ActionState.READY
	else:
		player_base.action_state = player_base.ActionState.COOLDOWN
		player_base.action_cooldown = randf_range(0.4, 0.8)
	
	player_base.update_animation()
