extends Node2D

@onready var caster_node = GlobalSettings.current_main_player_node

var target_player_node = null
var target_player_stats_node = null

# heal 5%
var heal_percentage = 0.05
var heal_amount = 10

func _ready():
	hide()
	GlobalSettings.request_entities(self, "initiate_heal", 1, "players_alive")

func initiate_heal(chosen_nodes):
	show()
	target_player_node = chosen_nodes[0]
	GlobalSettings.empty_entities_request()
	target_player_stats_node = target_player_node.player_stats_node

	heal_amount = target_player_stats_node.max_health * heal_percentage * randf_range(0.8, 1.2)

	target_player_stats_node.update_health(floor(heal_amount * randf_range(0.8, 1.2)))

	target_player_stats_node.update_mana( - 8)

	queue_free()
