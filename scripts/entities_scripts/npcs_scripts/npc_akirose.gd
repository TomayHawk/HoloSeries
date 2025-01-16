extends Node2D

func default_dialogue():
	TextBox.text_owner_node = self
	TextBox.text_queue += ["Do you want to recruit me?"]
	TextBox.current_state = TextBox.Text.READY
	TextBox.text_owner_reply = "recruit_question"

func recruit_question():
	TextBox.requestResponse(["Yes", "No", "Hell No"], "recruit_answer")

func recruit_answer(responseIndex):
	const responses := ["Thank You!", "But Why", "????"]
	TextBox.text_queue += [responses[responseIndex]]
	TextBox.current_state = TextBox.Text.READY
	TextBox.text_owner_reply = ""
