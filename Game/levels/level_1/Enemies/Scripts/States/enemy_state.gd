class_name EnemyState extends Node


## Stores a reference to the enemy that this state belongs to
var enemy : Enemy
var state_machine : EnemyStateMachine

# Called when the node enters the scene tree for the first time.
func init() -> void:
	pass

## What happens when the player enters this State?
func Enter() -> void:
	pass

## What happens when the player exits this State?
func Exit() -> void:
	pass

## What happens during the _process update in this State?
func Process(_delta: float) -> EnemyState:
	return null

## What happens during the _physics update in this State?
func Physics(_delta: float) -> EnemyState:
	return null



func get_4d(direction: Vector2) -> Vector2:
	# If no significant movement, return current direction or a default
	if direction.length() < 0.1:
		return Vector2.DOWN 
	var angle = direction.angle()
	if abs(angle) <= PI/4:
		return Vector2.RIGHT
	elif abs(angle) >= 3*PI/4:
		return Vector2.LEFT
	elif angle > 0:
		return Vector2.DOWN
	else:
		return Vector2.UP
