extends Node2D

# GLOBAL PLAYERS MANAGER

# ..............................................................................

#region VARIABLES

var main_player: PlayerBase = null
var standby_characters: Array[PlayerStats] = []

@onready var camera: Camera2D = $Camera

#endregion

# TODO: need to add a process to update stats.last_action_cooldown

# ..............................................................................

#region FUNCTIONS

# TODO: need to update states and variables
func toggle_process(toggled: bool) -> void:
	main_player.velocity = Vector2.ZERO
	set_physics_process(toggled)

	if toggled:
		main_player.apply_input_velocity()

# switch main player to ally, and switch target ally to main player
func switch_main_player(next_main_player: PlayerBase) -> void:
	main_player.switch_to_ally()
	next_main_player.switch_to_main()

# TODO: allow allies to switch with standby players
# update main player, add previous stats to standby, and update standby ui
func switch_standby_character(standby_index: int) -> void:
	if main_player.in_forced_move_state: return
	var prev_stats: PlayerStats = main_player.stats
	main_player.switch_character(standby_characters.pop_at(standby_index))
	standby_characters.insert(standby_index, prev_stats)
	Combat.ui.update_standby_ui(standby_index, prev_stats)

#endregion

# ..............................................................................
