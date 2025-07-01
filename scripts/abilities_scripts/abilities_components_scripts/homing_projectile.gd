extends Area2D

# ABILITIES COMPONENT: HOMING PROJECTILE

# ..............................................................................

#region VARIABLES

var speed: float = 100.0

var target_entity: EntityBase = null

@onready var ability: Node = get_parent()

#endregion

# ..............................................................................

#region PROCESS

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	# maintain direction if no target
	if not target_entity:
		ability.position += Vector2.RIGHT.rotated(ability.rotation) * speed * delta
		return
	
	var target_position: Vector2 = target_entity.position
	
	# look and move towards target
	ability.look_at(target_position)
	ability.position = ability.position.move_toward(target_position, speed * delta)

#endregion

# ..............................................................................

#region FUNCTIONS

func initiate_homing_projectile(entity: EntityBase, projectile_speed: float) -> void:
	target_entity = entity
	speed = projectile_speed
	
	$CollisionShape2D.disabled = false
	ability.look_at(target_entity.position)
	set_physics_process(true)

func _on_body_exited(body: Node2D) -> void:
	if body == target_entity:
		target_entity = null

#endregion

# ..............................................................................
