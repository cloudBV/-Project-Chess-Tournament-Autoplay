extends Control

const SQUARE_SCENE = preload('res://scenes/square.tscn')
const LIGHT_COLOR = Color(0.93,0.93,0.82)
const DARK_COLOR = Color(0.46,0.59,0.34)

@onready var board_grid = $Board

const PIECE_SCENE = preload('res://scenes/piece.tscn')

const START_LAYOUT = {
	0: ['rook','knight','bishop','queen','king','bishop','knight','rook'],
	1: ['pawn','pawn','pawn','pawn','pawn','pawn','pawn','pawn'],
	6: ['pawn','pawn','pawn','pawn','pawn','pawn','pawn','pawn'],
	7: ['rook','knight','bishop','queen','king','bishop','knight','rook']
}

var board_state = []

var animations_enabled : bool = true
const ANIMATION_DURATION : float = 0.3

var last_highlighted_squares : Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_board_state()
	build_board()
	place_starting_pieces()
	sync_state_form_layout()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func init_board_state():
	board_state.clear()
	for row in 8:
		var row_data = []
		for col in 8:
			row_data.append(null)
		board_state.append(row_data)

func build_board():
	for row in 8:
		for col in 8:
			var square = SQUARE_SCENE.instantiate()
			board_grid.add_child(square)
			square.board_row = row
			square.board_col = col
			var is_light = (row + col) % 2 == 0
			square.set_base_color(LIGHT_COLOR if is_light else DARK_COLOR)

func place_starting_pieces():
	for row in START_LAYOUT.keys():
		var color = 'black' if row <= 1 else 'white'
		var color_code = 'b' if color == 'black' else 'w'
		var types = START_LAYOUT[row]
		for col in 8:
			var type = types[col]
			var texture = load('res://assets/sprite/pieces/%s_%s_png_128px.png' % [color_code,type])
			var piece = PIECE_SCENE.instantiate()
			var square = board_grid.get_child(row * 8 + col)
			square.place_piece(piece)
			piece.setup(type,color,texture)

func sync_state_form_layout():
	for row in START_LAYOUT.keys():
		var color = 'black' if row<= 1 else 'white'
		var types = START_LAYOUT[row]
		for col in 8:
			board_state[row][col] = {'type': types[col], 'color': color}

func promote_piece(square : Array , new_type : String , color : String):
	var row = square[0]
	var col = square[1]
	var target_square = board_grid.get_child(row * 8 + col)
	var piece = target_square.piece_instance
	var color_code = 'b' if color == 'black' else 'w'
	var texture = load('res://assets/sprite/pieces/%s_%s_png_128px.png' % [color_code, new_type])
	
	piece.setup(new_type , color, texture)
	board_state[row][col] = {'type' : new_type , 'color' : color}

func finish_promotion(square , new_type : String):
	var piece = square.piece_instance
	var color = piece.piece_color
	var color_code = 'b' if color == 'black' else 'w'
	var texture = load('res://assets/sprite/pieces/%s_%s_png_128px.png' % [color_code , new_type])
	piece.setup(new_type , color , texture)

func apply_move(from: Array , to: Array , promotion_type : String = ''):
	highlight_move(from, to)
	
	var from_row = from[0]
	var from_col = from[1]
	var to_row = to[0]
	var to_col = to[1]
	
	var from_square = board_grid.get_child(from_row * 8 + from_col)
	var to_square = board_grid.get_child(to_row * 8 + to_col)
	
	if to_square.piece_instance != null:
		to_square.remove_piece()
		
	var moving_piece = from_square.piece_instance
	var start_pos = moving_piece.global_position
	
	from_square.release_piece()
	
	if animations_enabled:
		add_child(moving_piece)
		moving_piece.global_position = start_pos
		
		var target_pos = to_square.global_position + Vector2(to_square.size.x / 2 , to_square.size.y / 2)
		var tween = create_tween()
		tween.tween_property(moving_piece , 'global_position' , target_pos , ANIMATION_DURATION)
		tween.finished.connect(func():
			remove_child(moving_piece)
			to_square.place_piece(moving_piece)
			if promotion_type != '':
				finish_promotion(to_square , promotion_type)
			)
	else:
		to_square.place_piece(moving_piece)
		if promotion_type != '':
			finish_promotion(to_square , promotion_type)
	
	board_state[to_row][to_col] = board_state[from_row][from_col]
	board_state[from_row][from_col] = null
	if promotion_type != '':
		var piece_color = board_state[to_row][to_col]['color']
		board_state[to_row][to_col] = {'type' : promotion_type , 'color' : piece_color}

