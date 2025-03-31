class_name EntityBase extends CharacterBody2D

enum MoveState {
	IDLE,
	WALK,
	DASH,
	SPRINT,
	KNOCKBACK,
}

enum AttackState {
	OUT_OF_RANGE,
	READY,
	ATTACKING,
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
}

const VECTOR_TO_DIRECTION: Dictionary[Vector2, Directions] = {
    Vector2(0.0, -1.0): Directions.UP,
    Vector2(0.0, 1.0): Directions.DOWN,
    Vector2(-1.0, 0.0): Directions.LEFT,
    Vector2(1.0, 0.0): Directions.RIGHT,
	Vector2(-0.70710678, -0.70710678): Directions.UP_LEFT,
    Vector2(0.70710678, -0.70710678): Directions.UP_RIGHT,
    Vector2(-0.70710678, 0.70710678): Directions.DOWN_LEFT,
    Vector2(0.70710678, 0.70710678): Directions.DOWN_RIGHT,
}

# ................................................................................

# STATES

var move_state: MoveState = MoveState.IDLE
var move_direction: Directions = Directions.UP
var attack_state: AttackState = AttackState.READY # TODO: should be OUT_OF_RANGE
var attack_direction: Vector2 = Vector2(1.0, 0.0)

# ................................................................................

func snapped_direction(target_direction: Vector2) -> Vector2:
	if target_direction.y < -0.38268343:
		target_direction = \
				Vector2(-0.70710678, -0.70710678) if target_direction.x < -0.38268343 \
				else Vector2(0.70710678, -0.70710678) if target_direction.x > 0.38268343 \
				else Vector2(0.0, -1.0)
	elif target_direction.y > 0.38268343:
		target_direction = \
				Vector2(-0.70710678, 0.70710678) if target_direction.x < -0.38268343 \
				else Vector2(0.70710678, 0.70710678) if target_direction.x > 0.38268343 \
				else Vector2(0.0, 1.0)
	else:
		target_direction = Vector2(-1.0, 0.0) if target_direction.x < 0 else Vector2(1.0, 0.0)

	return target_direction
