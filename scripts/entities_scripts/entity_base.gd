class_name EntityBase extends CharacterBody2D

# ..............................................................................

# SIGNALS

signal knockback_timeout()
signal dash_timeout()

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
var process_interval: float = 0.0
var knockback_timer: float = 0.0
var dash_timer: float = 0.0

# AI VARIABLES

var can_move: bool = true
var can_attack: bool = true
var in_attack_range: bool = false
var action_queue: Array[Array] = []

# ..............................................................................

# PROCESS

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	process_interval += delta

	if process_interval > 0.1:
		# regenerate mana
		if stats.mana < stats.max_mana:
			stats.update_mana(0.025)

		# regenerate stamina
		if move_state != MoveState.DASH and move_state != MoveState.SPRINT and stats.stamina < stats.max_stamina:
			stats.update_stamina(1.5 if stats.fatigue else 3.0)
		
		# decrease effects timers
		for effect in stats.effects.duplicate():
			effect.effect_timer -= process_interval
			if effect.effect_timer <= 0.0:
				effect.effect_timeout(stats)

		# decrease knockback timer
		if knockback_timer > 0.0:
			knockback_timer -= process_interval
			if knockback_timer < 0.0:
				emit_signal(&"knockback_timeout")
		
		# decrease dash timer
		if dash_timer > 0.0:
			dash_timer -= process_interval
			if dash_timer < 0.0:
				emit_signal(&"dash_timeout")
		
		process_interval = 0.0

# ..............................................................................

# UNIVERSAL METHODS

func trigger_death() -> void:
	pass

# ..............................................................................

# UNIVERSAL SIGNALS

# TODO: need to add signal connections
func _on_combat_hit_box_mouse_entered() -> void:
	# TODO: need to implement/fix this
	# TODO: need to remove chosen entities from available
	if self in Entities.entities_available:
		Inputs.mouse_in_attack_range = false

func _on_combat_hit_box_mouse_exited() -> void:
	Inputs.mouse_in_attack_range = true
