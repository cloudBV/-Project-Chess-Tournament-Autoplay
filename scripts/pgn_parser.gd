class_name PGNParser
extends RefCounted

static func tokenize_pgn(movetext : String) -> Array:
	var raw_tokens = movetext.split(' ', false)
	var moves = []
	for token in raw_tokens:
		if token in ['1-0','0-1','1/2-1/2','*']:
			continue
		var dot_index = token.find('.')
		if dot_index != -1:
			token = token.substr(dot_index + 1)
		if token != '':
			moves.append(token)
	return moves

static func parse_token(token: String) -> Dictionary:
	var working = token.replace('+','').replace('#','')
	
	if working == 'o-o' or working == 'O-O' or working == '0-0':
		return{
			'is_castle' : true,
			'castle_side' : 'kingside'
		}
	if working == 'o-o-o' or working == 'O-O-O' or working == '0-0-0':
		return{
			'is_castle' : true,
			'castle_side' : 'queenside'
		}
	
	var promotion_type = ''
	var eq_index = working.find('=')
	var piece_type = 'pawn'
	var piece_letters = {
		'N':'knight',
		'B':'bishop',
		'R':'rook',
		'Q':'queen',
		'K':'king'
	}

	if eq_index != -1:
		var promo_letter = working.substr(eq_index + 1, 1)
		promotion_type = piece_letters[promo_letter]
		working = working.substr(0, eq_index)
	
	
	if piece_letters.has(working[0]):
		piece_type = piece_letters[working[0]]
		working = working.substr(1)
	
	var is_capture = working.contains('x')
	working = working.replace('x','')
	
	var dest_str = working.substr(working.length()-2)
	var dest_col = dest_str.unicode_at(0) - 'a'.unicode_at(0)
	var dest_row = 8 - int(dest_str.substr(1))
	
	var disambiguation = working.substr(0, working.length()-2)
	
	return {
		'piece_type':piece_type,
		'destination':[dest_row,dest_col],
		'is_capture':is_capture,
		'disambiguation':disambiguation,
		'promotion_type' : promotion_type
	}

#static func find_pawn_origin(destination: Array, color: String, is_capture: bool, disambiguation: String, board_state: Array) -> Array:
#	var dest_row = destination[0]
#	var dest_col = destination[1]
#	var forward = -1 if color == 'white' else 1
#	
#	if is_capture:
#		var origin_col = disambiguation.unicode_at(0) - 'a'.unicode_at(0)
#		var origin_row = dest_row - forward
#		return [origin_row, origin_col]
#	else:
#		var one_step_row = dest_row - forward
#		var one_step_piece = board_state[one_step_row][dest_col]
#		if one_step_piece != null and one_step_piece['type'] == 'pawn' and one_step_piece['color'] == color:
#			return [one_step_row, dest_col]
#		var two_step_row = dest_row - (2 * forward)
#		return [two_step_row, dest_col]

static func find_knight_origin(destination: Array, color: String, disambiguation: String, board_state: Array) -> Array:
	var dest_row = destination[0]
	var dest_col = destination[1]
	var offsets = [
		[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]
	]
	for jump in offsets:
		var check_row = dest_row + jump[0]
		var check_col = dest_col + jump[1]
		if check_row < 0 or check_row > 7 or check_col < 0 or check_col > 7:
			continue
		var piece = board_state[check_row][check_col]
		if piece != null and piece['type'] == 'knight' and piece['color'] == color:
			if disambiguation == '' or matches_disambiguation(check_row, check_col, disambiguation):
				return [check_row, check_col]
	return [-1, -1]

static func matches_disambiguation(row: int, col: int, disambiguation: String) -> bool:
	for c in disambiguation:
		if c >= 'a' and c <='h':
			if col != c.unicode_at(0) - 'a'.unicode_at(0):
				return false
		elif c >= '1' and c <= '8':
			if row != 8 - int(c):
				return false
	return true

#static func slide_search(dest_row: int, dest_col: int, directions: Array, color: String, piece_type: String, board_state : Array) -> Array:
#	for dir in directions:
#		var check_row = dest_row + dir[0]
#		var check_col = dest_col + dir [1]
#		while check_row >= 0 and check_row <= 7 and check_col >= 0 and check_col <= 7:
#			var piece = board_state[check_row][check_col]
#			if piece != null:
#				if piece['type'] == piece_type and piece['color'] == color:
#					return [check_row, check_col]
#				break
#			check_row += dir[0]
#			check_col += dir[1]
#	return [-1, -1]

static func find_rook_origin(destination: Array, color: String , disambiguation : String, board_state: Array) -> Array:
	var directions = [[-1,0],[1,0],[0,-1],[0,1]]
	return find_sliding_piece(destination, color, 'rook', directions, disambiguation, board_state)

static func find_bishop_origin(destination: Array, color: String, disambiguation: String, board_state: Array) -> Array:
	var directions = [[-1,-1],[-1,1],[1,-1],[1,1]]
	return find_sliding_piece(destination, color, "bishop", directions, disambiguation, board_state)

