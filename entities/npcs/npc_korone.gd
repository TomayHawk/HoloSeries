extends StaticBody2D

@onready var textbox_node = get_node("/root/WorldScene2/TextBox/")

var area_active = false

func _ready():
	set_process(false)

func _process(_delta):
	if Input.is_action_just_pressed("interact")&&(!textbox_node.textbox_container.is_visible()):
		textbox_node.start_text()
		run_dialogue()

func area_status(check_bool):
	area_active = check_bool
	set_process(area_active)

func run_dialogue():
	textbox_node.queue_text("Never gonna give you up.")
	textbox_node.queue_text("Never gonna let you down.")
	textbox_node.queue_text("Never gonna run around and desert you!")
