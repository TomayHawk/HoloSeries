extends Area2D

var mana_cost: float = 8.0
var damage: float = 10.0
var speed: float = 90.0

@onready var caster_node: Node2D = Players.main_player_node
@onready var caster_stats_node: Node2D = caster_node.character_node

const DAMAGE_TYPES: int = \
		Damage.DamageTypes.ENEMY_HIT \
		| Damage.DamageTypes.COMBAT \
		| Damage.DamageTypes.PHYSICAL

signal entities_chosen

func _ready() -> void:
	hide()

	connect("entities_chosen", Callable(self, "initiate_rocket_launcher"))
	
	# request targetable enemies
	Entities.request_entities(self, [Entities.Type.ENEMIES_ON_SCREEN])

	# if alt is pressed, auto-aim closest enemy
	if Input.is_action_pressed(&"alt"):
		Entities.target_entity("distance_least", caster_node)

# run after entity selection with Entities.choose_entities()
func initiate_rocket_launcher(chosen_node: Node) -> void:
	if caster_stats_node.mana < mana_cost or not caster_stats_node.alive:
		queue_free()
		return
	
	caster_stats_node.update_mana(-mana_cost)
	position = caster_node.position + Vector2(0, -7)

	$AnimatedSprite2D.play("shoot")
	$HomingProjectile.initiate_homing_projectile(chosen_node)
	$AreaOfEffect.scale_aoe_area(1.5, 1.5)
	$AbilityDespawnComponent.start_timer(5.0, 0.5)

	show()

# TODO: temporary value
func homing_projectile_speed() -> float:
	return speed * (1 + (caster_stats_node.intelligence / 1000) + (caster_stats_node.speed / 256))

func projectile_collision(move_direction) -> void:
	Players.camera_node.screen_shake(0.1, 1, 30, 5, false)

	for enemy_node in $AreaOfEffect.area_of_effect(&"enemies"):
		if Damage.combat_damage(damage, DAMAGE_TYPES, caster_node.character_node, enemy_node.base_enemy_node):
			enemy_node.dealt_knockback(move_direction, 1.5)
	
	queue_free()

func ability_request_failed() -> void:
	queue_free()

func despawn_timeout():
	# TODO: temporary code
	projectile_collision(Vector2.ZERO)

# on collision, 
func _on_body_entered(_body: Node2D) -> void:
	# TODO: temporary code
	projectile_collision(Vector2.ZERO)
