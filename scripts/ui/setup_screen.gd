class_name SetupScreen
extends Control

signal setup_confirmed(club_name: String, budget: float, students: int, weeks: int, timer_seconds: int)
signal back_pressed()

@onready var preset_option: OptionButton = $CenterContainer/Card/VBox/FormGrid/PresetOption
@onready var custom_name_input: LineEdit = $CenterContainer/Card/VBox/FormGrid/CustomNameInput

@onready var budget_slider: HSlider = $CenterContainer/Card/VBox/FormGrid/BudgetSlider
@onready var budget_val_label: Label = $CenterContainer/Card/VBox/FormGrid/BudgetValLabel

@onready var students_slider: HSlider = $CenterContainer/Card/VBox/FormGrid/StudentsSlider
@onready var students_val_label: Label = $CenterContainer/Card/VBox/FormGrid/StudentsValLabel

@onready var weeks_slider: HSlider = $CenterContainer/Card/VBox/FormGrid/WeeksSlider
@onready var weeks_val_label: Label = $CenterContainer/Card/VBox/FormGrid/WeeksValLabel

@onready var timer_option: OptionButton = $CenterContainer/Card/VBox/FormGrid/TimerOption

@onready var launch_btn: Button = $CenterContainer/Card/VBox/ButtonGroup/LaunchButton
@onready var back_btn: Button = $CenterContainer/Card/VBox/ButtonGroup/BackButton

const PRESETS := [
	"Mathletes Club",
	"Pi Pioneers",
	"Prime Time Math",
	"Algebra All-Stars",
	"Infinity Wizards",
	"Pythagoras Club"
]

const TIMER_OPTIONS := [
	{"label": "Off (Relaxed)", "seconds": 0},
	{"label": "30 Seconds", "seconds": 30},
	{"label": "60 Seconds", "seconds": 60},
	{"label": "90 Seconds", "seconds": 90},
	{"label": "120 Seconds", "seconds": 120}
]

func _ready() -> void:
	for p in PRESETS:
		preset_option.add_item(p)
	preset_option.add_item("Custom...")

	preset_option.item_selected.connect(_on_preset_selected)
	custom_name_input.text = PRESETS[0]

	for opt in TIMER_OPTIONS:
		timer_option.add_item(opt["label"])
	timer_option.selected = 0

	budget_slider.value_changed.connect(func(v): budget_val_label.text = "$%.0f" % v)
	students_slider.value_changed.connect(func(v): students_val_label.text = "%d Students" % int(v))
	weeks_slider.value_changed.connect(func(v): weeks_val_label.text = "%d Weeks" % int(v))

	launch_btn.pressed.connect(_on_launch)
	back_btn.pressed.connect(func(): back_pressed.emit())

	# Initial values
	budget_val_label.text = "$%.0f" % budget_slider.value
	students_val_label.text = "%d Students" % int(students_slider.value)
	weeks_val_label.text = "%d Weeks" % int(weeks_slider.value)

func _on_preset_selected(index: int) -> void:
	if index < PRESETS.size():
		custom_name_input.text = PRESETS[index]
		custom_name_input.editable = false
	else:
		custom_name_input.text = ""
		custom_name_input.editable = true
		custom_name_input.grab_focus()

func _on_launch() -> void:
	var final_name := custom_name_input.text.strip_edges()
	if final_name.is_empty():
		final_name = "Mathletes Club"

	var timer_idx: int = timer_option.selected
	var timer_seconds: int = TIMER_OPTIONS[timer_idx]["seconds"] if timer_idx >= 0 and timer_idx < TIMER_OPTIONS.size() else 0

	setup_confirmed.emit(
		final_name,
		float(budget_slider.value),
		int(students_slider.value),
		int(weeks_slider.value),
		timer_seconds
	)
