extends Area2D

var mana_cost: float = 8.0
var damage: float = 10.0
var speed: float = 90.0

@onready var caster_node: Node2D = GlobalSettings.current_main_player_node
@onready var caster_stats_node: Node2D = caster_node.player_stats_node

func _ready() -> void:
	hide()
	
	# request target entity
	CombatEntitiesComponent.request_entities(self, "initiate_rocket_launcher", 1, "all_enemies_on_screen")
	
	## might want to put this somewhere else
	if CombatEntitiesComponent.entities_available.size() == 0 and CombatEntitiesComponent.locked_enemy_node == null:
		queue_free()
	# if alt is pressed, auto-aim closest enemy
	elif Input.is_action_pressed("alt") and CombatEntitiesComponent.entities_available.size() != 0:
		CombatEntitiesComponent.target_entity("distance_least", caster_node)
	
	speed *= 1 + (caster_stats_node.intelligence / 1000) + (caster_stats_node.speed / 256)

# run after entity selection with CombatEntitiesComponent.choose_entities()
func initiate_rocket_launcher(chosen_node) -> void:
	if caster_stats_node.mana < mana_cost or !caster_stats_node.alive:
		queue_free()
	else:
		caster_stats_node.update_mana(-mana_cost)
		# begin despawn timer
		%AnimatedSprite2D.play("shoot")
		# run after entity selection with CombatEntitiesComponent.choose_entities()
		position = caster_node.position + Vector2(0, -7)
		%BasicProjectile.initiate_projectile((chosen_node.position - caster_node.position - Vector2(0, -7)).normalized(), speed)
		%AbilityDespawnComponent.start_timer(5.0, 0.5)
		show()
	
func projectile_collision(move_direction) -> void:
	GlobalSettings.camera_node.screen_shake(0.1, 1, 30, 5, false)

	for enemy_node in $AreaOfEffect.area_of_effect("enemies"):
		var temp_damage = CombatEntitiesComponent.magic_damage_calculator(damage, caster_node.player_stats_node, enemy_node.base_enemy_node)
		enemy_node.base_enemy_node.update_health(-temp_damage[0], temp_damage[1], move_direction, 0.5)
	
	queue_free()

func despawn_timeout():
	projectile_collision(%BasicProjectile.velocity.normalized())

# on collision, 
func _on_body_entered(_body: Node2D) -> void:
	projectile_collision(%BasicProjectile.velocity.normalized())
