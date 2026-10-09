class_name MathChallenge
extends RefCounted

var challenge_type: String = "calc"
var prompt: String = ""
var answer: float = 0.0
var unit: String = "$"
var options: Array[float] = []
var bonus_happiness: int = 5
var penalty_cost: float = 0.0

func _init(
	p_type: String = "calc",
	p_prompt: String = "",
	p_answer: float = 0.0,
	p_unit: String = "$",
	p_options: Array[float] = [],
	p_bonus_happiness: int = 5,
	p_penalty_cost: float = 0.0
) -> void:
	challenge_type = p_type
	prompt = p_prompt
	answer = p_answer
	unit = p_unit
	options = p_options
	bonus_happiness = p_bonus_happiness
	penalty_cost = p_penalty_cost
