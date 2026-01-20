extends RigidBody2D

signal collision


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	


func _on_body_entered(body: Node) -> void:
	collision.emit(body)
