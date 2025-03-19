class_name State_AttackGauntlet extends State
@export var attack_animation_duration: float = 0.5
@onready var walk: State = $"../Walk"
var timer: float = 0.0

func Enter() -> void:
	player.velocity = Vector2.ZERO
	player.UpdateAnimation("gauntlet_attack")
	timer = attack_animation_duration
	# You could spawn a melee hitbox here
	pass

func Exit() -> void:
	pass

func Process(delta: float) -> State:
	timer -= delta
	if timer <= 0:
		return walk
	return null

func Physics(_delta: float) -> State:
	return null

func HandleInput(_event: InputEvent) -> State:
	return null
