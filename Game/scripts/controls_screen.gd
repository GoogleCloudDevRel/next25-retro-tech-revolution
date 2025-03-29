extends Node

@export var blink_speed:float = 2.0  # Blinks per second
@export var pulse_speed: float = 2.0  # Full cycles per second
@export var pulse_speed2: float = 1.0  # Full cycles per second
@export var min_opacity: float = 0.0  # Minimum opacity
@export var max_opacity: float = 1.0  # Maximum opacity

var _waiting: bool = true
var color1: Color = Color(0.91, 0.26, 0.20, 1)  # Red
var color2: Color = Color(0.20, 0.65, 0.32, 1)  # Green
var color3: Color = Color(0.25, 0.52, 0.95, 1)  # Blue
var color4: Color = Color(0.95, 0.70, 0, 1)  # Yellow
var blinking_block
var fixed_block1
var fixed_block2
var timer = 0
var is_visible = true

var radius = 50



func _ready() -> void:
	SignalBus.gemini_backstory_image_received.connect(_on_backstory_received)
	_blinking_loading_block()
	
	
func _blinking_loading_block():
	
	var block1 = ColorRect.new()
	block1.position = Vector2(1800, 920)
	block1.size = Vector2(15, 40)
	block1.color =  color1
	
	add_child(block1)
	blinking_block = block1
	
	var block2 = ColorRect.new()
	block2.position = Vector2(1820, 920)
	block2.size = Vector2(15, 15)
	block2.color =  color1
	
	add_child(block2)
	fixed_block1 = block2
	
	var block3 = ColorRect.new()
	block3.position = Vector2(1820, 945)
	block3.size = Vector2(15, 15)
	block3.color =  color1
	
	add_child(block3)
	fixed_block2 = block3
	
func _process(_delta: float) -> void:
	var opacity_factor = (sin(Time.get_ticks_msec() * 0.001 * pulse_speed * PI * 2.0) + 1.0) / 2.0
	var opacity_factor2 = (sin(Time.get_ticks_msec() * 0.001 * pulse_speed2 * PI * 2.0) + 1.0) / 2.0
	# Map to our min/max opacity range
	var current_opacity = min_opacity + opacity_factor * (max_opacity - min_opacity)
	var current_opacity2 = min_opacity + opacity_factor2 * (max_opacity - min_opacity)
	# Apply the opacity while keeping the original color
	if _waiting:
		fixed_block1.color = Color(color1.r, color1.g, color1.b, current_opacity)
		fixed_block2.color = Color(color1.r, color1.g, color1.b, current_opacity2)
	
	await get_tree().create_timer(10.0).timeout  # Wait time for cooldown
	if Input.is_action_just_pressed("attack") && !_waiting:
		SignalBus.screen_state.emit(SignalBus.BACKSTORY)



func _on_backstory_received():
	_waiting = false
	blinking_block.color = color2
	fixed_block1.color = color2
	fixed_block2.color = color2
	$Timer.stop()


func _on_timer_timeout() -> void:
	_waiting = false
	blinking_block.color = color4
	fixed_block1.color = color4
	fixed_block2.color = color4
