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

var state: ClubState = null
var scenario_mgr: ScenarioManager = ScenarioManager.new("res://data/scenarios.json", "res://data/events.json")
var current_scenario: Scenario = null
var pending_choice: Choice = null

func _ready() -> void:

	title_screen.start_pressed.connect(_on_title_start)
	setup_screen.setup_confirmed.connect(_on_setup_confirmed)
	setup_screen.back_pressed.connect(_on_setup_back)

	scenario_panel.choice_selected.connect(_on_choice_selected)
	math_modal.math_resolved.connect(_on_math_resolved)
	event_modal.event_dismissed.connect(_on_event_dismissed)
	summary_modal.summary_dismissed.connect(_on_summary_dismissed)
	end_game_modal.restart_requested.connect(_on_restart_requested)

	_show_title()

func _show_title() -> void:
	title_screen.visible = true
	setup_screen.visible = false
	gameplay_view.visible = false
	_hide_all_modals()

func _on_title_start() -> void:
	title_screen.visible = false
	setup_screen.visible = true

func _on_setup_back() -> void:
	_show_title()

func _on_setup_confirmed(club_name: String, budget: float, students: int, weeks: int) -> void:
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
		var outcome := state.apply_event(event)
		hud.update_hud(state)
		stage_view.update_stage("Coach", state.happiness)

		var loss_check := state.check_immediate_loss()
		if loss_check["lost"]:
			end_game_modal.open_game_over(loss_check["reason"], state)
			return

		event_modal.open_event(event)
	else:
		_load_scenario()

func _on_event_dismissed() -> void:
	_load_scenario()

func _load_scenario() -> void:
	current_scenario = scenario_mgr.get_scenario_for_week(state.current_week, state)
	hud.update_hud(state)
	stage_view.update_stage(current_scenario.speaker, state.happiness)
	scenario_panel.display_scenario(current_scenario)

func _on_choice_selected(index: int) -> void:
	if current_scenario == null or index >= current_scenario.choices.size():
		return

	pending_choice = current_scenario.choices[index]

	if pending_choice.math_challenge != null:
		math_modal.open_challenge(pending_choice.math_challenge)
	else:
		_resolve_choice(null)

func _on_math_resolved(was_correct: bool) -> void:
	_resolve_choice(was_correct)

func _resolve_choice(math_correct: Variant) -> void:
	if pending_choice == null or state == null:
		return

	var outcome := state.apply_choice(pending_choice, math_correct)
	hud.update_hud(state)
	stage_view.update_stage(pending_choice.reaction, state.happiness)

	var loss_check := state.check_immediate_loss()
	if loss_check["lost"]:
		end_game_modal.open_game_over(loss_check["reason"], state)
		return

	summary_modal.open_summary(
		pending_choice.reaction,
		float(outcome["net_cash"]),
		outcome["effects"],
		state.budget
	)

func _on_summary_dismissed() -> void:
	state.advance_week()

	# Check victory or season completion
	if state.is_season_finished():
		var vic_check := state.check_victory()
		if vic_check["won"]:
			end_game_modal.open_victory(vic_check["message"], state)
		else:
			end_game_modal.open_game_over(vic_check["message"], state)
		return

	_start_current_week()

func _on_restart_requested() -> void:
	_hide_all_modals()
	gameplay_view.visible = false
	setup_screen.visible = true

func _hide_all_modals() -> void:
	math_modal.visible = false
	event_modal.visible = false
	summary_modal.visible = false
	end_game_modal.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not gameplay_view.visible:
		return

	# Modal open takes priority
	if math_modal.visible or event_modal.visible or summary_modal.visible or end_game_modal.visible:
		return

	# Keyboard shortcuts 1, 2, 3 for choice selection
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_on_choice_selected(0)
		elif event.keycode == KEY_2:
			_on_choice_selected(1)
		elif event.keycode == KEY_3:
			_on_choice_selected(2)
