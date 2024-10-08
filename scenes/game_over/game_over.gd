extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_menu_bt_pressed():
	GameManager.load_menu()

func _on_replay_pressed():
	GameManager.load_game_scene(GameManager.mode)
