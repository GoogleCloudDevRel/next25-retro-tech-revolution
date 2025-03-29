class_name State_Idle extends State

@onready var walk : State = $"../Walk"
var weapon_change_enabled = true
var is_idle: bool = false
var idle_time = 0
var time_start = 0 
var time_now = 0
var  last_call = 0
@onready var inactivity_timer: Timer = %inactivityTimer
@onready var bubble = preload("res://levels/level_1/Player/Scripts/bubble.tscn")

## What happens when the player enters this State?
func Enter() -> void:
	var weapon_prefix = player.current_weapon  # Get current weapon
	player.UpdateAnimation(weapon_prefix + "_idle")  # Update with the correct name
	idle_time = 0
	is_idle = 0
	inactivity_timer.stop()
	pass

## What happens when the player exits this State?
func Exit() -> void:
	pass

## What happens during the _process update in this State?
func Process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		is_idle = false
		inactivity_timer.stop()
		inactivity_timer.wait_time = 10
		time_start = 0 
		time_now = 0
		idle_time = 0
		return walk
	elif inactivity_timer.is_stopped()  and !is_idle: #not moving
		inactivity_timer.start()
		time_start =  Time.get_ticks_msec()
		idle_time = 5
	elif !inactivity_timer.is_stopped()  and is_idle:
		_create_buble()
		idle_time += int(_delta)
	
	time_now = Time.get_ticks_msec()
	idle_time = int( (time_now - time_start) / 1000.0 )
	
	print(idle_time)
	#send an event if iddle  more than 5s every 5s
	if idle_time % 10 == 0 and idle_time != last_call:
		last_call = idle_time
		SignalBus.player_idle.emit(player, 10) 
	
	player.velocity = Vector2.ZERO
	return null

func _on_inactivity_timer_timeout():
	# This function is called when the timer reaches 5 seconds without being stopped
	is_idle = true
	print("Player is idle for 5 seconds!")
	_create_buble()
	
func _create_buble():
	await get_tree().create_timer(randf_range(1, 4)).timeout
	#generate random bubbles
	var b = bubble.instantiate()
	b.position.x = randf_range(-13, 13) 
	b.position.y =  -40
	player.add_child(b)
	


## What happens during the _physics update in this State?
func Physics(_delta: float) -> State:
	return null

## What happens with input events in this State?
func HandleInput(_event: InputEvent) -> State:
	#if Input.is_action_just_pressed("camera_right", true) and not event.is_echo():
	if _event.is_action_pressed("attack"):
		#if player.current_weapon == "blaster" and player.is_current_weapon_usable():
		#	return $"../AttackBlaster"  # Transition to blaster attack state
		#elif player.current_weapon == "gauntlet" and player.is_current_weapon_usable():
		#	return $"../AttackGauntlet"  # Transition to gauntlet attack state
		#else:
		#	return $"../AttackUnarmed"  # Transition to unarmed attack state
		# Handle attack input as before
		match player.current_weapon:
			"unarmed":
				return $"../AttackUnarmed"
			"blaster":
				return $"../AttackBlaster"
			"gauntlet":
				return $"../AttackGauntlet"
	elif _event.is_action_pressed("cycle_weapon"):  
	#elif Input.is_action_just_pressed("cycle_weapon", true) and _event.is_pressed() and not _event.is_echo():  # Add this to handle TAB key
		# Cycle weapons when TAB is pressed
		#var timer = get_tree().create_timer(2.0)
		#await timer.timeout
		#weapon_change_enabled = true
		print("test")
		_cycle_weapon()  # Now calling from the base class
		# Keep the player in the idle state
		return null
	return null
