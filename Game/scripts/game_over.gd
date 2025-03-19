extends Node

@onready var stopwatch_label = %StopWatchLabel
@onready var score_label = %ScoreLabel
@onready var game_over = %GameOver

func _ready():
	game_over.play("default")
	score_label.text = str(SignalBus.score)
	update_stopwatch()
	
	
	
func update_stopwatch():
	var  msec = fmod(SignalBus.stopwatch, 1) * 1000
	var  sec = fmod(SignalBus.stopwatch, 60)
	var minutes= SignalBus.stopwatch/60
	#00 : 00 . 000
	var format_string = "%02d : %02d . %02d"
	stopwatch_label.text = format_string % [minutes, sec, msec]
