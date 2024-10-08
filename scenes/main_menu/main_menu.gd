extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_button_pvpoff_pressed():
	GameManager.load_game_scene(Constants.mode_pvpOff)


func _on_fight_ai_pressed():
	GameManager.load_game_scene(Constants.mode_AI)


func _on_pvponline_pressed():
	GameManager.load_game_scene(Constants.mode_pvpOnl)
