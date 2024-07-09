extends Node

# enemy node
@onready var enemy_node = get_parent()
@onready var knockback_timer_node = enemy_node.get_node("KnockbackTimer")
@onready var invincibility_frame_node = enemy_node.get_node("InvincibilityFrame")

@onready var health_bar_node = enemy_node.get_node("HealthBar")

# health variables
var alive = true
var max_health = 100
var health = 100
var health_bar_percentage = 1.0

# called upon instantiating (creating) each enemy
func _ready():
	health_bar_node.max_value = max_health
	update_health(enemy_node.position, 0.0, 0)
	set_physics_process(false)

func _physics_process(_delta):
	enemy_node.move_and_slide()

# deal damage to enemy (called by enemy)
func update_health(knockback_direction, knockback_weight, amount):
	# invincibility check
	if enemy_node.invincible:
		amount = 0
	elif amount < 0:
		enemy_node.invincible = true
		invincibility_frame_node.start(0.05)

	# update health bar
	health += amount
	health = clamp(health, 0, max_health)
	health_bar_node.value = health
	health_bar_node.visible = health != max_health

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
	
	GlobalSettings.enemy_nodes_in_combat.erase(enemy_node)
	if GlobalSettings.locked_enemy_node == enemy_node: GlobalSettings.locked_enemy_node = null
	if GlobalSettings.enemy_nodes_in_combat.is_empty(): GlobalSettings.attempt_leave_combat()

	enemy_node.set_physics_process(false)
	enemy_node.animation_node.play("death")
	enemy_node.get_node("DeathTimer").start(0.3)
	enemy_node.velocity = enemy_node.knockback_direction * 100
	set_physics_process(true)
