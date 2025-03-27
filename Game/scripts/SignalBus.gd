extends Node

#####Global variables
var standalone_mode = true #expect local calls to apis
var client_id = "1"
var session_id
var score = 0
var stopwatch = 0.0
enum {EASY, MEDIUM, HARD}
var game_difficulty = EASY #difficulty level
var last_screenshot = "" #last screenshot taken in base64
var last_screenshot_timestamp = ""
const SEND_SCREENSHOTS = true 
const GCS_BUCKET_BACKSTORIES = "gs://rtr_backstories"
### message bus that dispatch events between classes of the game
######All game states - our Finite state machine	
enum {SPLASHSCREEN, QUESTIONS, CONTROLS, BACKSTORY, LEVEL1, BOSS1, GAMEOVER}
var current_screen_state = SPLASHSCREEN
signal screen_state(_new_state) #new
####

signal start_game() #actual start of the game
signal end_game()

signal pause_game()
signal unpause_game()

signal stop_game_stopwatch() #new 3/24
signal show_congratulations() #new 3/24

signal score_up(new_score:int) #new

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
signal player_iddle(player:Player)
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
	session_id  = str(Time.get_unix_time_from_system())
	SignalBus.trivia_question_received.connect(_on_trivia_question_received)

#store it for gemini
func _on_trivia_question_received(q, a):
	trivia_result.append({'q':q,'a':a})

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
