extends StaticBody2D

@onready var text_box_node := GlobalSettings.text_box_node

var area_active := false

func _ready():
	set_process(false)

func _input(_event):
	# if in interactable area, interaction button just pressed, not in a dialogue and not in combat, start dialogue
	if area_active && Input.is_action_just_pressed("interact") && !text_box_node.textbox_container.is_visible() && !CombatEntitiesComponent.in_combat:
		text_box_node.text_queue += ["Never gonna give you up.",
									 "Never gonna let you down.",
									 "Never gonna run around and desert you!"]
		text_box_node.current_state = text_box_node.text_states.READY

# triggered on npc entering/exiting player interaction area
func area_status(check_bool):
	area_active = check_bool
