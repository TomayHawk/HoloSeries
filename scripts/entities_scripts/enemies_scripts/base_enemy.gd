extends Node2D

# enemy node
@onready var enemy_node := get_parent()
@onready var knockback_timer_node := $KnockbackTimer
@onready var invincibility_frame_node := $InvulnerabilityTimer

@onready var health_bar_node := $HealthBar

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

# called upon instantiating (creating) each enemy
func _ready():
	health_bar_node.max_value = max_health
	update_health(0, [], enemy_node.position, 0.0)

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

	# check death
	if health == 0: trigger_death()

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

func trigger_death():
	alive = false
	
	CombatEntitiesComponent.enemy_nodes_in_combat.erase(enemy_node)
	if CombatEntitiesComponent.locked_enemy_node == enemy_node: CombatEntitiesComponent.locked_enemy_node = null
	if CombatEntitiesComponent.enemy_nodes_in_combat.is_empty(): CombatEntitiesComponent.attempt_leave_combat()

	enemy_node.set_physics_process(false)
	enemy_node.animation_node.play("death")
	enemy_node.get_node("DeathTimer").start(0.3)
	enemy_node.velocity = enemy_node.knockback_direction * 200
	set_physics_process(true)

func _on_attack_cooldown_timeout():
	enemy_node.attack_ready = true

func _on_knockback_timer_timeout():
	enemy_node.animation_node.play("walk")
	enemy_node.taking_knockback = false
	enemy_node.knockback_weight = 0.0

func _on_invulnerability_timer_timeout():
	enemy_node.invincible = false

func _on_death_timer_timeout():
	CombatEntitiesComponent.enemy_nodes_in_combat.erase(self)
	if CombatEntitiesComponent.locked_enemy_node == self: CombatEntitiesComponent.locked_enemy_node = null
	if CombatEntitiesComponent.enemy_nodes_in_combat.is_empty(): CombatEntitiesComponent.attempt_leave_combat()
	queue_free()
