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
	var selected_weapon = get_next_weapon(player.current_weapon)
	player.current_weapon = selected_weapon.weapon_name
	SignalBus.weapon_changed.emit(selected_weapon.weapon_name, selected_weapon.weapon_idx)
	print("-->"+player.current_weapon)
	player.UpdateAnimation(player.current_weapon + "_idle")

# Helper function to get the next weapon in the list
func get_next_weapon(current_weapon: String) -> Dictionary:
	var weapon_name = "unarmed"
	
	var weapon_types = ["unarmed", "blaster", "gauntlet"]
	var counter = 1
	var index = weapon_types.find(current_weapon)
	var next_index = index
	while counter < 4:
		next_index = (index + counter) % weapon_types.size()
		print(weapon_types[next_index] + " "+ str(next_index)+" "+str(player.is_weapon_disabled(next_index)))
		if !player.is_weapon_disabled(next_index):
			weapon_name = weapon_types[next_index]
			break
		counter += 1
	return {"weapon_name":weapon_name, "weapon_idx":next_index}
	
