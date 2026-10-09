class_name HUD
extends PanelContainer

@onready var club_name_label: Label = $VBox/TopRow/ClubNameLabel
@onready var week_label: Label = $VBox/TopRow/WeekLabel
@onready var budget_label: Label = $VBox/TopRow/BudgetLabel
@onready var mute_btn: Button = $VBox/TopRow/MuteButton
@onready var burn_rate_label: Label = $VBox/BurnRateLabel

@onready var student_bar: ProgressBar = $VBox/MoraleRow/StudentCol/StudentBar
@onready var student_pct_label: Label = $VBox/MoraleRow/StudentCol/Header/StudentPctLabel

@onready var coach_bar: ProgressBar = $VBox/MoraleRow/CoachCol/CoachBar
@onready var coach_pct_label: Label = $VBox/MoraleRow/CoachCol/Header/CoachPctLabel

@onready var parent_bar: ProgressBar = $VBox/MoraleRow/ParentCol/ParentBar
@onready var parent_pct_label: Label = $VBox/MoraleRow/ParentCol/Header/ParentPctLabel

func _ready() -> void:
	mute_btn.pressed.connect(_on_mute_pressed)
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.mute_toggled.connect(_on_mute_state_changed)
		_update_mute_icon(audio.is_muted)

func _on_mute_pressed() -> void:
	if has_node("/root/AudioManager"):
		var audio = get_node("/root/AudioManager")
		audio.toggle_mute()

func _on_mute_state_changed(is_muted: bool) -> void:
	_update_mute_icon(is_muted)

func _update_mute_icon(is_muted: bool) -> void:
	mute_btn.text = "🔇" if is_muted else "🔊"

func update_hud(state: ClubState, animated: bool = true) -> void:
	club_name_label.text = state.club_name.to_upper()
	week_label.text = "WEEK %02d / %02d" % [state.current_week, state.total_weeks]

	# Budget display with formatting
	budget_label.text = "$%.2f" % state.budget
	if state.budget < 30.0:
		budget_label.modulate = Color("#ef4444") # Red
	elif state.budget < 100.0:
		budget_label.modulate = Color("#f59e0b") # Amber
	else:
		budget_label.modulate = Color("#10b981") # Green

	# Target Burn Rate or Danger Warning
	var min_happiness: float = minf(
		float(state.happiness.get("students", 70.0)),
		minf(float(state.happiness.get("coaches", 70.0)), float(state.happiness.get("parents", 70.0)))
	)

	if min_happiness < 40.0:
		burn_rate_label.text = "⚠️ CRITICAL MORALE DANGER: SCORE < 40% TRIGGERS LOSS!"
		burn_rate_label.modulate = Color("#ef4444")
	elif min_happiness < 48.0:
		burn_rate_label.text = "⚠️ MORALE WARNING: STAKEHOLDER MORALE NEARING DANGER ZONE (< 40%)"
		burn_rate_label.modulate = Color("#f59e0b")
	elif state.budget < 30.0:
		burn_rate_label.text = "⚠️ LOW BUDGET WARNING: AVOID DEFICIT TO PREVENT BANKRUPTCY!"
		burn_rate_label.modulate = Color("#ef4444")
	else:
		var weeks_left: int = maxi(1, state.total_weeks - state.current_week + 1)
		var safe_rate: float = state.budget / float(weeks_left)
		burn_rate_label.text = "Safe Target Burn Rate: ~$%.2f / week (%d weeks remaining)" % [safe_rate, weeks_left]
		burn_rate_label.modulate = Color("#38bdf8") # Light cyan

	# Update Bars
	_update_morale_gauge(student_bar, student_pct_label, float(state.happiness.get("students", 70.0)), animated)
	_update_morale_gauge(coach_bar, coach_pct_label, float(state.happiness.get("coaches", 70.0)), animated)
	_update_morale_gauge(parent_bar, parent_pct_label, float(state.happiness.get("parents", 70.0)), animated)

func _update_morale_gauge(bar: ProgressBar, pct_label: Label, value: float, animated: bool) -> void:
	var clamped_val: float = clampf(value, 0.0, 100.0)
	pct_label.text = "%d%%" % int(clamped_val)

	var target_col: Color
	if clamped_val >= 80.0:
		target_col = Color("#10b981") # Green (Goal target)
	elif clamped_val >= 50.0:
		target_col = Color("#eab308") # Yellow
	elif clamped_val >= 40.0:
		target_col = Color("#f97316") # Orange (Warning)
	else:
		target_col = Color("#ef4444") # Red (Loss danger)

	pct_label.modulate = target_col
	bar.modulate = target_col

	if animated and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(bar, "value", clamped_val, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		bar.value = clamped_val
