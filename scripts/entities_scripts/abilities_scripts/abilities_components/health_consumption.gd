extends Node

@onready var ability_node := get_parent()
@onready var player_stats_node := get_parent().caster_node.player_stats_node

func use_mana(mana_cost):
	if player_stats_node.mana < mana_cost || !player_stats_node.alive:
		ability_node.queue_free()
	else:
		player_stats_node.update_mana(-mana_cost)