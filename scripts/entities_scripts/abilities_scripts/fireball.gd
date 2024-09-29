extends CharacterBody2D

@export var base_damage := 10
@export var mana_cost := 10
@export var projectile_speed := 90

@onready var damage_multiplier: float = 1 + (GlobalSettings.current_main_player_node.player_stats_node.intelligence / 500)
@onready var speed_multiplier: float = 1 + (GlobalSettings.current_main_player_node.player_stats_node.intelligence / 1000) + (GlobalSettings.current_main_player_node.player_stats_node.speed / 256)

@onready var caster_node: Node = GlobalSettings.current_main_player_node
@onready var player_stats_node: Node = GlobalSettings.current_main_player_node.player_stats_node

func _ready():
	# disabled while selecting target
	set_physics_process(false)
	hide()
	
	# request target entity
	CombatEntitiesComponent.request_entities(self, "initiate_fireball", 1, "all_enemies_on_screen")
	
	if CombatEntitiesComponent.entities_available.size() == 0 && CombatEntitiesComponent.locked_enemy_node == null:
		queue_free()
	# if alt is pressed, auto-aim closest enemy
	elif Input.is_action_pressed("alt") && CombatEntitiesComponent.entities_available.size() != 0:
		CombatEntitiesComponent.target_entity("distance_least", caster_node)

# run after entity selection with CombatEntitiesComponent.choose_entities()
func initiate_fireball(chosen_node):
	if player_stats_node.mana < mana_cost || !player_stats_node.alive:
		queue_free()
	else:
		player_stats_node.update_mana(-mana_cost)
		# begin despawn timer
		$AnimatedSprite2D.play("shoot")
		# run after entity selection with CombatEntitiesComponent.choose_entities()
		$BasicProjectile.initiate_projectile(caster_node.position + Vector2(0, -7), (chosen_node.position - caster_node.position - Vector2(0, -7)).normalized(), projectile_speed * speed_multiplier)
		$AbilityDespawnComponent.start_timer(5.0, 0.5)
		show()
	
func projectile_collision(move_direction):
	for enemy_node in $AreaOfEffect.area_of_effect("enemies"):
		var temp_damage = CombatEntitiesComponent.magic_damage_calculator(base_damage * damage_multiplier, caster_node.player_stats_node, enemy_node.base_enemy_node)
		enemy_node.base_enemy_node.update_health(-temp_damage[0], temp_damage[1], move_direction, 0.5)
	queue_free()

func despawn_timeout():
	projectile_collision(velocity.normalized())