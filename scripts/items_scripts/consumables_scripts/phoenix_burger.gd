extends Resource

const item_name: String = "Phoenix Burger"
const request_count: int = 1
const request_types: int = Entities.Type.PLAYERS_DEAD

func use_item(target_nodes: Array[EntityBase]) -> void:
    target_nodes[0].stats.revive(target_nodes[0].stats.max_health * 0.25)
