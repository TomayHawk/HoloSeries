extends StaticBody2D

var active := false

@onready var npc_node := get_parent()

func _ready():
    set_process(false)
    npc_node.set_process(false)
    
func _input(_event):
    # if in interactable area, interaction button just pressed, not in a dialogue and not in combat, start dialogue
    if active and Input.is_action_just_pressed(&"interact") and TextBox.isInactive() and Combat.not_in_combat():
        npc_node.initiate_dialogue()

# triggered on npc entering/exiting player interaction area
func interaction_area(status: bool) -> void:
    active = status
