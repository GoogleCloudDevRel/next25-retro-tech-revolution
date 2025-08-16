extends Node2D


@onready var bubble = $iddle_state
@onready var animplayer = $AnimationBubble


# Movement settings
@export var min_speed = 50.0
@export var max_speed = 150.0
@export var horizontal_range = 100.0  # How far left/right it can move
@export var random_direction_change_time = 2.0  # Seconds between direction changes


var velocity = Vector2.ZERO
var direction_timer = 0.0
var initial_position = Vector2.ZERO

func _ready():
	# Store initial position for horizontal boundary calculation
	initial_position = position
	# Set initial random velocity
	randomize()
	change_direction()
	animplayer.play("iddle_state")
	

func _process(delta):
	# Move sprite based on current velocity
	position += velocity * delta
	
	# Update direction change timer
	direction_timer -= delta
	if direction_timer <= 0:
		change_direction()
		direction_timer = randf_range(random_direction_change_time * 0.5, random_direction_change_time * 1.5)
	
	# Keep within horizontal boundaries
	if abs(position.x - initial_position.x) > horizontal_range:
		position.x = initial_position.x + horizontal_range * sign(position.x - initial_position.x)
		velocity.x *= -1  # Bounce off the boundary


func change_direction():
	# Set a random upward velocity
	var speed = randf_range(min_speed, max_speed)
	var horizontal_component = randf_range(-0.5, 0.5)  # -0.5 to 0.5 for slight left/right movement
	
	# Create velocity vector (always moving upward, but with random speed and slight horizontal movement)
	velocity = Vector2(speed * horizontal_component, -speed)


func _on_timer_timeout():
	# Iterate through the children and queue them for deletion
	for child in get_children():
		child.queue_free()
	self.queue_free()

	# If the timer is set to One Shot, it will stop automatically.
	# If it's repeating, you might want to stop it here if needed.
	# timer.stop()
