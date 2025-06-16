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
	ATTACK,
	CAST,
	ITEM,
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

# ..............................................................................

# STATS

var stats: EntityStats = null

# STATES

var move_state: MoveState = MoveState.IDLE
var action_state: ActionState = ActionState.READY
var move_direction: Directions = Directions.DOWN

# VARIABLES

var attack_vector: Vector2 = Vector2.DOWN
var knockback_velocity: Vector2 = Vector2.UP
var move_state_timer: float = 0.0
var action_state_timer: float = 0.0
var process_interval: float = 0.0

# ACTION VARIABLES

var in_action_range: bool = false
var action_target: GDScript = EntityBase
var action_queue: Array[Array] = []

# ..............................................................................

# PROCESS

func _process(delta: float) -> void:
	process_interval += delta

	if process_interval > 0.1:
		# process stats
		stats.stats_process(process_interval)

		# decrease move state timer
		if move_state_timer > 0.0:
			move_state_timer -= process_interval
			if move_state_timer < 0.0:
				move_state_timeout.emit()

		# decrease action state timer
		if action_state_timer > 0.0:
			action_state_timer -= process_interval
			if action_state_timer < 0.0:
				action_state_timeout.emit()
		
		process_interval = 0.0

# ..............................................................................

# DEATH & REVIVE

func death() -> void:
	set_process(false)

	move_state = MoveState.IDLE
	action_state = ActionState.READY
	move_direction = Directions.DOWN

	attack_vector = Vector2.DOWN
	knockback_velocity = Vector2.UP
	move_state_timer = 0.0
	action_state_timer = 0.0
	process_interval = 0.0

	in_action_range = false
	action_target = EntityBase
	action_queue.clear()

func revive() -> void:
	set_process(true)

# ..............................................................................

# SIGNALS

func _on_combat_hit_box_mouse_entered() -> void:
	if self in Entities.entities_available:
		Inputs.mouse_in_combat_area = false

func _on_combat_hit_box_mouse_exited() -> void:
	Inputs.mouse_in_combat_area = true
