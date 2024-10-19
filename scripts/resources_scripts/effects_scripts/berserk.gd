extends CharacterBody2D

@onready var player_base := get_parent()

# node variables
@onready var player_stats_node := get_node_or_null("PlayerStatsComponent")
@onready var character_specifics_node := get_node_or_null("CharacterSpecifics")
@onready var animation_node := get_node_or_null("CharacterSpecifics/Animation")

# timer nodes
@onready var attack_shape_node := %AttackShape
@onready var attack_cooldown_node := %AttackCooldown
@onready var dash_cooldown_node := %DashCooldown
@onready var knockback_timer_node := %KnockbackTimer
@onready var death_timer_node := %DeathTimer

# speed variables

enum direction_states {UP, DOWN, LEFT, RIGHT, UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT}
enum move_states {IDLE, WALK, DASH, SPRINT, KNOCKBACK}
enum attack_states {READY, ATTACK, WAIT}

var animation_strings := ["up_idle", "down_idle", "left_idle", "right_idle",
                          "up_walk", "down_walk", "left_walk", "right_walk",
                          "up_attack", "down_attack", "left_attack", "right_attack",
                          "death"]
var animation_index := 0

var current_face_direction := direction_states.UP:
    set(next_direction):
        current_face_direction = next_direction
        animation_index = current_face_direction
        if current_attack_state == attack_states.ATTACK: animation_index += 8
        elif current_move_state == move_states.IDLE: animation_index += 4
        elif current_move_state == move_states.KNOCKBACK: animation_index += 4 ## ### need to add knockback animation
        animation_node.play(animation_strings[animation_index])

var current_move_direction := direction_states.UP:
    set(next_direction):
        if current_move_direction == next_direction: return
        current_move_direction = next_direction
        if current_move_direction in [direction_states.UP_LEFT, direction_states.UP_RIGHT]:
            if current_face_direction == direction_states.UP: current_face_direction = direction_states.UP
            elif current_move_direction == direction_states.UP_LEFT: current_face_direction = direction_states.LEFT
            else: current_face_direction = direction_states.RIGHT
        elif current_move_direction in [direction_states.DOWN_LEFT, direction_states.DOWN_RIGHT]:
            if current_face_direction == direction_states.DOWN: current_face_direction = direction_states.DOWN
            elif current_move_direction == direction_states.DOWN_LEFT: current_face_direction = direction_states.LEFT
            else: current_face_direction = direction_states.RIGHT
        else: current_face_direction = current_move_direction

var current_move_vectors := {
    direction_states.UP: Vector2(0, -1),
    direction_states.DOWN: Vector2(0, 1),
    direction_states.LEFT: Vector2(-1, 0),
    direction_states.RIGHT: Vector2(1, 0),
    direction_states.UP_LEFT: Vector2(-1, -1).normalized(),
    direction_states.UP_RIGHT: Vector2(1, -1).normalized(),
    direction_states.DOWN_LEFT: Vector2(-1, 1).normalized(),
    direction_states.DOWN_RIGHT: Vector2(1, 1).normalized()
}

var current_move_state := move_states.IDLE:
    set(next_move_state):
        if current_move_state == next_move_state: return
        current_move_state = next_move_state
        current_face_direction = current_face_direction
        if current_move_state == move_states.DASH:
            dash_cooldown_node.start(dash_time)
            player_stats_node.update_stamina(-dash_stamina_consumption)

var current_attack_state := attack_states.READY:
    set(next_attack_state):
        if current_attack_state == next_attack_state: return
        current_attack_state = next_attack_state
        if current_attack_state == attack_states.ATTACK:
            character_specifics_node.regular_attack()

# movement variables
var walk_speed := 7000.0

var dash_time := 0.2
var dash_speed := 30000.0
var dash_stamina_consumption := 35.0

var sprint_multiplier := 1.25
var sprinting_stamina_consumption := 0.8

var move_direction := Vector2.ZERO
var attack_direction := Vector2.ZERO
var knockback_direction := Vector2.ZERO

var attack_register := ""
var knockback_weight := 0.0

func _ready():
    animation_node.play(animation_strings[0])
    
func _physics_process(delta):
    # movement inputs
    player_base.velocity = Input.get_vector("left", "right", "up", "down") * walk_speed * delta

    if player_base.velocity == Vector2.ZERO: current_move_state = move_states.IDLE

    match current_move_state:
        move_states.IDLE:
            pass
        move_states.WALK:
            pass
        move_states.DASH:
            player_base.velocity += current_move_vectors[current_move_direction] * dash_speed * delta * \
                                    (1 - (dash_time - dash_cooldown_node.get_time_left()) / dash_time)
        move_states.SPRINT:
            if player_stats_node.stamina > 0 && !player_stats_node.stamina_slow_recovery:
                player_stats_node.update_stamina(-sprinting_stamina_consumption)
                player_base.velocity *= sprint_multiplier
            else: current_move_state = move_states.WALK
        move_states.KNOCKBACK:
            player_base.velocity = knockback_direction * 200 * (1 - (0.4 - knockback_timer_node.get_time_left()) / 0.4) * knockback_weight

    if current_attack_state == attack_states.ATTACK: player_base.velocity /= 2

    if attack_register != "" && animation_node.get_frame() == 1: character_specifics_node.call(attack_register)

    player_base.move_and_slide()

func _input(_event):
    if current_move_state != move_states.DASH && Input.is_action_just_pressed("dash"): current_move_state = move_states.DASH
    if current_move_state != move_states.DASH && Input.is_action_just_released("dash"): current_move_state = move_states.DASH

func update_nodes():
    player_stats_node = get_node_or_null("PlayerStatsComponent")
    character_specifics_node = get_node_or_null("CharacterSpecifics")
    animation_node = get_node_or_null("CharacterSpecifics/Animation")

func _on_combat_hit_box_area_input_event(_viewport, _event, _shape_idx):
    if Input.is_action_just_pressed("action"):
        if CombatEntitiesComponent.requesting_entities && self in CombatEntitiesComponent.entities_available && !(self in CombatEntitiesComponent.entities_chosen):
            CombatEntitiesComponent.entities_chosen.push_back(self)
            CombatEntitiesComponent.entities_chosen_count += 1
            if CombatEntitiesComponent.entities_request_count == CombatEntitiesComponent.entities_chosen_count:
                CombatEntitiesComponent.choose_entities()

func _on_interaction_area_body_entered(body):
    # npc can be interacted
    if body.has_method("area_status"):
        body.area_status(true)

func _on_interaction_area_body_exited(body):
    # npc cannot be interacted
    if body.has_method("area_status"):
        body.area_status(false)

func _on_attack_cooldown_timeout():
    current_attack_state = attack_states.READY

func _on_dash_cooldown_timeout():
    if Input.is_action_pressed("dash"): current_move_state = move_states.SPRINT
    else: current_move_state = move_states.WALK

func _on_knockback_timer_timeout():
    if Input.get_vector("left", "right", "up", "down") != Vector2.ZERO: current_move_state = move_states.WALK
    else: current_move_state = move_states.IDLE

func _on_death_timer_timeout():
    animation_node.pause()

func _on_combat_hit_box_area_mouse_entered():
    if CombatEntitiesComponent.requesting_entities:
        GlobalSettings.mouse_in_attack_area = false

func _on_combat_hit_box_area_mouse_exited():
    GlobalSettings.mouse_in_attack_area = true