static func find_queen_origin(destination: Array, color: String, disambiguation: String, board_state: Array) -> Array:
	var directions = [[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[-1,1],[1,-1],[1,1]]
	return find_sliding_piece(destination, color, "queen", directions, disambiguation, board_state)

static func find_sliding_piece(destination: Array, color: String, piece_type : String, directions: Array, disambiguation: String, board_state: Array) -> Array:
	for dir in directions:
		var check_row = destination[0] + dir[0]
		var check_col = destination[1] + dir[1]
		while check_row >= 0 and check_row <= 7 and check_col >= 0 and check_col <= 7:
			var piece = board_state[check_row][check_col]
			if piece != null:
				if piece['type'] == piece_type and piece['color'] == color:
					if disambiguation == '' or matches_disambiguation(check_row, check_col, disambiguation):
						return [check_row, check_col]
				break
			check_row += dir[0]
			check_col += dir[1]
	return [-1, -1]

static func find_king_origin(destination: Array, color: String, board_state: Array) -> Array:
	var dest_row = destination[0]
	var dest_col = destination[1]
	var directions = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]]
	for dir in directions:
		var check_row = dest_row + dir[0]
		var check_col = dest_col + dir[1]
		if check_row < 0 or check_row > 7 or check_col < 0 or check_col > 7:
			continue
		var piece = board_state[check_row][check_col]
		if piece != null and piece['type'] == 'king' and piece['color'] == color:
			return [check_row, check_col]
	return [-1,-1]

static func find_pawn_origin(destination: Array, color: String, is_capture: bool, disambiguation: String, board_state: Array) -> Dictionary:
	var dest_row = destination[0]
	var dest_col = destination[1]
	var forward = -1 if color == 'white' else 1
	
	if is_capture:
		var origin_col = disambiguation.unicode_at(0) - 'a'.unicode_at(0)
		var origin_row = dest_row - forward
		var is_en_passant = board_state[dest_row][dest_col] == null
		return {'origin' : [origin_row, origin_col], 'is_en_passant' : is_en_passant}
	else:
		var one_step_row = dest_row - forward
		var one_step_piece = board_state[one_step_row][dest_col]
		if one_step_piece != null and one_step_piece['type'] == 'pawn' and one_step_piece['color'] == color:
			return {'origin' : [one_step_row, dest_col], 'is_en_passant' : false}
		var two_step_row = dest_row - (2 * forward)
		return {'origin' : [two_step_row, dest_col], 'is_en_passant' : false}

static func load_pgn_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print('failed to open file : ' , path)
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var metadata = {}
	var lines = content.split('\n')
	var movetext_lines = []
	var in_headers = true
	
	for line in lines:
		var trimmed = line.strip_edges()
		if trimmed.begins_with('[') and in_headers:
			var key_end = trimmed.find(' ')
			var key = trimmed.substr(1, key_end - 1)
			var value_start = trimmed.find('"') + 1
			var value_end = trimmed.rfind('"')
			var value = trimmed.substr(value_start, value_end - value_start)
			metadata[key] = value
		elif trimmed == '':
			in_headers = false
		else:
			in_headers = false
			movetext_lines.append(trimmed)
		
	var movetext = ' '.join(movetext_lines)
	movetext = movetext.replace('(' , '').replace(')' , '')
	
	return {'metadata' : metadata , 'movetext' : movetext}

#static func get_random_game_from_category(category : String) -> Dictionary:
#	var folder_path = 'res://assets/games/%s/' % category
#	var dir = DirAccess.open(folder_path)
#	if dir == null:
#		print('failed to open category folder : ' , folder_path)
#		return {}
#	
#	var files = []
#	dir.list_dir_begin()
#	var file_name = dir.get_next()
#	while file_name != '':
#		if not dir.current_is_dir() and file_name.ends_with('.txt'):
#			files.append(file_name)
#		file_name = dir.get_next()
#	dir.list_dir_end()
#	
#	if files.is_empty():
#		print('No game files found in : ' , folder_path)
#		return {}
#	
#	var chosen_file = files[randi() % files.size()]
#	return load_pgn_file(folder_path + chosen_file)

static func get_random_game_from_categories(categories : Array) -> Dictionary:
	if categories.is_empty():
		print('No categories enabled')
		return {}
	
	var category = categories[randi() % categories.size()]
	var folder_path = 'res://assets/games/%s/' % category
	var dir = DirAccess.open(folder_path)
	
	if dir == null:
		print('Failed to open category folder : ' , folder_path)
		return {}
	
	var files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != '':
		if not dir.current_is_dir() and file_name.ends_with('.txt'):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	if files.is_empty():
		print('No game files found in : ' , folder_path)
		return{}
		
	var chosen_file = files[randi() % files.size()]
	var result = load_pgn_file(folder_path + chosen_file)
	result['category'] = category
	return result

static func get_random_game_by_time_control(all_categories: Array, selected_time_controls: Array) -> Dictionary:
	if selected_time_controls.is_empty() or all_categories.is_empty():
		return{}
	
	var max_attempts = 30
	for attempt in max_attempts:
		var category = all_categories[randi() % all_categories.size()]
		var folder_path = 'res://assets/games/%s/' % category
		var dir = DirAccess.open(folder_path)
		if dir == null:
			continue
		
		var files = []
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != '':
			if not dir.current_is_dir() and file_name.ends_with('.txt'):
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		if files.is_empty():
			continue
		
		var chosen_file = files[randi() % files.size()]
		var result = load_pgn_file(folder_path + chosen_file)
		var tc = result['metadata'].get('TimeControl','')
		if selected_time_controls.has(tc):
			result['category'] = category
			return result
			
	return {}
