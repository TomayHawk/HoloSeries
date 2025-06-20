class_name EntityBase extends CharacterBody2D

# ..............................................................................

# SIGNALS

signal move_state_timeout()
signal action_state_timeout()

# ..............................................................................

# CONSTANTS

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
	NOT_APPLICABLE,
}

enum ActionType {
	ATTACK,
	SUMMON,
	CAST,
	ITEM,
}

# ..............................................................................

# STATS

var stats: EntityStats = null

# STATES

var move_state: MoveState = MoveState.IDLE
var action_state: ActionState = ActionState.READY
var move_direction: Directions = Directions.DOWN

# VARIABLES

var move_state_velocity: Vector2 = Vector2.UP
var move_state_timer: float = 0.0
var action_state_timer: float = 0.0
var process_interval: float = 0.0

# ACTION

# TODO: UPDATE STATS UPDATES
var action_type: ActionType = ActionType.ATTACK
var action_target: EntityBase = null
var action_target_type: Entities.Type = Entities.Type.ENEMIES
var action_target_priority: StringName = &""
var action_target_get_max: bool = true
var action_vector: Vector2 = Vector2.DOWN
var action_fail_count: int = 0

# ..............................................................................

# PROCESS
func _process(delta: float) -> void:
	# decrease move state timer
	if move_state_timer > 0.0:
		move_state_timer -= delta
		if move_state_timer < 0.0:
			move_state_timeout.emit()
	
	# decrease action state timer
	if action_state_timer > 0.0:
		action_state_timer -= delta
		if action_state_timer < 0.0:
			action_state_timeout.emit()

	# process stats
	process_interval += delta
	if process_interval > 0.1:
		stats.stats_process(process_interval)
		process_interval = 0.0

# ..............................................................................

# DEATH & REVIVE

func death() -> void:
	set_process(false)

	move_state = MoveState.IDLE
	action_state = ActionState.READY
	move_direction = Directions.DOWN

	move_state_velocity = Vector2.UP
	move_state_timer = 0.0
	action_state_timer = 0.0
	process_interval = 0.0

func revive() -> void:
	set_process(true)
