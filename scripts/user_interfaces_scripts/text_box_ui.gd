extends CanvasLayer

@onready var textbox_container := %TextBoxMargin
@onready var text_area := %TextAreaLabel
@onready var end_symbol := %TextEndLabel

enum text_states {INACTIVE, READY, TYPING, END, WAITING}
var text_queue := []
var tween

var current_state := text_states.INACTIVE:
	set(next_state):
		# ignore same state, else update state
		if current_state == next_state: return
		current_state = next_state
		if current_state == text_states.READY:
			# end dialogue on empty queue
			if text_queue.size() == 0:
				CombatEntitiesComponent.toggle_movement(true)
				current_state = text_states.INACTIVE
				textbox_container.hide()
				text_area.text = ""
				end_symbol.hide()
				return
			# start dialogue on hidden text box
			if !textbox_container.visible:
				CombatEntitiesComponent.toggle_movement(false)
				textbox_container.show()
			# continue dialogue with animation
			current_state = text_states.TYPING
			text_area.text = text_queue.pop_front()
			text_area.visible_characters = 0
			end_symbol.hide()
			tween = create_tween()
			tween.tween_property(text_area, "visible_ratio", 1.0, len(text_area.text) * 0.04)
			await tween.finished
			current_state = text_states.END
		if current_state == text_states.END:
			# end current animation and display all text
			tween.kill()
			text_area.set_visible_ratio(1.0)
			end_symbol.show()

func _ready():
	textbox_container.hide()
	end_symbol.hide()
	text_area.text = ""

func _input(_event):
	if current_state != text_states.INACTIVE && Input.is_action_just_pressed("continue"):
		if current_state == text_states.TYPING: current_state = text_states.END
		elif current_state == text_states.END: current_state = text_states.READY
