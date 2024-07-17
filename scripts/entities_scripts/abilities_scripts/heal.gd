extends Node2D

@onready var caster_node := GlobalSettings.current_main_player_node

# heal 5%
const heal_percentage := 0.05
var heal_amount := 10.0
##### need to add stats multipliers

func _ready():
	GlobalSettings.request_entities(self, "initiate_heal", 1, "players_alive")
	if GlobalSettings.entities_available.size() == 0: queue_free()

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

func initiate_heal(chosen_node):
	# check mana sufficiency
	if caster_node.player_stats_node.mana < 8:
		queue_free()
	else:
		caster_node.player_stats_node.update_mana( - 8)

		# heal chosen node
		heal_amount = floor(chosen_node.player_stats_node.max_health * heal_percentage * randf_range(0.8, 1.2))
		chosen_node.player_stats_node.update_health(heal_amount, [null], Vector2.ZERO, 0.0)

		queue_free()
