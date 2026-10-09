class_name Scenario
extends RefCounted

var id: String = ""
var title: String = ""
var speaker: String = "Coach"
var description: String = ""
var choices: Array[Choice] = []

func _init(
	p_id: String = "",
	p_title: String = "",
	p_speaker: String = "Coach",
	p_description: String = "",
	p_choices: Array[Choice] = []
) -> void:
	id = p_id
	title = p_title
	speaker = p_speaker
	description = p_description
	choices = p_choices
