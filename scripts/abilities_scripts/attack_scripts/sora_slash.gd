extends ShapeCast2D

# ..............................................................................

#region VARIABLES

var player_base: PlayerBase = null
var animation_node: AnimatedSprite2D = null

#endregion

# ..............................................................................

#region FUNCTIONS

func action_setup() -> void:
	position = Vector2(0.0, -7.0)
	player_base = get_parent()
	animation_node = player_base.get_node("Animation")
	player_base.set_action(20.0, Entities.Type.ENEMIES, &"health", false)

func action_start() -> void:
	# begin action
	player_base.action_state = player_base.ActionState.ACTION

	# set action vector based on mouse position or action target
	if player_base.is_main_player:
		player_base.action_vector = (Inputs.get_global_mouse_position() - player_base.position).normalized()

	set_target_position(player_base.action_vector * 20)

	player_base.action_state = player_base.ActionState.ACTION

	force_shapecast_update()
	
	player_base.update_animation()

func action_trigger() -> void:
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

func action_cleanup() -> void:
	if not animation_node.animation in [&"up_attack", &"down_attack", &"left_attack", &"right_attack"]:
		player_base.action_state = player_base.ActionState.READY
		return

	if player_base.is_main_player:
		player_base.action_state = player_base.ActionState.READY
	else:
		player_base.action_state = player_base.ActionState.COOLDOWN
		player_base.action_cooldown = randf_range(0.4, 0.8)
	
	player_base.update_animation()

#endregion

# ..............................................................................
