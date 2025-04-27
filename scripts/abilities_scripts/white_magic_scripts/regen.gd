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

@onready var caster_node: EntityBase = Players.main_player_node

func _ready():
	# request target entity
	Entities.entities_request_ended.connect(entity_chosen, CONNECT_ONE_SHOT)
	Entities.request_entities([Entities.Type.PLAYERS_ALIVE])

	# if alt is pressed, auto-aim player with lowest health
	if Input.is_action_pressed(&"alt"):
		Entities.target_entity_by_stats("health", Entities.entities_available, false, true)

func entity_chosen(chosen_nodes: Array[EntityBase]):
	var target_node: EntityBase = null if chosen_nodes.is_empty() else chosen_nodes[0]
	# apply regen if node chosen, caster is alive and caster has enough mana
	if target_node and caster_node.character_node.alive and caster_node.character_node.mana >= mana_cost:
		caster_node.character_node.update_mana(-mana_cost)
		var effect: Resource = target_node.character_node.add_status(Entities.Status.REGEN)
		# 70 HP to 1470 HP (max at 7000 HP)
		effect.regen_settings(DAMAGE_TYPES, target_node.character_node,
				clamp(target_node.character_node.max_health * heal_percentage, 10.0, 210.0),
				4.0, regen_count, 0.8, 1.2)
		target_node.character_node.effects_timers[-1] = 4.0

	queue_free()