func apply_castle(color: String , side: String):
	#highlight_move(from, to)
	
	var row = 7 if color == 'white' else 0
	var king_from_col = 4
	var rook_from_col = 7 if side == 'kingside' else 0
	var king_to_col = 6 if side == 'kingside' else 2
	var rook_to_col = 5 if side == 'kingside' else 3
	
	apply_move([row, king_from_col],[row, king_to_col])
	apply_move([row, rook_from_col], [row, rook_to_col])

func apply_en_passant(origin: Array, destination: Array, color: String):
	#highlight_move(from, to)
	
	var captured_row = origin[0]
	var captured_col = destination[1]
	var captured_square = board_grid.get_child(captured_row * 8 + captured_col)
	captured_square.remove_piece()
	board_state[captured_row][captured_col] = null
	
	apply_move(origin, destination)

func apply_token(token: String, color: String):
	var parsed = PGNParser.parse_token(token)
	
	if parsed.get('is_castle', false):
		apply_castle(color, parsed['castle_side'])
		return
	
	var destination = parsed['destination']
	var piece_type = parsed['piece_type']
	var disambiguation = parsed['disambiguation']
	var is_capture = parsed['is_capture']
	
	var origin = [-1,-1]
	var is_en_passant = false
	match piece_type:
		'pawn':
			var result = PGNParser.find_pawn_origin(destination, color, is_capture, disambiguation, board_state)
			origin = result['origin']
			is_en_passant = result['is_en_passant']
			#origin = PGNParser.find_pawn_origin(destination, color, is_capture, disambiguation, board_state)
		'knight':
			origin = PGNParser.find_knight_origin(destination, color, disambiguation, board_state)
		'bishop':
			origin = PGNParser.find_bishop_origin(destination, color, disambiguation, board_state)
		'rook':
			origin = PGNParser.find_rook_origin(destination, color, disambiguation, board_state)
		'queen':
			origin = PGNParser.find_queen_origin(destination, color, disambiguation, board_state)
		'king':
			origin = PGNParser.find_king_origin(destination, color, board_state)
	if origin == [-1,-1]:
		#print('Failed to Find Origin for Token: ', token, ' Color: ', color)
		#print('Current board_state : ', board_state)
		return
	
	var promotion_type = parsed.get('promotion_type' , '')
	
	if is_en_passant:
		apply_en_passant(origin, destination, color)
	else:
		apply_move(origin, destination , promotion_type)
	
#	var promotion_type = parsed.get('promotion_type' , '')
#	if promotion_type != '':
#		promote_piece(destination, promotion_type, color)


func play_full_game(pgn_movetext: String):
	var tokens = PGNParser.tokenize_pgn(pgn_movetext)
	var color = 'white'
	for token in tokens:
		apply_token(token, color)
		color = 'black' if color == 'white' else 'white'

func highlight_move(from : Array , to : Array):
	for square in last_highlighted_squares:
		square.set_highlight(false)
		
	var from_square = board_grid.get_child(from[0] * 8 + from[1])
	var to_square = board_grid.get_child(to[0] * 8 + to[1])
	
	from_square.set_highlight(true)
	to_square.set_highlight(true)
	
	last_highlighted_squares = [from_square , to_square]
	
func reset_board():
	for square in board_grid.get_children():
		square.remove_piece()
		square.set_highlight(false)
	
	init_board_state()
	place_starting_pieces()
	sync_state_form_layout()
