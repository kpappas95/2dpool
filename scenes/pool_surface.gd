extends Area2D

@export var friction = 0.009

func _physics_process(_delta):
	for body in get_overlapping_bodies():
		if body is RigidBody2D:
			body.linear_velocity *= (1.0 - friction)
			body.angular_velocity *= (1.0 - friction)
