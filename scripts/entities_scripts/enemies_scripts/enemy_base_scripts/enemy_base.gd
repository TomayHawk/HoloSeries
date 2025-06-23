class_name EnemyBase
extends EntityBase

# CombatHitBox

func _on_combat_hit_box_mouse_entered() -> void:
	if self in Entities.entities_available:
		Inputs.action_inputs_enabled = false
		Inputs.zoom_inputs_enabled = false

func _on_combat_hit_box_mouse_exited() -> void:
	Inputs.action_inputs_enabled = true
	Inputs.zoom_inputs_enabled = true
