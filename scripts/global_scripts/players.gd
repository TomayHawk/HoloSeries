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
	Combat.ui.update_party_ui(main_player.party_index, next_stats)

	# update standby ui
	Combat.ui.update_standby_ui(standby_index, prev_stats)
