extends StaticBody2D

var area_active = false

func _ready():
	set_process(false)

func _process(_delta):
	if Input.is_action_just_pressed("interact")&&(!GlobalSettings.text_box_node.textbox_container.is_visible())&&!GlobalSettings.in_combat:
		GlobalSettings.text_box_node.start_text()
		run_dialogue()

func area_status(check_bool):
	area_active = check_bool
	set_process(area_active)

func run_dialogue():
	GlobalSettings.text_box_node.queue_text("Never gonna give you up.")
	GlobalSettings.text_box_node.queue_text("Never gonna let you down.")
	GlobalSettings.text_box_node.queue_text("Never gonna run around and desert you!")
