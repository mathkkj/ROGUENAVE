extends Inimigo_invocador
class_name Inimigo_cantor

var ultimo_inimigo_invocado: PackedScene = null


func _on_atirar_tempo_timeout() -> void:
	if ja_atirou:
		return

	if not pode_invocar():
		return

	var faltando = quantidade_max_de_inimigos - quantidade_de_inimigos

	if faltando <= 0:
		return

	ja_atirou = true
	estado_invocador = ESTADOS_INVOCADOR.INVOCANDO
	velocity = Vector2.ZERO

	for i in range(faltando):
		var cena_escolhida: PackedScene

		if inimigos_invocados_cenas.size() > 1:
			var cenas_disponiveis = inimigos_invocados_cenas.duplicate()

			if ultimo_inimigo_invocado != null:
				cenas_disponiveis.erase(ultimo_inimigo_invocado)

			cena_escolhida = cenas_disponiveis.pick_random()
		else:
			cena_escolhida = inimigos_invocados_cenas.pick_random()

		ultimo_inimigo_invocado = cena_escolhida

		var posicao_invocacao = pegar_pos_borda()

		var explosao = cena_explosao.instantiate()
		explosao.global_position = posicao_invocacao
		explosao.z_index = 100
		get_tree().current_scene.add_child(explosao)

		var inimigo = cena_escolhida.instantiate()
		inimigo.global_position = posicao_invocacao
		get_tree().current_scene.add_child(inimigo)

		inimigos_invocados.append(inimigo)
		inimigo.tree_exited.connect(invocadinho_morreu.bind(inimigo))

		quantidade_de_inimigos += 1

	estado_invocador = ESTADOS_INVOCADOR.NORMAL
	ja_atirou = false
	atualizar_animacao()

	if quantidade_de_inimigos < quantidade_max_de_inimigos:
		atirar_tempo.start()
