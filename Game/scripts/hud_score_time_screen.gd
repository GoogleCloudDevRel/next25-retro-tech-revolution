extends Node

@onready var stopwatch_label = %StopWatchLabel
@onready var score_label = %ScoreLabel

#stop watch 
var time_paused = false

func _ready():
	SignalBus.score = 0
	SignalBus.stopwatch = 0.0
	SignalBus.pause_game.connect(_on_game_paused)
	SignalBus.unpause_game.connect(_on_game_unpaused)
	SignalBus.player_score_increased.connect(_on_player_score_increased)
	
func _process(delta: float) -> void:
	if time_paused:
		return
	SignalBus.stopwatch += delta
	update_stopwatch()

func reset_stopwatch():
	SignalBus.stopwatch = 0.0

func update_stopwatch():
	var  msec = fmod(SignalBus.stopwatch, 1) * 1000
	var  sec = fmod(SignalBus.stopwatch, 60)
	var minutes = SignalBus.stopwatch/60
	#00 : 00 . 000
	var format_string = "%02d : %02d . %02d"
	stopwatch_label.text = format_string % [minutes, sec, msec]

#update the score
func _on_player_score_increased(points:int):
	SignalBus.score += points
	score_label.text = str(SignalBus.score)

#pause the game
func _on_game_paused():
	time_paused = true

#restart
func _on_game_unpaused():
	time_paused = false
	
func _on_reset_game():
	SignalBus.score = 0
	SignalBus.stopwatch = 0
	score_label.text = str(SignalBus.score)
	update_stopwatch()
	
