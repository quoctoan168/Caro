extends Node

var board_scene: PackedScene = preload("res://scenes/board/board.tscn")
var lobby_scene: PackedScene = preload("res://scenes/lobby/lobby.tscn")

const MAIN_MENU = preload("res://scenes/main_menu/main_menu.tscn")
@onready var result = $GameOverLayer/MarginContainer/VBoxContainer/Result
# Tải script basicAI.gd
var BasicAIScript = preload("res://scenes/AI/basicAI.gd")

var PVPOnlineScript = preload("res://scenes/server/pvpServices.gd")

var NonePlayerNode: Node

var mode:int = Constants.mode_pvpOff # 0: PvP offline 1: vs AI simple

var board_size:Vector2
var board_state:Array

var winner = -1 #-1 : draw 0:O Win 1: X:Win
var start_point
var end_point

var turn = 0
var waitFromBoard = true #Wait player to make a move


var playing = true

var last_move: Vector2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if mode == Constants.mode_AI and playing and !waitFromBoard:
		make_a_move(NonePlayerNode.basicAI()) 

func load_game_scene(mode_:int)->void:
	mode = mode_
	if mode == Constants.mode_AI or mode == Constants.mode_pvpOff:
		if mode == Constants.mode_AI:
			NonePlayerNode = BasicAIScript.new()
		add_child(NonePlayerNode)	
		get_tree().change_scene_to_packed(board_scene)
		
	if mode == Constants.mode_pvpOnl:
		NonePlayerNode = PVPOnlineScript.new()
		get_tree().change_scene_to_packed(lobby_scene)
	
	match mode:
		Constants.mode_AI:
			playing = true
			waitFromBoard = true
		Constants.mode_pvpOff:
			playing = true
			waitFromBoard = true
	#playing =true
	#waitFromBoard = true

func load_menu()->void:
	get_tree().change_scene_to_packed(MAIN_MENU)

func call_actionFromCell(cell:Sprite2D)->void:
	if waitFromBoard:
		var pos = get_Position(cell.name)
		make_a_move(pos)

func make_a_move(pos:Vector2)->void:
	if board_state[pos.x][pos.y]== Constants.STATE_Empty:
		last_move=pos
		var cell = get_cell(pos)
		cell.update_texture_(turn)
		board_state[pos.x][pos.y] = turn
		if checkWin(pos):
			call_winProcess(pos)
			return
		changeTurn()

func call_winProcess(pos)->void:
	SignalManager.on_gameover.emit()
	playing = false
	waitFromBoard = false
	pass

func changeTurn()->void:
	turn=(turn+1)%2
	if not mode==Constants.mode_pvpOff:
		waitFromBoard=!waitFromBoard

# Check win game
func checkWin(pos: Vector2) -> bool:
	var target_value = GameManager.board_state[pos.x][pos.y]
	if target_value == -1:  # Giả sử -1 là giá trị không hợp lệ (chưa được đánh)
		return false

	# Kiểm tra hàng ngang
	if countConsecutive(pos, Vector2(1, 0), target_value) + countConsecutive(pos, Vector2(-1, 0), target_value) + 1 >= 5:
		highlight_winning_sequence(pos,Vector2(1, 0),Vector2(-1, 0))
		return true

	# Kiểm tra hàng dọc
	if countConsecutive(pos, Vector2(0, 1), target_value) + countConsecutive(pos, Vector2(0, -1), target_value) + 1 >= 5:
		highlight_winning_sequence(pos,Vector2(0, 1),Vector2(0, -1))
		return true

	# Kiểm tra đường chéo chính (từ trái sang phải, trên xuống dưới)
	if countConsecutive(pos, Vector2(1, 1), target_value) + countConsecutive(pos, Vector2(-1, -1), target_value) + 1 >= 5:
		highlight_winning_sequence(pos,Vector2(1, 1),Vector2(-1, -1))
		return true

	# Kiểm tra đường chéo phụ (từ phải sang trái, trên xuống dưới)
	if countConsecutive(pos, Vector2(-1, 1), target_value) + countConsecutive(pos, Vector2(1, -1), target_value) + 1 >= 5:
		highlight_winning_sequence(pos, Vector2(-1, 1), Vector2(1, -1))
		return true

	return false

func highlight_winning_sequence(pos, forward_direction, backward_direction):
	var target_value = GameManager.board_state[pos.x][pos.y]
	var start = find_limit(pos, forward_direction, target_value)
	var end = find_limit(pos, backward_direction, target_value)
	if is_valid_sequence(start, end, 5):
		GameManager.start_point= start
		GameManager.end_point = end
		#highlight_line(start, end)

func find_limit(pos, direction, target_value) -> Vector2:
	var current = pos
	while (is_within_bounds(current + direction) 
	and GameManager.board_state[current.x + direction.x][current.y + direction.y] == target_value):
		current += direction
	return current

func is_within_bounds(pos) -> bool:
	return (pos.x >= 0 and pos.x < GameManager.board_state.size() 
	and pos.y >= 0 and pos.y < GameManager.board_state[0].size())
	
func is_valid_sequence(start, end, min_length):
	# Check if the points are aligned horizontally, vertically, or diagonally
	var horizontal = start.y == end.y and abs(end.x - start.x) + 1 >= min_length
	var vertical = start.x == end.x and abs(end.y - start.y) + 1 >= min_length
	var diagonal = (abs(end.x - start.x) == abs(end.y - start.y) 
					and abs(end.x - start.x) + 1 >= min_length)

	return horizontal or vertical or diagonal

func countConsecutive(pos: Vector2, direction: Vector2, target_value) -> int:
	var count = 0
	var current_pos = pos + direction
	while (current_pos.x >= 0 and current_pos.x < GameManager.board_state.size() 
	and current_pos.y >= 0 and current_pos.y < GameManager.board_state[current_pos.x].size() 
	and GameManager.board_state[current_pos.x][current_pos.y] == target_value):
		count += 1
		current_pos += direction
	return count

func get_Position(name)->Vector2:
	var parts = name.split("_")  # This splits the name into ["Cell", "15", "6"]
	if parts.size() >= 3:  # Make sure the name is in the expected format
		var x = int(parts[1])  # Convert the second part to an integer
		var y = int(parts[2])  # Convert the third part to an integer
		return Vector2(x, y)
	else:
		print("Error: Name format is incorrect")
		return Vector2()  # Return a default Vector2 if the format is wrong

func get_cell(pos:Vector2):
	var nodePath = "/root/Board/Cell_"+str(pos.x)+"_"+str(pos.y)
	return get_node_or_null(nodePath)

