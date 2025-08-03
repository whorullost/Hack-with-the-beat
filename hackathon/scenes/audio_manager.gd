extends Node2D
@onready var beat_player = $AudioStreamPlayer
@onready var stop_timer = $Timer

var playback_pos := 0.0
var segment_duration := 0.5

func _ready() -> void:
	stop_timer.connect("timeout", Callable(self, "_on_stop_timer_timeout"))
	
func play_segment() -> void:
	if not beat_player.playing:
		beat_player.seek(playback_pos)	
		beat_player.play()
		stop_timer.start()

func _on_stop_timer_timeout() -> void:
	playback_pos = beat_player.get_playback_position()
	if playback_pos >= beat_player.stream.get_length():
		playback_pos = 0.0
	beat_player.stop
		
