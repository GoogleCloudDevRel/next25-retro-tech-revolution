class_name Enemy extends CharacterBody2D

####Added enemies base mgt ######
var speed = 300
#var target_player
@export var health = 100.0
@export var damage_points = 1 #damage to player
var points = 5 
var type = "enemy"
var hit_count = 0
@export  var is_dead = false
@export  var id = 0
@export var can_fire: bool = false
@export var detection_radius: float = 100.0
@export var timer: Timer

####Added enemies base mgt ######

#@onready var players = get_parent().players

signal direction_changed(new_direction: Vector2)

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

@export var hp: int = 3
var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var invulnerable: bool = false
var player: Player

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
# @onready var hit_box: Hitbox = $Hitbox
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine
@export var max_bullet:int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	id = get_instance_id()
	state_machine.initialize( self )
	##player = SignalBus.player[0]
	call_deferred("setup")
	
	if SignalBus.game_difficulty == SignalBus.EASY:
		points = 5
		health = 70.0
		detection_radius = 100.0
		damage_points = 1
		speed = 20
	elif SignalBus.game_difficulty == SignalBus.MEDIUM:
		points = 10
		health = 100.0
		detection_radius = 150.0
		damage_points = 2
		speed = 50
	else:
		points = 15
		health = 120.0
		detection_radius = 300.0
		damage_points = 2
		speed = 50
	
	
	
func setup():
	SignalBus.enemy_created.emit(self)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#target_player = find_closest_player()
	#if target_player != null:
	#	SetDirection(target_player.global_position)
	#	state_machine.change_state(EnemyStateWander.new() )
	#	print("Wandering")
		#update_animation("Wander") 
		#var direction = self.global_position.direction_to(target_player.global_position)
	#	velocity = direction * speed
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
	#print(state + "_" + anim_direction())
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
	SignalBus.enemy_taking_damage.emit(self, player_damage)
	

func _on_body_entered(body: Node2D) -> void:
	queue_free()
	if body.has_method("_is_moving"):
		body.is_getting_hit(damage_points)

		
func on_death() -> void:
		if !is_dead:
			is_dead = true
			#print("dying ...")
			SignalBus.player_score_increased.emit(points)
			SignalBus.enemy_health_depleted.emit(self)	
			%CollisionShape.call_deferred("set", "disabled", true)
			var script = self.get_script()
			if script.get_global_name() == "Boss":
				SignalBus.show_congratulations.emit()
	
	
