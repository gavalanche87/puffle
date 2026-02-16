extends Node

var saw_stream: AudioStreamMP3
var saw_player: AudioStreamPlayer
var saw_visible_count: int = 0

func _ready() -> void:
	# Initialize the saw sound player
	saw_stream = load("res://assets/sound/saw.mp3")
	if saw_stream:
		saw_stream.loop = true
	
	saw_player = AudioStreamPlayer.new()
	saw_player.stream = saw_stream
	# Set a reasonable volume, maybe -10 dB because mechanical sounds can be loud
	saw_player.volume_db = -10.0
	add_child(saw_player)

func add_saw_on_screen() -> void:
	# Saw SFX temporarily disabled.
	saw_visible_count += 1

func remove_saw_on_screen() -> void:
	saw_visible_count = max(0, saw_visible_count - 1)
	# Saw SFX temporarily disabled.

func _update_saw_sound() -> void:
	# Saw SFX temporarily disabled.
	if saw_player and saw_player.playing:
		saw_player.stop()
