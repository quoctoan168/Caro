extends Sprite2D
const empty_cell = preload("res://resource/cell/cell_empty.png")
const x_cell = preload("res://resource/cell/O_Cell.png")
const o_cell = preload("res://resource/cell/X_Cell.png")
const win_cover_texture = preload("res://resource/cell/win_cover.png")
var current_texture = 0  # 0 for empty, 1 for X, 2 for O
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


			
func update_texture():
	print(name)
	#current_texture = (current_texture + 1) % 3  # Cycle through 0, 1, 2
	var turn: int = 0
	var board = get_parent()
	if board:
		turn = board.call("get_React",GameManager.get_Position(get_name()))
		
	current_texture = turn
	if current_texture == -1:
		self.texture = empty_cell
	elif current_texture == 0:
		self.texture = x_cell
	elif current_texture == 1:
		self.texture = o_cell
	#print(get_name())
			
func update_texture_(state:int):
	match state:
		Constants.STATE_Empty:
			self.texture = empty_cell
		Constants.STATE_X:
			self.texture = x_cell
		Constants.STATE_O:
			self.texture = o_cell



func show_win_cover(show: bool):
	# Access the cover child which is a Sprite2D node
	var cover_sprite = get_node_or_null("cover")
	if cover_sprite:
		if show:
			cover_sprite.texture = win_cover_texture
			cover_sprite.visible = true  # Make the sprite visible
		else:
			cover_sprite.visible = false  # Hide the sprite when not showing the win cover

func get_touch():
	GameManager.call_actionFromCell(self)
