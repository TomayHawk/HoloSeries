extends Resource

const item_name: String = "Reset Button"
const request_count: int = 0
const request_types: Array[Entities.Type] = []

func use_item(_target_nodes: Array[EntityBase]) -> void:
    for player_node in Entities.entities_of_type[Entities.Type.PLAYERS_PARTY_DEAD].call():
        player_node.character_node.revive(player_node.character_node.max_health)
