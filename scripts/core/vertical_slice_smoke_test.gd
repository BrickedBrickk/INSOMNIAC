extends SceneTree

var _failures: PackedStringArray = []
var _statuses: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_scene.instantiate()
	root.add_child(main)

	await physics_frame
	await physics_frame

	var player: PlayerDesktopRig = main.get_node("Apartment/PlayerDesktopRig")
	var encoder: DreamEncoder = main.get_node("Apartment/DreamEncoder")
	var hud: HUD = main.get_node("HUD")
	var interaction_controller := player.get_interaction_controller()
	var inventory := player.get_inventory()

	encoder.status_changed.connect(_statuses.append)
	for action in [
		InputActions.MOVE_FORWARD,
		InputActions.MOVE_BACK,
		InputActions.MOVE_LEFT,
		InputActions.MOVE_RIGHT,
		InputActions.JUMP,
		InputActions.INTERACT,
		InputActions.CYCLE_RECIPE,
		InputActions.TOGGLE_MOUSE,
	]:
		_expect(InputMap.has_action(action), "Missing input action: %s" % action)

	_expect(inventory.get_item_amount("blank_cartridge") == 3, "Should start with Blank Cartridge x3.")
	_expect(inventory.get_item_amount("beach_fragment") == 2, "Should start with Beach Fragment x2.")
	_expect(inventory.get_item_amount("calm_layer") == 2, "Should start with Calm Layer x2.")
	_expect(inventory.get_item_amount("speed_fragment") == 1, "Should start with Speed Fragment x1.")
	_expect(inventory.get_item_amount("hype_layer") == 1, "Should start with Hype Layer x1.")
	_expect(inventory.get_item_amount("luxury_fragment") == 1, "Should start with Luxury Fragment x1.")
	_expect(inventory.get_item_amount("premium_layer") == 1, "Should start with Premium Layer x1.")
	_expect(hud.inventory_debug.text.contains("Blank Cartridge x3"), "HUD should show starting inventory.")

	_expect(encoder.recipes.size() == 3, "Encoder should have three recipe Resources.")
	_expect(encoder.recipes[0].output_item.id == "beach_loop", "First recipe should output Beach Loop.")
	_expect(encoder.recipes[1].output_item.id == "fast_life", "Second recipe should output Fast Life.")
	_expect(encoder.recipes[2].output_item.id == "penthouse", "Third recipe should output Penthouse.")
	_expect(
		interaction_controller.get_current_prompt() == "Press E: Encode Beach Loop\nPress R: Switch Recipe",
		"Initial raycast should show Beach Loop and the secondary action."
	)
	_expect(hud.machine_panel.visible, "Looking at the encoder should show the machine panel.")
	_expect(hud.machine_panel.machine_name_label.text == "Dream Encoder", "Panel should show the machine name.")
	_expect(hud.machine_panel.recipe_label.text == "Recipe: Beach Loop", "Panel should show Beach Loop.")
	_expect(hud.machine_panel.output_label.text == "Output: Beach Loop", "Panel should show the output item.")
	_expect(hud.machine_panel.stats_label.text.contains("Clarity: 20"), "Panel should show Lucid clarity.")
	_expect(hud.machine_panel.stats_label.text.contains("Value: $25"), "Panel should show Lucid value.")
	_expect(
		hud.machine_panel.ingredients_label.text.contains("Blank Cartridge: 3 / 1"),
		"Panel should show owned and required ingredients."
	)
	_expect(hud.machine_panel.availability_label.text == "Ready to encode", "Panel should show ready state.")
	_expect(not hud.machine_panel.progress_label.visible, "Progress should be hidden while idle.")

	_send_action(interaction_controller, InputActions.CYCLE_RECIPE)
	await physics_frame
	_expect(encoder.get_selected_recipe().display_name == "Fast Life", "First cycle should select Fast Life.")
	_expect(interaction_controller.get_current_prompt().contains("Fast Life"), "Prompt should update to Fast Life.")
	_expect(hud.machine_panel.recipe_label.text == "Recipe: Fast Life", "Panel should update to Fast Life.")
	_expect(hud.machine_panel.stats_label.text.contains("Intensity: 55"), "Fast Life stats should update.")

	_send_action(interaction_controller, InputActions.CYCLE_RECIPE)
	await physics_frame
	_expect(encoder.get_selected_recipe().display_name == "Penthouse", "Second cycle should select Penthouse.")
	_expect(hud.machine_panel.output_label.text == "Output: Penthouse", "Panel should update to Penthouse.")

	_send_action(interaction_controller, InputActions.CYCLE_RECIPE)
	await physics_frame
	_expect(encoder.get_selected_recipe().display_name == "Beach Loop", "Third cycle should wrap to Beach Loop.")

	var start_position := player.global_position
	Input.action_press(InputActions.MOVE_FORWARD)
	for _frame in 10:
		await physics_frame
	Input.action_release(InputActions.MOVE_FORWARD)
	_expect(player.global_position.z < start_position.z, "Move forward should move the player toward -Z.")

	for _frame in 60:
		if player.is_on_floor():
			break
		await physics_frame
	_expect(player.is_on_floor(), "Player should settle onto the apartment floor.")

	player._try_jump()
	_expect(player.velocity.y > 0.0, "Jump should give the player upward velocity.")
	for _frame in 120:
		await physics_frame
		if player.is_on_floor():
			break
	_expect(player.is_on_floor(), "Player should land before encoder panel tests continue.")
	_expect(hud.machine_panel.visible, "Player should reacquire the encoder panel after landing.")

	_send_action(interaction_controller, InputActions.INTERACT)
	_expect(inventory.get_item_amount("blank_cartridge") == 2, "Beach Loop should consume a Blank Cartridge immediately.")
	_expect(inventory.get_item_amount("beach_fragment") == 1, "Beach Loop should consume a Beach Fragment immediately.")
	_expect(inventory.get_item_amount("calm_layer") == 1, "Beach Loop should consume a Calm Layer immediately.")
	_expect(
		hud.machine_panel.ingredients_label.text.contains("Blank Cartridge: 2 / 1"),
		"Panel should update immediately after ingredients are consumed."
	)
	_expect(hud.machine_panel.progress_label.visible, "Progress should appear while encoding.")
	_expect(hud.machine_panel.progress_label.text.begins_with("Encoding:"), "Panel should show encoding progress text.")

	_send_action(interaction_controller, InputActions.INTERACT)
	_expect(_statuses.has("Encoder already running"), "Second interaction should report a running encoder.")

	await create_timer(0.6).timeout
	await physics_frame
	var active_progress := encoder.get_progress_percent()
	var displayed_progress := int(hud.machine_panel.progress_label.text.replace("Encoding: ", "").replace("%", ""))
	_expect(active_progress > 0 and active_progress < 100, "Encoding progress should advance during the wait.")
	_expect(
		displayed_progress > 0 and displayed_progress < 100 and abs(displayed_progress - active_progress) <= 2,
		"Panel should display the current encoding percentage. Displayed: %d, encoder: %d." % [
			displayed_progress,
			active_progress,
		]
	)

	await create_timer(1.6).timeout
	_expect(inventory.get_item_amount("beach_loop") == 1, "First encode should add Beach Loop x1.")
	_expect(hud.inventory_debug.text.contains("Beach Loop x1"), "HUD inventory should update after output is added.")
	_expect(not hud.machine_panel.progress_label.visible, "Progress should hide after encoding finishes.")

	_send_action(interaction_controller, InputActions.INTERACT)
	await create_timer(2.1).timeout
	_expect(inventory.get_item_amount("beach_loop") == 2, "Second encode should stack Beach Loop x2.")
	_expect(inventory.get_item_amount("beach_fragment") == 0, "Second Beach Loop should consume the last Beach Fragment.")
	_expect(inventory.get_item_amount("calm_layer") == 0, "Second Beach Loop should consume the last Calm Layer.")

	_send_action(interaction_controller, InputActions.INTERACT)
	_expect(_statuses.has("Missing ingredients for Beach Loop"), "Beach Loop should stop when ingredients run out.")
	_expect(inventory.get_item_amount("blank_cartridge") == 1, "Failed encode should not consume ingredients.")
	_expect(
		hud.machine_panel.ingredients_label.text.contains("Beach Fragment: 0 / 1 MISSING"),
		"Panel should clearly mark missing ingredients."
	)
	_expect(hud.machine_panel.availability_label.text == "Missing ingredients", "Panel should show missing state.")

	_send_action(interaction_controller, InputActions.CYCLE_RECIPE)
	await physics_frame
	_send_action(interaction_controller, InputActions.INTERACT)
	_expect(inventory.get_item_amount("blank_cartridge") == 0, "Fast Life should consume the final Blank Cartridge.")
	_expect(inventory.get_item_amount("speed_fragment") == 0, "Fast Life should consume Speed Fragment.")
	_expect(inventory.get_item_amount("hype_layer") == 0, "Fast Life should consume Hype Layer.")
	await create_timer(2.1).timeout
	_expect(inventory.get_item_amount("fast_life") == 1, "Fast Life recipe should create Fast Life x1.")

	_send_action(interaction_controller, InputActions.CYCLE_RECIPE)
	await physics_frame
	_send_action(interaction_controller, InputActions.INTERACT)
	_expect(_statuses.has("Missing ingredients for Penthouse"), "Penthouse should report its missing Blank Cartridge.")
	_expect(inventory.get_item_amount("luxury_fragment") == 1, "Failed Penthouse encode should not consume Luxury Fragment.")
	_expect(inventory.get_item_amount("premium_layer") == 1, "Failed Penthouse encode should not consume Premium Layer.")
	_expect(
		hud.machine_panel.ingredients_label.text.contains("Blank Cartridge: 0 / 1 MISSING"),
		"Penthouse panel should mark its missing Blank Cartridge."
	)

	interaction_controller.collision_mask = 0
	await physics_frame
	await physics_frame
	_expect(not hud.machine_panel.visible, "Looking away from the encoder should hide the machine panel.")
	_expect(interaction_controller.get_current_panel_data().is_empty(), "Looking away should clear panel data.")

	if _failures.is_empty():
		print("VERTICAL_SLICE_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("VERTICAL_SLICE_SMOKE_TEST: FAIL")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _send_action(interaction_controller: InteractionController, action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	interaction_controller._unhandled_input(event)
