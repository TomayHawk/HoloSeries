extends CharacterBody2D

@export var base_damage: int = 10

@onready var caster_node: Node = GlobalSettings.current_main_player_node
@onready var player_stats_node: Node = GlobalSettings.current_main_player_node.player_stats_node

@onready var area_of_effect_node := $AreaOfEffect
@onready var ability_despawn_node := $AbilityDespawnComponent
@onready var basic_projectile_node := $BasicProjectile
@onready var damage_over_time_node := $DamageOverTime

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
		time_left_node.start()
		# run after entity selection with CombatEntitiesComponent.choose_entities()
		basic_projectile_node.initiate_projectile(caster_node.position + Vector2(0, -7), (chosen_node.position - caster_node.position - Vector2(0, -7)).normalized(), 90.0)
		show()

##### var temp_damage = CombatEntitiesComponent.magic_damage_calculator(damage * damage_stats_multiplier, caster_node.player_stats_node, enemy_node.enemy_stats_node)
##### @onready var damage_multiplier: float = 1 + (GlobalSettings.current_main_player_node.player_stats_node.intelligence / 500)
##### @onready var projectile_speed_multiplier: float = 1 + (get_parent().caster_node.player_stats_node.intelligence / 1000) + (get_parent().caster_node.player_stats_node.speed / 256)
##### 		enemy_node.enemy_stats_node.update_health(-temp_damage[0], temp_damage[1], move_direction, 0.5)
##### 	queue_free()
	
##### func projectile_collision():

@onready var time_left_node := $TimeLeft

const mana_cost := 10
const speed := 90
const damage := 10

@onready var speed_stats_multiplier: float = 1 + (GlobalSettings.current_main_player_node.player_stats_node.intelligence / 1000) + (GlobalSettings.current_main_player_node.player_stats_node.speed / 256)
@onready var damage_stats_multiplier: float = 1 + (GlobalSettings.current_main_player_node.player_stats_node.intelligence / 500)

var move_direction := Vector2.ZERO
var nodes_in_blast_area: Array[Node] = []
