class_name BasicEnemyBase extends EnemyBase

var walk_speed := 45.0
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_weight: float = 1.0
var knockback_multiplier: float = 120

@onready var enemy_stats_node: BasicEnemyStats = $BasicEnemy
@onready var knockback_timer_node: Timer = $BasicEnemy/KnockbackTimer

# ................................................................................

# STATES

func set_move_state(next_state: MoveState) -> void:
	if move_state == next_state or not enemy_stats_node.alive: return
	move_state = next_state
	update_animation()

func set_move_direction(direction: Directions) -> void:
	if move_direction == direction or not enemy_stats_node.alive: return
	move_direction = direction
	update_animation()

func update_velocity(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		set_move_state(MoveState.IDLE)
		velocity = Vector2.ZERO
		return
	
	if VECTOR_TO_DIRECTION.has(direction):
		set_move_direction(VECTOR_TO_DIRECTION[direction])
	
	var temp_velocity: Vector2 = direction * walk_speed

	match move_state:
		MoveState.IDLE:
			set_move_state(MoveState.WALK)
	
	velocity = temp_velocity

func update_animation() -> void:
	pass

#func set_move_state(next_state: MoveState) -> void:
#    if move_state == next_state or not character_node.alive: return
#    move_state = next_state
#    update_animation()

func dealt_knockback(direction: Vector2, weight: float = 1.0) -> void:
	if move_state == MoveState.KNOCKBACK: return
	if direction == Vector2.ZERO or weight == 0.0: return
	set_move_state(MoveState.KNOCKBACK)
	
	knockback_direction = direction
	knockback_weight = weight

	enemy_stats_node.play("death")
	$BasicEnemy/KnockbackTimer.start(0.4)

# TODO: knockback_direction: Vector2 = Vector2.ZERO, knockback_weight: float = 0.0
# knockback
# 
# $KnockbackTimer.start(0.4)
# enemy_node.velocity = enemy_node.knockback_direction * 200 DEATH

func trigger_death() -> void:
	Combat.remove_active_enemy(self)
	set_physics_process(false)

# ................................................................................

# ATTACK

#func set_attack_state(next_state: AttackState) -> void:
#    if attack_state == next_state or not character_node.alive: return
#    # ally conditions
#    if not is_main_player:
#        #if not ally_can_attack:
#            #return
#        if attack_state != AttackState.READY and next_state == AttackState.ATTACK:
#            return
#
#    attack_state = next_state
#
#    if attack_state == AttackState.ATTACK: attempt_attack()
#
#    update_animation()
#
#func attempt_attack(attack_name: String = "") -> void:
#    if character_node != get_node_or_null("CharacterBase"):
#        set_attack_state(AttackState.READY) # TODO: depends
#        return
#    
#    if attack_name != "":
#        pass # call attack with conditions
#    elif character_node.auto_ultimate and character_node.ultimate_gauge == character_node.max_ultimate_gauge:
#        character_node.ultimate_attack()
#    else:
#        character_node.basic_attack()

# TODO: need to implement
#func filter_nodes(initial_nodes: Array[EntityBase], get_stats_nodes: bool, origin_position: Vector2 = Vector2(-1.0, -1.0), range_min: float = -1.0, range_max: float = -1.0) -> Array[Node]:
#    var resultant_nodes: Array[Node] = []
#    var check_distance: bool = range_max > 0
#    
#    if check_distance:
#        range_min *= range_min
#        range_max *= range_max
#    
#    for entity_node in initial_nodes:
#        if check_distance:
#            var temp_distance: float = origin_position.distance_squared_to(entity_node.position)
#            if temp_distance < range_min or temp_distance > range_max:
#                continue
#        if entity_node is PlayerBase:
#            resultant_nodes.push_back(entity_node.character_node if get_stats_nodes else entity_node)
#        elif entity_node is BasicEnemyBase:
#            resultant_nodes.push_back(entity_node.enemy_stats_node if get_stats_nodes else entity_node)
#    
#    return resultant_nodes

# TODO: IMPLEMENTING RIGHT NOW
#func enter_attack_range() -> void:
#    if attack_state == AttackState.OUT_OF_RANGE:
#        attack_state = AttackState.READY
#    # TODO: COOLDOWN ?

# TODO: IMPLEMENTING RIGHT NOW
#func exit_attack_range() -> void:
#    if attack_state == AttackState.READY:
#        attack_state = AttackState.OUT_OF_RANGE

# ................................................................................

# COMBAT HIT BOX

# left click handler
func _on_combat_hit_box_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if Input.is_action_just_pressed(&"action"):
		if Input.is_action_pressed(&"alt"):
			Combat.lock(self)
		if Entities.requesting_entities:
			Entities.choose_entity(self)

func _on_combat_hit_box_mouse_entered() -> void:
	if Entities.requesting_entities:
		Inputs.mouse_in_attack_position = false

func _on_combat_hit_box_mouse_exited() -> void:
	Inputs.mouse_in_attack_position = true
