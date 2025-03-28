extends Node2D

#game viewport
@onready var viewport_display = $GameView/ViewportDisplay
@onready var game_viewport = $GameViewport


#screenshot trigger
var timer = null

#gemini dialog
const dialog_template = preload("res://dialogues/gemini_help.dialogue")
var is_displaying_dialog = false

#add overlays
@onready var hud_score_time = preload("res://assets/hud/hud_score_time.tscn")
@onready var  gcp_overlay_scene = preload("res://assets/gcp_overlay/gcp_overlay.tscn")

func _ready():
	SignalBus.gemini_help_received.connect(_on_gemini_help)
	SignalBus.show_congratulations.connect(_on_show_congratulations)
	#stopwarch & score loading
	var hud_st =  hud_score_time.instantiate()
	add_child(hud_st)
	
	#add gcp logo overlay
	var gcp_overlay =  gcp_overlay_scene.instantiate()
	add_child(gcp_overlay)
	
	####START game view port
	#game_viewport.size = Vector2i(640, 360)
	#game_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Wait one frame to ensure viewport texture is ready
	await get_tree().process_frame
	
	# Create a new timer
	timer = Timer.new()
	
	# Set timer properties
	timer.wait_time = 10.0
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	timer.start()
	SignalBus.send_screenshot_to_gcs.emit()
	
	
	
	
	
	# Set the viewport texture to our display node
	#viewport_display.texture = game_viewport.get_texture()
	
	# Center in screen
	#viewport_display.size = Vector2(640, 360)
	#viewport_display.custom_minimum_size = Vector2(640, 360)
	#viewport_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Optional: Scale up with nearest-neighbor filtering for crisp pixels
	#viewport_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	#viewport_display.anchors_preset = Control.PRESET_CENTER
	#viewport_display.scale = Vector2(3, 3)
	
	#game_viewport.handle_input_locally = true

#trigger screen capture and send yo GCS
func _on_timer_timeout() -> void:
	SignalBus.send_screenshot_to_gcs.emit()

#defeated the boss
func _on_show_congratulations() -> void:
	%Congratulations.visible = true
	SignalBus.stop_game_stopwatch.emit()
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 10
	timer.one_shot = true  # Only run once
	timer.timeout.connect(_on_show_gameover)
	timer.start()
	
#after displaying congratulations go to gameover
func _on_show_gameover() -> void:
	SignalBus.screen_state.emit(SignalBus.GAMEOVER)

func _input(event: InputEvent) -> void:
	#if Input.is_action_just_released("up"):
	$Test.push_input(event)
	#$GameViewport/level_1.push_input(event)



	####Game View port END
#func _unhandled_input(event):
		# Convert the input event's position from outer viewport space to inner viewport space
		#$Test.push_input(event)
		
		#var transformed_event
		#if event is Input or event is InputEventScreenTouch:
		#	transformed_event = event.duplicate()
	
		# Scale factor between outer and inner viewport
		#var scale_factor = Vector2(
		#	1920 / game_viewport.size.x,
		#	1080 / game_viewport.size.y
		#)
		# Transform the position
		# This assumes the inner viewport display is positioned at the center
		#var centered_pos = event.position - Vector2(
		#	(1920 - game_viewport.size.x * 3) / 2,
		#	(1080 - game_viewport.size.y * 3) / 2
		#)
		# Scale down to inner viewport coordinates
		#transformed_event.position = centered_pos / 3
		
		# Forward to inner viewport
		#game_viewport.push_input(transformed_event)
		
func _physics_process(_delta: float) -> void:
	#if Input.is_action_just_pressed("up"):
	#	game_viewport.push_input(Input)
	#call to gemini
	if Input.is_action_just_pressed("call_gemini") and !is_displaying_dialog:
		SignalBus.gemini_help_requested.emit()

#incoming gemini help message
#TODO debug how to get notified when finished
func _on_gemini_help(msg) -> void:
	
	SignalBus.gemini_help = msg.to_upper() #save gemini returned value
	DialogueManager.show_dialogue_balloon(dialog_template, "start")
	is_displaying_dialog = true
	DialogueManager.dialogue_ended.connect(_on_dialog_finished) 

#enable calling gemini
func _on_dialog_finished(t):
	print("dialog is closed")
	is_displaying_dialog = false
	$GeminiTimer.wait_time = 15
	$GeminiTimer.start()

func _on_gemini_timer_call_help() -> void:
	SignalBus.gemini_help_requested.emit()
	$GeminiTimer.stop()	
