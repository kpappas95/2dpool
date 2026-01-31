extends Area2D

var goes_for_spin = false
var point_pos
var spin_added = false
var spin_x = 0
var spin_y = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	point_pos = $Ball/Point.position


func _process(_delta: float) -> void:
	if $Ball/Point.position == point_pos:
		spin_x = 0
		spin_y = 0
	if goes_for_spin:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			$Ball/Point.position = point_pos
			
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			spin_added = false
			var mouse_pos = get_viewport().get_mouse_position()
			$Ball/Point.global_position = mouse_pos
			calculate_spin()
		else:
			if not spin_added:				
				spin_added = true


func _on_mouse_entered() -> void:
	goes_for_spin = true

func _on_mouse_exited() -> void:
	goes_for_spin = false
	
func calculate_spin():
	spin_y = $Ball/Point.position.y * -0.00019
	spin_x = $Ball/Point.position.x * 0.018
func reset_spin():
	$Ball/Point.position = point_pos
	spin_x = 0
	spin_y = 0
