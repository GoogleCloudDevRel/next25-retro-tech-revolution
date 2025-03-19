extends BaseDialogueTestScene

@onready var viewport_display = $GameView/ViewportDisplay
@onready var game_viewport = $GameViewport


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var balloon = load("res://dialogues/rtr_balloon/balloon.tscn").instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(resource, title)
	SignalBus.gemini_backstory_image_requested.emit("generate a sign")
	
	####START game view port
	game_viewport.size = Vector2i(640, 360)
	game_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Wait one frame to ensure viewport texture is ready
	await get_tree().process_frame
	
	# Set the viewport texture to our display node
	viewport_display.texture = game_viewport.get_texture()
	
	# Center in screen
	viewport_display.size = Vector2(640, 360)
	viewport_display.custom_minimum_size = Vector2(640, 360)
	viewport_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Optional: Scale up with nearest-neighbor filtering for crisp pixels
	viewport_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport_display.anchors_preset = Control.PRESET_CENTER
	viewport_display.scale = Vector2(3, 3)
	
	
	####END
	
	#SignalBus.gemini_backstory_image_received.connect(_on_image_received)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_image_received(base64_image):
	print("Base64 string length: " + str(base64_image.length()))
	print("First 20 chars: " + base64_image.substr(0, 20))
	if( base64_image.length()> 0):
		print("----1")
		var image_bytes = Marshalls.base64_to_raw(base64_image)
		print("Decoded bytes length: " + str(image_bytes.size()))
		
		var save_file = FileAccess.open("res://backstory-images/debug_image.png", FileAccess.WRITE)
		
		save_file.store_buffer(image_bytes)
		save_file.close()
		
		# Create an Image and load it from the byte data.
		var image = Image.new()
		print("----2")
		#var err = image.load_png_from_buffer(image_bytes)
		var err = image.load("res://debug_image.png")
		assert(err == OK, "Failed to load pic at: res://debug_image.png")
		
		if err == OK:
			print("----3")
			# Create an ImageTexture and set it on the TextureRect.
			var image_texture = ImageTexture.create_from_image(image) #add image to our background-story
			%BackStoryImage.texture = image_texture  # Display the image.
			print("Image generated and displayed successfully!")
		else:
			printerr("Failed to load image from buffer: ", err)
