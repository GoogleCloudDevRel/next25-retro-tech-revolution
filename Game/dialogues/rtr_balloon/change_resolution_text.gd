extends CanvasLayer


@onready var viewport_display = $ViewportDisplay

func _ready():
	# Get reference to the game viewport
	var game_viewport = get_node("../GameViewport")
	
	# Create viewport texture from the game viewport
	var viewport_texture = game_viewport.get_texture()
	
	# Set the texture to our viewport display sprite
	viewport_display.texture = viewport_texture
	
	# Scale it up to fit a portion of our 1920x1080 screen
	# This will make the 640x360 content appear pixelated/retro
	viewport_display.scale = Vector2(3, 3) # 640*3 = 1920, 360*3 = 1080
	
	# Center it (optional, depends on your design)
	viewport_display.position = Vector2(1920/2, 1080/2)
	viewport_display.offset = Vector2(-320, -180) # Half of viewport size
