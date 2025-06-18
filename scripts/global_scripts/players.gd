extends Node

var main_player: PlayerBase = null
var standby_characters: Array[PlayerStats] = []

@onready var party_node: Node2D = $Party
@onready var camera_node: Camera2D = $Camera2D

func update_main_player(player_base: PlayerBase) -> void:
	var prev_main_player: PlayerBase = main_player
	main_player = player_base

	main_player.is_main_player = true
	prev_main_player.is_main_player = false
	
	camera_node.new_parent(main_player)
	Entities.end_entities_request()

# TODO: allow allies to switch with standby players
func update_standby_player(standby_index: int) -> void:
	var prev_stats: PlayerStats = main_player.stats
	var next_stats: PlayerStats = standby_characters.pop_at(standby_index)
	
	# add previous stats to standby
	standby_characters.insert(standby_index, prev_stats)

	# update main player
	main_player.update_stats(next_stats)

	# update player ui
	Combat.ui.name_labels[main_player.get_index()].text = next_stats.CHARACTER_NAME

	# update standby ui
	Combat.ui.standby_name_labels[standby_index].text = prev_stats.CHARACTER_NAME
	Combat.ui.standby_level_labels[standby_index].text = str(prev_stats.level)
	Combat.ui.standby_health_labels[standby_index].text = str(int(prev_stats.health))
	Combat.ui.standby_mana_labels[standby_index].text = str(int(prev_stats.mana))
