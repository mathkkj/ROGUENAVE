extends Area2D
class_name Projetil_do_inimigo

var direcao = Vector2.RIGHT
var speed = 800
@onready var particula_cena = preload("res://cenas_tscn/inimigos_tscn/explosao_destruiacao_bala.tscn")

#signal projetil_inimigo_encostou_dash
func _physics_process(delta: float) -> void:
	position += direcao.normalized() * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("arma_multimidia"):
		
		var particula = particula_cena.instantiate()
		particula.position = global_position
		get_tree().current_scene.add_child(particula)
		
		print(particula)
		return

	if body.is_in_group("jogador") and body.has_method("perder_vida") and body.pode_dash:
		body.perder_vida(1, direcao, 900)
		queue_free()
		return
	if body.is_in_group("jogador") and body.has_method("perder_vida") and not body.pode_dash:
		body.z_index = 1
		return

	if body.is_in_group("inimigos"):
		return

	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("arma_multimidia"):
		var particula = particula_cena.instantiate()
		particula.position = global_position
		get_tree().current_scene.add_child(particula)
		print(particula)
		queue_free()
		return
	
