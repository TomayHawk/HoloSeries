class_name BasicEnemyBase extends EnemyBase

var walk_speed: float = 45.0

var enemy_in_combat: bool = false
var players_in_detection_area: Array[Node] = []
var players_in_attack_area: Array[Node] = []

var in_action_range: bool = false # TODO: temporary variable

# ..............................................................................

# MOVE STATE

# ..............................................................................

# KNOCKBACK & DEATH

func knockback(direction: Vector2, weight: float = 1.0) -> void:
	if move_state in [MoveState.KNOCKBACK, MoveState.STUN]: return

	move_state = MoveState.KNOCKBACK

	knockback_velocity = direction * (200.0 if not stats.alive else weight * 160.0) # TODO: should use weight stat
	if stats.alive: $Animation.speed_scale = 0.3 # TODO
	velocity = knockback_velocity

	$Animation.play(&"death") # TODO
	move_state_timer = 0.4
	await move_state_timeout

	move_state = MoveState.IDLE
	$Animation.speed_scale = 1.0 # TODO
	$Animation.play(&"idle")

func death() -> void:
	$Animation.play(&"death")

	enemy_in_combat = false
	players_in_detection_area.clear()
	players_in_attack_area.clear()
	stats.entity_types &= ~Entities.Type.ENEMIES_ON_SCREEN
	remove_from_group(&"enemies_on_screen")
	Combat.remove_active_enemy(self)

	# death timer
	var death_timer: Timer = Timer.new()
	add_child(death_timer)
	death_timer.wait_time = 0.4
	death_timer.start()

	await death_timer.timeout
	
	for i in 3:
		var item: Node = load("res://entities/entities_items/lootable.tscn").instantiate()
		item.instantiate_item(global_position, "res://art/temp_shirakami.png", 0, 0)
	
	queue_free()

# ..............................................................................

# SIGNALS

# COMBAT HIT BOX

func _on_combat_hit_box_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if Input.is_action_just_pressed(&"action") and event.is_action_pressed(&"action"):
		if Input.is_action_pressed(&"alt"):
			Combat.lock(self)
		elif self in Entities.entities_available:
			Entities.choose_entity(self)

# DETECTION AREA

func _on_detection_area_body_entered(body: Node2D) -> void:
	if not stats.alive or not body.stats.alive: return
	Combat.add_active_enemy(self)
	stats.entity_types |= Entities.Type.ENEMIES_IN_COMBAT
	enemy_in_combat = true
	if not players_in_detection_area.has(body):
		players_in_detection_area.append(body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	players_in_attack_area.erase(body)
	players_in_detection_area.erase(body)
	if players_in_attack_area.is_empty() and action_state != ActionState.ACTION:
		in_action_range = false
	if players_in_detection_area.is_empty():
		Combat.remove_active_enemy(self)
		stats.entity_types &= ~Entities.Type.ENEMIES_IN_COMBAT
		enemy_in_combat = false

# ATTACK AREA

func _on_attack_area_body_entered(body: Node2D) -> void:
	if not stats.alive or not body.stats.alive: return
	enemy_in_combat = true
	if in_action_range:
		action_state = ActionState.READY
	if not players_in_detection_area.has(body):
		players_in_detection_area.append(body)
	if not players_in_attack_area.has(body):
		players_in_attack_area.append(body)

func _on_attack_area_body_exited(body: Node2D) -> void:
	players_in_attack_area.erase(body)
	if players_in_attack_area.is_empty():
		in_action_range = false

# ON SCREEN STATUS

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	stats.entity_types |= Entities.Type.ENEMIES_ON_SCREEN
	add_to_group(&"enemies_on_screen")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	stats.entity_types &= ~Entities.Type.ENEMIES_ON_SCREEN
	remove_from_group(&"enemies_on_screen")
