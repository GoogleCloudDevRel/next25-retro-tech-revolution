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
