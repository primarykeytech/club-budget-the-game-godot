extends Node

var passed_count := 0
var failed_count := 0

func _ready() -> void:
	print("========================================")
	print("Running Club Budget UI Flow Test Suite")
	print("========================================")

	run_test("test_main_scene_instantiation", test_main_scene_instantiation)
	run_test("test_title_to_setup_transition", test_title_to_setup_transition)
	run_test("test_setup_to_gameplay_transition", test_setup_to_gameplay_transition)
	run_test("test_scenario_choice_and_summary_flow", test_scenario_choice_and_summary_flow)
	run_test("test_math_modal_interaction", test_math_modal_interaction)
	run_test("test_game_over_modal_trigger", test_game_over_modal_trigger)
	run_test("test_restart_to_setup_flow", test_restart_to_setup_flow)

	print("========================================")
	print("Results: %d Passed, %d Failed" % [passed_count, failed_count])
	print("========================================")

	if failed_count == 0:
		get_tree().quit(0)
	else:
		get_tree().quit(1)

func run_test(test_name: String, test_callable: Callable) -> void:
	print("[RUN] %s" % test_name)
	var err = test_callable.call()
	if err == null or err == "":
		print("  -> PASS")
		passed_count += 1
	else:
		printerr("  -> FAIL: %s" % str(err))
		failed_count += 1

func _create_game_controller() -> GameController:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var controller: GameController = scene.instantiate()
	add_child(controller)
	return controller

func test_main_scene_instantiation() -> String:
	var controller := _create_game_controller()
	if not is_instance_valid(controller):
		return "Failed to instantiate GameController"
	if not controller.title_screen.visible:
		return "Expected TitleScreen to be visible initially"
	if controller.setup_screen.visible:
		return "Expected SetupScreen to be hidden initially"
	if controller.gameplay_view.visible:
		return "Expected GameplayView to be hidden initially"
	controller.queue_free()
	return ""

func test_title_to_setup_transition() -> String:
	var controller := _create_game_controller()
	controller._on_title_start()
	if controller.title_screen.visible:
		return "Expected TitleScreen to be hidden after start"
	if not controller.setup_screen.visible:
		return "Expected SetupScreen to be visible after start"
	controller.queue_free()
	return ""

func test_setup_to_gameplay_transition() -> String:
	var controller := _create_game_controller()
	controller._on_setup_confirmed("Infinity Math", 350.0, 20, 8)
	if controller.setup_screen.visible:
		return "Expected SetupScreen to be hidden"
	if not controller.gameplay_view.visible:
		return "Expected GameplayView to be visible"
	if controller.state.club_name != "Infinity Math":
		return "Expected club name to match setup"
	if not is_equal_approx(controller.state.budget, 350.0):
		return "Expected budget to match setup"
	if controller.hud.club_name_label.text != "INFINITY MATH":
		return "Expected HUD club name to be formatted in uppercase"
	controller.queue_free()
	return ""

func test_scenario_choice_and_summary_flow() -> String:
	var controller := _create_game_controller()
	controller._on_setup_confirmed("Alpha Club", 300.0, 16, 8)
	if controller.current_scenario == null:
		return "Expected current_scenario to be populated"

	# Simulate picking choice 0
	controller._on_choice_selected(0)

	# If choice had a math challenge, modal should be open
	if controller.pending_choice.math_challenge != null:
		if not controller.math_modal.visible:
			return "Expected MathModal to be visible"
		controller._on_math_resolved(true)

	if not controller.summary_modal.visible:
		return "Expected SummaryModal to be visible after choice resolution"

	# Dismiss summary
	controller._on_summary_dismissed()
	if controller.state.current_week != 2:
		return "Expected current_week to advance to 2, got %d" % controller.state.current_week

	controller.queue_free()
	return ""

func test_math_modal_interaction() -> String:
	var modal: MathModal = load("res://scenes/ui/modals/math_modal.tscn").instantiate()
	add_child(modal)

	var challenge := MathChallenge.new("test", "What is 4 * 4?", 16.0, "$", [12.0, 14.0, 16.0, 18.0], 5, 2.0)
	modal.open_challenge(challenge)

	if not modal.visible:
		return "Expected modal to be visible"
	if modal.options_container.get_child_count() != 4:
		return "Expected 4 option buttons"

	modal._on_option_chosen(16.0)
	if not modal.is_correct:
		return "Expected answer 16.0 to be evaluated as correct"
	if not modal.feedback_panel.visible:
		return "Expected feedback panel to be visible"
	if not modal.continue_btn.visible:
		return "Expected continue button to be visible"

	modal.queue_free()
	return ""

func test_game_over_modal_trigger() -> String:
	var controller := _create_game_controller()
	controller._on_setup_confirmed("Alpha Club", 300.0, 16, 8)

	# Force low morale
	controller.state.happiness["students"] = 35.0
	var loss_status := controller.state.check_immediate_loss()
	if not loss_status["lost"]:
		return "Expected immediate loss condition"

	controller.end_game_modal.open_game_over(loss_status["reason"], controller.state)
	if not controller.end_game_modal.visible:
		return "Expected EndGameModal to be visible on loss"
	if not controller.end_game_modal.title_label.text.contains("SUSPENDED"):
		return "Expected title to indicate season suspension"

	controller.queue_free()
	return ""

func test_restart_to_setup_flow() -> String:
	var controller := _create_game_controller()
	controller._on_setup_confirmed("Alpha Club", 300.0, 16, 8)
	controller._on_restart_requested()

	if controller.gameplay_view.visible:
		return "Expected gameplay view to hide on restart"
	if not controller.setup_screen.visible:
		return "Expected setup screen to show on restart"

	controller.queue_free()
	return ""
