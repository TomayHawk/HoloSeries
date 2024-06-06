extends CharacterBody2D

var move_direction = Vector2.ZERO
var speed = 50

var last_node = null # #### set this to default node

var on_node = true
var snap_speed = 200
var snap_node = null
var temp_snap_distance = 0
var snap_distance = 100000
var nodes_on_screen = []

func _onready():
    pass # #### update last_node from global_settings

func _physics_process(_delta):
    move_direction = Input.get_vector("left", "right", "up", "down")
    velocity = move_direction * speed
    if velocity == Vector2.ZERO: snap_to_nearest()
    move_and_slide()

func snap_to_nearest():
    snap_node = null
    snap_distance = 100000

    for i in nodes_on_screen:
        pass