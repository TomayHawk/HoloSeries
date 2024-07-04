extends Node2D

@onready var caster_node = GlobalSettings.current_main_player_node

@onready var regen_timer_node = $Timer

var target_player_node = null
var target_player_stats_node = null

# 7 times
var regen_count = 7
# 4 seconds intervals
var regen_time_intervals = 4
# 3% each time
var heal_percentage = 0.02
var heal_amount = 10
# total: 21% over 28 seconds

func _ready():
	GlobalSettings.request_entities(self, "initiate_regen", 1, "players_alive")

func initiate_regen(chosen_nodes):
	target_player_node = chosen_nodes[0]
	target_player_stats_node = target_player_node.player_stats_node

	heal_amount = target_player_stats_node.max_health * heal_percentage
	# 70 HP to 1470 HP (max at 7000 HP)
	clamp(heal_amount, 10, 210)

	regen_timer_node.start(4)

func _on_timer_timeout():
	target_player_stats_node.update_health(heal_amount * randf_range(0.8, 1.2))
	regen_count -= 1
	if regen_count == 0:
		queue_free()
