extends Node2D

## need to dynamically allocate caster in case of ally/enemy casts
@onready var caster_node: Node = GlobalSettings.current_main_player_node
@onready var caster_stats_node: Node = caster_node.player_stats_node

var mana_cost: float = 4.0
var heal_percentage: float = 0.05

func _ready():
	hide()

	# request target entities
	CombatEntitiesComponent.request_entities(self, "initiate_heal", 1, "players_alive")

	# if alt is pressed, target player with lowest health
	if Input.is_action_pressed("alt"):
		CombatEntitiesComponent.target_entity("health", caster_node)

func initiate_heal(chosen_node):
	## should add a variable for "player can cast spells"
	# check caster mana sufficiency and 
	if caster_stats_node.mana < mana_cost or !caster_stats_node.alive:
		queue_free()
		return
	# check caster status and mana sufficiency

	caster_stats_node.update_mana(-mana_cost)

	# heal chosen node
	var heal_amount: float = CombatEntitiesComponent.magic_heal_calculator(chosen_node.player_stats_node.max_health * heal_percentage, caster_stats_node)
	chosen_node.player_stats_node.update_health(heal_amount, [null], Vector2.ZERO, 0.0)

	queue_free()
