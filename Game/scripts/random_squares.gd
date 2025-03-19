extends Node2D


# Block size
const BLOCK_SIZE = 48
const MARGIN = 72

# Define the zones
const ZONE1_X_MIN = MARGIN
const ZONE1_X_MAX = 517 - MARGIN
const ZONE2_X_MIN = 1446 + MARGIN
const ZONE2_X_MAX = 1920 - MARGIN

# Four color options - you can change these to any colors you want
var color1: Color = Color(0.91, 0.26, 0.20, 1)  # Red
var color2: Color = Color(0.20, 0.65, 0.32, 1)  # Green
var color3: Color = Color(0.25, 0.52, 0.95, 1)  # Blue
var color4: Color = Color(0.95, 0.70, 0, 1)  # Yellow

# Block appearance/disappearance settings
var max_blocks = 100
var spawn_interval_min = 0.2
var spawn_interval_max = 1.0
var block_lifetime_min = 2.0
var block_lifetime_max = 4.0

# Screen height minus the top and bottom borders
var screen_height
var y_min
var y_max

# For storing the blocks
var blocks = []
var spawn_timer = 0

# Array of available colors
var colors = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set Y boundaries (exclude top and bottom 48px)
	y_min = MARGIN
	y_max = 1080 - MARGIN
	
	# Initialize random number generator
	randomize()
	# Set initial spawn timer
	spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)
	
	# Setup color array
	colors = [color1, color2, color3, color4]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0 and blocks.size() < max_blocks:
		spawn_block()
		spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)



func spawn_block():
	# Randomly decide which zone to place the block
	var zone = randi() % 2  # 0 or 1
	
	var x_pos
	if zone == 0:
		# Zone 1
		x_pos = ZONE1_X_MIN + randi() % (ZONE1_X_MAX - ZONE1_X_MIN + 1)
	else:
		# Zone 2
		x_pos = ZONE2_X_MIN + randi() % (ZONE2_X_MAX - ZONE2_X_MIN + 1)
	
	# Calculate Y position (anywhere between the borders)
	var y_pos = y_min + randi() % int(y_max - y_min + 1)
	
	# Snap positions to grid
	x_pos = floor(x_pos / BLOCK_SIZE) * BLOCK_SIZE
	y_pos = floor(y_pos / BLOCK_SIZE) * BLOCK_SIZE
	
	# Select one of the four colors at random
	var color_index = randi() % 4
	var color = colors[color_index]
	
	# Create the block
	var block = ColorRect.new()
	block.position = Vector2(x_pos, y_pos)
	block.size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
	block.color = color
	
	# Make sure we don't spawn a block on top of another one
	for existing_block in blocks:
		if existing_block.position == block.position:
			block.queue_free()
			return
	
	# Add block to scene
	add_child(block)
	blocks.append(block)
	
	# Set up disappearance timer for this block
	var lifetime = randf_range(block_lifetime_min, block_lifetime_max)
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_block_timeout.bind(block, timer))
	add_child(timer)
	timer.start()


func _on_block_timeout(block, timer):
	#print("remove block")
	remove_child(block)
	remove_child(timer)
