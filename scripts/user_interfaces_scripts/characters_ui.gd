extends CanvasLayer

@onready var stats_label_nodes := %StatsMarginGridContainer.get_children()
@onready var stats_left_button_node := %StatsLeftButton
@onready var stats_right_button_node := %StatsRightButton

var characters: Array[Node] = []
var current_stats := -1

func _input(_event: InputEvent) -> void:
    if Input.is_action_just_pressed(&"esc"):
        Inputs.accept_event()
        exit_ui()

func _on_characters_pressed():
    characters.clear()
    for player_node in Players.party_node.get_children():
        characters.push_back(player_node.character)
    for character in Players.standby_node.get_children():
        characters.push_back(character)

    current_stats = Players.main_player.character.node_index
    _on_left_button_pressed()
    _on_right_button_pressed()

func update_characters():
    stats_label_nodes[1].text = characters[current_stats].get_parent().character.CHARACTER_NAME
    stats_label_nodes[3].text = str(round(characters[current_stats].level))
    stats_label_nodes[5].text = str(round(characters[current_stats].health)) + " / " + str(round(characters[current_stats].max_health))
    stats_label_nodes[7].text = str(round(characters[current_stats].mana)) + " / " + str(round(characters[current_stats].max_mana))
    stats_label_nodes[9].text = str(round(characters[current_stats].stamina)) + " / " + str(round(characters[current_stats].max_stamina))
    stats_label_nodes[11].text = str(round(characters[current_stats].defense))
    stats_label_nodes[13].text = str(round(characters[current_stats].ward))
    stats_label_nodes[15].text = str(round(characters[current_stats].strength))
    stats_label_nodes[17].text = str(round(characters[current_stats].intelligence))
    stats_label_nodes[19].text = str(round(characters[current_stats].speed))
    stats_label_nodes[21].text = str(round(characters[current_stats].agility))
    stats_label_nodes[23].text = str(round(characters[current_stats].crit_chance * 100)) + "%"
    stats_label_nodes[25].text = str(round(characters[current_stats].crit_damage * 100)) + "%"

func exit_ui() -> void:
    Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")
    queue_free()

func _on_left_button_pressed():
    if current_stats != 0:
        current_stats -= 1
        update_characters()
        stats_right_button_node.modulate.a = 1.0
        stats_right_button_node.disabled = false
    if current_stats == 0:
        stats_left_button_node.modulate.a = 0.0
        stats_left_button_node.disabled = true

func _on_right_button_pressed():
    if current_stats != characters.size() - 1:
        current_stats += 1
        update_characters()
        stats_left_button_node.modulate.a = 1.0
        stats_left_button_node.disabled = false
    if current_stats == characters.size() - 1:
        stats_right_button_node.modulate.a = 0.0
        stats_right_button_node.disabled = true