extends ShapeCast2D

func initialize() -> void:
	var action_area: Area2D = base.get_node(^"ActionArea")

	action_area.get_node(^"CollisionShape2D").shape.radius = 20.0

	# update action target variables
	base.action_target_types = Entities.Type.ENEMIES
	base.action_target_stats = &"health"
	base.action_target_get_max = false

	# clear previous action targets to avoid edge cases
	base.action_target_candidates.clear()
	base.action_target = null

	# await collision shape update
	await Global.get_tree().physics_frame
	await Global.get_tree().physics_frame

	# update action targets
	base.action_target_candidates = \
			Entities.type_entities_array(action_area.get_overlapping_bodies().filter(
			func(node): return node.stats.entity_types & base.action_target_types))
	base.set_action_target()

	base.in_action_range = base.action_target_candidates.size()

	position = Vector2(0.0, -7.0)

func execute() -> void:
	pass

func resolve() -> void:
	pass

func finish() -> void:
	pass

'''

var basic_damage: float = 10.0
var ultimate_damage: float = 100.0

# ATTACKS

func basic_attack(initialization: bool = false) -> void:
	# return if base doesn't exists
	if not base:
		return

	# initialization mode: initialize base action variables and return
	if initialization:
		

		return
	
	# begin action
	base.action_state = base.ActionState.ACTION
	base.action_fail_count = 0

	# set action vector based on mouse position or action target
	if base.is_main_player:
		base.action_vector = (Inputs.get_global_mouse_position() - base.position).normalized()

	var attack_shape: ShapeCast2D = base.get_node(^"AttackShape")
	var animation_node: AnimatedSprite2D = base.get_node(^"Animation")
	var dash_attack: bool = base.move_state == base.MoveState.DASH

	attack_shape.set_target_position(base.action_vector * 20)

	base.action_state = base.ActionState.ACTION

	attack_shape.force_shapecast_update()
	
	base.update_animation()

	await animation_node.frame_changed
	if not animation_node.animation in [&"up_attack", &"down_attack", &"left_attack", &"right_attack"]:
		base.action_state = base.ActionState.READY
		return

	var temp_damage: float = basic_damage
	var enemy_body = null
	var knockback_weight = 1.0

	if dash_attack:
		temp_damage *= 1.5
		knockback_weight = 1.5
		dash_attack = false
	
	if attack_shape.is_colliding():
		await Players.camera.screen_shake(5, 1, 10, 10.0)
		for collision_index in attack_shape.get_collision_count():
			enemy_body = attack_shape.get_collider(collision_index).get_parent() # TODO: null instance bug need fix
			if Damage.combat_damage(temp_damage,
					Damage.DamageTypes.ENEMY_HIT | Damage.DamageTypes.COMBAT | Damage.DamageTypes.PHYSICAL,
					self, enemy_body.stats):
				enemy_body.knockback(base.action_vector, knockback_weight)
	
	await animation_node.animation_finished
	if not animation_node.animation in [&"up_attack", &"down_attack", &"left_attack", &"right_attack"]:
		base.action_state = base.ActionState.READY
		return

	if base.is_main_player:
		base.action_state = base.ActionState.READY
	else:
		base.action_state = base.ActionState.COOLDOWN
		base.action_cooldown = randf_range(0.4, 0.8)
	
	base.update_animation()
'''
