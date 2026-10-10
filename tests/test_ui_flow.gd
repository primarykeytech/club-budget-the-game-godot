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
	run_test("test_character_names_display", test_character_names_display)
	run_test("test_timer_integration", test_timer_integration)
	run_test("test_hud_restart_button_and_confirmation", test_hud_restart_button_and_confirmation)
	run_test("test_hud_exit_button_and_confirmation", test_hud_exit_button_and_confirmation)
	run_test("test_title_screen_exit_button", test_title_screen_exit_button)

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

func test_character_names_display() -> String:
	var controller := _create_game_controller()
	var student_text := controller.stage_view.student_badge.text
	var coach_text := controller.stage_view.coach_badge.text
	var parent_text := controller.stage_view.parent_badge.text

	if student_text != "Piper (Student)":
		controller.queue_free()
		return "Expected Student badge 'Piper (Student)', got '%s'" % student_text

	if not coach_text.contains("Coach John"):
		controller.queue_free()
		return "Expected Coach badge to contain 'Coach John', got '%s'" % coach_text

	if parent_text != "Ms. Chaidee (Parent)":
		controller.queue_free()
		return "Expected Parent badge 'Ms. Chaidee (Parent)', got '%s'" % parent_text

	controller.queue_free()
	return ""

func test_timer_integration() -> String:
	var controller := _create_game_controller()

	# Verify setup screen has 5 timer presets
	if controller.setup_screen.timer_option.get_item_count() != 5:
		controller.queue_free()
		return "Expected 5 timer options, got %d" % controller.setup_screen.timer_option.get_item_count()

	# Start game with 60-second timer
	controller._on_setup_confirmed("Timer Test Club", 300.0, 16, 8, 60)
	if controller.timer_limit != 60:
		controller.queue_free()
		return "Expected controller timer_limit to be 60, got %d" % controller.timer_limit

	if not controller.scenario_panel.timer_box.visible:
		controller.queue_free()
		return "Expected scenario panel timer box to be visible"

	if controller.scenario_panel.timer_label.text != "60s":
		controller.queue_free()
		return "Expected scenario panel timer label '60s', got '%s'" % controller.scenario_panel.timer_label.text

	# Test math modal with 30s timer
	var challenge := MathChallenge.new("test", "Solve 5 + 5", 10.0, "$", [8.0, 9.0, 10.0, 11.0], 5, 2.0)
	controller.math_modal.open_challenge(challenge, 30)
	if not controller.math_modal.timer_box.visible:
		controller.queue_free()
		return "Expected math modal timer box to be visible"

	if controller.math_modal.timer_label.text != "30s":
		controller.queue_free()
		return "Expected math modal timer label '30s', got '%s'" % controller.math_modal.timer_label.text

	# Trigger timeout
	controller.math_modal._on_time_expired()
	if not controller.math_modal.answered:
		controller.queue_free()
		return "Expected challenge to be marked answered on timeout"
	if controller.math_modal.is_correct:
		controller.queue_free()
		return "Expected challenge to be marked incorrect on timeout"
	if not controller.math_modal.feedback_label.text.contains("Time's Up!"):
		controller.queue_free()
		return "Expected feedback label to announce 'Time's Up!'"

	controller.queue_free()
	return ""

func test_hud_restart_button_and_confirmation() -> String:
	var controller := _create_game_controller()
	controller._on_setup_confirmed("Restart Test Club", 300.0, 16, 8)

	if not controller.hud.restart_btn.visible:
		controller.queue_free()
		return "Expected HUD restart button to be visible"

	if not controller.hud.restart_btn.text.contains("Restart"):
		controller.queue_free()
		return "Expected restart button text to contain 'Restart'"

	# Simulate pressing HUD restart button
	controller.hud.restart_btn.pressed.emit()

	if not controller.confirm_modal.visible:
		controller.queue_free()
		return "Expected ConfirmModal to be visible after clicking Restart"

	if not controller.confirm_modal.title_label.text.contains("Restart"):
		controller.queue_free()
		return "Expected modal title to mention Restart"

	# Confirm restart
	controller.confirm_modal.confirm_btn.pressed.emit()

	if controller.gameplay_view.visible:
		controller.queue_free()
		return "Expected gameplay view to hide after confirming restart"

	if not controller.setup_screen.visible:
		controller.queue_free()
		return "Expected setup screen to show after confirming restart"

	controller.queue_free()
	return ""

func test_hud_exit_button_and_confirmation() -> String:
	var controller := _create_game_controller()
	controller._on_setup_confirmed("Exit Test Club", 300.0, 16, 8)

	if not controller.hud.exit_btn.visible:
		controller.queue_free()
		return "Expected HUD exit button to be visible"

	if not controller.hud.exit_btn.text.contains("Exit"):
		controller.queue_free()
		return "Expected exit button text to contain 'Exit'"

	# Simulate pressing HUD exit button
	controller.hud.exit_btn.pressed.emit()

	if not controller.confirm_modal.visible:
		controller.queue_free()
		return "Expected ConfirmModal to be visible after clicking Exit Game"

	if not controller.confirm_modal.title_label.text.contains("Exit"):
		controller.queue_free()
		return "Expected modal title to mention Exit"

	# Confirm exit to title
	controller.confirm_modal.confirm_btn.pressed.emit()

	if controller.gameplay_view.visible:
		controller.queue_free()
		return "Expected gameplay view to hide after confirming exit"

	if not controller.title_screen.visible:
		controller.queue_free()
		return "Expected title screen to show after confirming exit"

	controller.queue_free()
	return ""

func test_title_screen_exit_button() -> String:
	var controller := _create_game_controller()
	if not controller.title_screen.exit_btn.visible:
		controller.queue_free()
		return "Expected title screen exit button to be visible"

	if not controller.title_screen.exit_btn.text.contains("Exit"):
		controller.queue_free()
		return "Expected title screen exit button text to contain 'Exit'"

	controller.queue_free()
	return ""
