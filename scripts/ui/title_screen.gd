class_name TitleScreen
extends Control

signal start_pressed()

@onready var start_btn: Button = $CenterContainer/Card/VBox/StartButton

func _ready() -> void:
	start_btn.pressed.connect(func(): start_pressed.emit())
	start_btn.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		start_pressed.emit()
		get_viewport().set_input_as_handled()
