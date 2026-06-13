extends Inimigo_Projetil

func atirar():
	if not is_instance_valid(alvo):
		return

	estado_atual = ESTADOS.ATIRANDO
	velocity = Vector2.ZERO
	knockback_force = Vector2.ZERO
	
	for i in range(4):
		var projetil = projetil_instancia.instantiate()
		projetil.global_position = global_position

		var direcao = (alvo.global_position - global_position).normalized()
		projetil.speed = 350
		var spread = deg_to_rad(15)
		var angulo = (i - 1) * spread

		projetil.direcao = direcao.rotated(angulo)
		projetil.rotation = projetil.direcao.angle()

		get_tree().current_scene.add_child(projetil)

		

	if not is_inside_tree():
		return

	estado_atual = ESTADOS.CACANDO
	atirar_tempo.start()


func _on_hurtbox_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
