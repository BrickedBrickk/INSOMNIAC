extends SceneTree

var _failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	_expect(main_scene != null, "Main scene should load.")
	if main_scene == null:
		_finish()
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	await physics_frame

	var apartment := main.get_node_or_null("Apartment") as Node3D
	var player := main.get_node_or_null("Apartment/PlayerDesktopRig") as PlayerDesktopRig
	var hud := main.get_node_or_null("HUD") as HUD
	_expect(apartment != null, "Apartment should exist in Main.")
	_expect(player != null, "PlayerDesktopRig should exist in the apartment.")
	_expect(hud != null, "HUD should exist in Main.")
	if apartment == null or player == null or hud == null:
		_finish()
		return

	var required_props: PackedStringArray = [
		"ArtBlockout/SleepCorner/DirtyMattress",
		"ArtBlockout/EncoderLab/WorkDesk",
		"ArtBlockout/EncoderLab/SmallServerBox",
		"ArtBlockout/StashAndOrders/StashCrateVisuals",
		"ArtBlockout/RightWallStorage/MetalShelf",
		"ArtBlockout/WallDressing/BlackoutCurtainsLeft",
		"ArtBlockout/WallDressing/BackWallPosters",
		"ArtBlockout/Lighting/CheapCeilingLight",
	]
	for prop_path in required_props:
		_expect(apartment.get_node_or_null(prop_path) != null, "Missing apartment prop: %s" % prop_path)

	var required_machines: PackedStringArray = [
		"DreamEncoder",
		"SellTerminal",
		"SupplyTerminal",
		"StashBox",
		"CustomerOrderBoard",
	]
	for machine_path in required_machines:
		_expect(apartment.get_node_or_null(machine_path) != null, "Missing gameplay machine: %s" % machine_path)

	var art_blockout := apartment.get_node_or_null("ArtBlockout")
	_expect(art_blockout != null, "ArtBlockout hierarchy should exist.")
	if art_blockout != null:
		_expect(
			_find_physics_bodies(art_blockout).is_empty(),
			"Visual art props should not add physics bodies that block the playable aisle."
		)

	var interaction := player.get_interaction_controller()
	var interaction_targets := {
		"DreamEncoder": Vector3(0, 0.9, 2.5),
		"SellTerminal": Vector3(2.2, 0.9, 2.5),
		"SupplyTerminal": Vector3(3.75, 0.9, 2.5),
		"StashBox": Vector3(-2.2, 0.9, 2.5),
		"CustomerOrderBoard": Vector3(-3.75, 0.9, 2.5),
	}
	for target_name in interaction_targets:
		player.position = interaction_targets[target_name]
		await physics_frame
		var target := apartment.get_node(target_name) as Node3D
		interaction.target_position = interaction.to_local(target.global_position)
		interaction.force_raycast_update()
		await physics_frame
		var collider := interaction.get_collider() as Node
		_expect(collider != null and collider.name == target_name, "%s should remain reachable." % target_name)
		_expect(not interaction.get_current_prompt().is_empty(), "%s should retain an interaction prompt." % target_name)
		_expect(hud.machine_panel.visible, "%s should still show the MachinePanel." % target_name)

	player.position = Vector3(0, 0.9, 2.5)
	await physics_frame
	var start_position := player.global_position
	Input.action_press(InputActions.MOVE_FORWARD)
	for _frame in 20:
		await physics_frame
	Input.action_release(InputActions.MOVE_FORWARD)
	_expect(player.global_position.z < start_position.z - 0.5, "Player should move through the central aisle.")

	_finish()


func _find_physics_bodies(node: Node) -> Array[Node]:
	var bodies: Array[Node] = []
	for child in node.get_children():
		if child is PhysicsBody3D:
			bodies.append(child)
		bodies.append_array(_find_physics_bodies(child))
	return bodies


func _finish() -> void:
	if _failures.is_empty():
		print("APARTMENT_ART_BLOCKOUT_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("APARTMENT_ART_BLOCKOUT_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
