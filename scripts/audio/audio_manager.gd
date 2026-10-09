extends Node

signal mute_toggled(is_muted: bool)

var sfx_streams := {
	"select": preload("res://assets/audio/sfx/select.wav"),
	"confirm": preload("res://assets/audio/sfx/confirm.wav"),
	"cash": preload("res://assets/audio/sfx/cash.wav"),
	"alarm": preload("res://assets/audio/sfx/alarm.wav"),
	"correct": preload("res://assets/audio/sfx/correct.wav"),
	"game_over": preload("res://assets/audio/sfx/game_over.wav"),
	"victory": preload("res://assets/audio/sfx/victory.wav"),
}

var music_stream: AudioStream = preload("res://assets/audio/music/theme_music.wav")

var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var is_muted: bool = false

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.stream = music_stream
	# Enable loop on music if supported
	if music_stream is AudioStreamWAV:
		(music_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	add_child(music_player)

	# Auto-start cozy music
	play_music()

func play_sfx(sound_name: String) -> void:
	if is_muted:
		return
	if sfx_streams.has(sound_name):
		# Create a short-lived one-shot player for polyphonic overlapping sounds
		var player := AudioStreamPlayer.new()
		player.stream = sfx_streams[sound_name]
		player.bus = "Master"
		add_child(player)
		player.finished.connect(player.queue_free)
		player.play()

func play_music() -> void:
	if is_muted:
		return
	if not music_player.playing:
		music_player.play()

func stop_music() -> void:
	music_player.stop()

func toggle_mute() -> bool:
	set_muted(not is_muted)
	return is_muted

func set_muted(mute: bool) -> void:
	is_muted = mute
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), is_muted)
	if is_muted:
		music_player.stop()
	else:
		music_player.play()
	mute_toggled.emit(is_muted)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			toggle_mute()
			get_viewport().set_input_as_handled()
