extends Node

var socket = WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED

var url = "ws://15.235.142.203:5000/"

# Hàm xử lý việc kiểm tra và nhận dữ liệu từ socket
func poll() -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		socket.poll()

	var state = socket.get_ready_state()
	if last_state != state:
		last_state = state
		if state == WebSocketPeer.STATE_OPEN:
			# Gửi tin nhắn "start_connect" với dữ liệu người chơi khi kết nối thành công
			send({
				"head": "start_connect", 
				"player_name": "TênNgườiChơi"
			})
			SignalManager.connected_to_server.emit()
		elif state == WebSocketPeer.STATE_CLOSED:
			SignalManager.connection_closed.emit()

	while socket.get_ready_state() == WebSocketPeer.STATE_OPEN and socket.get_available_packet_count() > 0:
		SignalManager.message_received.emit(get_message())

# Hàm nhận tin nhắn từ server
func get_message() -> Variant:
	if socket.get_available_packet_count() < 1:
		return null

	var packet = socket.get_packet()
	if socket.was_string_packet():
		return packet.get_string_from_utf8()

	return bytes_to_var(packet)

# Hàm gửi tin nhắn đến server, hỗ trợ cả chuỗi văn bản và tin nhắn JSON
func send(message) -> int:
	if typeof(message) == TYPE_STRING:
		return socket.send_text(message)

	var packet = JSON.stringify(message).to_utf8_buffer()
	return socket.send(packet)

# Kết nối đến server qua URL
func connect_to_url(url) -> int:
	var error = socket.connect_to_url(url)
	if error != OK:
		return error

	last_state = socket.get_ready_state()
	return OK

# Đóng kết nối WebSocket
func close(code := 1000, reason := "") -> void:
	socket.close(code, reason)
	last_state = socket.get_ready_state()

# Hàm khởi động node khi lần đầu tiên vào scene tree
func _ready():
	var err = connect_to_url(url)
	if err != OK:
		set_process(false)
		print("Không thể kết nối: %s" % err)
	else:
		set_process(true)
		print("Đã kết nối WebSocket")

# Hàm gọi liên tục mỗi frame, xử lý các sự kiện
func _process(delta):
	poll()
