class_name ConfettiBurst
extends Node2D

@onready var left_particles: CPUParticles2D = $LeftParticles
@onready var right_particles: CPUParticles2D = $RightParticles

func _ready() -> void:
	burst()

func burst() -> void:
	if left_particles:
		left_particles.restart()
		left_particles.emitting = true
	if right_particles:
		right_particles.restart()
		right_particles.emitting = true

	# Auto-free after particles fade
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(queue_free)
