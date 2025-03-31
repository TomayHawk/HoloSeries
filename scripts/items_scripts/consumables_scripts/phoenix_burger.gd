extends Resource

const item_name: String = "Phoenix Burger"
const request_count: int = 1
const request_types: Array[Entities.Type] = [Entities.Type.PLAYERS_PARTY_DEAD]

func use_item(target_nodes: Array[EntityBase]) -> void:
    target_nodes[0].character_node.revive(target_nodes[0].character_node.max_health * 0.25)
