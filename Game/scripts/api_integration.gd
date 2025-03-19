extends Node


const GEMINI_API_KEY =""


#const GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-pro-exp-02-05:generateContent?key=" + GEMINI_API_KEY
#const GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:generateContent?key=" + GEMINI_API_KEY

#const GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key" + GEMINI_API_KEY

const GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-pro-exp-02-05:generateContent?key=" + GEMINI_API_KEY
const IMAGEN3_URL ="https://us-central1-aiplatform.googleapis.com/v1/projects/data-cloud-interactive-demo/locations/us-central1/publishers/google/models/imagen-3.0-generate-002:predict"

var gcp_token = ""

var counter_before_gemini_help = 20 #wait 20 bullets before calling gemini for help 

var endpoint = "http://localhost"
###connect on all the messages
func _ready():
	##connect with bus
	#SignalBus.bullet_created.connect(_on_add_bullet_action)
	SignalBus.gemini_help_requested.connect(_on_need_gemini_help)
	SignalBus.gemini_backstory_requested.connect( _on_get_gemini_backstory)
	SignalBus.gemini_backstory_image_requested.connect(call_api_bridge_generate_backstory_image)
	#print("---api integration ready---")

###request support from Gemini sending a screenshot + prompt
func _on_need_gemini_help():
	var capture = get_viewport().get_texture().get_image()
	var _time = Time.get_datetime_string_from_system()
	var filename = "res://screenshots/Screenshot-{0}.png".format({"0":_time})
	capture.save_png(filename)
	
	var prompt_text = "You are assisting a user who is playing a video game. you know that the boss level is on the far top right side of the level,
	and that to beat him you can go retrieve an object placed in the middle of the level. You also know that the tornado can  protect you against floppy disk,
	and the flow can work against the crt. Give instruction to the player to help him go to the 2 locations. Here are some information on the player status:
		health is 80/100, hit count is 5 score=0, player hasn't moved for 1min, and time since starting the game is 2 mins, he doesn t have the necessary object yet. If you think you should not help just yet just crack a joke or give a fun fact. Prepare your answer with the textual help for the first field and a second field that represents the difficulty level of the game from 0 to 3 with 0 being easy and 3 being hard if you consider that the user is not doing well, the last field is the reason why you adjusted the difficulty a certain way, please follow a JSON format {\"help\":\"\", \"difficulty_level\":0, \"reason\":\"\"}"
	#var image_path = #"res://screenshots/screenshot-1741159543.png"  # Or "user://your_image.png", etc.
	
	var image = Image.load_from_file(filename)
	
	# 1. Encode the image to base64.
	var image_bytes = image.save_png_to_buffer() # Use PNG for best results with Gemini
	var base64_image = Marshalls.raw_to_base64(image_bytes)
	
	#signal for analytics
	SignalBus.gemini_help_requested_details.emit(prompt_text, base64_image)
	
	#call gemini
	call_gemini_with_prompt_and_image(base64_image, prompt_text) 

##########################################Signals handling & call preparation	

#using answers from the user ask gemini to generate a story about the datacenter
#using the backstory ask imagen3 gemini for a background image 
func _on_get_gemini_backstory():
	var prompt = "You are a video game story writer and you are tasked to write a very short backstory of the game to make the player want to play.\n" 
	prompt += "The game takes place in an old  datacenter from the 80s or 90s swarming with old technologies like CRTs or floppies. the hero of the story is tasked to clean those technology and find the boss that controls the old tech and hide in the datacenter.  \n 
	Use the following answers to the questions asked to the player in your story:.\n"
	for i in SignalBus.trivia_result.size():
		prompt +="Question:" + SignalBus.trivia_result[i]['q'] +", Answer:"+ SignalBus.trivia_result[i]['a'] + ".\n"	
	prompt += "Finally, Also provide instruction telling that the player needs to first find the secret tool to increase his chances to win against the boss level"
	call_gemini_backstory(prompt)

##########################################API Integration	

####Connect to a local API Bridge

#connect to the api bridge to get the backstory image
func call_api_bridge_generate_backstory_image(prompt):
	var http_request  = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_call_api_bridge_backstory_image_request_completed.bind(http_request))
	var connection ="http://localhost:5055/get_backstory_image"
	var headers = ["Content-type: x-www-form-urlencoded"]
	http_request.request(connection, headers, HTTPClient.METHOD_POST, prompt) 

func _on_call_api_bridge_backstory_image_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray, _req_node : HTTPRequest = null):
	if result != OK:
			printerr("Imagen3: failed to generate image")
	else:
		var base64_image = body.get_string_from_utf8()
		#print(base64_image)
		SignalBus.gemini_backstory_image = base64_image
		SignalBus.gemini_backstory_image_received.emit(base64_image)


#connect locally to send analytic sensors data
func call_api_bridge_analytics(json_string):
	var http_request  = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_call_api_bridge_request_completed.bind(http_request))
	var connection ="http://localhost:5055/backendcomm"
	var headers = ["Content-type: application/json"]
	http_request.request(connection, headers, HTTPClient.METHOD_POST, json_string) 

####Receiving answer from the API Bridge
func _on_call_api_bridge_request_completed(result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray, _req_node : HTTPRequest = null):
	if result != OK:
			printerr("Pub/Sub: failed to send analytic data")

