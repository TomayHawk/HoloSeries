extends Node2D

enum NpcState {NEVER_SPOKEN, REGULAR, SHOP_OPEN, SHOP_CLOSED, CAN_RECRUIT}

var npc_state := NpcState.NEVER_SPOKEN

func initiate_dialogue():
	match npc_state:
		NpcState.NEVER_SPOKEN:
			default_dialogue()
		NpcState.SHOP_OPEN:
			pass
		NpcState.SHOP_CLOSED:
			pass
		NpcState.CAN_RECRUIT:
			pass
		_:
			default_dialogue()

func default_dialogue():
	TextBox.text_owner_node = self
	TextBox.text_queue += ["Do you want to recruit me?"]
	TextBox.text_box_state = TextBox.TextBoxState.READY
	TextBox.text_owner_reply = "recruit_question"

func recruit_question():
	TextBox.requestResponse(["Yes", "No", "Hell No"], "recruit_answer")

func recruit_answer(responseIndex):
	const responses := ["Thank You!", "But Why", "????"]
	TextBox.text_queue += [responses[responseIndex]]
	TextBox.text_box_state = TextBox.TextBoxState.READY
	TextBox.text_owner_reply = ""
