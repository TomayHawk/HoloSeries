extends Node2D

@onready var caster_node := GlobalSettings.current_main_player_node

@onready var regen_timer_node := %Timer

var target_player_stats_node: Node = null

const mana_cost := 20
# 7 times
var regen_count := 7
# 2% each time
const heal_percentage := 0.02
var heal_amount := 10.0
# total: 14% over 28 seconds
##### need to add stats multipliers

func _ready():
	hide()

	# request target entity
	CombatEntitiesComponent.request_entities(self, "initiate_regen", 1, "players_alive")
	
	if CombatEntitiesComponent.entities_available.size() == 0:
		queue_free()
	# if alt is pressed, auto-aim player with lowest health
	elif Input.is_action_pressed("alt"):
		CombatEntitiesComponent.target_entity("health", caster_node)

func initiate_regen(chosen_node):
	# check caster status and mana sufficiency
	if caster_node.player_stats_node.mana < mana_cost || !caster_node.player_stats_node.alive:
		queue_free()
	else:
		caster_node.player_stats_node.update_mana(-mana_cost)
		show()

		target_player_stats_node = chosen_node.player_stats_node

		# 70 HP to 1470 HP (max at 7000 HP)
		heal_amount = clamp(target_player_stats_node.max_health * heal_percentage, 10, 210)

		regen_timer_node.start(4)

func _on_timer_timeout():
	target_player_stats_node.update_health(CombatEntitiesComponent.magic_heal_calculator(heal_amount * randf_range(0.8, 1.2), caster_node.player_stats_node), [null], Vector2.ZERO, 0.0)

	# check times healed
	regen_count -= 1
	if regen_count == 0: queue_free()
