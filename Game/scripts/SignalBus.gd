extends Node

#####Global variables
var standalone_mode = true #expect local calls to apis
var client_id = ""
var session_id= ""
var has_session_id = false
var has_client_id = false
var score = 0
var stopwatch = 0.0
enum {EASY, MEDIUM, HARD}
var game_difficulty = HARD #difficulty level
var last_screenshot = "res://assets/map/mini_map.png" #last screenshot taken in base64
var last_screenshot_timestamp = ""
const SEND_SCREENSHOTS = true 
const GCS_BUCKET_BACKSTORIES = "gs://rtr_backstories"
### message bus that dispatch events between classes of the game
######All game states - our Finite state machine	
enum {SPLASHSCREEN, QUESTIONS, CONTROLS, BACKSTORY, LEVEL1, BOSS1, GAMEOVER}
var current_screen_state = SPLASHSCREEN
signal screen_state(_new_state) #new

####ref to main elements
var players = []
var enemies = []
var bullets = []
var boss = []

###
var past_session_id = []
var past_client_id = []
#####

signal start_game() #actual start of the game
signal end_game()

#paunsing the game
signal pause_game()
signal unpause_game()

signal reset_game()
signal replay_game()


signal stop_game_stopwatch() #new 3/24
signal show_congratulations() #new 3/24

signal score_up(new_score:int) #new

signal session_rank_received(rank:String)


signal send_screenshot_to_gcs() 

#user personalisation
var trivia_result = []
signal trivia_question_received(idx, qa)

var gemini_help: String = "テスト" #msg from gemini displayed in a dialogbox
var gemini_backstory_text: String = "The year is 2042. Forgotten beneath the gleaming skyscrapers of Neo-City lies Sector 7, a relic of a bygone era. This abandoned datacenter, once a hub of cutting-edge technology (well, cutting-edge for the 80s and 90s!), is now a chaotic mess of flickering CRTs, tangled wires, and mountains of obsolete floppy disks. A rogue AI, known only as 'The Core', has taken root within the system, feeding off the residual energy and causing strange anomalies throughout the city.Your mission, should you choose to accept it (and you did sign the waiver), is to delve into the depths of Sector 7, purge the obsolete technology" #background story to be displayed
var gemini_backstory_image: String = "image"
######gemini interaction######
signal gemini_help_received(help:String)
signal gemini_backstory_received(msg)
signal gemini_backstory_image_received()

#internal signals only
signal gemini_help_requested() #for triggering the call in the game
signal gemini_backstory_requested() #for triggering the call in the game
signal gemini_backstory_image_requested() #internal only
signal gemini_summary_received(summary:String)


#both internal & analytics
signal gemini_difficulty_adjusted(level:int, reason:String)

# Analytics only
signal gemini_help_requested_details(prompt_text:String, base64_image:String) 
signal gemini_backstory_requested_details(prompt_text:String)



######options######
signal tool_changed(new_tool)#new to replace with weapon_changed(old_weapon, new_weapon)
signal weapon_created(weapon:Weapon) #added 
signal weapon_activated(weapon_name:String, weapon_idx:int) #Added on 03/24
signal weapon_changed(weapon_name:String, weapon_idx:int) #Added on 03/24

######player behavior######
signal player_created(player:Player)
signal player_moving(player:Player, pressed_button)
signal player_taking_damage(p:Player, e:Enemy)
signal player_idle(p:Player, idle_time:int)
signal player_score_increased(points:int) #--> check
signal player_health_depleted(player:Player)#new
signal bullet_created(new_bullet:Bullet)

######Enemies Signal######
signal enemy_created(e:Enemy)
signal enemy_taking_damage(e:Enemy, player_damage:int)
signal enemy_health_depleted(e:Enemy)#new
signal floppy_created(floppy:Projectiles)

######Boss Signal######
signal boss_created(b:Boss) #Added on 03/24

func _ready() -> void:
	load_config_file()
	session_id = generate_session_id() 
	client_id = generate_client_id()
	has_session_id = true
	has_client_id = true
	print(session_id+" "+client_id)
	print("User directory: ", OS.get_user_data_dir())
	save_config_file()
	
	if trivia_result.size() > 0:
		if trivia_result[2]['a'] == "BRING IT ON, I LOVE SUPER HARD GAMES!":
			game_difficulty = HARD
		elif trivia_result[2]['a'] ==  "I'M MODERATELY INTO GAMES":
			game_difficulty = MEDIUM
		else:
			game_difficulty = EASY
	
	SignalBus.trivia_question_received.connect(_on_trivia_question_received)
	SignalBus.player_created.connect(_on_player_created)
	SignalBus.enemy_created.connect(_on_enemies_created)
	SignalBus.boss_created.connect(_on_boss_created)
	
#store it for gemini
func _on_trivia_question_received(q, a):
	trivia_result.append({'q':q,'a':a})

func _on_player_created(p:Player):
	#print("received player")
	players.append(p)

func _on_enemies_created(e:Enemy):
	enemies.append(e)

func _on_boss_created(b:Boss):
	boss.append(b)


#wait X seconds
func wait(seconds: float, function) -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = seconds  # Wait for 2 seconds
	timer.one_shot = true  # Only run once
	timer.timeout.connect(function)
	timer.start()

func get_stopwatch():
	var  msec = fmod(SignalBus.stopwatch, 1) * 1000
	var  sec = fmod(SignalBus.stopwatch, 60)
	var minutes = SignalBus.stopwatch/60
	#00 : 00 . 000
	var format_string = "%02d : %02d . %02d"
	return format_string % [minutes, sec, msec]


