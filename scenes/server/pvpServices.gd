extends Node

var AIMark = 1

var highest = 0
var moveList:Array

var waittingOpponent = false
var findingMatch = true
var room_id: String

func _ready():

	SignalManager.message_received.connect(messageCame)
	SignalManager.on_gameover.connect(sendLastMove)
	findingMatch=true
	pass

func _process(delta):
	
	if findingMatch:
		return
		
	if GameManager.playing and !GameManager.waitFromBoard and !waittingOpponent:
		waittingOpponent = true
		var message = {"head": "move",
		"room_id":room_id,
		"player": (GameManager.turn+1)%2,
		"pos":[GameManager.last_move.x, GameManager.last_move.y]}
		
		WebSocketClient.send(JSON.stringify(message))
	
# Cấu trúc json message
#{
	#"head":"setup",
	#"yourturn":1,
#}
#{
	#"head":"move",
	#"player":1,
	#"pos":[4,4]
#}
	
func messageCame(message:String)->void:
	
	var json = JSON.parse_string(message)
	if json == null:
		return
	if !json.has("head"):
		return
	print(json)
	var head = json.get("head",null)
	
	print(message)
	
	if head == "room_list":
		SignalManager.get_room_list.emit(json.get("rooms"))
	
	if head == "setup":
		var room = json.get("room_id",null)
		if room!= null:
			room_id = room
		var turn = json.get("yourturn",null)
		if turn == 1:
			GameManager.playing =true
			GameManager.waitFromBoard = false
			waittingOpponent = true
			findingMatch = false
		if turn == 0:
			GameManager.playing =true
			GameManager.waitFromBoard = true
			waittingOpponent = false
			findingMatch = false
		if !findingMatch:
			SignalManager.end_findingRoom.emit()	
	if head == "move":
		opponentMove(json)
		
func opponentMove(json: Variant) -> void:
	#var pos = string_to_vector2(message)
	#if pos != Vector2(-1, -1):
		#if is_valid_move(pos):
			#waittingOpponent = false
			#GameManager.make_a_move(pos)
	#var json = JSON.parse_string(message)
	if json==null:
		return
	if !json.has("player"):
		return
	
	var player = json.get("player", -1)
	var pos_array = json.get("pos", null)
	
	if player == GameManager.turn and pos_array != null and pos_array.size() == 2:
		var pos = Vector2(pos_array[0], pos_array[1])
		if is_valid_move(pos):
			waittingOpponent = false
			GameManager.make_a_move(pos)
	else:
		print("Not correct move")

func sendLastMove()->void:
	print("send last move")
	var message = {"head": "move",
		"room_id": room_id,
		"player": GameManager.turn,
		"pos":[GameManager.last_move.x, GameManager.last_move.y]}
		
	WebSocketClient.send(JSON.stringify(message))
	
	
# Hàm kiểm tra xem nước đi có hợp lệ hay không
func is_valid_move(pos: Vector2) -> bool:
	return GameManager.board_state[pos.x][pos.y] == -1

