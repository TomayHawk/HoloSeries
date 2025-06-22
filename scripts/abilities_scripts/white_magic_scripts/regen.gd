extends Node

const DAMAGE_TYPES: int = \
		Damage.DamageTypes.PLAYER_HIT \
		| Damage.DamageTypes.HEAL \
		| Damage.DamageTypes.MAGIC \
		| Damage.DamageTypes.NO_CRITICAL \
		| Damage.DamageTypes.NO_MISS

var mana_cost: float = 20
var heal_percentage: float = 0.02
var regen_count: int = 7
# TODO: need to add stats multipliers

@onready var caster_node: EntityBase = Players.main_player

func _ready():
	# request target entity
	Entities.entities_request_ended.connect(entity_chosen, CONNECT_ONE_SHOT)
	Entities.request_entities([Entities.Type.PLAYERS_ALIVE])

	# if alt is pressed, auto-aim player with lowest health
	if Inputs.alt_pressed:
		Entities.choose_entity(Entities.target_entity_by_stats(Entities.entities_available, &"health", false))

func entity_chosen(chosen_nodes: Array[EntityBase]):
	var target_node: EntityBase = null if chosen_nodes.is_empty() else chosen_nodes[0]
	# apply regen if node chosen, caster is alive and caster has enough mana
	if target_node and caster_node.stats.alive and caster_node.stats.mana >= mana_cost:
		caster_node.stats.update_mana(-mana_cost)
		var effect: Resource = target_node.stats.add_status(Entities.Status.REGEN)
		# 70 HP to 1470 HP (max at 7000 HP)
		effect.regen_settings(DAMAGE_TYPES, target_node.stats,
				clamp(target_node.stats.max_health * heal_percentage, 10.0, 210.0),
				4.0, regen_count, 0.8, 1.2)

	queue_free()
