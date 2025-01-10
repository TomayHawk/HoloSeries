extends StaticBody2D

var area_active := false

@onready var object_node := get_parent()

func _input(_event):
    if area_active and Input.is_action_just_pressed("interact") and !TextBox.textbox_container.is_visible() and !CombatEntitiesComponent.in_combat:
        object_node.interact_object()

func interaction_area(check_bool):
    area_active = check_bool
