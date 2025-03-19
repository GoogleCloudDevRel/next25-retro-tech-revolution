class_name State_Idle extends State

@onready var walk : State = $"../Walk"

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
	if _event.is_action_pressed("attack"):
		# Handle attack input as before
		match player.current_weapon:
			"unarmed":
				return $"../AttackUnarmed"
			"blaster":
				return $"../AttackBlaster"
			"gauntlet":
				return $"../AttackGauntlet"
	elif _event.is_action_pressed("cycle_weapon"):  # Add this to handle TAB key
		# Cycle weapons when TAB is pressed
		_cycle_weapon()  # Now calling from the base class
		# Keep the player in the idle state
		return null
	return null
