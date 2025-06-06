extends Resource

const item_name: String = "Reset Button"
const request_count: int = 0
const request_types: Array[Entities.Type] = []

func use_item(_target_nodes: Array[EntityBase]) -> void:
    for player_node in Entities.entities_of_type[Entities.Type.PLAYERS_DEAD].call():
        var heal_amount: float = player_node.character.max_health
        player_node.character.revive(heal_amount)
        Damage.damage_display(abs(heal_amount), player_node.position, Damage.DamageTypes.HEAL)
