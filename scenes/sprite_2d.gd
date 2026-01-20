extends Sprite2D

var power: float = 0.0
var shooting := false
signal shoot
var last_mouse_pos := Vector2.ZERO
var mouse_delta := Vector2.ZERO

@export var drag_scale := 1.0

func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	scale.x = -0.149

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not shooting:
			power = 0

			# Mouse just pressed
			shooting = true
			last_mouse_pos = mouse_pos
			mouse_delta = Vector2.ZERO
		else:
			# Mouse held — calculate delta
			mouse_delta = mouse_pos - last_mouse_pos
			last_mouse_pos = mouse_pos
			apply_drag(mouse_delta)
	else:
		# Mouse released
		if shooting:
			shooting = false
			mouse_delta = Vector2.ZERO
			shoot.emit(power * transform.x.normalized())
		look_at(mouse_pos)
		
		
func apply_drag(delta: Vector2):
	# Cue’s rotated X axis (world space)
	var axis_x = transform.x.normalized()

	# Project mouse movement onto cue axis
	var amount = delta.dot(axis_x)

	# Move only along the cue’s axis
	position += axis_x * amount * drag_scale

	# Optional: accumulate power
	power += abs(amount)
