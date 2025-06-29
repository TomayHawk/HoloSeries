extends Node

# GLOBAL MANAGER

# ..............................................................................

#region SIGNALS

signal new_scene_ready

#endregion

# ..............................................................................

#region VARIABLES

# NEXUS VARIABLES

# -1: null
# 0: empty
# 1-8: HP, MP, DEF, WRD, STR, INT, SPD, AGI
# 9-11: special, white magic, black magic
# 12-15: diamond, clover, heart, spade
var nexus_types: Array[int] = []

# -1 for all non-stats nodes
var nexus_qualities: Array[int] = []

#endregion

# ..............................................................................

#region SCENE CHANGE

func change_scene(next_scene_path: String, next_position: Vector2, camera_limits: Array[int], bgm_path: String) -> void:
	# disable inputs
	Inputs.action_inputs_enabled = false
	Inputs.world_inputs_enabled = false
	Inputs.zoom_inputs_enabled = false
	
	# disable camera smoothing
	Players.camera.position_smoothing_enabled = false

	# start black screen
	await Players.camera.toggle_black_screen(true)

	# disable players
	Players.toggle_process(false)

	# reparent players and main camera to self
	Players.reparent.call_deferred(self)

	# change scene
	get_tree().change_scene_to_file.call_deferred(next_scene_path)

	# wait for scene to load
	await new_scene_ready

	# update bgm
	start_bgm(bgm_path)

	# reparent players to the new scene
	Players.reparent(get_tree().current_scene)

	# reposition players and update camera
	for player_node in Players.get_children():
		if player_node.is_main_player:
			player_node.position = next_position
			Players.camera.force_zoom(Players.camera.target_zoom)
			Players.camera.update_camera_limits(camera_limits)
		else:
			player_node.ally_teleport(next_position)

	# reset world objects and values
	Entities.end_entities_request()
	Combat.clear_combat_entities()
	Combat.leave_combat()

	# move Inputs to the bottom of the tree
	get_tree().root.move_child(Inputs, -1)

	# await 2 frames to ensure everything is loaded
	await get_tree().process_frame
	await get_tree().process_frame

	# enable players
	Players.toggle_process(true)

	# end black screen
	Players.camera.toggle_black_screen(false)

	# enable camera smoothing
	Players.camera.position_smoothing_enabled = true

	# enable inputs
	Inputs.action_inputs_enabled = true
	Inputs.world_inputs_enabled = true
	Inputs.zoom_inputs_enabled = true

#endregion

# ..............................................................................

#region GLOBAL UI

func add_global_child(node_name: String, node_path: String) -> void:
	if get_node_or_null(NodePath(node_name)): return
	add_child(load(node_path).instantiate())

func remove_global_child(node_name: String) -> void:
	if not get_node_or_null(NodePath(node_name)): return
	get_node(NodePath(node_name)).queue_free()

#endregion

# ..............................................................................

#region BGM

func start_bgm(bgm_path: String) -> void:
	# return if currently playing the same track
	if $BgmPlayer.stream.resource_path == bgm_path:
		return

	# free old bgm player if applicable
	if get_node_or_null(^"OldBgmPlayer"):
		$OldBgmPlayer.queue_free()
		await $OldBgmPlayer.tree_exited

	# no tweens if no volume (or low volume)
	if AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"BGM")) < -70.0:
		$BgmPlayer.stream = load(bgm_path)
		$BgmPlayer.play()
		return
	
	# turn down old bgm player
	$BgmPlayer.name = "OldBgmPlayer"
	var tween_1 = $OldBgmPlayer.create_tween()
	tween_1.tween_property($OldBgmPlayer, "volume_db", -80.0, 3.0) \
			.set_trans(Tween.TRANS_LINEAR) \
			.set_ease(Tween.EASE_OUT)

	# initialize new bgm player
	var new_bgm_player = AudioStreamPlayer.new()
	add_child(new_bgm_player)

	new_bgm_player.name = "BgmPlayer"
	$BgmPlayer.stream = load(bgm_path)
	$BgmPlayer.bus = "BGM"
	$BgmPlayer.volume_db = -80.0
	
	$BgmPlayer.play()
	
	# turn up new bgm player
	$BgmPlayer.create_tween().tween_property($BgmPlayer, "volume_db",
			AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"BGM")), 4.0) \
			.set_trans(Tween.TRANS_EXPO) \
			.set_ease(Tween.EASE_OUT)

	# free old bgm player
	await tween_1.finished
	if get_node_or_null(^"OldBgmPlayer"):
		$OldBgmPlayer.queue_free()

#endregion

# ..............................................................................
