class_name EndGameModal
extends PanelContainer

signal restart_requested()

@onready var icon_label: Label = $Card/VBox/IconLabel
@onready var title_label: Label = $Card/VBox/TitleLabel
@onready var message_label: Label = $Card/VBox/MessageLabel
@onready var stats_label: Label = $Card/VBox/StatsBox/StatsLabel
@onready var restart_btn: Button = $Card/VBox/RestartButton

func _ready() -> void:
	restart_btn.pressed.connect(_on_restart)

func open_game_over(reason: String, state: ClubState) -> void:
	icon_label.text = "🚨"
	title_label.text = "SEASON SUSPENDED"
	title_label.modulate = Color("#ef4444")
	message_label.text = reason

	stats_label.text = "Final Balance: $%.2f\nFinal Morale:\n• Students: %d%%\n• Coaches: %d%%\n• Parents: %d%%\nWeeks Completed: %d of %d" % [
		state.budget,
		int(state.happiness.get("students", 0)),
		int(state.happiness.get("coaches", 0)),
		int(state.happiness.get("parents", 0)),
		state.current_week - 1,
		state.total_weeks
	]

	visible = true
	restart_btn.grab_focus()

func open_victory(msg: String, state: ClubState) -> void:
	icon_label.text = "🏆"
	title_label.text = "GOLD RIBBON SEASON!"
	title_label.modulate = Color("#fbbf24")
	message_label.text = msg

	stats_label.text = "Final Balance: $%.2f\nFinal Morale:\n• Students: %d%%\n• Coaches: %d%%\n• Parents: %d%%\nFull Season Completed: %d Weeks!" % [
		state.budget,
		int(state.happiness.get("students", 0)),
		int(state.happiness.get("coaches", 0)),
		int(state.happiness.get("parents", 0)),
		state.total_weeks
	]

	visible = true
	restart_btn.grab_focus()

func _on_restart() -> void:
	visible = false
	restart_requested.emit()
