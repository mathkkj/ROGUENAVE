extends Area2D

var direcao = Vector2.RIGHT
var speed = 300

func _physics_process(delta: float) -> void:
	position += direcao * speed * delta
