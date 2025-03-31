extends Area2D

const DAMAGE_TYPES: int = \
		Damage.DamageTypes.ENEMY_HIT \
		| Damage.DamageTypes.COMBAT \
		| Damage.DamageTypes.MAGIC

var mana_cost: float = 8.0
var damage: float = 10.0
var speed: float = 90.0

# TODO: should create an "ability queue" that clears when changing player or something (or caster dies)
# TODO: Combat UI has wrong mana description. need to fix

# TODO: should this damage multiplier be here? (Damage.magic_damage already has a multiplier)
# TODO: @onready var damage_multiplier: float = 1 + (Players.main_player_node.character_node.intelligence / 500)

@onready var caster_node: Node2D = Players.main_player_node
@onready var caster_stats_node: Node2D = caster_node.character_node

signal entities_chosen

func _ready() -> void:
	hide()
	connect("entities_chosen", Callable(self, "initiate_fireball"))
	# request target entity
	Entities.request_entities(self, [Entities.Type.ENEMIES_ON_SCREEN])
	
	# TODO: might want to put this somewhere else
	if Entities.entities_available.size() == 0 and not Combat.is_locked():
		queue_free()
	# if alt is pressed, auto-aim closest enemy
	elif Input.is_action_pressed(&"alt") and Entities.entities_available.size() != 0:
		Entities.target_entity("distance_least", caster_node)
	
	speed *= 1 + (caster_stats_node.intelligence / 1000) + (caster_stats_node.speed / 256)

# run after entity selection with Entities.choose_entities()
func initiate_fireball(chosen_node) -> void:
	if caster_stats_node.mana < mana_cost or not caster_stats_node.alive:
		queue_free()
	else:
		caster_stats_node.update_mana(-mana_cost)
		# begin despawn timer
		%AnimatedSprite2D.play("shoot")
		# run after entity selection with Entities.choose_entities()
		position = caster_node.position + Vector2(0, -7)
		%BasicProjectile.initiate_projectile((chosen_node.position - caster_node.position - Vector2(0, -7)).normalized(), speed)
		%AbilityDespawnComponent.start_timer(5.0, 0.5)
		show()
	
func projectile_collision(move_direction) -> void:
	Players.camera_node.screen_shake(0.1, 1, 30, 5, false)

	for enemy_node in $AreaOfEffect.area_of_effect(&"enemies"):
		if Damage.combat_damage(damage, DAMAGE_TYPES, caster_node.character_node, enemy_node.base_enemy_node):
			enemy_node.dealt_knockback(move_direction, 0.5)
	
	queue_free()

func ability_request_failed() -> void:
	queue_free()

func despawn_timeout():
	projectile_collision(%BasicProjectile.velocity.normalized())

# on collision, 
func _on_body_entered(_body: Node2D) -> void:
	projectile_collision(%BasicProjectile.velocity.normalized())
