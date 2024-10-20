extends CanvasLayer

@onready var textbox_container := %TextBoxMargin
@onready var text_area := %TextAreaLabel
@onready var end_symbol := %TextEndLabel

enum Text {INACTIVE, READY, TYPING, END, WAITING}
var text_queue := []
var tween

var current_state := Text.INACTIVE:
	set(next_state):
		# ignore same state, else update state
		if current_state == next_state: return
		current_state = next_state
		if current_state == Text.READY:
			# end dialogue on empty queue
			if text_queue.size() == 0:
				CombatEntitiesComponent.toggle_movement(true)
				current_state = Text.INACTIVE
				textbox_container.hide()
				text_area.text = ""
				end_symbol.hide()
				return
			# start dialogue on hidden text box
			if !textbox_container.visible:
				CombatEntitiesComponent.toggle_movement(false)
				textbox_container.show()
			# continue dialogue with animation
			current_state = Text.TYPING
			text_area.text = text_queue.pop_front()
			text_area.visible_characters = 0
			end_symbol.hide()
			tween = create_tween()
			tween.tween_property(text_area, "visible_ratio", 1.0, len(text_area.text) * 0.04)
			await tween.finished
			current_state = Text.END
		if current_state == Text.END:
			# end current animation and display all text
			tween.kill()
			text_area.set_visible_ratio(1.0)
			end_symbol.show()

func _ready():
	textbox_container.hide()
	end_symbol.hide()
	text_area.text = ""

func _input(_event):
	if current_state != Text.INACTIVE and Input.is_action_just_pressed("continue"):
		if current_state == Text.TYPING: current_state = Text.END
		elif current_state == Text.END: current_state = Text.READY
