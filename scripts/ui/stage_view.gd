class_name StageView
extends PanelContainer

@onready var student_card: PanelContainer = $HBox/StudentCard
@onready var student_mood_label: Label = $HBox/StudentCard/Content/VBox/MoodLabel
@onready var student_avatar: Label = $HBox/StudentCard/Content/VBox/AvatarLabel
@onready var student_badge: Label = $HBox/StudentCard/Content/VBox/NameLabel

@onready var coach_card: PanelContainer = $HBox/CoachCard
@onready var coach_mood_label: Label = $HBox/CoachCard/Content/VBox/MoodLabel
@onready var coach_avatar: Label = $HBox/CoachCard/Content/VBox/AvatarLabel
@onready var coach_badge: Label = $HBox/CoachCard/Content/VBox/NameLabel

@onready var parent_card: PanelContainer = $HBox/ParentCard
@onready var parent_mood_label: Label = $HBox/ParentCard/Content/VBox/MoodLabel
@onready var parent_avatar: Label = $HBox/ParentCard/Content/VBox/AvatarLabel
@onready var parent_badge: Label = $HBox/ParentCard/Content/VBox/NameLabel

func update_stage(speaker: String, happiness_dict: Dictionary) -> void:
	var speaker_clean := speaker.to_lower().strip_edges()

	# Highlight speaking character
	_set_speaker_highlight(student_card, speaker_clean == "student")
	_set_speaker_highlight(coach_card, speaker_clean == "coach")
	_set_speaker_highlight(parent_card, speaker_clean == "parent")

	# Update emotional statuses and avatars
	_update_card_mood(student_mood_label, student_avatar, float(happiness_dict.get("students", 70.0)), ["😃 Thrilled", "🙂 Content", "😟 Worried", "😭 Mutiny"])
	_update_card_mood(coach_mood_label, coach_avatar, float(happiness_dict.get("coaches", 70.0)), ["😄 Confident", "🙂 Engaged", "😓 Burnt Out", "😫 Resigned"])
	_update_card_mood(parent_mood_label, parent_avatar, float(happiness_dict.get("parents", 70.0)), ["😊 Supportive", "🙂 Neutral", "🤨 Concerned", "😡 Boycott"])

func _set_speaker_highlight(card: PanelContainer, is_speaking: bool) -> void:
	if is_speaking:
		card.modulate = Color(1.2, 1.2, 1.0, 1.0) # Subtle glow
		card.scale = Vector2(1.02, 1.02)
	else:
		card.modulate = Color(0.88, 0.88, 0.88, 1.0)
		card.scale = Vector2(1.0, 1.0)

func _update_card_mood(mood_lbl: Label, avatar_lbl: Label, score: float, status_set: Array) -> void:
	if score >= 80.0:
		mood_lbl.text = "EXCELLENT (%d%%)" % int(score)
		mood_lbl.modulate = Color("#10b981") # Green
		avatar_lbl.text = status_set[0]
	elif score >= 50.0:
		mood_lbl.text = "STABLE (%d%%)" % int(score)
		mood_lbl.modulate = Color("#eab308") # Yellow
		avatar_lbl.text = status_set[1]
	elif score >= 40.0:
		mood_lbl.text = "STRAINED (%d%%)" % int(score)
		mood_lbl.modulate = Color("#f97316") # Orange
		avatar_lbl.text = status_set[2]
	else:
		mood_lbl.text = "CRITICAL (%d%%)" % int(score)
		mood_lbl.modulate = Color("#ef4444") # Red
		avatar_lbl.text = status_set[3]
