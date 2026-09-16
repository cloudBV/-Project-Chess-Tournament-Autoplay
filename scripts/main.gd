extends Node

@onready var chess_board = $ChessBoard
@onready var move_timer = $MoveTimer
#@onready var next_game_button = $UI/NextGameButton
#@onready var game_info_label = $UI/GameInfoLabel
#@onready var restart_button = $UI/RestartButton
#@onready var auto_advance_toggle = $UI/AutoAdvanceToggle
#@onready var move_counter_label = $UI/MoveCounterLabel
#@onready var category_label = $UI/CategoryLabel
@onready var ui = $UI

#const CURRENT_CATEGORY = 'london'

const CATEGORY_DISPLAY_NAMES = {
	'caro_kann' : 'Caro-Kann Defense',
	'english' : 'English Opening',
	'four_knights' : 'Four Knights Game',
	'french' : 'French Defense',
	'indian' : 'Indian Defense',
	'italian' : 'Italian Game',
	'london' : 'London System',
	'sicilian' : 'Sicilian Defense'
}

var enabled_categories : Array = [
'caro_kann',
'english',
'four_knights',
'french',
'indian',
'italian',
'london',
'sicilian'
]

var current_game_data : Dictionary = {}

var moves : Array = []
var current_move_index : int = 0
var current_color : String = 'white'

var auto_advance_enabled : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	move_timer.timeout.connect(_on_move_timer_timeout)
	#next_game_button.pressed.connect(load_new_game)
	#restart_button.pressed.connect(restart_current_game)
	#auto_advance_toggle.toggled.connect(_on_auto_advance_toggled)
	#auto_advance_toggle.button_pressed = true
	#category_label.text = 'Category : %s' % CATEGORY_DISPLAY_NAMES.get(CURRENT_CATEGORY , CURRENT_CATEGORY)
	ui.next_game_pressed.connect(load_new_game)
	ui.restart_pressed.connect(restart_current_game)
	ui.auto_advance_toggled.connect(_on_auto_advance_toggled)
	ui.category_toggled.connect(_on_category_toggled)
	ui.build_category_checkboxes(CATEGORY_DISPLAY_NAMES, enabled_categories)
	load_new_game()

func _on_auto_advance_toggled(is_on : bool):
	auto_advance_enabled = is_on
	#auto_advance_toggle.text = str('Auto Advance : On') if is_on else str('Auto Advance : Off')
	ui.set_auto_advance_label(is_on)
	if is_on and current_move_index >= moves.size():
		load_new_game()

	if is_on and current_move_index >= moves.size():
		load_new_game()

func _on_category_toggled(category: String, is_on : bool):
	if is_on:
		if not enabled_categories.has(category):
			enabled_categories.append(category)
	else:
		if enabled_categories.size() <= 1:
			ui.build_category_checkboxes(CATEGORY_DISPLAY_NAMES, enabled_categories)
			return
		enabled_categories.erase(category) 

func start_game(game_data : Dictionary):
	move_timer.stop()
	chess_board.reset_board()
	moves = PGNParser.tokenize_pgn(game_data['movetext'])
	current_move_index = 0
	current_color = 'white'
	#category_label.text = 'Category : %s' % CATEGORY_DISPLAY_NAMES.get(game_data.get('category' , '') , 'Unknown')
	ui.set_category_text('Category : %s' % CATEGORY_DISPLAY_NAMES.get(game_data.get('category' , '') , 'Unknown'))
	update_game_info(game_data['metadata'])
	update_move_counter()
	move_timer.start()

func update_game_info(metadata : Dictionary):
	var white = metadata.get('White' , 'Unknown')
	var black = metadata.get('Black' , 'Unknown')
	var white_elo = metadata.get('WhiteElo' , '?')
	var black_elo = metadata.get('BlackElo' , '?')
	var opening = metadata.get('Opening' , 'Unknown Opening')
	var result = metadata.get('Result' , '')
	
	var result_text = ''
	match result:
		'1-0' : result_text = 'White wins'
		'0-1' : result_text = 'Black wins'
		'1/2-1/2' : result_text = 'Draw'
		_: result_text = 'In progress'
		
	#game_info_label.text = '%s\n\n%s (%s) vs %s (%s)\n\n%s' % [opening, white, white_elo, black, black_elo, result_text]
	ui.set_game_info('%s\n\n%s (%s) \nvs\n %s (%s)\n\n%s' % [opening, white, white_elo, black, black_elo, result_text])


func update_move_counter():
	#move_counter_label.text = 'Move %d / %d' % [current_move_index , moves.size()]
	ui.set_move_counter('Move %d / %d' % [current_move_index , moves.size()])

func load_new_game():
	#var game_data = PGNParser.get_random_game_from_category('london')
	#var game_data = PGNParser.load_pgn_file('res://assets/games/london/queen_s_pawn_game_accelerated_london_system_steinitz_countergambit_005.txt')
	#start_game(game_data)
	#current_game_data = PGNParser.get_random_game_from_category(CURRENT_CATEGORY)
	current_game_data = PGNParser.get_random_game_from_categories(enabled_categories)
	start_game(current_game_data)

func restart_current_game():
	start_game(current_game_data)

func _on_move_timer_timeout():
	if current_move_index >= moves.size():
		move_timer.stop()
		if auto_advance_enabled:
			load_new_game()
		return
		
	var token = moves[current_move_index]
	chess_board.apply_token(token, current_color)
	
	current_move_index += 1
	current_color = 'black' if current_color == 'white' else 'white'
	update_move_counter()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		load_new_game()
