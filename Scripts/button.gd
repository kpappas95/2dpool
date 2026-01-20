extends Button

var ready_to_play = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_pressed() -> void:
	if ready_to_play:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		ready_to_play = true
		text = "Play"
		$"../How to".visible = true
		$"../Goal".visible = false
