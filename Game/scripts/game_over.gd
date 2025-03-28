extends Node

@onready var stopwatch_label = %StopWatchLabel
@onready var score_label = %ScoreLabel
@onready var game_over = %GameOver

func _ready():
	game_over.play("default")
	score_label.text = str(SignalBus.score)
	update_stopwatch()
	SignalBus.session_rank_received.connect(_on_rank_received)
	
	
func update_stopwatch():
	var  msec = fmod(SignalBus.stopwatch, 1) * 1000
	var  sec = fmod(SignalBus.stopwatch, 60)
	var minutes= SignalBus.stopwatch/60
	#00 : 00 . 000
	var format_string = "%02d : %02d . %02d"
	stopwatch_label.text = format_string % [minutes, sec, msec]


#display the rank received from BigQuery
func _on_rank_received(rank:String):
	%RankLabel.text = "#"+rank
