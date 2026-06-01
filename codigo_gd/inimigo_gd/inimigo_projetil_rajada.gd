extends Inimigo_Projetil


func atirar():
	if not is_instance_valid(alvo):
		return

	estado_atual = ESTADOS.ATIRANDO
	velocity = Vector2.ZERO
	for i in range(4):
		var projetil = projetil_instancia.instantiate()
		projetil.global_position = global_position
		projetil.direcao = (alvo.global_position - projetil.global_position).normalized()
		projetil.rotation = projetil.direcao.angle()
		projetil.speed = 650

		get_tree().current_scene.add_child(projetil)
		await get_tree().create_timer(0.15).timeout # espera 0.15s

	# Sai do estado de ataque depois do tempo do Timer
	estado_atual = ESTADOS.CACANDO
	atirar_tempo.start()
