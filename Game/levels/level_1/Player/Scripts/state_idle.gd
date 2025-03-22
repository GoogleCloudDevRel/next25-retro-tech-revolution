class_name State_Idle extends State

@onready var walk : State = $"../Walk"
var weapon_change_enabled = true



## What happens when the player enters this State?
func Enter() -> void:
	var weapon_prefix = player.current_weapon  # Get current weapon
	player.UpdateAnimation(weapon_prefix + "_idle")  # Update with the correct name
	pass

## What happens when the player exits this State?
func Exit() -> void:
	pass

## What happens during the _process update in this State?
func Process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	player.velocity = Vector2.ZERO
	return null

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
