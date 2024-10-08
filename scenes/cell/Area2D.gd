extends Area2D

@onready var board = get_parent().get_parent()  # Area2D is a child of Cell and Cell is a child of Board

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("input_event", Callable(self, "_on_Area2D_input_event"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_Area2D_input_event(viewport, event, shape_idx):
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and 
	event.is_released()):
		var cell = get_parent()
		if cell:
			var board = cell.get_parent()
			if board.hold_time < 150:
				#cell.call("update_texture")
				cell.call("get_touch")
