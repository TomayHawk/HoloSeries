extends Area2D

const DAMAGE_TYPES: int = \
		Damage.DamageTypes.ENEMY_HIT \
		| Damage.DamageTypes.COMBAT \
		| Damage.DamageTypes.MAGIC

var mana_cost: float = 8.0
var damage: float = 10.0
var speed: float = 90.0

var velocity: Vector2 = Vector2.ZERO

@onready var caster_node: Node2D = Players.main_player_node
@onready var caster_stats_node: Node2D = caster_node.character_node

func _ready() -> void:
	set_physics_process(false)
	hide()

	# request target entity
	Entities.entities_request_ended.connect(entity_chosen)
	Entities.request_entities([Entities.Type.ENEMIES_ON_SCREEN])
	
	# if alt is pressed, target nearest enemy
	if Input.is_action_pressed(&"alt"):
		Entities.target_entity_by_distance(caster_node.position, Entities.entities_available, false, true)

func _physics_process(delta: float) -> void:
	position += velocity * delta

func entity_chosen(chosen_nodes) -> void:
	var target_node: EntityBase = null if chosen_nodes.is_empty() else chosen_nodes[0]
	Entities.entities_request_ended.disconnect(entity_chosen)
	if not target_node or caster_stats_node.mana < mana_cost or not caster_stats_node.alive:
		queue_free()
		return
	caster_stats_node.update_mana(-mana_cost)
	# begin despawn timer
	%AnimatedSprite2D.play("shoot")
	position = caster_node.position + Vector2(0, -7)
	%DespawnComponent.initiate_timers(5.0, 1.0)
	$AreaOfEffect.collision_mask |= 1 << 1
	velocity = (target_node.position - caster_node.position - Vector2(0, -7)).normalized() * speed \
			* (1 + (caster_stats_node.intelligence / 1000) + (caster_stats_node.speed / 256))
	set_physics_process(true)
	show()
	
func projectile_collision(move_direction) -> void:
	Players.camera_node.screen_shake(0.1, 1, 30, 5, false)
	var target_enemy_nodes: Array[EntityBase] = await $AreaOfEffect.area_of_effect(2)
	for enemy_node in target_enemy_nodes:
		if Damage.combat_damage(damage, DAMAGE_TYPES, caster_node.character_node, enemy_node.enemy_stats_node):
			enemy_node.dealt_knockback(move_direction, 0.5)
	queue_free()

func despawn_timeout():
	projectile_collision(velocity.normalized())

# on collision, 
func _on_body_entered(_body: Node2D) -> void:
	projectile_collision(velocity.normalized())
