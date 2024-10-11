extends Node2D

# enemy node
@onready var enemy_node := get_parent()
@onready var health_bar_node := %HealthBar
@onready var knockback_timer_node := %KnockbackTimer
@onready var invincibility_frame_node := %InvulnerabilityTimer
@onready var enemy_marker_path := "res://resources/entity_highlights/enemy_marker.tscn"

# health variables
var alive := true
var max_health := 200.0
var health := 200.0
var health_bar_percentage := 1.0

var level := 1
var mana := 10.0
var stamina := 100.0

var defence := 10.0
var shield := 10.0
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
	update_health(0, [], Vector2.ZERO, 0.0)
	set_physics_process(false)

func _physics_process(_delta):
	enemy_node.move_and_slide()

# deal damage to enemy (called by enemy)
func update_health(amount, types, knockback_direction, knockback_weight):
	# invincibility check
	if enemy_node.invincible || health <= 0:
		amount = 0
	elif amount < 0:
		enemy_node.invincible = true
		invincibility_frame_node.start(0.05)

	# update health bar
	health += amount
	health = clamp(health, 0, max_health)
	health_bar_node.value = health
	health_bar_node.visible = health != max_health

	if amount < 0:
		CombatEntitiesComponent.damage_display(floor(amount), enemy_node.position, types)

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
	
	CombatEntitiesComponent.enemy_nodes_in_combat.erase(enemy_node)
	if CombatEntitiesComponent.locked_enemy_node == enemy_node: CombatEntitiesComponent.locked_enemy_node = null
	if CombatEntitiesComponent.enemy_nodes_in_combat.is_empty(): CombatEntitiesComponent.attempt_leave_combat()

	enemy_node.set_physics_process(false)
	enemy_node.animation_node.play("death")
	get_node("DeathTimer").start(0.3)
	enemy_node.velocity = enemy_node.knockback_direction * 200
	set_physics_process(true)

# left click handler
func _on_combat_hit_box_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Input.is_action_pressed("alt"):
				if CombatEntitiesComponent.locked_enemy_node != null:
					CombatEntitiesComponent.locked_enemy_node.remove_child(CombatEntitiesComponent.locked_enemy_node.get_node("EnemyMarker"))
					CombatEntitiesComponent.locked_enemy_node = null
				CombatEntitiesComponent.locked_enemy_node = enemy_node
				add_child(load(enemy_marker_path).instantiate())
			if CombatEntitiesComponent.requesting_entities && (enemy_node in CombatEntitiesComponent.entities_available) && !(enemy_node in CombatEntitiesComponent.entities_chosen):
				CombatEntitiesComponent.entities_chosen.push_back(enemy_node)
				CombatEntitiesComponent.entities_chosen_count += 1
				if CombatEntitiesComponent.entities_request_count == CombatEntitiesComponent.entities_chosen_count:
					CombatEntitiesComponent.choose_entities()

func _on_combat_hit_box_area_mouse_entered():
	if CombatEntitiesComponent.requesting_entities:
		GlobalSettings.mouse_in_attack_area = false

func _on_combat_hit_box_area_mouse_exited():
	GlobalSettings.mouse_in_attack_area = true

func _on_detection_area_body_entered(body):
	if alive == true && body.player_stats_node.alive:
		CombatEntitiesComponent.enter_combat()
		players_exist_in_detection_area = true
		if !CombatEntitiesComponent.enemy_nodes_in_combat.has(enemy_node): CombatEntitiesComponent.enemy_nodes_in_combat.push_back(enemy_node)
		if !player_nodes_in_detection_area.has(body): player_nodes_in_detection_area.push_back(body)

func _on_detection_area_body_exited(body):
	_on_attack_area_body_exited(body)

	player_nodes_in_detection_area.erase(body)

	if player_nodes_in_detection_area.is_empty():
		if CombatEntitiesComponent.locked_enemy_node == enemy_node: CombatEntitiesComponent.locked_enemy_node = null
		CombatEntitiesComponent.enemy_nodes_in_combat.erase(enemy_node)
		players_exist_in_detection_area = false

	if CombatEntitiesComponent.enemy_nodes_in_combat.is_empty():
		CombatEntitiesComponent.attempt_leave_combat()

func _on_attack_area_body_entered(body):
	if alive == true && body.player_stats_node.alive:
		CombatEntitiesComponent.enter_combat()
		players_exist_in_detection_area = true
		players_exist_in_attack_area = true
		if !CombatEntitiesComponent.enemy_nodes_in_combat.has(enemy_node): CombatEntitiesComponent.enemy_nodes_in_combat.push_back(enemy_node)
		if !player_nodes_in_detection_area.has(body): player_nodes_in_detection_area.push_back(body)
		if !player_nodes_in_attack_area.has(body): player_nodes_in_attack_area.push_back(body)

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
	CombatEntitiesComponent.enemy_nodes_in_combat.erase(enemy_node)
	if CombatEntitiesComponent.locked_enemy_node == enemy_node: CombatEntitiesComponent.locked_enemy_node = null
	if CombatEntitiesComponent.enemy_nodes_in_combat.is_empty():
		CombatEntitiesComponent.attempt_leave_combat()
	enemy_node.trigger_true_death()
	enemy_node.queue_free()
