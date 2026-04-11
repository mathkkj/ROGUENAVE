class_name ColetavelArma
extends Area2D

@export var qual_arma_que_coleta : int

func _ready():
	$CollisionShape2D.set_deferred("disabled", true)
	await get_tree().physics_frame
	
	for body in get_overlapping_bodies():
		if body.is_in_group("jogador"):
			queue_free()
			return
	
	$CollisionShape2D.set_deferred("disabled", false)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jogador") and Global.arma_atual < 0:
		Global.arma_atual = qual_arma_que_coleta
		queue_free()
