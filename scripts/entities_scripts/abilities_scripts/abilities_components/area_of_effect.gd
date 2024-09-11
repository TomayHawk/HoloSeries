extends Node

@onready var collision_shape := $CollisionShape2D
var nodes_in_blast_area: Array[Node] = []

# set collision shape
func set_collision_shape(set_shape):
	collision_shape.shape = set_shape
	
# blast
func area_impact():
	# deal damage to each enemy in blast radius
	for enemy_node in get_overlapping_bodies():
		var temp_damage = CombatEntitiesComponent.magic_damage_calculator(damage * damage_stats_multiplier, caster_node.player_stats_node, enemy_node.enemy_stats_node)
		enemy_node.enemy_stats_node.update_health(-temp_damage[0], temp_damage[1], move_direction, 0.5)
	queue_free()
