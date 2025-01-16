extends CanvasLayer

enum Text {INACTIVE, READY, TYPING, END, WAITING}
var text_owner_node: Node = null
var text_owner_reply := ""
var text_queue := []
var tween

var current_state := Text.INACTIVE:
	set(next_state):
		# ignore same state, else update state
		if current_state == next_state: return
		if next_state == Text.READY:
			# end dialogue on empty queue
			if text_queue.size() == 0:
				clearTextBox()
				current_state = Text.INACTIVE
				CombatEntitiesComponent.toggle_movement(true)
				return
			# start dialogue on hidden text box
			if isInactive():
				CombatEntitiesComponent.toggle_movement(false)
				%TextBoxMargin.show()
			# continue dialogue with animation
			current_state = Text.TYPING
			%TextAreaLabel.text = text_queue.pop_front()
			%TextAreaLabel.visible_characters = 0
			%TextEndLabel.hide()
			tween = create_tween()
			tween.tween_property(%TextAreaLabel, "visible_ratio", 1.0, len(%TextAreaLabel.text) * 0.04)
			await tween.finished
			next_state = Text.END
		if next_state == Text.END:
			# end current animation and display all text
			tween.kill()
			%TextAreaLabel.set_visible_ratio(1.0)
			%TextEndLabel.show()
			current_state = Text.END

			if text_queue.size() == 0 and text_owner_reply != "":
				text_owner_node.call_deferred(text_owner_reply)
				current_state = Text.WAITING

func _ready():
	clearTextBox()
	clearOptions()

func _input(_event):
	if !isInactive() and Input.is_action_just_pressed("continue"):
		if current_state == Text.TYPING:
			current_state = Text.END
		elif current_state == Text.END:
			current_state = Text.READY

func clearTextBox():
	%TextBoxMargin.hide()
	%TextAreaLabel.text = ""
	%TextEndLabel.hide()

func clearOptions():
	%OptionsMargin.hide()
	for option_button in [%Option1Button, %Option2Button, %Option3Button, %Option4Button]:
		option_button.text = ""
		option_button.hide()

func isInactive():
	return current_state == Text.INACTIVE

func requestResponse(options, reply_function):
	%TextEndLabel.hide()
	text_owner_reply = reply_function
	var option_buttons := [%Option1Button, %Option2Button, %Option3Button, %Option4Button]
	for optionIndex in options.size():
		option_buttons[optionIndex].text = options[optionIndex]
		option_buttons[optionIndex].show()
	%OptionsMargin.show()

func _on_option_button_pressed(extra_arg_0):
	text_owner_node.call_deferred(text_owner_reply, extra_arg_0)
	clearOptions()
