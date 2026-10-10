class_name GameController
extends Control

@onready var title_screen: TitleScreen = $TitleScreen
@onready var setup_screen: SetupScreen = $SetupScreen

@onready var gameplay_view: Control = $GameplayView
@onready var hud: HUD = $GameplayView/VBox/HUD
@onready var stage_view: StageView = $GameplayView/VBox/StageView
@onready var scenario_panel: ScenarioPanel = $GameplayView/VBox/ScenarioPanel

@onready var math_modal: MathModal = $Modals/MathModal
@onready var event_modal: EventModal = $Modals/EventModal
@onready var summary_modal: SummaryModal = $Modals/SummaryModal
@onready var end_game_modal: EndGameModal = $Modals/EndGameModal
@onready var confirm_modal: ConfirmModal = $Modals/ConfirmModal

var state: ClubState = null
var scenario_mgr: ScenarioManager = ScenarioManager.new("res://data/scenarios.json", "res://data/events.json")
var current_scenario: Scenario = null
var pending_choice: Choice = null
var timer_limit: int = 0

func _ready() -> void:
	title_screen.start_pressed.connect(_on_title_start)
	title_screen.exit_pressed.connect(_on_title_exit)
	setup_screen.setup_confirmed.connect(_on_setup_confirmed)
	setup_screen.back_pressed.connect(_on_setup_back)

	hud.restart_pressed.connect(_on_hud_restart_pressed)
	hud.exit_pressed.connect(_on_hud_exit_pressed)

	scenario_panel.choice_selected.connect(_on_choice_selected)
	math_modal.math_resolved.connect(_on_math_resolved)
	event_modal.event_dismissed.connect(_on_event_dismissed)
	summary_modal.summary_dismissed.connect(_on_summary_dismissed)
	end_game_modal.restart_requested.connect(_on_restart_requested)
	confirm_modal.confirmed.connect(_on_confirm_action)
	confirm_modal.cancelled.connect(_on_confirm_cancelled)

	_show_title()

func _play_sfx(sound_name: String) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx(sound_name)

func _show_title() -> void:
	title_screen.visible = true
	setup_screen.visible = false
	gameplay_view.visible = false
	_hide_all_modals()

func _on_title_start() -> void:
	_play_sfx("confirm")
	title_screen.visible = false
	setup_screen.visible = true

func _on_setup_back() -> void:
	_play_sfx("select")
	_show_title()

func _on_setup_confirmed(club_name: String, budget: float, students: int, weeks: int, timer_seconds: int = 0) -> void:
	_play_sfx("confirm")
	timer_limit = timer_seconds
	state = ClubState.new(club_name, budget, students, weeks, 72.0)
	scenario_mgr.start_season(weeks, true)

	setup_screen.visible = false
	gameplay_view.visible = true
	_hide_all_modals()

	_start_current_week()

func _start_current_week() -> void:
	hud.update_hud(state)
	stage_view.update_stage("Coach", state.happiness)

	# Check for random unexpected event (weeks 3, 6, 9...)
	var event: GameEvent = scenario_mgr.get_event_if_triggered(state.current_week, state)
	if event != null:
		_play_sfx("alarm")
		var outcome := state.apply_event(event)
		hud.update_hud(state)
		stage_view.update_stage("Coach", state.happiness)
		stage_view.show_morale_deltas(outcome["effects"])

		var loss_check := state.check_immediate_loss()
		if loss_check["lost"]:
			_play_sfx("game_over")
			_shake_gameplay_view(12.0)
			end_game_modal.open_game_over(loss_check["reason"], state)
			return

		event_modal.open_event(event)
	else:
		_load_scenario()

func _on_event_dismissed() -> void:
	_play_sfx("select")
	_load_scenario()

func _load_scenario() -> void:
	current_scenario = scenario_mgr.get_scenario_for_week(state.current_week, state)
	hud.update_hud(state)
	stage_view.update_stage(current_scenario.speaker, state.happiness)
	scenario_panel.display_scenario(current_scenario, timer_limit)

func _on_choice_selected(index: int) -> void:
	if current_scenario == null or index >= current_scenario.choices.size():
		return

	_play_sfx("select")
	pending_choice = current_scenario.choices[index]

	if pending_choice.math_challenge != null:
		math_modal.open_challenge(pending_choice.math_challenge, timer_limit)
	else:
		_resolve_choice(null)

