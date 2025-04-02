extends CanvasLayer

@onready var stopwatch_label = %StopWatchLabel
@onready var score_label = %ScoreLabel
@onready var game_over = %GameOver

@onready var button1 = $MarginContainer/VBoxContainer/VBoxContainer/MarginContainer/HUD/ReplayButton
@onready var button2 = $MarginContainer/VBoxContainer/VBoxContainer/MarginContainer/HUD/ResetButton

var buttons = []
var current_button_index = 0

var is_summary_received = false
var is_scrolling = false

func _ready():
	var balloon_node = get_node_or_null("/root/Game/ExampleBalloon")
	if balloon_node:
		balloon_node.queue_free()
		
	buttons = [button1, button2]
	
	buttons[0].grab_focus()
	
	button1.focus_neighbor_bottom = button2.get_path()
	button2.focus_neighbor_top = button1.get_path()
	
	#button1.pressed.connect(_on_replay_pressed)
	#button2.pressed.connect(_on_reset_pressed)
	
	game_over.play("default")
	score_label.text = "[right]%03d[/right]" % SignalBus.score
	%RankLabel.text = "[right]%03d[/right]" % int(0)
	%Summary.text = "Congratulations, Your id is : [font_size=30][b][color=#34A853]" + str(SignalBus.client_id) + "[/color][/b], and session id : [font_size=30][b][color=#EA4335]" + str(SignalBus.session_id) + "[/color][/b], [p]"
	
	update_stopwatch()
	SignalBus.session_rank_received.connect(_on_rank_received)
	SignalBus.gemini_summary_received.connect(_on_gemini_summary_received)

func _on_replay_pressed():
	print("Button 1 pressed")
	#keep the client_id
	SignalBus.reset_game_settings()
	SignalBus.replay_game.emit()

func _on_reset_pressed():
	#reset both session_id & client_id
	print("Button 2 pressed")
	
	SignalBus.reset_game.emit()

func update_stopwatch():
	var  msec = fmod(SignalBus.stopwatch, 1) * 1000
	var  sec = fmod(SignalBus.stopwatch, 60)
	var minutes= SignalBus.stopwatch/60
	#00 : 00 . 000
	var format_string = "[right]%02d : %02d . %03d[/right]"
	stopwatch_label.text = format_string % [minutes, sec, msec]


#display the rank received from BigQuery
func _on_rank_received(rank:String):
	%RankLabel.text = "[right]%03d[/right]" % int(rank)

func _on_gemini_summary_received(summary:String):
	%Summary.text += summary.to_upper()


func _on_button_pressed(button_index):
	if button_index == 0:
		_on_replay_pressed()
	else:
		_on_reset_pressed()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		_on_button_pressed(current_button_index)
		
	if Input.is_action_just_pressed("ui_right"):
		# Move to next button
		current_button_index = min(current_button_index + 1, buttons.size() - 1)
		buttons[current_button_index].grab_focus()
	elif Input.is_action_just_pressed("ui_left"):
		# Move to previous button
		current_button_index = max(current_button_index - 1, 0)
		buttons[current_button_index].grab_focus()	
	
	
	
	var scroll_direction = 0
	var scroll_speed = 20
	var rich_text_label = %Summary
# For gamepad D-pad input
	if Input.is_action_pressed("ui_down"):
		#print("down")
		scroll_direction = 1
	if Input.is_action_pressed("ui_up"):
		#print("up")
		scroll_direction = -1
	# Apply scrolling
	if scroll_direction != 0:
		# Get the current scroll position
		
		var v_scroll_bar = rich_text_label.get_v_scroll_bar()
		# Calculate new scroll position
		var current_scroll = v_scroll_bar.value
		var new_scroll = current_scroll + (scroll_direction * scroll_speed)
		
		#print(v_scroll_bar.max_value)
		
		# Clamp between valid values
		new_scroll = clamp(new_scroll, 0, v_scroll_bar.max_value+ 500)
			
		# Set the scrollbar value (this is equivalent to setting v_scroll)
		v_scroll_bar.value = new_scroll
		#print(str(v_scroll_bar.value) + " " + str(new_scroll) +" "+str(v_scroll_bar.max_value))
	
	if !is_scrolling:
		scroll_text_from_top_to_bottom()


func scroll_text_from_top_to_bottom():
	is_scrolling = true
	var text2scroll = %Summary
	var v_scroll = text2scroll.get_v_scroll_bar()
	
	# First, reset to top
	v_scroll.value = 0
	#print(v_scroll.value)
	# Get the max scroll value
	var max_scroll = v_scroll.max_value
	#print("-->" + str(max_scroll))
	# Create a tween to animate the scrollbar
	var tween = create_tween()
	var duration = 12.0  # seconds to scroll through entire text

	# Animate the scrollbar value from 0 to max
	tween.tween_property(v_scroll, "value", max_scroll, duration)
	tween.set_ease(Tween.EASE_IN)
	
	v_scroll.grab_focus()
