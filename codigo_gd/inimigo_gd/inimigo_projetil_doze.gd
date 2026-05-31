extends Inimigo_Projetil


func atirar():
	if not is_instance_valid(alvo):
		return

	estado_atual = ESTADOS.ATIRANDO
	velocity = Vector2.ZERO

	var projetil = projetil_instancia.instantiate()
	projetil.global_position = global_position
	projetil.direcao = (alvo.global_position - projetil.global_position).normalized()
	projetil.rotation = projetil.direcao.angle()

	get_tree().current_scene.add_child(projetil)

	# Sai do estado de ataque depois do tempo do Timer
	estado_atual = ESTADOS.CACANDO
	atirar_tempo.start()
