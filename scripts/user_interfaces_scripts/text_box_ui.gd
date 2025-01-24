extends CanvasLayer

enum TextBoxState {
	INACTIVE,
	READY,
	TYPING,
	END,
	WAITING,
}

var text_owner_node: Node = null
var text_queue := []
var text_options := []
var tween

var text_box_state := TextBoxState.INACTIVE:
	set(next_state):
		# ignore same state
		if text_box_state == next_state: return
		if next_state == TextBoxState.READY:
			# end dialogue on empty text queue
			if text_queue.size() == 0:
				clearTextBox()
				text_box_state = TextBoxState.INACTIVE
				CombatEntitiesComponent.toggle_movement(true)
				return
			# start dialogue on hidden text box
			if isInactive():
				CombatEntitiesComponent.toggle_movement(false)
				%TextBoxMargin.show()
			# continue dialogue with animation
			text_box_state = TextBoxState.TYPING
			%TextAreaLabel.text = text_queue.pop_front()
			%TextAreaLabel.visible_characters = 0
			%TextEndLabel.hide()
			tween = create_tween()
			tween.tween_property(%TextAreaLabel, "visible_ratio", 1.0, len(%TextAreaLabel.text) * 0.04)
			# let dialogue finish naturally
			await tween.finished
			next_state = TextBoxState.END
		if next_state == TextBoxState.END:
			# force end dialogue animation
			tween.kill()
			%TextAreaLabel.set_visible_ratio(1.0)
			%TextEndLabel.show()
			text_box_state = TextBoxState.END

			# check for response request
			if text_queue.size() == 0 and text_options.size() != 0:
				requestResponse()
				text_box_state = TextBoxState.WAITING

func _ready():
	# empty text boxes
	clearTextBox()
	clearOptions()

func _input(_event):
	if !isInactive() and Input.is_action_just_pressed("continue"):
		# force end dialogue animation
		if text_box_state == TextBoxState.TYPING:
			text_box_state = TextBoxState.END
		# continue or end dialogue
		elif text_box_state == TextBoxState.END:
			text_box_state = TextBoxState.READY

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
	return text_box_state == TextBoxState.INACTIVE

func npcDialogue(owner_node: Node, text_array: Array[String], options: Array[String]):
	text_owner_node = owner_node
	text_queue = text_array
	text_options = options
	text_box_state = TextBox.TextBoxState.READY

func requestResponse():
	# Hide Text End Symbol
	%TextEndLabel.hide()

	# Connect, Update and Show Each Button
	var option_buttons := [%Option1Button, %Option2Button, %Option3Button, %Option4Button]
	for optionIndex in text_options.size():
		option_buttons[optionIndex].text = text_options[optionIndex]
		option_buttons[optionIndex].show()

	# Show Options Container
	%OptionsMargin.show()

func _on_option_button_pressed(extra_arg_0: int):
	emit_signal("option_selected", extra_arg_0)
	clearOptions()
