extends Area2D

const DAMAGE_TYPES: int = \
		Damage.DamageTypes.ENEMY_HIT \
		| Damage.DamageTypes.COMBAT \
		| Damage.DamageTypes.PHYSICAL

var mana_cost: float = 8.0
var speed: float = 90.0
var damage: float = 10.0

@onready var caster_node: Node2D = Players.main_player_node
@onready var caster_stats_node: Node2D = caster_node.character_node

func _ready() -> void:
	hide()

	# request target entity
	Entities.entities_request_ended.connect(entity_chosen)
	Entities.request_entities([Entities.Type.ENEMIES_ON_SCREEN])

	# if alt is pressed, auto-aim closest enemy
	if Input.is_action_pressed(&"alt"):
		Entities.target_entity_by_distance(caster_node.position, Entities.entities_available, false, true)

func entity_chosen(chosen_nodes: Array[EntityBase]) -> void:
	var target_node: EntityBase = null if chosen_nodes.is_empty() else chosen_nodes[0]
	Entities.entities_request_ended.disconnect(entity_chosen)
	if not target_node or not caster_stats_node.alive or caster_stats_node.mana < mana_cost:
		queue_free()
		return
	
	caster_stats_node.update_mana(-mana_cost)
	position = caster_node.position + Vector2(0, -7)

	$AnimatedSprite2D.play("shoot")
	$HomingProjectile.initiate_homing_projectile(target_node,
			speed * (1 + (caster_stats_node.intelligence / 1000) + (caster_stats_node.speed / 256)),
			)
	$AreaOfEffect.collision_mask |= 1 << 1
	$AreaOfEffect/CollisionShape2D.scale = Vector2(1.5, 1.5)
	$DespawnComponent.initiate_timers(5.0, 1.0)

	show()

func projectile_collision(move_direction) -> void:
	Players.camera_node.screen_shake(0.1, 1, 30, 5, false)
	var target_enemy_nodes: Array[EntityBase] = await $AreaOfEffect.area_of_effect(2)
	for enemy_node in target_enemy_nodes:
		if Damage.combat_damage(damage, DAMAGE_TYPES, caster_node.character_node, enemy_node.enemy_stats_node):
			enemy_node.dealt_knockback(move_direction, 1.5)
	queue_free()

func despawn_timeout():
	# TODO: temporary code
	projectile_collision(Vector2.ZERO)

# on collision, 
func _on_body_entered(_body: Node2D) -> void:
	# TODO: temporary code
	projectile_collision(Vector2.ZERO)
