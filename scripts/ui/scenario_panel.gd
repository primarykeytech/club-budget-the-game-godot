class_name ScenarioPanel
extends PanelContainer

signal choice_selected(index: int)

@onready var title_label: Label = $VBox/Header/HeaderTop/TitleLabel
@onready var timer_box: HBoxContainer = $VBox/Header/HeaderTop/TimerBox
@onready var timer_bar: ProgressBar = $VBox/Header/HeaderTop/TimerBox/TimerBar
@onready var timer_label: Label = $VBox/Header/HeaderTop/TimerBox/TimerLabel
@onready var speaker_label: Label = $VBox/Header/SpeakerLabel
@onready var description_label: Label = $VBox/DescriptionLabel
@onready var choices_container: VBoxContainer = $VBox/ChoicesContainer

var current_scenario: Scenario = null
var time_remaining: float = 0.0
var max_time: float = 0.0
var is_timer_active: bool = false

func _process(delta: float) -> void:
	if not is_timer_active:
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
		choice_selected.emit(0)

func display_scenario(scenario: Scenario, timer_limit: int = 0) -> void:
	current_scenario = scenario
	title_label.text = scenario.title
	speaker_label.text = "%s presents this week's situation:" % scenario.speaker
	description_label.text = scenario.description

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

	# Clear old buttons
	for child in choices_container.get_children():
		child.queue_free()

	for i in range(scenario.choices.size()):
		var choice: Choice = scenario.choices[i]
		var card := _create_choice_card(i, choice)
		choices_container.add_child(card)

func _create_choice_card(index: int, choice: Choice) -> PanelContainer:
	var panel := PanelContainer.new()
	var box_style := StyleBoxFlat.new()
	box_style.set_content_margin_all(8.0)
	box_style.bg_color = Color(0.09, 0.14, 0.22, 0.95)
	box_style.border_color = Color(0.25, 0.35, 0.48, 1.0)
	box_style.set_border_width_all(1)
	box_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", box_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)

	# Main action button
	var btn := Button.new()
	btn.text = choice.text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(func():
		is_timer_active = false
		choice_selected.emit(index)
	)
	hbox.add_child(btn)

	# Optional Math badge indicator
	if choice.math_challenge != null:
		var math_badge := Label.new()
		math_badge.text = "📐 Math Challenge!"
		math_badge.modulate = Color("#38bdf8")
		math_badge.add_theme_font_size_override("font_size", 13)
		hbox.add_child(math_badge)

	return panel
