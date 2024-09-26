extends Node2D

@onready var caster_node := GlobalSettings.current_main_player_node

const mana_cost := 8
# heal 5%
const heal_percentage := 0.05
var heal_amount := 10.0

func _ready():
	hide()

	# request target entity
	CombatEntitiesComponent.request_entities(self, "initiate_heal", 1, "players_alive")
	
	if CombatEntitiesComponent.entities_available.size() == 0:
		queue_free()
	# if alt is pressed, auto-aim player with lowest health
	elif Input.is_action_pressed("alt"):
		CombatEntitiesComponent.target_entity("health", caster_node)

func initiate_heal(chosen_node):
	# check caster status and mana sufficiency
	if caster_node.player_stats_node.mana > mana_cost && caster_node.player_stats_node.alive:
		caster_node.player_stats_node.update_mana(-mana_cost)

		# heal chosen node
		heal_amount = CombatEntitiesComponent.magic_heal_calculator(chosen_node.player_stats_node.max_health * heal_percentage, caster_node.player_stats_node)
		chosen_node.player_stats_node.update_health(heal_amount, [null], Vector2.ZERO, 0.0)

	queue_free()
