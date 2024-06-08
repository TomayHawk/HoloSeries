extends CharacterBody2D

@export var speed = 100

var spawn_direction = 0.0
var spawn = Vector2.ZERO
var spawn_rotation = 0.0

func _ready():
    position = spawn
    rotation = spawn_rotation

func _physics_process(_delta):
    velocity = Vector2(0, speed).rotated(spawn_direction)
    move_and_slide()