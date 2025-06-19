extends Resource

const item_name: String = "MAX Potion"
const request_count: int = 0
const request_types: Array[Entities.Type] = []

func use_item(_target_nodes: Array[EntityBase]) -> void:
    for player_node in Players.party_node.get_children():
        if player_node.stats.alive:
            player_node.stats.update_health(99999.9)
            Damage.damage_display(99999, player_node.position, Damage.DamageTypes.HEAL)
