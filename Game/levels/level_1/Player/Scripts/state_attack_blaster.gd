class_name State_AttackBlaster extends State
@export var attack_animation_duration: float = 0.4
@onready var walk: State = $"../Walk"
var timer: float = 0.0

func Enter() -> void:
	player.velocity = Vector2.ZERO
	player.UpdateAnimation("blaster_attack")
	timer = attack_animation_duration
	# You could spawn a projectile here
	pass

func Exit() -> void:
	pass

func Process(delta: float) -> State:
	if Input.is_action_just_pressed("attack"):	
			%Gun.shoot()
	timer -= delta
	if timer <= 0:
		return walk
	return null

func Physics(_delta: float) -> State:
	return null

func HandleInput(_event: InputEvent) -> State:
	return null
