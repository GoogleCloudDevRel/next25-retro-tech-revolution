extends CanvasLayer

#@onready var backgroundStoryText = $VBoxContainer/BackstoryHBox/BackStoryBackStory
#@onready var backgroundStoryImage= $VBoxContainer/BackstoryHBox/BackStoryImage

var is_story_received = false
var is_scrolling = false

func _ready():
	_on_story_received(SignalBus.gemini_backstory_text)
	_on_image_received(SignalBus.gemini_backstory_image)
	
	SignalBus.gemini_backstory_received.connect(_on_story_received)
	#SignalBus.gemini_backstory_image_received.connect(_on_image_received)

	


func _process(_delta: float) -> void:
	var scroll_direction = 0
	var scroll_speed = 20
	var rich_text_label = %BackStoryText
# For gamepad D-pad input
	if Input.is_action_pressed("ui_down"):
		#print("down")
		scroll_direction = 1
	if Input.is_action_pressed("ui_up"):
		#print("up")
		scroll_direction = -1
	# Apply scrolling
	if scroll_direction != 0:
		# Get the current scroll position
		
		var v_scroll_bar = rich_text_label.get_v_scroll_bar()
		# Calculate new scroll position
		var current_scroll = v_scroll_bar.value
		var new_scroll = current_scroll + (scroll_direction * scroll_speed)
		
		#print(v_scroll_bar.max_value)
		
		# Clamp between valid values
		new_scroll = clamp(new_scroll, 0, v_scroll_bar.max_value+ 500)
			
		# Set the scrollbar value (this is equivalent to setting v_scroll)
		v_scroll_bar.value = new_scroll
		#print(str(v_scroll_bar.value) + " " + str(new_scroll) +" "+str(v_scroll_bar.max_value))
	
	if !is_scrolling:
		scroll_text_from_top_to_bottom()
		
		
	
	if Input.is_action_just_pressed("attack"):
		_on_next_pressed()


#######gemini result
#display generated text
func _on_story_received(t:String):
	%BackStoryText.text = t.to_upper()
	#scroll_text_from_top_to_bottom()

func scroll_text_from_top_to_bottom():
	is_scrolling = true
	var text2scroll = %BackStoryText
	var v_scroll = text2scroll.get_v_scroll_bar()
	
	# First, reset to top
	v_scroll.value = 0
	#print(v_scroll.value)
	# Get the max scroll value
	var max_scroll = v_scroll.max_value
	#print("-->" + str(max_scroll))
	# Create a tween to animate the scrollbar
	var tween = create_tween()
	var duration = 20.0  # seconds to scroll through entire text

	# Animate the scrollbar value from 0 to max
	tween.tween_property(v_scroll, "value", max_scroll, duration)
	tween.set_ease(Tween.EASE_IN)
	
	v_scroll.grab_focus()

#display the generated image
func _on_image_received(base64_image):
	#var base64_image = SignalBus.gemini_backstory_image
	#print("Base64 string length: " + str(base64_image.length()))
	print("First 20 chars: " + base64_image.substr(0, 20))
	if( base64_image.length()> 0):
		#print("----1")
		var image_bytes = Marshalls.base64_to_raw(base64_image)
		#print("Decoded bytes length: " + str(image_bytes.size()))
		
		#var save_file = FileAccess.open("user://backstory-images/debug_image" +str(Time.get_unix_time_from_system()), FileAccess.WRITE)
		#file.open("user://debug_image.png", File.WRITE)
		#save_file.store_buffer(image_bytes)
		#save_file.close()
		
		# Create an Image and load it from the byte data.
		var image = Image.new()
		#print("----2")
		var err = image.load_png_from_buffer(image_bytes)
		#var err = image.load_png_from_buffer(image_bytes)

		if err == OK:
			#print("----3")
			# Create an ImageTexture and set it on the TextureRect.
			var image_texture = ImageTexture.create_from_image(image) #add image to our background-story
			%BackStoryImage.texture = image_texture  # Display the image.
			#print("Image generated and displayed successfully!")
		else:
			printerr("Failed to load image from buffer: ", err)
#next screen
func _on_next_pressed() -> void:
	SignalBus.screen_state.emit(SignalBus.LEVEL1)
