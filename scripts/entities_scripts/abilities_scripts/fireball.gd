extends CharacterBody2D

@onready var animation_node = $AnimatedSprite2D

func _ready():
    velocity = 50 * (Vector2(1, 1))

func _physics_process(_delta):
    move_and_slide()