extends CanvasLayer

#game viewport
@onready var viewport_display = $GameView/ViewportDisplay
@onready var game_viewport = $GameViewport

@export var difficulty_down: Texture2D  = preload("res://levels/level_1/assets/difficulty_down.png")
@export var difficulty_up: Texture2D  = preload("res://levels/level_1/assets/difficulty_up.png")
@export var difficulty_unchanged: Texture2D  = preload("res://levels/level_1/assets/difficulty_unchanged.png")

@export var scan_duration = 5.0

#screenshot trigger
var timer = null

#gemini dialog
const dialog_template = preload("res://dialogues/gemini_help.dialogue")
var is_displaying_dialog = false
var dialogballoon

#add overlays
@onready var hud_score_time = preload("res://assets/hud/hud_score_time.tscn")
@onready var  gcp_overlay_scene = preload("res://assets/gcp_overlay/gcp_overlay.tscn")

func _ready():
	SignalBus.gemini_help_received.connect(_on_gemini_help)
	SignalBus.show_congratulations.connect(_on_show_congratulations)
	SignalBus.gemini_difficulty_adjusted.connect(_on_level_changed)
	#stopwarch & score loading
	var hud_st =  hud_score_time.instantiate()
	add_child(hud_st)
	
	#add gcp logo overlay
	var gcp_overlay =  gcp_overlay_scene.instantiate()
	add_child(gcp_overlay)
	_on_level_changed(0, "")
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
	
func _on_level_changed(level:int, reason:String):
	if SignalBus.prev_game_difficulty == level:
			#show unchanged
			$level_adujsted_msg.texture = difficulty_unchanged
	elif SignalBus.prev_game_difficulty > level:
			#show down
			$level_adujsted_msg.texture = difficulty_down	
	else:
			#show up	
			$level_adujsted_msg.texture = difficulty_up
	$level_adujsted_msg.visible = true
	$level_adujsted_msg/display_level_change_timer.start()
	

func create_scan_animation():
	# Create animation player if it doesn't exist
	var anim_player = $AnimationPlayer if has_node("AnimationPlayer") else AnimationPlayer.new()
	if not has_node("AnimationPlayer"):
		add_child(anim_player)
	
	# Create the animation
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	
	# Set track properties
	animation.track_set_path(track_index, "level_adjusted:material:shader_parameter/scan_line_position")
	
	# Add key frames for the animation
	animation.track_insert_key(track_index, 0.0, 0.0)  # Start at the top (0.0)
	animation.track_insert_key(track_index, scan_duration, 1.0)  # End at the bottom (1.0)
	
	# Set animation length
	animation.length = scan_duration
	
	# Add the animation to the animation player
	anim_player
	anim_player.set_current_animation("scan_effect", animation)
	
	# Set to loop
	anim_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_PHYSICS
	anim_player.autoplay = "scan_effect"
	anim_player.playback_default_blend_time = 0
	
	# Play the animation
	anim_player.play("scan_effect")

	
func _on_hide_level_changed():
		$level_adujsted_msg.visible = false	
	
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
	var balloon_node = get_node_or_null("/root/Game/ExampleBalloon")
	if balloon_node:
		balloon_node.queue_free()
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
	if(!is_displaying_dialog):
		SignalBus.gemini_help = msg.to_upper()
		dialogballoon = DialogueManager.show_dialogue_balloon(dialog_template, "start")
		is_displaying_dialog = true
		DialogueManager.dialogue_ended.connect(_on_dialog_finished) 

#enable calling gemini
func _on_dialog_finished(t):
	#print("dialog is closed")
	is_displaying_dialog = false
	$GeminiTimer.wait_time = 15
	$GeminiTimer.start()

func _on_gemini_timer_call_help() -> void:
	SignalBus.gemini_help_requested.emit()
	$GeminiTimer.stop()	
