extends Area2D

@onready var hit_sound: AudioStreamPlayer = $AudioStreamPlayer
var can_play := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hit_sound.play()
	hit_sound.stop()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_body_entered(body) -> void:
	if body is RigidBody2D:
		
		hit_sound.play()
		can_play = false
