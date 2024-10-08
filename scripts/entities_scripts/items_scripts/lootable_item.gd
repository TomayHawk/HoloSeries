extends RigidBody2D

var item_id := 0
var attraction := 1000
var can_leave_attraction := false

var player_nodes: Array[Node] = []
var player_in_range := false

var temp_player_node: Node = null
var temp_distance := INF

func _ready():
    set_physics_process(false)

func _physics_process(delta):
    apply_central_impulse(distance_least() * delta)
    if get_colliding_bodies().size() != 0: loot()

func instantiate_item(texture_path, area_scale, id, attraction_strength, temp_can_leave_attraction):
    %Sprite2D.texture = load(texture_path)
    %Area2D.CollisionShape2D.scale = area_scale
    
    item_id = id
    attraction = attraction_strength
    can_leave_attraction = temp_can_leave_attraction

func distance_least():
    temp_distance = INF
    for player_node in player_nodes:
        if position.distance_to(player_node.position) < temp_distance:
            temp_player_node = player_node
            temp_distance = position.distance_to(player_node.position)
    
    return (temp_player_node.position - position).normalized() * attraction

func loot():
    queue_free()

    # orb script
    get_colliding_bodies()[0].player_stats_node.update_ultimate_gauge(10)

func _on_area_2d_body_entered(body):
    if !player_nodes.has(body):
        player_nodes.push_back(body)

    player_in_range = true
    set_physics_process(true)

func _on_area_2d_body_exited(body):
    if !can_leave_attraction: return

    player_nodes.erase(body)

    if player_nodes.is_empty():
        player_in_range = false
        set_physics_process(false)
