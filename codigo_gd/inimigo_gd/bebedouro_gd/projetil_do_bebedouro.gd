extends Projetil_do_inimigo

var camera_lenta := false
var bebedouro: Node = null
var jogador_entrou := false



func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("jogador"):
		return

	if not camera_lenta:
		return

	Engine.time_scale = 0.15
	
	


func _on_area_2d_body_exited(body: Node2D) -> void:
	if not body.is_in_group("jogador"):
		return

	if not camera_lenta:
		return

	Engine.time_scale = 1.0

	# O jogador conseguiu passar pelo tiro
	if bebedouro != null:
		bebedouro.jogador_passou_tiro()
		bebedouro.quantidade_disparos += 1

	

func _on_body_entered2(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		if body.pode_dash:
			body.perder_vida(0, direcao, 1500)

			if bebedouro != null:
				bebedouro.jogador_passou_tiro()
				bebedouro.quantidade_disparos -= 1

			queue_free()
			return

	if body.is_in_group("arma_multimidia"):
		if bebedouro != null:
			bebedouro.jogador_passou_tiro()
			bebedouro.quantidade_disparos += 1

		queue_free()
		return

	