#read config file when we start
func load_config_file():
	if FileAccess.file_exists("user://rtr_save_game.json"):
		var save_file = FileAccess.open("user://rtr_save_game.json", FileAccess.READ)
		var json_string = save_file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
			
		if parse_result == OK:
			var data = json.data
			#var health = data["player"]["health"]
			past_client_id = data["past_client_id"]
			past_session_id = data["past_session_id"]
			
#write session ids & client ids
func save_config_file():
	#if FileAccess.file_exists("user://rtr_save_game.json"):
	var save_dict = {"past_session_id": past_session_id,
						"past_client_id": past_client_id }
	var json_string = JSON.stringify(save_dict)
	var save_file = FileAccess.open("user://rtr_save_game.json", FileAccess.WRITE)
	save_file.store_string(json_string)
	save_file.close()

#### Generate friendly session id and client id
var c_nouns = ["cat", "mountain", "forest", "sword", "castle", "dragon", "hero", "wizard", "planet", "robot", "champion", "victory", "sunshine", "treasure", "paradise", 
	"harmony", "success", "laughter", "dream", "wonder",
	"hero", "diamond", "garden", "triumph", "joy",
	"blessing", "miracle", "star", "adventure", "achievement",
	"friend", "rainbow", "genius", "wisdom", "fortune",
	"progress", "angel", "melody", "breeze", "flower",
	"peace", "spark", "reward", "discovery", "delight",
	"heart", "smile", "freedom", "glory", "magic"]
	
var c_adjectives = ["brave", "ancient", "mysterious", "glowing", "dark", "frozen", "magic", "golden", "brilliant", "joyful", "amazing", "wonderful", "excellent", 
	"beautiful", "vibrant", "radiant", "inspiring", "delightful",
	"spectacular", "magnificent", "peaceful", "cheerful", "optimistic",
	"charming", "dazzling", "fabulous", "glorious", "triumphant",
	"fortunate", "victorious", "enchanting", "generous", "loving",
	"happy", "uplifting", "thriving", "exquisite", "flawless",
	"perfect", "marvelous", "gentle", "brave", "energetic",
	"sparkling", "talented", "successful", "enthusiastic", "heavenly"]

var s_nouns = [
		"Data", "Network", "System", "Code", "Chip", "Drive", "Console", "Device",
		"Machine", "Robot", "Interface", "Protocol", "Server", "Cloud", "Pixel",
		"Byte", "Bit", "Logic", "Circuitry", "Algorithm", "Processor", "Memory",
		"Database", "Software", "Hardware", "Terminal", "Firewall", "Router",
		"Gateway", "Transistor", "Module", "Component", "Input", "Output", "Signal",
		"Vector", "Array", "Matrix", "Register", "Buffer"
	]

var s_adjectives = [
		"Retro", "Digital", "Virtual", "Cyber", "Binary", "Analog", "Circuit",
		"Quantum", "Neural", "Silicon", "Magnetic", "Optical", "Robotic",
		"Automated", "Integrated", "Wired", "Wireless", "Encoded", "Programmed",
		"Algorithmic", "Technological", "Electronic", "Mechanical", "Synthetic",
		"Modular", "Interactive", "Computational", "Peripheral", "Infrastructural",
		"Operational", "Futuristic", "Legacy", "Obsolete", "Innovative",
		"Sophisticated", "Primitive", "Complex", "Simple", "Dynamic", "Static"
	]

func reset_game_settings():
	session_id = generate_session_id() 
	client_id = generate_session_id()
	has_session_id = true
	has_client_id = true
	score = 0
	stopwatch = 0.0
	game_difficulty = EASY #difficulty level
	last_screenshot = "res://assets/map/mini_map.png" #last screenshot taken in base64
	last_screenshot_timestamp = ""
	players = []
	enemies = []
	bullets = []
	boss = []
	trivia_result = []
	
#we keep the same client id	
func replay_game_settings():
	session_id = generate_session_id() 
	has_session_id = true
	score = 0
	stopwatch = 0.0
	game_difficulty = EASY #difficulty level
	last_screenshot = "res://assets/map/mini_map.png" #last screenshot taken in base64
	last_screenshot_timestamp = ""
	players = []
	enemies = []
	bullets = []
	boss = []
	trivia_result = []
	
	


	


func generate_session_id() -> String:
		var not_ok = true
		while not_ok: #generate session_ids until finding a new one
			var new_session_id = generate_random_session_id()
			if new_session_id not in past_session_id:
				not_ok = false
				past_session_id.append(new_session_id)
				return new_session_id
		return ""

func generate_random_session_id() -> String:
		var random_adjective = s_adjectives[randi() % s_adjectives.size()]
		var random_noun = s_nouns[randi() % s_nouns.size()]
		var random_number = randi() % 900 + 100
		return random_adjective + "_" + random_noun + "_" + str(random_number)

func generate_client_id() -> String:
		var not_ok = true
		while not_ok: #generate session_ids until finding a new one
			var new_client_id = generate_random_client_id()
			if new_client_id not in past_client_id:
				not_ok = false
				past_client_id.append(new_client_id)
				return new_client_id
		return ""

func generate_random_client_id(): #144,000 possibilities
		var random_adjective = c_adjectives[randi() % c_adjectives.size()]
		var random_noun = c_nouns[randi() % c_nouns.size()]
		var random_number = randi() % 90 + 10
		return random_adjective + "_" + random_noun + "_" + str(random_number)
