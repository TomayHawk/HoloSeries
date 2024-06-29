extends CharacterBody2D

# node variables
@onready var combat_UI_node = GlobalSettings.combat_UI_node
@onready var current_player_node = GlobalSettings.players[GlobalSettings.current_main_player]

# speed variables
var speed = 200
var dash_speed = 500
var sprint_multiplier = 1.5

# player node information variables
var player_index = 0
var current_main = false

# player movement variables

# dash and sprint variables
var dash_ready = true
var sprinting = false

# ally movement variables

# combat variables
var attack_direction = Vector2.ZERO

# player combat variables
var player_attack_ready = true

# ally combat variables
var ally_attack_ready = true
var ally_target_enemy = null

func _ready():
	pass

func _physics_process(delta):
	pass

func _on_combat_hit_box_area_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	pass # Replace with function body.

func _on_entities_detection_area_body_exited(body: Node2D):
	pass # Replace with function body.

func _on_inner_entities_detection_area_body_exited(body: Node2D):
	pass # Replace with function body.

func _on_inner_entities_detection_area_body_entered(body: Node2D):
	pass # Replace with function body.

func _on_interaction_area_body_entered(body: Node2D):
	pass # Replace with function body.

func _on_interaction_area_body_exited(body: Node2D):
	pass # Replace with function body.

func _on_attack_cooldown_timeout():
	pass # Replace with function body.

func _on_dash_cooldown_timeout():
	pass # Replace with function body.

func _on_ally_attack_cooldown_timeout():
	pass # Replace with function body.

func _on_ally_direction_cooldown_timeout():
	pass # Replace with function body.

func _on_ally_pause_timer_timeout():
	pass # Replace with function body.