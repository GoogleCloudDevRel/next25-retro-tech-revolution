extends Node

var wait_time = 20.0

func _physics_process(_delta):
		if Input.is_action_just_pressed("attack"):
			#StartScreenCanvas.visible = false
			SignalBus.screen_state.emit(SignalBus.QUESTIONS)
			

#wait a certain time before replaying the initial video
func _on_initial_video_finished() -> void:
	var timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout.bind(timer))
	add_child(timer)
	timer.start()

#time to play the video
func _on_timer_timeout(t) -> void:
	%InitialVideo.play()
	t.queue_free()
