extends Node

var _waiting: bool = true

func _ready() -> void:
	SignalBus.gemini_backstory_image_received.connect(_on_backstory_received)
	pass


func _process(_delta: float) -> void:
	await get_tree().create_timer(10.0).timeout  # Wait time for cooldown
	if Input.is_action_just_pressed("attack") && !_waiting:
		SignalBus.screen_state.emit(SignalBus.BACKSTORY)



func _on_backstory_received():
	_waiting = false


func _on_timer_timeout() -> void:
	_waiting = false
