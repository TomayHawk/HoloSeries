class_name PlayerAlly extends PlayerBase

# ally variables
var can_move: bool = true
var can_attack: bool = true
var in_attack_range: bool = false

func _physics_process(_delta: float) -> void:
	character.ally_process()
	move_and_slide()
