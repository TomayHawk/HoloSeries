extends Node2D

@onready var caster_node: Node = Players.main_player_node

@onready var regen_timer_node := %Timer

const DAMAGE_TYPES: int = \
		Damage.DamageTypes.PLAYER_HIT \
		| Damage.DamageTypes.HEAL \
		| Damage.DamageTypes.MAGIC \
		| Damage.DamageTypes.NO_CRITICAL \
		| Damage.DamageTypes.NO_MISS

const mana_cost := 20
# 7 times
var regen_count := 7
# 2% each time
const heal_percentage := 0.02
# total: 14% over 28 seconds
# TODO: need to add stats multipliers

signal entities_chosen

func _ready():
	hide()

	connect("entities_chosen", Callable(self, "initiate_regen"))

	# request target entity
	Entities.request_entities(self, [Entities.Type.PLAYERS_PARTY_ALIVE])
	
	if Entities.entities_available.size() == 0:
		queue_free()
	# if alt is pressed, auto-aim player with lowest health
	elif Input.is_action_pressed(&"alt"):
		Entities.target_entity("health", caster_node)

func initiate_regen(chosen_node):
	# check caster status and mana sufficiency
	if caster_node.character_node.mana < mana_cost or not caster_node.character_node.alive:
		queue_free()
	else:
		caster_node.character_node.update_mana(-mana_cost)
		var effect: Resource = chosen_node.character_node.add_status(Entities.Status.REGEN)
		chosen_node.character_node.effects_timers[-1] = 4.0
		effect.regen_settings(
			DAMAGE_TYPES,
			chosen_node.character_node,
			clamp(chosen_node.character_node.max_health * heal_percentage, 10, 210), # 70 HP to 1470 HP (max at 7000 HP)
			4.0,
			regen_count,
			0.8,
			1.2,
		)

func ability_request_failed() -> void:
	queue_free()
