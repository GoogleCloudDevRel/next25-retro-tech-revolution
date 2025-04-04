class_name Player extends CharacterBody2D
var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO


var current_weapon: String = "unarmed" # Default weapon state
#managed the weapons retrieved by the player
var weapons = [
	{"name": "unarmed", "disabled":false},
	{"name": "blaster", "disabled":true},
	{"name": "gauntlet", "disabled":true},	
]

####added to player
var strength = 50
@export var speed = 500
@export var health = 100.0
const DAMAGE_RATE = 10.0
var friction = 0.18
var hit_count = 0
var x = 0
var y = 0
var counter = 0

@onready var hurtbox = $HurtBox

#####
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D
@onready var state_machine : PlayerStateMachine = $StateMachine
@onready var timerHit =  $TimerHit


##Gemini
@export var gemini_rotation_speed: float = 8.0 
@export var gemini_rotation_direction: int = 1

var is_waiting_gemini = true

func _ready():
		PlayerManager.player = self
		state_machine.Initialize(self)
		SignalBus.player_created.emit(self)
		SignalBus.gemini_help_requested.connect(_on_help_requested)
		SignalBus.gemini_help_received.connect(_on_help_received)
		pass

func _process(_delta):
	
	if(is_waiting_gemini):
		%Gemini.rotate(gemini_rotation_speed * gemini_rotation_direction * _delta)
	
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	#print("-->"+str(direction.x))
	# Normalize direction to prevent faster diagonal movement
	if direction.length() > 1.0:
		direction = direction.normalized()
		_is_moving()
	
func _physics_process(delta):
	velocity = direction * speed #added
	#_is_getting_hit(delta)
	move_and_slide()
	
			
func SetDirection() -> bool:
	var new_dir : Vector2 = cardinal_direction
	if direction == Vector2.ZERO:
		return false
	
	if direction.y == 0:
		new_dir = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_dir = Vector2.UP if direction.y < 0 else Vector2.DOWN
	else:
		# Handle diagonal movement
		if abs(direction.x) > abs(direction.y):
			new_dir = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
		else:
			new_dir = Vector2.UP if direction.y < 0 else Vector2.DOWN
	
	if new_dir == cardinal_direction:
		return false
	
	cardinal_direction = new_dir
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

#check if a weapon is active or not
func is_current_weapon_disabled()-> bool:
	return weapons[weapons.find(current_weapon)]['disabled']

func is_weapon_disabled(idx)-> bool:
	return weapons[idx]['disabled']

func _find_weapon_index(weapon_name):
	for i in range(weapons.size()):
		if weapons[i]['name'] == weapon_name:
			return i
	return -1

	
#activate a weapon
func activate_weapon(weapon_name:String):
	var weapon_idx =_find_weapon_index(weapon_name)
	print(weapon_name+" "+str(weapon_idx))
	if weapons[weapon_idx]['disabled']:
		weapons[weapon_idx]['disabled'] = false
		$swirlPlay.modulate.a = 0
		$swirlPlay.play()
		var tween = create_tween()
		tween.tween_property($swirlPlay, "modulate:a", 0.8, 2.0)
		current_weapon = weapon_name
		SignalBus.weapon_activated.emit(weapon_name, weapon_idx)

#ease out the video
func _on_video_finished():
	# Create a new tween for the fade-out effect
	var tween = create_tween()
	tween.tween_property($swirlPlay, "modulate:a", 0.0, 2.0)		




func UpdateAnimation(state: String) -> void:
	animation_player.play(state + "_" + AnimDirection())

func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"

#is the player getting hit
func is_getting_hit(damage_points) -> void:
		$Sprite2D/healthDepletionAnimation.play("depleting")
		hit_count += 1
		health -= damage_points
		$HealthBar.value = health
		
		#attach a timer to switch back
		if timerHit.is_stopped():
			timerHit.wait_time = 2
			timerHit.start()
		else:
			timerHit.wait_time = 2
			
		##we are dead
		if health <= 0:			
			SignalBus.player_health_depleted.emit(self)

func _on_reset_getting_hit():
	$Sprite2D/healthDepletionAnimation.play("RESET")
	timerHit.stop()


#func is_not_getting_hit() -> void:
#	$Sprite2D/healthDepletionAnimation.play("RESET")

func _is_moving() -> void:
		var left_stick_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		var left_stick_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		
		# Apply deadzone to avoid detecting tiny movements
		if abs(left_stick_x) < 0.5:
			left_stick_x = 0
		if abs(left_stick_y) < 0.5:
			left_stick_y = 0
			
		# Use the values (for example, to move a character)
		if left_stick_x != 0 or left_stick_y != 0:
			SignalBus.player_moving.emit(self, left_stick_x, left_stick_y)
			print("Left stick position: ", Vector2(left_stick_x, left_stick_y))
			
func _on_help_requested():
	%Gemini.visible = true
	is_waiting_gemini = true

func _on_help_received(t):	
	%Gemini.visible = false
	is_waiting_gemini = false
