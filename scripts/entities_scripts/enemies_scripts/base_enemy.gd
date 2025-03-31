extends Node2D

# enemy node
@onready var enemy_node := get_parent()
@onready var health_bar_node := %HealthBar
@onready var knockback_timer_node := %KnockbackTimer
@onready var invincibility_frame_node := %InvulnerabilityTimer

# health variables
var alive := true
var max_health := 200.0
var health := 200.0
var health_bar_percentage := 1.0

var level := 1
var mana := 10.0
var stamina := 100.0

var defense := 10.0
var ward := 10.0
var strength := 10.0
var intelligence := 10.0
var speed := 0.0
var agility := 0.0
var crit_chance := 0.05
var crit_damage := 0.50

var players_exist_in_detection_area := false
var player_nodes_in_detection_area: Array[Node] = []
var players_exist_in_attack_area := false
var player_nodes_in_attack_area: Array[Node] = []

# called upon instantiating (creating) each enemy
func _ready():
	health_bar_node.max_value = max_health
	update_health(0.0)
	set_physics_process(false)

func _physics_process(_delta):
	enemy_node.move_and_slide()

# deal damage to enemy (called by enemy)
func update_health(value: float, knockback_direction: Vector2 = Vector2.ZERO, knockback_weight: float = 0.0) -> void:
	# invincibility check
	if enemy_node.invincible or health <= 0: return
	
	if value < 0:
		enemy_node.invincible = true
		invincibility_frame_node.start(0.05)

	# update health bar
	health = clamp(health + value, 0, max_health)
	health_bar_node.value = health
	health_bar_node.visible = health != max_health

	# determine health bar modulation based on percentage
	health_bar_percentage = health * 1.0 / max_health
	if health_bar_percentage > 0.5: health_bar_node.modulate = "a9ff30"
	elif health_bar_percentage > 0.2: health_bar_node.modulate = "c8a502"
	else: health_bar_node.modulate = "a93430"

	# knockback
	enemy_node.taking_knockback = true
	enemy_node.knockback_direction = knockback_direction
	enemy_node.knockback_weight = knockback_weight
	knockback_timer_node.start(0.4)

	# check death
	if health == 0: trigger_death()

func trigger_death():
	alive = false
	health_bar_node.visible = false
	
	Combat.remove_active_enemy(enemy_node)

	enemy_node.set_physics_process(false)
	enemy_node.animation_node.play("death")
	get_node(^"DeathTimer").start(0.3)
	enemy_node.velocity = enemy_node.knockback_direction * 200
	set_physics_process(true)

	_on_visible_on_screen_notifier_2d_screen_exited()

# left click handler
func _on_combat_hit_box_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Input.is_action_pressed(&"alt"):
				if not Combat.is_locked(enemy_node):
					Combat.unlock()
				Combat.lock(enemy_node)
			if Entities.requesting_entities and (enemy_node in Entities.entities_available) and not (enemy_node in Entities.entities_chosen):
				Entities.entities_chosen.push_back(enemy_node)
				if Entities.entities_requested_count == Entities.entities_chosen.size():
					Entities.choose_entities()

func _on_combat_hit_box_area_mouse_entered():
	if Entities.requesting_entities:
		Inputs.mouse_in_attack_position = false

func _on_combat_hit_box_area_mouse_exited():
	Inputs.mouse_in_attack_position = true

func _on_detection_area_body_entered(body):
	if alive and body.character_node.alive:
		Combat.add_active_enemy(enemy_node)
		players_exist_in_detection_area = true
		if not player_nodes_in_detection_area.has(body): player_nodes_in_detection_area.push_back(body)

func _on_detection_area_body_exited(body):
	_on_attack_area_body_exited(body)

	player_nodes_in_detection_area.erase(body)

	if player_nodes_in_detection_area.is_empty():
		Combat.remove_active_enemy(enemy_node)
		players_exist_in_detection_area = false

func _on_attack_area_body_entered(body):
	if alive and body.character_node.alive:
		players_exist_in_detection_area = true
		players_exist_in_attack_area = true
		if not player_nodes_in_detection_area.has(body): player_nodes_in_detection_area.push_back(body)
		if not player_nodes_in_attack_area.has(body): player_nodes_in_attack_area.push_back(body)

func _on_attack_area_body_exited(body):
	player_nodes_in_attack_area.erase(body)
	if player_nodes_in_attack_area.is_empty(): players_exist_in_attack_area = false

func _on_attack_cooldown_timeout():
	enemy_node.attack_ready = true

func _on_knockback_timer_timeout():
	enemy_node.animation_node.play("walk")
	enemy_node.taking_knockback = false
	enemy_node.knockback_weight = 0.0

func _on_invulnerability_timer_timeout():
	enemy_node.invincible = false

func _on_death_timer_timeout():
	enemy_node.trigger_true_death()
	enemy_node.queue_free()

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	enemy_node.add_to_group("on_screen")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	enemy_node.remove_from_group("on_screen")
