extends Inimigo_Projetil


func atirar():
	if not is_instance_valid(alvo):
		return

	estado_atual = ESTADOS.ATIRANDO
	velocity = Vector2.ZERO
	for i in range(4):
		var projetil = projetil_instancia.instantiate()
		projetil.global_position = global_position

		var direcao = (alvo.global_position - global_position).normalized()
		projetil.speed = 500
		var spread = deg_to_rad(15) # 15 graus para cada lado
		var angulo = (i - 1) * spread # -15, 0, +15

		projetil.direcao = direcao.rotated(angulo)
		projetil.rotation = projetil.direcao.angle()

		get_tree().current_scene.add_child(projetil)

	# sai do estado de ataque depois do tempo do atirar tempo
	estado_atual = ESTADOS.CACANDO
	atirar_tempo.start()


func _on_hurtbox_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
