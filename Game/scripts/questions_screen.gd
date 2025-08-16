extends CanvasLayer

#questions
var trivia = []
var trivia_JP = []
var trivia_labels = []
var current_trivia_selection = 0

#focus management
var buttons = []
var current_button_index = 0

var disable_buttons = true


#pick randomly an answer 
func _on_answer5_pressed():
	if trivia[current_trivia_selection]["a"].size() == 0:
		return null
	randomize()
	var random_index = randi() % trivia[current_trivia_selection]["a"].size()
	_on_button_pressed(random_index)
	
func _ready() -> void:
	
	
	#random color blocks
	
	
	#manage focus with joypad
	buttons = [%Answer1, %Answer2, %Answer3, %Answer4]
		
	#Q1
	trivia.append({
	"q" : "✦ WHAT'S YOUR FAVORITE FRUIT?",
	"a" : ["🍊\nORANGE", "🍓\nSTRAWBERRY", "🍌\nBANANA", "🍉\nWATERMELON"]
	})
	#Q2
	trivia.append({
	"q" : "✦ ARE YOU MORE?",
	"a" : ["ADVENTUROUS", "COZY BEHIND A DESK", "DREAMING ABOUT SCIFI", "NOT REALLY INTO ANYTHING"]
	})
	#Q3
	trivia.append({
	"q" : "✦ HOW MUCH OF A GAMER ARE YOU?",
	"a" : ["BRING IT ON, I LOVE SUPER HARD GAMES!", "I'M MODERATELY INTO GAMES", "I ENJOY MORE WATCHING", "NOT A PLAYER, I'M HERE FOR THE INSIGHTS"]
	})
	
	## -- JP support
	trivia_JP.append({
	"q" : "✦ 好きな果物は何ですか？",
	"a" : ["🍊\nオレンジ", "🍓\nイチゴ", "🍌\nバナナ", "🍉\nスイカ"]
	})
	#Q2
	trivia_JP.append({
	"q" : "✦ どちらかと言えば",
	"a" : ["アクティブな方ですか", "お家でゆっくり過ごすのか", "SFの世界を妄想するのが", "特にハマっていることはありません"]
	})
	#Q3
	trivia_JP.append({
	"q" : "✦ ゲームはどの程度やりますか？",
	"a" : ["かかってこい！激ムズのゲームが大好きだ！", "ゲームはそこそこやります。", "自分でやるより、見る方が好きです。", "ゲームはしないのですが、データ分析の方が興味あります。"]
	})
	
	#--default: EN
	
	##--- JP
	if SignalBus.language == "JP":
		trivia_labels = trivia_JP
		%Answer5.text = "驚かせて下さい！"
	else:
		trivia_labels = trivia
		%Answer5.text = "JUST SURPRISE ME"
	set_button_texts(trivia_labels[current_trivia_selection])	
			
	buttons[0].grab_focus()
	
	# Connect signals for all buttons
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_button_pressed.bind(i))
	
	await get_tree().create_timer(2.0).timeout  # Wait time for cooldown
	disable_buttons = false
	
func _process(_delta):
	#manage focus with joypad
	if Input.is_action_just_pressed("attack"):
		_on_button_pressed(current_button_index)
		
	if Input.is_action_just_pressed("ui_right"):
		# Move to next button
		current_button_index = min(current_button_index + 1, buttons.size() - 1)
		buttons[current_button_index].grab_focus()
	elif Input.is_action_just_pressed("ui_left"):
		# Move to previous button
		current_button_index = max(current_button_index - 1, 0)
		buttons[current_button_index].grab_focus()	

func set_button_texts(qa_array):
	#print( qa_array['q'])
	%Question.text = qa_array['q']
	#buttons[0].grab_focus()
	for i in qa_array['a'].size():
		#print( qa_array['a'][i])
		buttons[i].text = qa_array['a'][i]

func _on_button_pressed(button_index):
	if !disable_buttons:
		disable_buttons = true
		#print("Question " + trivia[current_trivia_selection]['a'][button_index])
		SignalBus.trivia_question_received.emit(trivia[current_trivia_selection]['q'], trivia[current_trivia_selection]['a'][button_index])
		current_trivia_selection += 1
		if current_trivia_selection < trivia.size():
			#print("next question")
			set_button_texts(trivia_labels[current_trivia_selection])
		else: #go back to the game
			#print("finsihed")
			SignalBus.screen_state.emit(SignalBus.CONTROLS)	
		
		await get_tree().create_timer(1.0).timeout  # Wait time for cooldown
		disable_buttons = false
