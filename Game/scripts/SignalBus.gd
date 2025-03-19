extends Node

#####Global variables
var standalone_mode = true #expect local calls to apis
var client_id = "1"
var session_id  = "1"
var score = 0
var stopwatch = 0.0 

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

signal score_up(new_score:int) #new

#user personalisation
var trivia_result = []
signal trivia_question_received(idx, qa)

var gemini_help: String = "テスト" #msg from gemini displayed in a dialogbox
var gemini_backstory_text: String = "The year is 2042. Forgotten beneath the gleaming skyscrapers of Neo-City lies Sector 7, a relic of a bygone era. This abandoned datacenter, once a hub of cutting-edge technology (well, cutting-edge for the 80s and 90s!), is now a chaotic mess of flickering CRTs, tangled wires, and mountains of obsolete floppy disks. A rogue AI, known only as 'The Core', has taken root within the system, feeding off the residual energy and causing strange anomalies throughout the city.Your mission, should you choose to accept it (and you did sign the waiver), is to delve into the depths of Sector 7, purge the obsolete technology" #background story to be displayed
var gemini_backstory_image: String = "image"
######gemini interaction######
signal gemini_help_received(help:String)
signal gemini_backstory_received(msg)
signal gemini_backstory_image_received(base64_image:String)

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
signal tool_changed(new_tool)#new

######player behavior######
signal player_created(player:Player)
signal player_moving(player:Player, pressed_button)
signal player_taking_damage(p:Player, e:Enemy)
signal player_iddle(player:Player)
signal player_score_increased(player:Player) #--> check
signal player_health_depleted(player:Player)#new
signal bullet_created(new_bullet:Bullet)

######Enemies Signal######
signal enemy_created(e:Enemy)
signal enemy_taking_damage(e:Enemy, player_damage:int)
signal enemy_health_depleted(e:Enemy)#new

func _ready() -> void:
	SignalBus.trivia_question_received.connect(_on_trivia_question_received)

#store it for gemini
func _on_trivia_question_received(_idx, qa):
	trivia_result.append(qa)

#wait X seconds
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
