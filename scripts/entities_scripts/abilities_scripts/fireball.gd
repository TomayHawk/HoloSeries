extends RigidBody2D

@export var base_damage: int = 10

@onready var caster_node: Node = GlobalSettings.current_main_player_node
@onready var player_stats_node: Node = get_parent().caster_node.player_stats_node

@onready var area_of_effect_node := $AreaOfEffect
@onready var ability_despawn_node := $AbilityDespawnComponent
@onready var basic_projectile_node := $BasicProjectile
@onready var damage_over_time_node := $DamageOverTime

func _ready():
	# disabled while selecting target
	set_physics_process(false)
	hide()
	
	# request target entity
	GlobalSettings.request_entities(self, "initiate_fireball", 1, "all_enemies_on_screen")
	
	if GlobalSettings.entities_available.size() == 0 && GlobalSettings.locked_enemy_node == null:
		queue_free()
	# if alt is pressed, auto-aim closest enemy
	elif Input.is_action_pressed("alt") && GlobalSettings.entities_available.size() != 0:
		CombatEntitiesComponent.target_entity("distance_least", caster_node)

# run after entity selection with GlobalSettings.choose_entities()
func initiate_fireball(_chosen_node):
	if player_stats_node.mana < mana_cost || !player_stats_node.alive:
		queue_free()
	else:
		player_stats_node.update_mana(-mana_cost)
		
		# begin despawn timer
		$AnimatedSprite2D.play("shoot")
		set_physics_process(true)
		time_left_node.start()
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

func _physics_process(delta):
	# blast on collision
	var collision_information = move_and_collide(velocity * delta)
	if collision_information != null: area_impact()

# run after entity selection with GlobalSettings.choose_entities()
func initiate_fireball(chosen_node):
	# set position, move direction and velocity
	position = caster_node.position + Vector2(0, -7)
	move_direction = (chosen_node.position - position).normalized()
	velocity = move_direction * speed * speed_stats_multiplier
