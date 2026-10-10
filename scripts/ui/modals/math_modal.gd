class_name MathModal
extends PanelContainer

signal math_resolved(was_correct: bool)

@onready var card: PanelContainer = $Card
@onready var timer_box: HBoxContainer = $Card/VBox/TimerBox
@onready var timer_bar: ProgressBar = $Card/VBox/TimerBox/TimerBar
@onready var timer_label: Label = $Card/VBox/TimerBox/TimerLabel
@onready var prompt_label: Label = $Card/VBox/PromptLabel
@onready var options_container: VBoxContainer = $Card/VBox/OptionsContainer
@onready var feedback_panel: PanelContainer = $Card/VBox/FeedbackPanel
@onready var feedback_label: Label = $Card/VBox/FeedbackPanel/FeedbackLabel
@onready var continue_btn: Button = $Card/VBox/ContinueButton

var confetti_scene: PackedScene = preload("res://scenes/ui/effects/confetti_burst.tscn")
var current_challenge: MathChallenge = null
var answered: bool = false
var is_correct: bool = false
var time_remaining: float = 0.0
var max_time: float = 0.0
var is_timer_active: bool = false

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue_pressed)

func _process(delta: float) -> void:
	if not is_timer_active or answered:
		return

	time_remaining -= delta
	timer_bar.value = maxf(0.0, time_remaining)
	var secs := int(ceilf(maxf(0.0, time_remaining)))
	timer_label.text = "%ds" % secs

	if time_remaining <= 5.0:
		timer_label.modulate = Color("#ef4444")
	else:
		timer_label.modulate = Color("#facc15")

	if time_remaining <= 0.0:
		is_timer_active = false
		_on_time_expired()

func open_challenge(challenge: MathChallenge, timer_limit: int = 0) -> void:
	current_challenge = challenge
	answered = false
	is_correct = false
	prompt_label.text = challenge.prompt
	feedback_panel.visible = false
	continue_btn.visible = false

	if timer_limit > 0:
		max_time = float(timer_limit)
		time_remaining = max_time
		timer_bar.max_value = max_time
		timer_bar.value = max_time
		timer_label.text = "%ds" % timer_limit
		timer_label.modulate = Color("#facc15")
		timer_box.visible = true
		is_timer_active = true
	else:
		timer_box.visible = false
		is_timer_active = false

	# Clear old options
	for child in options_container.get_children():
		child.queue_free()

	for opt_val in challenge.options:
		var btn := Button.new()
		var unit := challenge.unit
		if unit == "$":
			btn.text = "$%.2f" % opt_val
		else:
			btn.text = "%.2f %s" % [opt_val, unit]
		btn.custom_minimum_size = Vector2(0, 42)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var captured_val: float = opt_val
		btn.pressed.connect(func(): _on_option_chosen(captured_val))
		options_container.add_child(btn)

	visible = true
	_animate_open()

func _animate_open() -> void:
	if not is_inside_tree():
		return
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_time_expired() -> void:
	if answered:
		return
	answered = true
	is_correct = false

	for child in options_container.get_children():
		if child is Button:
			child.disabled = true

	feedback_panel.visible = true
	var style: StyleBoxFlat = feedback_panel.get_theme_stylebox("panel").duplicate()
	style.bg_color = Color(0.40, 0.12, 0.12, 0.95)
	style.border_color = Color("#ef4444")
	var penalty_str := ""
	if current_challenge.penalty_cost > 0:
		penalty_str = " (Administrative penalty: -$%.2f)" % current_challenge.penalty_cost
	feedback_label.text = "⏰ Time's Up!\nYou ran out of time to solve the challenge.\nThe correct answer was %s%.2f.%s\nStakeholder morale suffered a slight dip." % [
		current_challenge.unit, current_challenge.answer, penalty_str
	]
	feedback_panel.add_theme_stylebox_override("panel", style)

	continue_btn.visible = true
	continue_btn.grab_focus()

func _on_option_chosen(chosen_val: float) -> void:
	if answered:
		return
	answered = true
	is_timer_active = false
	is_correct = is_equal_approx(chosen_val, current_challenge.answer)

	# Disable all option buttons
	for child in options_container.get_children():
		if child is Button:
			child.disabled = true

	# Display Feedback
	feedback_panel.visible = true
	var style: StyleBoxFlat = feedback_panel.get_theme_stylebox("panel").duplicate()
	if is_correct:
		style.bg_color = Color(0.06, 0.35, 0.20, 0.95)
		style.border_color = Color("#10b981")
		feedback_label.text = "🎉 Correct! (%s%.2f)\nEarned +%d Bonus Happiness across stakeholders!" % [
			current_challenge.unit, current_challenge.answer, current_challenge.bonus_happiness
		]
		# Spawn celebratory confetti
		var confetti = confetti_scene.instantiate()
		add_child(confetti)
	else:
		style.bg_color = Color(0.40, 0.12, 0.12, 0.95)
		style.border_color = Color("#ef4444")
		var penalty_str := ""
		if current_challenge.penalty_cost > 0:
			penalty_str = " (Administrative penalty: -$%.2f)" % current_challenge.penalty_cost
		feedback_label.text = "❌ Incorrect!\nThe correct answer was %s%.2f.%s\nStakeholder morale suffered a slight dip." % [
			current_challenge.unit, current_challenge.answer, penalty_str
		]
	feedback_panel.add_theme_stylebox_override("panel", style)

	continue_btn.visible = true
	continue_btn.grab_focus()

func _on_continue_pressed() -> void:
	visible = false
	math_resolved.emit(is_correct)
