class_name State_Walk extends State
@export var move_speed: float = 130.0
@export var weapon_types: Array[String] = ["unarmed", "blaster", "gauntlet"] # Your different weapon states
@onready var idle: State = $"../Idle"
var current_weapon_index: int = 0

## What happens when the player enters this State?
func Enter() -> void:
	UpdatePlayerAnimation()
	pass

## What happens when the player exits this State?
func Exit() -> void:
	pass

## What happens during the _process update in this State?
func Process(_delta: float) -> State:
	if player.direction == Vector2.ZERO:
		return idle
		
	player.velocity = player.direction * move_speed
	
	if player.SetDirection():
		UpdatePlayerAnimation()
	return null

## What happens during the _physics update in this State?
func Physics(_delta: float) -> State:
	return null

## What happens with input events in this State?
func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("attack"):  # Make sure space is mapped to "attack"
		#if player.current_weapon == "blaster" and player.is_current_weapon_usable():
		#	return $"../AttackBlaster"  # Transition to blaster attack state
		#elif player.current_weapon == "gauntlet" and player.is_current_weapon_usable():
		#	return $"../AttackGauntlet"  # Transition to gauntlet attack state
		#else:
		#	return $"../AttackUnarmed"  # Transition to unarmed attack state
		
		match player.current_weapon:
			"unarmed":
				return $"../AttackUnarmed"  # Transition to unarmed attack state
			"blaster":
				return $"../AttackBlaster"  # Transition to blaster attack state
			"gauntlet":
				return $"../AttackGauntlet"  # Transition to gauntlet attack state
	elif _event.is_action_pressed("cycle_weapon"):
		# Cycle to the next weapon
		current_weapon_index = (current_weapon_index + 1) % weapon_types.size()
		
		
		UpdatePlayerAnimation()
		player.current_weapon = weapon_types[current_weapon_index]
	return null

## Helper function to set the correct animation based on current weapon
func UpdatePlayerAnimation() -> void:
	var weapon_prefix = weapon_types[current_weapon_index]
	player.UpdateAnimation(weapon_prefix + "_walk")
