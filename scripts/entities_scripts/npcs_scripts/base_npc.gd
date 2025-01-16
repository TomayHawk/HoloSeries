extends StaticBody2D

var area_active := false

@onready var npc_node := get_parent()

func _ready():
    set_process(false)
    npc_node.set_process(false)
    
func _input(_event):
    # if in interactable area, interaction button just pressed, not in a dialogue and not in combat, start dialogue
    if area_active and Input.is_action_just_pressed("interact") and TextBox.isInactive() and !CombatEntitiesComponent.in_combat:
        npc_node.default_dialogue()

# triggered on npc entering/exiting player interaction area
func interaction_area(check_bool):
    area_active = check_bool
