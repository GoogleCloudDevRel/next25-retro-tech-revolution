extends CanvasLayer

@onready var backgroundStoryText = $/root/Game/BackgroundStoryCanvas/backgroundStory
@onready var backgroundStoryScreen = $/root/Game/BackgroundStoryCanvas
@onready var texture_rect = $/root/Game/BackgroundStoryCanvas/backgroundImage 

@export var pause_game_action: StringName = &"pause_game"

var is_able_to_skip : bool = true

func _ready():
	SignalBus.gemini_backstory_received.connect(_on_story_received)
	SignalBus.gemini_backstory_image_received.connect(_on_image_received)

#display generated text
func _on_story_received(t:String):
	backgroundStoryText.text = t
	backgroundStoryScreen.visible = true

#display the generated image
func _on_image_received(base64_image):
	
	var image_bytes = Marshalls.base64_to_raw(base64_image)
	# Create an Image and load it from the byte data.
	var image = Image.new()
	var err = image.load_png_from_buffer(image_bytes)

	if err == OK:
		# Create an ImageTexture and set it on the TextureRect.
		var image_texture = ImageTexture.create_from_image(image) #add image to our background-story
		texture_rect.texture = image_texture  # Display the image.
		print("Image generated and displayed successfully!")
	else:
		printerr("Failed to load image from buffer: ", err)
	backgroundStoryScreen.visible = true
	get_tree().paused = true
	SignalBus.pause_game.emit()
	$storyTimer.start()

func _process(delta: float) -> void:
	if Input.is_action_pressed(pause_game_action) and backgroundStoryScreen.visible and is_able_to_skip:
		print("go next")
		get_tree().paused = false #unpause
		SignalBus.unpause_game.emit()
		backgroundStoryScreen.visible = false
		is_able_to_skip = false
		$storyTimer.start()

func _on_timer_timeout() -> void:
	is_able_to_skip = true
	$storyTimer.stop()