func _on_math_resolved(was_correct: bool) -> void:
	if was_correct:
		_play_sfx("correct")
	else:
		_play_sfx("alarm")
		_shake_gameplay_view(5.0)
	_resolve_choice(was_correct)

func _resolve_choice(math_correct: Variant) -> void:
	if pending_choice == null or state == null:
		return

	var outcome := state.apply_choice(pending_choice, math_correct)
	var net_cash: float = float(outcome["net_cash"])
	if net_cash > 0.0:
		_play_sfx("cash")
	elif net_cash < 0.0:
		_play_sfx("select")

	hud.update_hud(state)
	stage_view.update_stage(pending_choice.reaction, state.happiness)
	stage_view.show_morale_deltas(outcome["effects"])

	var loss_check := state.check_immediate_loss()
	if loss_check["lost"]:
		_play_sfx("game_over")
		_shake_gameplay_view(12.0)
		end_game_modal.open_game_over(loss_check["reason"], state)
		return

	summary_modal.open_summary(
		pending_choice.reaction,
		net_cash,
		outcome["effects"],
		state.budget
	)

func _on_summary_dismissed() -> void:
	_play_sfx("select")
	state.advance_week()

	# Check victory or season completion
	if state.is_season_finished():
		var vic_check := state.check_victory()
		if vic_check["won"]:
			_play_sfx("victory")
			end_game_modal.open_victory(vic_check["message"], state)
		else:
			_play_sfx("game_over")
			end_game_modal.open_game_over(vic_check["message"], state)
		return

	_start_current_week()

func _on_restart_requested() -> void:
	_play_sfx("confirm")
	_hide_all_modals()
	gameplay_view.visible = false
	setup_screen.visible = true

func _on_title_exit() -> void:
	_play_sfx("select")
	get_tree().quit()

func _on_hud_restart_pressed() -> void:
	_play_sfx("select")
	confirm_modal.open_confirm(
		"Restart Season?",
		"Are you sure you want to abandon the current season and return to club setup?\nAll progress in this season will be reset.",
		"restart",
		"Restart Season"
	)

func _on_hud_exit_pressed() -> void:
	_play_sfx("select")
	confirm_modal.open_confirm(
		"Exit Game?",
		"Are you sure you want to exit the current season?\nUnsaved progress will be lost.",
		"exit_to_title",
		"Exit to Title",
		true
	)

func _on_confirm_action(action_id: String) -> void:
	_play_sfx("confirm")
	if action_id == "restart":
		_on_restart_requested()
	elif action_id == "exit_to_title":
		_show_title()

func _on_confirm_cancelled() -> void:
	_play_sfx("select")

func _hide_all_modals() -> void:
	math_modal.visible = false
	event_modal.visible = false
	summary_modal.visible = false
	end_game_modal.visible = false
	confirm_modal.visible = false

func _shake_gameplay_view(intensity: float = 6.0) -> void:
	if not is_inside_tree() or not gameplay_view:
		return
	var orig_pos: Vector2 = gameplay_view.position
	var tween := create_tween()
	for i in range(4):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(gameplay_view, "position", orig_pos + offset, 0.04)
	tween.tween_property(gameplay_view, "position", orig_pos, 0.04)

func _unhandled_input(event: InputEvent) -> void:
	# Global Fullscreen toggle (F11 or F)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or event.keycode == KEY_F:
			var mode := DisplayServer.window_get_mode()
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			get_viewport().set_input_as_handled()
			return

	if not gameplay_view.visible:
		return

	# Modal open takes priority
	if confirm_modal.visible:
		if event.is_action_pressed("ui_cancel"):
			confirm_modal._on_cancel()
			get_viewport().set_input_as_handled()
		return

	if math_modal.visible or event_modal.visible or summary_modal.visible or end_game_modal.visible:
		return

	# ESC key brings up exit confirmation during gameplay
	if event.is_action_pressed("ui_cancel"):
		_on_hud_exit_pressed()
		get_viewport().set_input_as_handled()
		return

	# Keyboard shortcuts 1, 2, 3 for choice selection, R for restart
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_on_hud_restart_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			_on_choice_selected(0)
		elif event.keycode == KEY_2:
			_on_choice_selected(1)
		elif event.keycode == KEY_3:
			_on_choice_selected(2)
