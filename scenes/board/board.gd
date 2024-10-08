extends Node2D
@onready var camera_2d = $Camera2D
const GAME_OVER = preload("res://scenes/game_over/game_over.tscn")

const cell_scene = preload("res://scenes/cell/cell.tscn")
const CELLSIZE = 22
@export var boardSize = Vector2(10,10)
#var table: Array

var zoom_minimum = Vector2(0.46,0.46,)
var zoom_maximum = Vector2(2.0,2.0)
var zoom_speed =Vector2(0.03,0.03)

var is_dragging = false
var last_mouse_position = Vector2()
var hold_time = 0
var clickPressed = 0

# Called when the node enters the scene tree for the first time.
func _ready():

	SignalManager.on_gameover.connect(endGameMenu)
	GameManager.board_state = create_board(boardSize,-1)
	createCell()
	center_camera_on_board()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GameManager.playing:
		if is_dragging: 
			if clickPressed == 0:
				clickPressed = Time.get_ticks_msec()
			else:
				hold_time=Time.get_ticks_msec()-clickPressed

func _input(event: InputEvent)->void:
	if !GameManager.playing:
		return
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if camera_2d.zoom > zoom_minimum:
					camera_2d.zoom -= zoom_speed
					#print("DOWN:",camera_2d.zoom )
					pass
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if camera_2d.zoom < zoom_maximum:
					camera_2d.zoom += zoom_speed
					#print("UP:",camera_2d.zoom )
					pass	
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				is_dragging = true
				last_mouse_position = event.position
		if event.is_released():
			is_dragging = false
			clickPressed = 0

	if event is InputEventMouseMotion and is_dragging:
		var mouse_movement = event.position - last_mouse_position
		camera_2d.position -= mouse_movement / camera_2d.zoom
		last_mouse_position = event.position
		
		
func get_React(pos:Vector2)->int:
	if not GameManager.playing: 
		return -1
	if GameManager.board_state[pos.x][pos.y] == -1:
		GameManager.board_state[pos.x][pos.y] = GameManager.turn
		var result = GameManager.turn + 1
		GameManager.turn = (GameManager.turn + 1)%2
		#print("result %s"% result)
		WinProcess(pos)
		
		return result
	else:
		return -1
		
# Function to create and initialize the board
func create_board(size: Vector2, default_value: int) -> Array:
	GameManager.board_size=boardSize
	var board = []
	for i in range(size.y):  # Iterate over rows
		var row = []
		for j in range(size.x):  # Iterate over columns
			row.append(default_value)
		board.append(row)
	return board

func createCell():
	var board_pixel_size = Vector2(CELLSIZE * boardSize.x, CELLSIZE * boardSize.y)
	var topCorner = Vector2(CELLSIZE/2 ,CELLSIZE/2)
	for i in range(boardSize.x):
		for j in range(boardSize.y):
			addCell("Cell_" + str(i) + "_" + str(j), Vector2(i * CELLSIZE + topCorner.x, j * CELLSIZE + topCorner.y))

func addCell(name, position):
	var cell = cell_scene.instantiate()
	cell.name = name
	cell.position =  position  # Đặt vị trí cho cell
	add_child(cell)  # Thêm cell vào Board

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

func countConsecutive(pos: Vector2, direction: Vector2, target_value) -> int:
	var count = 0
	var current_pos = pos + direction
	while (current_pos.x >= 0 and current_pos.x < GameManager.board_state.size() 
	and current_pos.y >= 0 and current_pos.y < GameManager.board_state[current_pos.x].size() 
	and GameManager.board_state[current_pos.x][current_pos.y] == target_value):
		count += 1
		current_pos += direction
	return count

func WinProcess(pos:Vector2):
	if checkWin(pos):
		GameManager.playing=false
		SignalManager.on_gameover.emit()
		#set_process_input(false)  # Disable input processing for the Board node
	#print("isWIN %s"% checkWin(pos))

func highlight_winning_sequence(pos, forward_direction, backward_direction):
	var target_value = GameManager.board_state[pos.x][pos.y]
	var start = find_limit(pos, forward_direction, target_value)
	var end = find_limit(pos, backward_direction, target_value)
	if is_valid_sequence(start, end, 5):
		GameManager.start_point= start
		GameManager.end_point = end
		highlight_line(start, end)

func highlight_winning_(pos:Vector2):
	var target_value = GameManager.board_state[pos.x][pos.y]
	# Kiểm tra hàng ngang
	if countConsecutive(pos, Vector2(1, 0), target_value) + countConsecutive(pos, Vector2(-1, 0), target_value) + 1 >= 5:
		highlight_winning_sequence(pos,Vector2(1, 0),Vector2(-1, 0))
		return 

	# Kiểm tra hàng dọc
	if countConsecutive(pos, Vector2(0, 1), target_value) + countConsecutive(pos, Vector2(0, -1), target_value) + 1 >= 5:
		highlight_winning_sequence(pos,Vector2(0, 1),Vector2(0, -1))
		return 

	# Kiểm tra đường chéo chính (từ trái sang phải, trên xuống dưới)
	if countConsecutive(pos, Vector2(1, 1), target_value) + countConsecutive(pos, Vector2(-1, -1), target_value) + 1 >= 5:
		highlight_winning_sequence(pos,Vector2(1, 1),Vector2(-1, -1))
		return 

	# Kiểm tra đường chéo phụ (từ phải sang trái, trên xuống dưới)
	if countConsecutive(pos, Vector2(-1, 1), target_value) + countConsecutive(pos, Vector2(1, -1), target_value) + 1 >= 5:
		highlight_winning_sequence(pos, Vector2(-1, 1), Vector2(1, -1))
		return 

func find_limit(pos, direction, target_value) -> Vector2:
	var current = pos
	while (is_within_bounds(current + direction) 
	and GameManager.board_state[current.x + direction.x][current.y + direction.y] == target_value):
		current += direction
	return current

func highlight_line(start, end):
	var current = start
	var step = Vector2(sign(end.x - start.x), sign(end.y - start.y))  # Determine the step direction

	while current != end + step:  # Loop until just past the 'end' to include it
		var cell_node_path = "Cell_" + str(current.x) + "_" + str(current.y)
		var cell_node = get_node_or_null(cell_node_path)
		if cell_node:
			cell_node.show_win_cover(true)
		current += step  # Move to the next cell in the line

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

func center_camera_on_board():
	var board_pixel_size = Vector2(CELLSIZE * boardSize.x, CELLSIZE * boardSize.y)
	var center_position = Vector2(board_pixel_size.x / 2, board_pixel_size.y / 2)
	camera_2d.position = center_position

func endGameMenu():
	highlight_line(GameManager.start_point, GameManager.end_point)
	var gameOver = GAME_OVER.instantiate()
	gameOver.position=camera_2d.position
	add_child(gameOver)




