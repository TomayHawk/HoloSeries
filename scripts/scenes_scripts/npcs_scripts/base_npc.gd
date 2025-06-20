extends StaticBody2D

@onready var npc_node := get_parent()

func _ready() -> void:
    set_process_input(false)
    
func _input(event: InputEvent) -> void:
    if (
            Input.is_action_just_pressed(&"interact") # interaction button pressed
            and TextBox.isInactive() # text box is inactive
            and Combat.not_in_combat() # not in combat
            and Inputs.world_inputs_enabled # world inputs are enabled
            and event.is_action(&"interact") # event is an interaction event
            
    ):
        Inputs.accept_event()
        npc_node.initiate_dialogue()

# triggered on npc entering/exiting player interaction area
func interaction_area(status: bool) -> void:
    set_process_input(status)
