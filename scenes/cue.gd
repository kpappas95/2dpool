extends Node2D

signal shoot

@export var drag_scale := 1.0
@export var max_pull_distance := 80.0

var rest_position: Vector2

var power: float = 0.0
var shooting := false
var selecting_spin = false
var last_mouse_pos := Vector2.ZERO
var mouse_delta := Vector2.ZERO
var moving_balls = false
var sounds_playing = false

@onready var sprite: Sprite2D = $Sprite2D


func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	
	sprite.scale.x = -0.149
	if not selecting_spin:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not shooting:
				power = 0
				shooting = true
				last_mouse_pos = mouse_pos
				mouse_delta = Vector2.ZERO
				rest_position = global_position
			else:
				mouse_delta = mouse_pos - last_mouse_pos
				last_mouse_pos = mouse_pos
				apply_drag(mouse_delta)
		else:
			if shooting:
				shooting = false
				mouse_delta = Vector2.ZERO

				# Emit direction * power
				if power > 0 and not moving_balls:
					if not sounds_playing:
						
						shoot.emit(power * transform.x.normalized())

			look_at(mouse_pos)

func apply_drag(delta: Vector2) -> void:
	var axis_x = transform.x.normalized()

	var amount = delta.dot(axis_x)
	var current_pull = (global_position - rest_position).dot(axis_x)
	var new_pull = current_pull + amount * drag_scale

	new_pull = clamp(new_pull, -max_pull_distance, 0.0)

	global_position = rest_position + axis_x * new_pull
	power = abs(new_pull)*7
	
func reset_cue(pos):
	position = pos
