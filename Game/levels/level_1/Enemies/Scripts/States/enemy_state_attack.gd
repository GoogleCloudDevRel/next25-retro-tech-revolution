class_name EnemyStateAttack extends EnemyState
@export var anim_name: String = "attack"
@export var wander_speed: float = 50.0
@export_category("AI")
@export var state_animation_duration: float = 0.5
@export var state_cycles_min: int = 1
@export var state_duration_max: int = 8
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
	print("attack state enter")
	_timer = state_duration_max
	enemy.update_animation(anim_name)
	
	#### fire bullet
	# Setup timer for controlling fire rate
	if enemy.can_fire:
		print("can fire enemy")
		enemy.timer = Timer.new()
		enemy.timer.wait_time = 1.0 / enemy.fire_rate
		enemy.timer.one_shot = true
		enemy.timer.connect("timeout", _on_timer_timeout)
		enemy.add_child(enemy.timer)
	
	pass


func Process(_delta: float) -> EnemyState:
	_timer -= _delta
	if _timer < 0:
		return next_state
	return null

func _physics_process(delta: float) -> void:
	#print("attack mode")
	player = find_closest_player(get_parent().get_parent().get_parent().players)
	
	if player != null and !enemy.is_dead:
		var distance_to_player = enemy.global_position.distance_to(player.global_position)
		
		
		if distance_to_player < enemy.detection_radius:
			var direction_to_player = player.global_position - enemy.global_position
			# Convert to 4-way direction
			var new_direction = get_4way_direction(direction_to_player)
			
			enemy.sprite.scale.x = -1 if new_direction == "left" else 1
			var new_animation_direction = "side" if new_direction == "left" or new_direction == "right" else new_direction
			animation_player.play( "attack_" + new_animation_direction)
			
			if distance_to_player <= enemy.detection_radius:
				# Shoot if we can
				if enemy.can_fire:
					print("Fire")
					# Face the player
					animation_player.play( "attack_" + new_direction)
					shoot_at_player(new_direction)
					enemy.can_fire = false
					enemy.timer.start()
	enemy.move_and_slide()


func find_closest_player(players):
	var closest_player
	var closest_dist = -1
	if players.size() > 0:
		for i in range(0, players.size()): 
			var new_dist = enemy.global_position.distance_to(players[i].global_position)
			if new_dist < closest_dist or closest_dist == -1:
				closest_player = players[i]
				closest_dist = new_dist
		return closest_player
	return null



## What happens when the player exits this State?
func Exit() -> void:
	pass

#fire at a player
func shoot_at_player(new_direction:String):	
	
	# Create bullet instance
	
	for i in range(1, randi_range(1, enemy.max_bullet)):
		var floppy = projectile.instantiate()
		SignalBus.floppy_created.emit(floppy,  enemy.global_position)
		SignalBus.wait(1)

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
		return "right"
	elif degrees >= 45 and degrees < 135:
		return "down"
	elif degrees >= 135 and degrees < 225:
		return "left"
	else:  # degrees >= 225 and degrees < 315
		return "up"

func _on_timer_timeout():
	enemy.can_fire = true
