extends CanvasLayer

@onready var textbox_container = $TextBoxContainer
@onready var end_symbol = $TextBoxContainer/MarginContainer/HBoxContainer/TextEnd
@onready var label = $TextBoxContainer/MarginContainer/HBoxContainer/TextArea

@onready var player_anim_node = [null, null, null, null]

var temp_string = ""
var state_ready = true
var state_end = false
var text_queue = []
var tween

# update nodes and disable text on ready
func _ready():
	GlobalSettings.update_nodes()
	for i in GlobalSettings.active_players:
		player_anim_node[i] = GlobalSettings.players[i].get_node("Animation")
	hide_text()
	set_process(false)

func _process(_delta):
	# check for next text
	if state_ready:
		if text_queue.size() > 0: display_text()
		else: hide_text()
	# check for input
	elif Input.is_action_just_pressed("continue"):
		# 
		if state_end:
			state_end = false
			state_ready = true
		else:
			tween.kill()
			label.set_visible_ratio(1.0)
			state_end = true
			end_symbol.text = "v"
			end_symbol.show()

func start_text():
	set_process(true)

	for i in GlobalSettings.active_players:
		GlobalSettings.players[i].set_physics_process(false)

		#update player animation in case alive and not "idle"
		if PartyStatsComponent.alive[i]:
			if GlobalSettings.players[i].last_move_direction.x > 0: player_anim_node[i].play("right_idle")
			elif GlobalSettings.players[i].last_move_direction.x < 0: player_anim_node[i].play("left_idle")
			elif GlobalSettings.players[i].last_move_direction.y > 0: player_anim_node[i].play("front_idle")
			else: player_anim_node[i].play("back_idle")
	
	textbox_container.show()
		
func hide_text():
	textbox_container.hide()
	end_symbol.hide()
	label.text = ""
	for i in GlobalSettings.active_players: if PartyStatsComponent.alive[i]:GlobalSettings.players[i].set_physics_process(true)
	set_process(false)

# queue text from npcs
func queue_text(next_text):
	text_queue.push_back(next_text)

# display text in queue
func display_text():
	label.text = text_queue.pop_front()
	label.visible_characters = 0
	# start new text animation
	tween = get_tree().create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, len(label.text) * 0.04)
	state_ready = false
	# wait until text ends
	await tween.finished
	state_end = true
	end_symbol.show()
