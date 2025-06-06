class_name BasicEnemyBase extends EnemyBase

var walk_speed := 45.0
var knockback: Vector2 = Vector2.ZERO

var enemy_in_combat: bool = false
var players_in_detection_area: Array[Node] = []
var players_in_attack_area: Array[Node] = []

@onready var enemy_stats_node: BasicEnemyStats = $BasicEnemyStats
@onready var knockback_timer_node: Timer = $KnockbackTimer

# ................................................................................

# MOVE STATE

# ................................................................................

# KNOCKBACK & DEATH

func dealt_knockback(direction: Vector2, weight: float = 1.0) -> void:
	if move_state == MoveState.KNOCKBACK: return
	if direction == Vector2.ZERO or weight == 0.0: return
	move_state = MoveState.KNOCKBACK

	knockback = direction * (200.0 if not enemy_stats_node.alive else weight * 160.0) # TODO: should use weight stat
	if enemy_stats_node.alive: enemy_stats_node.speed_scale = 0.3 # TODO
	velocity = knockback

	enemy_stats_node.play(&"death") # TODO
	$KnockbackTimer.start(0.4)
	await $KnockbackTimer.timeout

	move_state = MoveState.IDLE
	enemy_stats_node.speed_scale = 1.0 # TODO
	enemy_stats_node.play(&"idle")

func trigger_death() -> void:
	enemy_in_combat = false
	players_in_detection_area.clear()
	players_in_attack_area.clear()
	enemy_stats_node.entity_types &= ~Entities.Type.ENEMIES_ON_SCREEN
	remove_from_group(&"enemies_on_screen")
	Combat.remove_active_enemy(self)

	get_node(^"DeathTimer").start()
	await $DeathTimer.timeout
	
	for i in 3:
		var item: Node = load("res://entities/entities_items/lootable.tscn").instantiate()
		item.instantiate_item(global_position, "res://art/temp_shirakami.png", 0, 0)
	
	queue_free()

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
		Inputs.mouse_in_attack_range = false

func _on_combat_hit_box_mouse_exited() -> void:
	Inputs.mouse_in_attack_range = true

# ................................................................................

# DETECTION AREA

func _on_detection_area_body_entered(body: Node2D) -> void:
	if not enemy_stats_node.alive or not body.character.alive: return
	Combat.add_active_enemy(self)
	enemy_stats_node.entity_types |= Entities.Type.ENEMIES_IN_COMBAT
	enemy_in_combat = true
	if not players_in_detection_area.has(body):
		players_in_detection_area.push_back(body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	players_in_attack_area.erase(body)
	players_in_detection_area.erase(body)
	if players_in_attack_area.is_empty() and attack_state != AttackState.ATTACK:
		attack_state = AttackState.OUT_OF_RANGE
	if players_in_detection_area.is_empty():
		Combat.remove_active_enemy(self)
		enemy_stats_node.entity_types &= ~Entities.Type.ENEMIES_IN_COMBAT
		enemy_in_combat = false

# ................................................................................

# ATTACK AREA

func _on_attack_area_body_entered(body: Node2D) -> void:
	if not enemy_stats_node.alive or not body.character.alive: return
	enemy_in_combat = true
	if attack_state == AttackState.OUT_OF_RANGE:
		attack_state = AttackState.READY
	if not players_in_detection_area.has(body):
		players_in_detection_area.push_back(body)
	if not players_in_attack_area.has(body):
		players_in_attack_area.push_back(body)

func _on_attack_area_body_exited(body: Node2D) -> void:
	players_in_attack_area.erase(body)
	if players_in_attack_area.is_empty():
		attack_state = AttackState.OUT_OF_RANGE

# ................................................................................

# ON SCREEN STATUS

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	enemy_stats_node.entity_types |= Entities.Type.ENEMIES_ON_SCREEN
	add_to_group(&"enemies_on_screen")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	enemy_stats_node.entity_types &= ~Entities.Type.ENEMIES_ON_SCREEN
	remove_from_group(&"enemies_on_screen")
