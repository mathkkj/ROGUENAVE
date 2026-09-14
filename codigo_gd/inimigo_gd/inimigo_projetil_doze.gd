extends Inimigo_Projetil
class_name Inimigo_projetil_rajada


func atirar():
	if not is_instance_valid(alvo):
		return

	estado_atual = ESTADOS.ATIRANDO
	velocity = Vector2.ZERO
	knockback_force = Vector2.ZERO

	# comeca a preparacao
	ultima_animacao = ""
	animacao.play("preparando_guitarra")

	# espera a duracao da animacao
	var duracao_preparacao = animacao.sprite_frames.get_frame_count("preparando_guitarra") / animacao.sprite_frames.get_animation_speed("preparando_guitarra")
	await get_tree().create_timer(duracao_preparacao).timeout

	if not is_inside_tree():
		return

	if not is_instance_valid(alvo):
		return

	# toca a guitarra enquanto dispara
	ultima_animacao = ""
	animacao.play("atirar")

	for i in range(4):
		if not is_inside_tree():
			return

		velocity = Vector2.ZERO

		var projetil = projetil_instancia.instantiate()
		projetil.global_position = global_position

		var direcao = (alvo.global_position - global_position).normalized()
		projetil.speed = 350

		var spread = deg_to_rad(15)
		var angulo = (i - 1) * spread

		projetil.direcao = direcao.rotated(angulo)
		projetil.rotation = projetil.direcao.angle()

		get_tree().current_scene.add_child(projetil)

		await get_tree().create_timer(0.1).timeout

	if not is_inside_tree():
		return

	velocity = Vector2.ZERO
	estado_atual = ESTADOS.CACANDO
	ultima_animacao = ""
	atirar_tempo.start()
	atualizar_animacao()
