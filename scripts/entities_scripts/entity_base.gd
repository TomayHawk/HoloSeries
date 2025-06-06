class_name EntityBase extends CharacterBody2D

signal knockback_timeout()
signal dash_timeout()

enum MoveState {
	IDLE,
	WALK,
	DASH,
	SPRINT,
	KNOCKBACK,
	STUN,
}

enum AttackState {
	READY,
	ATTACK,
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

# ................................................................................

# VARIABLES

var stats: EntityStats = null
var process_interval: float = 0.0

# STATES

var move_state: MoveState = MoveState.IDLE
var attack_state: AttackState = AttackState.READY
var move_direction: Directions = Directions.DOWN
var attack_vector: Vector2 = Vector2.RIGHT

# KNOCKBACK

var knockback_velocity: Vector2 = Vector2.LEFT
var knockback_timer: float = 0.0

# DASH
var dash_timer: float = 0.0

# ................................................................................

# PROCESS

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
