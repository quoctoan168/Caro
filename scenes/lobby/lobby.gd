extends Control
var room_tag_scene = preload("res://scenes/room_tag/room_tag.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func get_room_list_(roomlist: Array) -> void:

	# Find the VBoxContainer inside the ScrollContainer
	var vbox_container = $LobbyLayer/VBoxContainer/ScrollContainer/VBoxContainer
	
	## Clear current children in the VBoxContainer
	#for child in vbox_container.get_children():
		#child.queue_free()
	
	# Add a button for each room in the list
	for room in roomlist:
		var room_tag = room_tag_scene.instantiate()
		#var room_button = Button.new()
		#room_button.text = room # Assuming each room has a 'name' attribute	
		#room_button.connect("pressed", _on_room_button_pressed.bind(room)) # Assuming each room has an 'id' attribute
		#vbox_container.add_child(room_button)
		vbox_container.add_child(room_tag)
		
		
func _on_room_button_pressed(room_id):
	var message = {"head": "join_room", "room_id": room_id}
	GameManager.NonePlayerNode.WebSocket.send(message)
	print("Joining room with id: ", room_id)



func _on_create_room_pressed():
	var message = {"head": "create_room"}
	#GameManager.NonePlayerNode.WebSocket.send(message)
	WebSocketClient.send(message)
	pass # Replace with function body.


func _on_join_room_pressed():
	var message = {"head": "join_room"}
	GameManager.NonePlayerNode.WebSocket.send(message)
	pass # Replace with function body.
