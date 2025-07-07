class_name EntityBase
extends CharacterBody2D

# ..............................................................................

#region SIGNALS

signal move_state_timeout
signal action_cooldown_timeout

#endregion

# ..............................................................................

#region CONSTANTS

enum MoveState {
	IDLE,
	WALK,
	DASH,
	SPRINT,
	KNOCKBACK,
	STUN,
}

enum ActionState {
	READY,
	ACTION,
	COOLDOWN,
}

enum Directions {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	UP_LEFT,
	UP_RIGHT,
	DOWN_LEFT,
	DOWN_RIGHT,
	NONE,
}

enum ActionType {
	NONE,
	ATTACK,
	SUMMON,
	CAST,
	ITEM,
}

const ALL_DIRECTIONS: Array[Directions] = [
	Directions.RIGHT,
	Directions.DOWN_RIGHT,
	Directions.DOWN,
	Directions.DOWN_LEFT,
	Directions.LEFT, 
	Directions.UP_LEFT,
	Directions.UP,
	Directions.UP_RIGHT,
]

#endregion

# ..............................................................................

#region VARIABLES

var stats: EntityStats = null
var process_interval: float = 0.0

# MOVEMENT
var move_state: MoveState = MoveState.IDLE:
	set(next_state):
		move_state = next_state
		in_forced_move_state = \
				next_state == MoveState.KNOCKBACK or next_state == MoveState.STUN

var move_state_timer: float = 0.5
var move_direction: Directions = Directions.DOWN
var move_state_velocity: Vector2 = Vector2.DOWN

var in_forced_move_state: bool = false

# ACTION
var action_state: ActionState = ActionState.READY
var action_node: Node = null
var action_callable: Callable = Callable()
var action_vector: Vector2 = Vector2.DOWN
var action_cooldown: float = 0.0
var in_action_range: bool = false

# ACTION TARGETS
var action_target: EntityBase = null
var action_target_candidates: Array[EntityBase] = []
var action_target_types: int = 0
var action_target_stats: StringName = &""
var action_target_get_max: bool = true

#endregion

# ..............................................................................

#region PROCESS

func _process(delta: float) -> void:
	# decrease move state timer
	if move_state_timer > 0.0:
		move_state_timer -= delta
		if move_state_timer < 0.0:
			move_state_timeout.emit()
	
	# decrease action cooldown
	if action_cooldown > 0.0:
		action_cooldown -= delta
		if action_cooldown < 0.0:
			action_cooldown_timeout.emit()

	# process stats
	process_interval += delta
	if process_interval > 0.1:
		stats.stats_process(process_interval)
		process_interval = 0.0

#endregion

# ..............................................................................

#region DEATH & REVIVE

func death() -> void:
	set_process(false)

	# reset variables
	process_interval = 0.0
	reset_movement()
	reset_action()
	reset_action_targets()

func revive() -> void:
	set_process(true)

#endregion

# ..............................................................................

#region UTILITIES

func reset_movement(idle_time: float = 0.5) -> void:
	move_state = MoveState.IDLE
	move_state_timer = idle_time
	move_direction = Directions.DOWN
	move_state_velocity = Vector2.DOWN

func reset_action() -> void:
	action_state = ActionState.READY
	action_node = null
	action_cooldown = 0.0
	action_callable = Callable()
	action_vector = Vector2.DOWN
	in_action_range = false

func reset_action_targets() -> void:
	action_target = null
	action_target_candidates.clear()
	action_target_types = 0
	action_target_stats = &""
	action_target_get_max = true

func toggle_process(toggled: bool) -> void:
	# ignore if not alive
	if not stats.alive:
		return

	# toggle animation
	if toggled:
		$Animation.play()
	else:
		$Animation.pause()
	
	# toggle processes
	set_process(toggled)
	set_physics_process(toggled)

#endregion

# ..............................................................................
