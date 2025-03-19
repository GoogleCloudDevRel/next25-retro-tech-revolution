class_name State extends Node

## Stores a reference to the player that this State belongs to
static var player: Player

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

## What happens when the player enters this State?
func Enter() -> void:
	pass

## What happens when the player exits this State?
func Exit() -> void:
	pass

## What happens during the _process update in this State?
func Process(_delta: float) -> State:
	return null

## What happens during the _physics update in this State?
func Physics(_delta: float) -> State:
	return null

## What happens with input events in this State?
func HandleInput(_event: InputEvent) -> State:
	return null

# Helper function to cycle weapons
func _cycle_weapon():
	player.current_weapon = get_next_weapon(player.current_weapon)
	player.UpdateAnimation(player.current_weapon + "_idle")

# Helper function to get the next weapon in the list
func get_next_weapon(current_weapon: String) -> String:
	var weapon_types = ["unarmed", "blaster", "gauntlet"]
	var index = weapon_types.find(current_weapon)
	return weapon_types[(index + 1) % weapon_types.size()]
