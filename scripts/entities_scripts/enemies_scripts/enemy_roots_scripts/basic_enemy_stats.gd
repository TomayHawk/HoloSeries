class_name BasicEnemyStats extends EnemyStats

var entity_types: int = 0

var enemy_in_combat: bool = false
var players_in_detection_area: Array[Node] = []
var players_in_attack_area: Array[Node] = []

@onready var enemy_node: BasicEnemyBase = get_parent()

# ................................................................................

func _ready() -> void:
	update_health(0.0)

# ................................................................................

# HEALTH AND DEATH

func update_health(value: float) -> void:
	if not alive or (value < 0 and has_status(Entities.Status.INVINCIBLE)):
		return
	
	# update health
	health = clamp(health + value, 0.0, max_health)

	# update and modulate health bar
	$HealthBar.visible = health > 0.0 and health < max_health
	$HealthBar.max_value = max_health
	$HealthBar.value = health
	
	var health_bar_percentage = health / max_health
	$HealthBar.modulate = \
			"a9ff30" if health_bar_percentage > 0.5 \
			else "c8a502" if health_bar_percentage > 0.2 \
			else "a93430"

	# add invincibility if damage dealt
	if value < 0.0:
		add_status(Entities.Status.INVINCIBLE)

	# handle death
	if health == 0.0:
		trigger_death()

func trigger_death() -> void:
	alive = false
	enemy_in_combat = false
	players_in_detection_area.clear()
	players_in_attack_area.clear()
	play("death")
	enemy_node.trigger_death()
	_on_visible_on_screen_notifier_2d_screen_exited()
	$DeathTimer.start()

# ................................................................................

# DETECTION AREA

func _on_detection_area_body_entered(body: Node) -> void:
	if not alive or not body.character_node.alive: return
	Combat.add_active_enemy(enemy_node)
	enemy_in_combat = true
	if not players_in_detection_area.has(body):
		players_in_detection_area.push_back(body)

func _on_detection_area_body_exited(body: Node) -> void:
	players_in_attack_area.erase(body)
	players_in_detection_area.erase(body)
	if players_in_attack_area.is_empty() and enemy_node.attack_state != enemy_node.AttackState.ATTACK:
		enemy_node.attack_state = enemy_node.AttackState.OUT_OF_RANGE
	if players_in_detection_area.is_empty():
		Combat.remove_active_enemy(enemy_node)
		enemy_in_combat = false

# ................................................................................

# ATTACK AREA

func _on_attack_area_body_entered(body: Node) -> void:
	if not alive or not body.character_node.alive: return
	enemy_in_combat = true
	if enemy_node.attack_state == enemy_node.AttackState.OUT_OF_RANGE:
		enemy_node.attack_state = enemy_node.AttackState.READY
	if not players_in_detection_area.has(body):
		players_in_detection_area.push_back(body)
	if not players_in_attack_area.has(body):
		players_in_attack_area.push_back(body)

func _on_attack_area_body_exited(body: Node) -> void:
	players_in_attack_area.erase(body)
	if players_in_attack_area.is_empty():
		enemy_node.attack_state = enemy_node.AttackState.OUT_OF_RANGE

# ................................................................................

# ON SCREEN STATUS

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	entity_types |= Entities.Type.ENEMIES_ON_SCREEN
	enemy_node.add_to_group("enemies_on_screen")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	entity_types &= ~Entities.Type.ENEMIES_ON_SCREEN
	enemy_node.remove_from_group("enemies_on_screen")

# ................................................................................

# TIMERS

func _on_attack_cooldown_timeout() -> void:
	if enemy_node.attack_state != enemy_node.AttackState.OUT_OF_RANGE and not players_in_detection_area.is_empty():
		enemy_node.attack_state = enemy_node.AttackState.READY

func _on_knockback_timer_timeout() -> void:
	enemy_node.move_state = enemy_node.MoveState.IDLE
	play("idle")

func _on_death_timer_timeout() -> void:
	var item: Node
	for i in 3:
		item = load("res://entities/entities_items/lootable_item.tscn").instantiate()
		Combat.lootable_items_node.add_child(item)
		item.instantiate_item("res://art/temp_shirakami.png", Vector2(4.0, 4.0), 0, 1000, true)
		item.global_position = global_position + Vector2(5 * randf_range(-1, 1), 5 * randf_range(-1, 1)) * 5
	
	enemy_node.queue_free()
