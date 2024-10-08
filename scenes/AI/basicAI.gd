extends Node

var AIMark = 1

var highest = 0
var moveList:Array

func basicAImakeMove()->void:
	var move = basicAI()
	var cell_name = "/root/Board/Cell_"+str(move.x)+"_"+str(move.y)
	var cellPress = get_node(cell_name)
	cellPress.call("update_texture")
	pass

func basicAI() -> Vector2:
	var turn = GameManager.turn
	var move = Vector2(-1, -1)  # Mặc định là không có nước đi hợp lệ
	
	var size = GameManager.board_size
	
	moveList = []
	# Duyệt qua tất cả các ô trên bảng
	for x in range(size.x):
		for y in range(size.y):
			var pos = Vector2(x, y)
			if is_valid_move(pos):
				if check_win(pos, turn):
					return pos  # Trả về nước đi chiến thắng
				if check_(pos,turn,4):	
					return pos
	var opponent_turn = !turn 
	 # First, check if the opponent has a move that reaches three in a row
	for x in range(size.x):
		for y in range(size.y):
			var pos = Vector2(x, y)
			if is_valid_move(pos):
				if check_(pos, opponent_turn, 5):
					return pos  # Return the blocking move
				if check_(pos, opponent_turn, 4):
					return pos  # Return the blocking move
	
	# Duyệt qua tất cả các ô trên bảng
	for x in range(size.x):
		for y in range(size.y):
			var pos = Vector2(x, y)
			if is_valid_move(pos):
				var a=4
				while(a>0):
					if check_(pos,turn,a) and a>=highest:
						highest=a
						moveList.append(pos)
					a=a-1
	
	if moveList.size()>0:
		var i = get_random_number(0,moveList.size()-1)
		return moveList[i]

	while true:
		var x = get_random_number(0,size.x-1)
		var y = get_random_number(0,size.y-1)
		var pos = Vector2(x, y)
		if is_valid_move(pos):
				return pos  # Trả về nước đi ngẫu nhiên hợp lệ

	return move  # Trả về nước đi mặc định nếu không có nước đi hợp lệ

# Hàm kiểm tra xem nước đi có hợp lệ hay không
func is_valid_move(pos: Vector2) -> bool:
	return GameManager.board_state[pos.x][pos.y] == -1

func check_win(pos: Vector2, turn: int) -> bool:
	return check_(pos,turn, 5)

func check_(pos: Vector2, turn: int, a: int) -> bool:
	var target_value = turn

	# Kiểm tra hàng ngang
	if count_consecutive(pos, Vector2(1, 0), target_value) + count_consecutive(pos, Vector2(-1, 0), target_value) + 1 >= a:
		return true

	# Kiểm tra hàng dọc
	if count_consecutive(pos, Vector2(0, 1), target_value) + count_consecutive(pos, Vector2(0, -1), target_value) + 1 >= a:
		return true

	# Kiểm tra đường chéo chính (từ trái sang phải, trên xuống dưới)
	if count_consecutive(pos, Vector2(1, 1), target_value) + count_consecutive(pos, Vector2(-1, -1), target_value) + 1 >= a:
		return true

	# Kiểm tra đường chéo phụ (từ phải sang trái, trên xuống dưới)
	if count_consecutive(pos, Vector2(-1, 1), target_value) + count_consecutive(pos, Vector2(1, -1), target_value) + 1 >= a:
		return true

	return false

func count_consecutive(pos: Vector2, direction: Vector2, target_value: int) -> int:
	var count = 0
	var current_pos = pos + direction
	while is_within_bounds(current_pos) and GameManager.board_state[current_pos.x][current_pos.y] == target_value:
		count += 1
		current_pos += direction
	return count

func is_within_bounds(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < GameManager.board_size.x and pos.y >= 0 and pos.y < GameManager.board_size.y

func get_random_number(a: int, b: int) -> int:
	return randi() % (b - a + 1) + a
