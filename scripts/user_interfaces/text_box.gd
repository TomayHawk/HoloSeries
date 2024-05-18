extends CanvasLayer

@onready var textbox_container = $TextboxContainer
@onready var end_symbol = $TextboxContainer/MarginContainer/HBoxContainer/TextEnd
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/TextArea

@onready var player_anim_node = [null, null, null, null]

var temp_string = ""
var state_ready = true
var state_end = false
var text_queue = []
var tween

func _ready():
	GlobalSettings.update_players()
	for i in GlobalSettings.active_players:
		player_anim_node[i] = GlobalSettings.players[i].get_node("Animation")
	hide_text()

func _process(_delta):
	if state_ready:
		if text_queue.size() > 0: display_text()
		else: hide_text()
	elif state_end&&Input.is_action_just_pressed("continue"):
		state_end = false
		state_ready = true
	elif Input.is_action_just_pressed("continue"):
		tween.kill()
		label.set_visible_ratio(1.0)
		state_end = true
		end_symbol.text = "v"
		end_symbol.show()

func start_text():
	set_process(true)
	for i in GlobalSettings.active_players:
		GlobalSettings.players[i].set_physics_process(false)
	textbox_container.show()

func hide_text():
	textbox_container.hide()
	end_symbol.hide()
	label.text = ""
	for i in GlobalSettings.active_players:
		GlobalSettings.players[i].set_physics_process(true)
	set_process(false)

func queue_text(next_text):
	text_queue.push_back(next_text)

#display text in queue
func display_text():
	label.text = text_queue.pop_front()
	label.visible_characters = 0
	#update player animation in case not "idle"
	for i in GlobalSettings.active_players:
		if GlobalSettings.players[i].last_input_direction.x != 0:
			player_anim_node[i].play("side_idle")
			player_anim_node[i].flip_h = GlobalSettings.players[i].last_input_direction.x < 0
		elif GlobalSettings.players[i].last_input_direction.y > 0:
			player_anim_node[i].play("front_idle")
		else:
			player_anim_node[i].play("back_idle")
	#start new text animation
	tween = get_tree().create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, len(label.text) * 0.04)
	state_ready = false
	#wait until text ends
	await tween.finished
	end_symbol.show()
