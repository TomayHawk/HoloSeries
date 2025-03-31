extends Resource

const item_name: String = "MAX Potion"
const request_count: int = 0
const request_types: Array[Entities.Type] = []

func use_item(_target_nodes: Array[EntityBase]) -> void:
    for player_node in Players.party_node.get_children():
        if player_node.character_node.alive:
            player_node.character_node.update_health(99999.9)
