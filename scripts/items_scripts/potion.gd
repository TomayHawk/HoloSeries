extends Resource

const item_name: String = "Potion"
const request_count: int = 1
const request_types: Array[Entities.Type] = [Entities.Type.PLAYERS_ALIVE]

func use_item(target_nodes: Array[EntityBase]) -> void:
    target_nodes[0].character.update_health(200.0)
    Damage.damage_display(200, target_nodes[0].position, Damage.DamageTypes.HEAL)
