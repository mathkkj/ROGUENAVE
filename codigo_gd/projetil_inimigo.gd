extends Area2D

var direcao = Vector2.RIGHT
var speed = 500

func _physics_process(delta: float) -> void:
	position += direcao.normalized() * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("arma"):
		queue_free()
		return

	if body.is_in_group("jogador") and body.has_method("perder_vida"):
		body.perder_vida(1, direcao, 600)
		queue_free()
		return

	if body.is_in_group("inimigos"):
		return

	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("arma"):
		queue_free()
		return
