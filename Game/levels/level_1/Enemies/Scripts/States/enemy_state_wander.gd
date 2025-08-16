class_name EnemyStateWander extends EnemyState
@export var anim_name: String = "walk"
@export var wander_speed: float = 50.0
@export_category("AI")
@export var state_animation_duration: float = 0.5
@export var state_cycles_min: int = 1
@export var state_cycles_max: int = 3
@export var next_state: EnemyState

var _timer: float = 0.0
var _direction: Vector2

# Called when the node enters the scene tree for the first time.
func init() -> void:
	#print("wander state init")
	pass

## What happens when the player enters this State?
func Enter() -> void:
	#print("wander state enter")
	_timer = randi_range(state_cycles_min, state_cycles_max) * state_animation_duration
	
	#default is random
	var rand = randi_range(0, 3)
	var _direction = enemy.DIR_4[rand]
	
	#orient toward the user if within a certain distance
	var distance = SignalBus.players[0].global_transform.origin.distance_to(enemy.global_position)
	if distance  < enemy.detection_radius and !enemy.is_inactive:
		_direction = get_4d(enemy.global_position.direction_to(SignalBus.players[0].global_transform.origin))
	enemy.velocity = _direction * wander_speed
	
	#print(enemy.velocity)
	#
	#enemy.cardinal_direction = Vector2.LEFT
	#enemy.velocity = direction *  wander_speed

	enemy.cardinal_direction = _direction
	enemy.SetDirection(_direction)
	enemy.update_animation(anim_name)
	#enemy.update_animation("walk_side")
	#print("wander state enter")
	#pass

## What happens when the player exits this State?
func Exit() -> void:
	pass

## What happens during the _process update in this State?
func Process(_delta: float) -> EnemyState:
	_timer -= _delta
	if _timer < 0:
		return next_state
	return null

## What happens during the _physics update in this State?
func Physics(_delta: float) -> EnemyState:
	return null
	

	
