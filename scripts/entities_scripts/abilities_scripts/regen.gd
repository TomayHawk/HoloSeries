extends Node2D

@onready var caster_node = GlobalSettings.current_main_player_node

@onready var regen_timer_node = $Timer

var target_player_stats_node = null

# 7 times
var regen_count = 7
# 2% each time
var heal_percentage = 0.02
var heal_amount = 10
# total: 14% over 28 seconds
##### need to add stats multipliers

func _ready():
	GlobalSettings.request_entities(self, "initiate_regen", 1, "players_alive")
	if GlobalSettings.entities_available.size() == 0: queue_free()

	hide()

	# if alt is pressed, auto-aim player with lowest health
	if Input.is_action_pressed("alt"):
		var temp_health = 0
		var selected_player = null

		for entity_node in GlobalSettings.entities_available:
			if entity_node.player_stats_node.health < temp_health:
				temp_health = entity_node.player_stats_node.health
				selected_player = entity_node

		GlobalSettings.entities_chosen.push_back(selected_player)
		GlobalSettings.choose_entities()

func initiate_regen(chosen_node):
	# check mana sufficiency
	if caster_node.player_stats_node.mana < 20:
		queue_free()
	else:
		caster_node.player_stats_node.update_mana( - 20)
		show()

		target_player_stats_node = chosen_node.player_stats_node

		# 70 HP to 1470 HP (max at 7000 HP)
		heal_amount = clamp(target_player_stats_node.max_health * heal_percentage, 10, 210)

		regen_timer_node.start(4)

func _on_timer_timeout():
	target_player_stats_node.update_health(floor(heal_amount * randf_range(0.8, 1.2)), [null], Vector2.ZERO, 0.0)

	# check times healed
	regen_count -= 1
	if regen_count == 0: queue_free()
