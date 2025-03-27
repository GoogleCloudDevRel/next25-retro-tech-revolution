extends Node

#@onready var backgroundStoryText = $VBoxContainer/BackstoryHBox/BackStoryBackStory
#@onready var backgroundStoryImage= $VBoxContainer/BackstoryHBox/BackStoryImage

func _ready():
	_on_story_received(SignalBus.gemini_backstory_text)
	_on_image_received(SignalBus.gemini_backstory_image)
	
	SignalBus.gemini_backstory_received.connect(_on_story_received)
	SignalBus.gemini_backstory_image_received.connect(_on_image_received)
	
	


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		_on_next_pressed()


#######gemini result
#display generated text
func _on_story_received(t:String):
	%BackStoryText.text = t
	scroll_text_from_top_to_bottom()

func scroll_text_from_top_to_bottom():
	var text2scroll = %BackStoryText
	var v_scroll = text2scroll.get_v_scroll_bar()
	
	# First, reset to top
	v_scroll.value = 0
	
	# Get the max scroll value
	var max_scroll = v_scroll.max_value - v_scroll.page

	# Create a tween to animate the scrollbar
	var tween = create_tween()
	var duration = 10.0  # seconds to scroll through entire text

	# Animate the scrollbar value from 0 to max
	tween.tween_property(v_scroll, "value", max_scroll, duration)
	tween.set_ease(Tween.EASE_IN)
	
	v_scroll.grab_focus()

#display the generated image
func _on_image_received(base64_image):
	print("Base64 string length: " + str(base64_image.length()))
	print("First 20 chars: " + base64_image.substr(0, 20))
	if( base64_image.length()> 0):
		print("----1")
		var image_bytes = Marshalls.base64_to_raw(base64_image)
		print("Decoded bytes length: " + str(image_bytes.size()))
		
		var save_file = FileAccess.open("res://backstory-images/debug_image" +str(Time.get_unix_time_from_system()), FileAccess.WRITE)
		#file.open("user://debug_image.png", File.WRITE)
		save_file.store_buffer(image_bytes)
		save_file.close()
		
		# Create an Image and load it from the byte data.
		var image = Image.new()
		print("----2")
		var err = image.load_png_from_buffer(image_bytes)
		#var err = image.load_png_from_buffer(image_bytes)

		if err == OK:
			print("----3")
			# Create an ImageTexture and set it on the TextureRect.
			var image_texture = ImageTexture.create_from_image(image) #add image to our background-story
			%BackStoryImage.texture = image_texture  # Display the image.
			print("Image generated and displayed successfully!")
		else:
			printerr("Failed to load image from buffer: ", err)
#next screen
func _on_next_pressed() -> void:
	SignalBus.screen_state.emit(SignalBus.LEVEL1)
