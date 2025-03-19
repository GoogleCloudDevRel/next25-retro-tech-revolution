class_name EnemyStateAttack extends EnemyState
@export var anim_name: String = "attack"
@export var wander_speed: float = 50.0
@export_category("AI")
@export var state_animation_duration: float = 0.5
@export var state_cycles_min: int = 1
@export var state_cycles_max: int = 40
@export var next_state: EnemyState 

var _timer: float = 0.0
var _direction: Vector2

enum Direction { UP, RIGHT, DOWN, LEFT }
var current_direction = "down"

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var projectile = preload("res://levels/level_1/Enemies/Projectiles/projectiles.tscn")


## Stores a reference to the player that this State belongs to
var player: Player

# Called when the node enters the scene tree for the first time.
func init():
	
	
	
	pass # Replace with function body.

## What happens when the player enters this State?
func Enter() -> void:
	print("attack mode")
	enemy.update_animation(anim_name)
	
	#### fire bullet
	# Setup timer for controlling fire rate
	if enemy.can_fire:
		enemy.timer = Timer.new()
		enemy.timer.wait_time = 1.0 / enemy.fire_rate
		enemy.timer.one_shot = true
		enemy.timer.connect("timeout", _on_timer_timeout)
		enemy.add_child(enemy.timer)
	
	pass


func Process(_delta: float) -> EnemyState:
	player = get_parent().get_parent().get_parent().players[0]
	var distance_to_player = enemy.global_position.distance_to(player.global_position)
	var direction_to_player = player.global_position - enemy.global_position
	# Convert to 4-way direction
	var new_direction = get_4way_direction(direction_to_player)
	
	if distance_to_player <= enemy.detection_radius:
		# Shoot if we can
		if enemy.can_fire:
			# Face the player
			enemy.ShootingPoint.look_at(player.global_position)
			if new_direction != current_direction:
				current_direction = new_direction
				print("new direction:"+new_direction)
				animation_player.play( "attack_" + new_direction)

			
			
			
			shoot_at_player()
			enemy.can_fire = false
			enemy.timer.start()
	
		
	_timer -= _delta
	if _timer < 0:
		return next_state
	return null


## What happens when the player exits this State?
func Exit() -> void:
	pass

func shoot_at_player():
	# Create bullet instance
	var floppy = projectile.instantiate()
	
	# Set bullet position
	floppy.global_position = enemy.ShootingPoint.global_position
	
	# Calculate direction vector toward player
	var direction = (player.global_position - enemy.ShootingPoint.global_position).normalized()
	
	# Set bullet direction
	floppy.direction = direction
	
	# Add bullet to scene
	get_tree().current_scene.add_child(floppy)

func get_4way_direction(direction_vector):
	# Normalize the vector
	direction_vector = direction_vector.normalized()

	# Calculate the angle in radians
	var angle = direction_vector.angle()
	
	# Convert to degrees and ensure it's in the range [0, 360)
	var degrees = rad_to_deg(angle)
	if degrees < 0:
		degrees += 360

	# Map angle to 4-way direction
	# 315-45 degrees: RIGHT (0)
	# 45-135 degrees: DOWN (2)
	# 135-225 degrees: LEFT (3)
	# 225-315 degrees: UP (1)
	if degrees >= 315 or degrees < 45:
		return "side"
	elif degrees >= 45 and degrees < 135:
		return "down"
	elif degrees >= 135 and degrees < 225:
		return "side"
	else:  # degrees >= 225 and degrees < 315
		return "up"

func _on_timer_timeout():
	enemy.can_fire = true
