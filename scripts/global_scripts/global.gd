extends Node

# nexus
var nexus_stats_types: Array[Vector2] = []
var nexus_stats_qualities: Array[int] = []

@onready var tree: SceneTree = get_tree()

# ................................................................................

# SCENE CHANGE

func change_scene(next_scene_path: String, next_position: Vector2, camera_limits: Array[int], bgm_path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", next_scene_path)
	
	Entities.reset_entity_request()
	Combat.clear_combat_entities()
	Combat.leave_combat()

	# TODO: Fix flicker
	Players.camera_node.position_smoothing_enabled = false
	Players.main_player_node.position = next_position
	await tree.process_frame
	Players.camera_node.position_smoothing_enabled = true

	for player_node in Players.party_node.get_children():
		if player_node == Players.main_player_node: continue
		player_node.position = next_position + (25 * Vector2(randf_range(-1, 1), randf_range(-1, 1)))

	Players.camera_node.force_zoom(Players.camera_node.target_zoom)
	Players.camera_node.new_limits(camera_limits)

	start_bgm(bgm_path)

# ................................................................................

# GLOBAL UI

func add_global_child(node_name: String, node_path: String) -> void:
	if get_node_or_null(NodePath(node_name)): return
	add_child(load(node_path).instantiate())

func remove_global_child(node_name: String) -> void:
	if not get_node_or_null(NodePath(node_name)): return
	get_node(NodePath(node_name)).queue_free()

# ................................................................................

# BGM

func start_bgm(bgm_path: String) -> void:
	# return if currently playing the same track
	if $BgmPlayer.stream.resource_path == bgm_path:
		return

	# no tweens if no volume (or low volume)
	if AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM")) < -70.0:
		$BgmPlayer.stream = load(bgm_path)
		$BgmPlayer.play()
		return

	# free old bgm player if applicable
	if get_node_or_null(^"OldBgmPlayer"):
		$OldBgmPlayer.queue_free()
		await get_tree().process_frame
	
	# turn down old bgm player
	$BgmPlayer.name = "OldBgmPlayer"
	var tween_1 = $OldBgmPlayer.create_tween()
	tween_1.tween_property(
			$OldBgmPlayer, "volume_db",
			-80.0, 3.0
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

	# initialize new bgm player
	var new_bgm_player = AudioStreamPlayer.new()
	add_child(new_bgm_player)

	new_bgm_player.name = "BgmPlayer"
	$BgmPlayer.stream = load(bgm_path)
	$BgmPlayer.bus = "BGM"
	$BgmPlayer.volume_db = -80.0
	
	$BgmPlayer.play()
	
	# turn up new bgm player
	var tween_2 = $BgmPlayer.create_tween()
	tween_2.tween_property(
			$BgmPlayer, "volume_db",
			AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM")), 4.0
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	# free old bgm player
	await tween_2.finished
	if get_node_or_null(^"OldBgmPlayer"):
		$OldBgmPlayer.queue_free()

# ................................................................................

# SETTINGS

func is_full_screen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func toggle_full_screen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_full_screen() else DisplayServer.WINDOW_MODE_FULLSCREEN)

func set_resolution(x: int, y: int) -> void:
	DisplayServer.window_set_size(Vector2i(x, y))
	
	if not is_full_screen():
		DisplayServer.window_set_position((DisplayServer.screen_get_size() - Vector2i(x, y)) / 2)

func set_master_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func set_music_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), linear_to_db(value))


# TODO: temporary
var temporary_global_variable := {
	"last_nodes": [167, 154, 333, 0, 132],
	"unlocked": [[135, 167, 182], [139, 154, 170], [284, 333, 364], [], [100, 132, 147]],
	"converted": [[[]], [[]], [[]], [[]], [[]]], # [node, type, quality],
}