####Call gemini to get a backstory
#Call
func call_gemini_backstory(prompt:String) -> String:
	var http_request  = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_call_gemini_backstory_request_completed.bind(http_request))
	var connection = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" + GEMINI_API_KEY
	var post_data = '{
  "contents": [{
	"parts":[{"text":"'+prompt+'"}]
	}]
   }'
	#var json_data = JSON.print(post_data) #convert dictionary to json string
	var headers = ["Content-Type: application/json"] #set header
	http_request.request(connection, headers, HTTPClient.METHOD_POST, post_data)
	return ""

#results received
func _on_call_gemini_backstory_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray, _req_node : HTTPRequest = null):
	if result != OK:
		print("Error")
	else:
		var dict_body = JSON.parse_string(body.get_string_from_utf8())
		print(dict_body.candidates[0].content.parts[0].text)
		SignalBus.gemini_backstory_text = dict_body.candidates[0].content.parts[0].text
		
		#send to backgound story
		call_api_bridge_generate_backstory_image(dict_body.candidates[0].content.parts[0].text)
		#SignalBus.gemini_backstory_received.emit(dict_body.candidates[0].content.parts[0].text)
		
		#generate an image that goes with the text
		#call_imagen3_generate_image("Generate an image representing the following story for a video game:" + dict_body.candidates[0].content.parts[0].text)
		
		
		
		
####call gemini with prompt & an image
#Call
func call_gemini_with_prompt_and_image(base64_image:String, prompt_text: String):
	var http_request  = HTTPRequest.new()
	add_child(http_request)
	# 2. Construct the request body (JSON).
	var request_data = {
		"contents": [
			{
				"parts": [
					{
						"text": prompt_text
					},
					{
						"inline_data": {
							"mime_type": "image/png",  # Important: Set the correct MIME type.
							"data": base64_image
						}
					}
				]
			}
		]
	}
	var json_string = JSON.stringify(request_data)

	# 3. Create an HTTPRequest node.

	http_request.request_completed.connect(_on_request_completed)

	# 4. Set headers.
	var headers = [
		"Content-Type: application/json"
		]

	# 5. Make the request.
	var error = http_request.request(GEMINI_URL, headers, HTTPClient.METHOD_POST, json_string)
	if error != OK:
		printerr("HTTP request failed: ", error)
		http_request.queue_free()  # Clean up on error
		return

	print("Sending request to Gemini...")

#received 
func _on_request_completed(_result, response_code, _headers, body):
	# Remove the HTTPRequest node now that we're done with it.
	if response_code == 200:
		# Success! Parse the JSON response.
		var response_json = JSON.parse_string(body.get_string_from_utf8())

		if response_json and response_json.has("candidates") and response_json["candidates"].size() > 0:
			if response_json["candidates"][0].has("content") and response_json["candidates"][0]["content"].has("parts"):
				var generated_text = response_json["candidates"][0]["content"]["parts"][0]["text"]
				print(generated_text)
				var parsedJSON = JSON.parse_string(generated_text.replace("```json", "").replace("```", ""))  
				
				print(parsedJSON)
				SignalBus.gemini_help_received.emit(parsedJSON ["help"])
				SignalBus.gemini_difficulty_adjusted.emit(parsedJSON["difficulty_level"], parsedJSON['reason'])
			else:
				printerr("Unexpected response format (no content/parts):", response_json)
		else: 
			printerr("Unexpected response format (no candidates):", response_json)

	else:
		printerr("Gemini HTTP request failed with code ", response_code)
		printerr("Response body:\n", body.get_string_from_utf8())  # Print the raw response for debugging.

####### generate story background image with imagen3
func call_imagen3_generate_image(prompt_text: String):
	# 1. Construct the request body.
	var request_data = {
		"contents": [
			{
				"parts": [
					{
						"text": prompt_text
					}
				]
			}
		]
	}
	#imagen3 format
	request_data = {
		"instances": [
			{
				"prompt": prompt_text
			}
			],
			"parameters": {
			"sampleCount": 1,
			"aspectRatio": "1:1",
			"negativePrompt": "",
			"enhancePrompt": false,
			"personGeneration": "allow_adult",
			"safetySetting": "block_few",
			"addWatermark": true,
			"includeRaiReason": true,
			"language": "auto"
			}	
	}
	
	
	var json_string = JSON.stringify(request_data)

	# 2. Create an HTTPRequest node.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect( _on_background_story_image_completed)

	# 3. Set headers.
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer "+ gcp_token
	]

	# 4. Make the request.
	var error = http_request.request(IMAGEN3_URL, headers, HTTPClient.METHOD_POST, json_string)
	if error != OK:
		printerr("HTTP request failed: ", error)
		http_request.queue_free()
		return

	print("Sending request to Gemini...")

#receive results from Gemini
# TODO go through the API Bridge using python
func _on_background_story_image_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var response_json = JSON.parse_string(body.get_string_from_utf8())
		if response_json and response_json.has("predictions") and response_json["predictions"].size() > 0:
			if response_json["predictions"][0].has("bytesBase64Encoded"):
						# Decode the base64 image data.
						var base64_image = response_json["predictions"][0]["bytesBase64Encoded"]
						SignalBus.gemini_backstory_image = base64_image
						SignalBus.gemini_backstory_image_received.emit(base64_image)
			else:
				printerr("Unexpected response format (no predictions content):", response_json)
		else:
			printerr("Unexpected response format (no predictions):", response_json)
	else:
		printerr("HTTP request failed with code ", response_code)
		printerr("Response body:\n", body.get_string_from_utf8())
