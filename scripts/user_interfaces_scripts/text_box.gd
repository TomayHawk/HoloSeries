extends CanvasLayer

@onready var textbox_container := %TextBoxMargin
@onready var end_symbol := %TextEndLabel
@onready var label := %TextAreaLabel

var state_ready := true
var state_end := false
var text_queue: Array[String] = []
var tween

# update nodes and disable text on ready
func _ready():
	textbox_container.hide()
	end_symbol.hide()
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
			end_symbol.show()

func start_text():
	set_process(true)
	GlobalSettings.game_paused = true

	for player_node in GlobalSettings.party_node.get_children():
		player_node.set_physics_process(false)

		#update player animation in case alive and not "idle"
		if player_node.player_stats_node.alive:
			if player_node.last_move_direction.x > 0: player_node.animation_node.play("right_idle")
			elif player_node.last_move_direction.x < 0: player_node.animation_node.play("left_idle")
			elif player_node.last_move_direction.y > 0: player_node.animation_node.play("up_idle")
			else: player_node.animation_node.play("down_idle")
	
	textbox_container.show()

func hide_text():
	textbox_container.hide()
	end_symbol.hide()
	label.text = ""
	for player_node in GlobalSettings.party_node.get_children():
		if player_node.player_stats_node.alive:
			player_node.set_physics_process(true)
	GlobalSettings.game_paused = false
	set_process(false)

# queue text from npcs
func queue_text(next_text):
	text_queue.push_back(next_text)

# display text in queue
func display_text():
	label.text = text_queue.pop_front()
	label.visible_characters = 0
	# start new text animation
	tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, len(label.text) * 0.04)
	state_ready = false
	end_symbol.hide()
	# wait until text ends
	await tween.finished
	state_end = true
	end_symbol.show()
