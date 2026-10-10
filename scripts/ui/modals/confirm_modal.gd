class_name ConfirmModal
extends PanelContainer

signal confirmed(action_id: String)
signal cancelled()

@onready var card: PanelContainer = $Card
@onready var title_label: Label = $Card/VBox/TitleLabel
@onready var message_label: Label = $Card/VBox/MessageLabel
@onready var confirm_btn: Button = $Card/VBox/ButtonGroup/ConfirmButton
@onready var desktop_quit_btn: Button = $Card/VBox/ButtonGroup/DesktopQuitButton
@onready var cancel_btn: Button = $Card/VBox/ButtonGroup/CancelButton

var current_action_id: String = ""

func _ready() -> void:
	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)
	desktop_quit_btn.pressed.connect(_on_desktop_quit)

func open_confirm(
	title: String,
	message: String,
	action_id: String,
	confirm_btn_text: String = "Confirm",
	show_desktop_quit: bool = false
) -> void:
	current_action_id = action_id
	title_label.text = title
	message_label.text = message
	confirm_btn.text = confirm_btn_text

	desktop_quit_btn.visible = show_desktop_quit and not OS.has_feature("web")

	visible = true
	_animate_open()
	cancel_btn.grab_focus()

func _animate_open() -> void:
	if not is_inside_tree():
		return
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_confirm() -> void:
	visible = false
	confirmed.emit(current_action_id)

func _on_cancel() -> void:
	visible = false
	cancelled.emit()

func _on_desktop_quit() -> void:
	visible = false
	get_tree().quit()
