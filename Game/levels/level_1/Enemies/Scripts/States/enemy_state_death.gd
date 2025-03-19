class_name EnemyStateDeath extends EnemyState
@export var anim_name: String = "death"

@export_category("AI")
@export var state_animation_duration: float = 0.5
@export var state_duration_min: float = 0.5
@export var state_duration_max: float = 1.5
@export var next_state: EnemyState 
var _timer: float = 0.0
var _direction: Vector2

## Stores a reference to the player that this State belongs to
#static var player: Player

# Called when the node enters the scene tree for the first time.
func init():
	pass # Replace with function body.

## What happens when the player enters this State?
func Enter() -> void:
	print("death state enter")
	_timer = randf_range(state_duration_min, state_duration_max)
	enemy.update_animation(anim_name)
	const SMOKE_SCENE = preload("res://assets/enemies/smoke_explosion/smoke_explosion.tscn")
	var smoke = SMOKE_SCENE.instantiate()
	get_parent().get_parent().add_child(smoke)
	smoke.global_position = get_parent().get_parent().global_position

func Process(_delta: float) -> EnemyState:
	_timer -= _delta
	if _timer < 0:
		return null
	return null	

## What happens during the _physics update in this State?
func Physics(_delta: float) -> EnemyState:
	return null
	
func Exit() -> void:
	#print("idle state exit")
	pass
