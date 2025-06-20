extends Node

# TODO: allow allies to switch with standby players

var main_player: PlayerBase = null
var standby_characters: Array[PlayerStats] = []

@onready var party_node: Node2D = $Party
@onready var camera_node: Camera2D = $Camera2D

func switch_main_player(next_main_player: PlayerBase) -> void:
	main_player.switch_to_ally()
	next_main_player.switch_to_main()
	main_player = next_main_player

func switch_standby_character(standby_index: int) -> void:
	if main_player.move_state in [main_player.MoveState.KNOCKBACK, main_player.MoveState.STUN]:
		return

	var prev_stats: PlayerStats = main_player.stats

	# update main player
	main_player.switch_character(standby_characters.pop_at(standby_index))

	# add previous stats to standby
	standby_characters.insert(standby_index, prev_stats)

	# update standby ui
	Combat.ui.update_standby_ui(standby_index, prev_stats)
