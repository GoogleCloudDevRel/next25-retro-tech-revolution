class_name Boss extends Enemy

@export var floppy_speed: float = 300.0
@export var fire_rate: float = 1.0  # Bullets per second
@export var ShootingPoint: Marker2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	id = get_instance_id()
	state_machine.initialize( self )
	
	SignalBus.gemini_difficulty_adjusted.connect(_on_game_difficulty_changed)
	_on_game_difficulty_changed(SignalBus.game_difficulty, "Init")
	can_fire = true

	ShootingPoint = %ShootingPoint
	SignalBus.boss_created.emit(self)
	

	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	move_and_slide()

func SetDirection(new_direction: Vector2) -> bool:
	direction = new_direction
	if direction == Vector2.ZERO:
		return false
	 
	var direction_id: int = int(round(
		(direction + cardinal_direction * 0.1).angle()
		/ TAU * DIR_4.size()
	))
	var new_dir = DIR_4[direction_id]
	if new_dir == cardinal_direction:
		return false
	cardinal_direction = new_dir
	direction_changed.emit(new_dir)
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

func update_animation(state: String) -> void:
	animation_player.play(state + "_" + anim_direction())

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"

func take_damage(player_damage):
	#add health counter
	health -= player_damage
	hit_count += 1
	$HealthBar.value = health
	$Sprite2D/healthDepletion.play("enemyHit")
	
	
func _on_game_difficulty_changed(new_level, reason):
	if SignalBus.game_difficulty == SignalBus.EASY:
		points = 40
		health = 100.0
		detection_radius = 200.0
		max_bullet = 2
		damage_points = 1
		speed = 5
	elif SignalBus.game_difficulty == SignalBus.MEDIUM:
		points = 70
		health = 150.0
		detection_radius = 300.0
		max_bullet = 3
		damage_points = 2
		speed = 20
	else:
		points = 70
		health = 300.0
		detection_radius = 300.0
		max_bullet = 5
		fire_rate = 2.0
		damage_points = 5
		speed = 50
