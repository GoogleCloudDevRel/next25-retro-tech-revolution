extends Node

@onready var stopwatch_label = %StopWatchLabel
@onready var score_label = %ScoreLabel

@export var blink_speed:float = 2.0  # Blinks per second
@export var pulse_speed: float = 2.0  # Full cycles per second
@export var pulse_speed2: float = 1.0  # Full cycles per second
@export var min_opacity: float = 0.0  # Minimum opacity
@export var max_opacity: float = 1.0  # Maximum opacity
@export var radius : float = 10.0

var color1: Color = Color(0.91, 0.26, 0.20, 1)  # Red
var color2: Color = Color(0.20, 0.65, 0.32, 1)  # Green
var color3: Color = Color(0.25, 0.52, 0.95, 1)  # Blue
var color4: Color = Color(0.95, 0.70, 0, 1)  # Yellow
var blinking_block
var fixed_block1
var fixed_block2
var timer = 0
var is_visible = true
var selected_color



#stop watch 
var time_paused = false

func _ready():
	SignalBus.score = 0
	SignalBus.stopwatch = 0.0
	SignalBus.stop_game_stopwatch.connect(_on_stop_game_stopwatch)
	SignalBus.pause_game.connect(_on_game_paused)
	SignalBus.unpause_game.connect(_on_game_unpaused)
	SignalBus.player_score_increased.connect(_on_player_score_increased)
	SignalBus.gemini_difficulty_adjusted.connect(_on_difficulty_changed)
	_blinking_loading_block()
	
func _process(delta: float) -> void:
	if time_paused:
		return
	SignalBus.stopwatch += delta
	update_stopwatch()
	
	var opacity_factor = (sin(Time.get_ticks_msec() * 0.001 * pulse_speed * PI * 2.0) + 1.0) / 2.0
	var current_opacity = min_opacity + opacity_factor * (max_opacity - min_opacity)
	blinking_block.color = Color(selected_color.r, selected_color.g, selected_color.b, current_opacity)

	
func _blinking_loading_block():
	
	var block1 = ColorRect.new()
	#block1.position = Vector2(1800, 920)
	block1.size = Vector2(40, 15)
	
	if SignalBus.game_difficulty == SignalBus.EASY:
		selected_color = color2
		block1.color = color2
		block1.position.y = 30
	elif 	SignalBus.game_difficulty == SignalBus.MEDIUM:
		selected_color = color4
		block1.color = color4
		block1.position.y = 15	
	else:
		selected_color = color1
		block1.color = color1
		block1.position.y = 0	
	
	#%HBoxContainer.
	%level.add_child(block1)
	#%HBoxContainer.move_child(block1, 0)
	blinking_block = block1


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

func _on_stop_game_stopwatch():
	time_paused = true
	
#restart
func _on_game_unpaused():
	time_paused = false

func _on_reset_game():
	SignalBus.score = 0
	SignalBus.stopwatch = 0
	score_label.text = str(SignalBus.score)
	update_stopwatch()

func _on_difficulty_changed(level:int, reason:String):
	if level == 0:
		selected_color = color2
		blinking_block.color = color2
		blinking_block.position.y = 0	
	elif 	level == 1:
		selected_color = color4
		blinking_block.color = color4
		blinking_block.position.y = 30
	else:
		selected_color = color1
		blinking_block.color = color1
		blinking_block.position.y = 15	 
	
