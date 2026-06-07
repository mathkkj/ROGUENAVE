extends Inimigo_meele
class_name Inimigo_meele_pesado

@onready var cena_explosao_props = preload("res://cenas_tscn/explosao.tscn")

func check_posicao_alvo():
	var collider = LOS.get_collider()

	if collider != null and collider.is_in_group("quebraveis"):
		return

	if collider == alvo and atirar_tempo.is_stopped():
		atirar_tempo.start()
	elif collider != alvo and not atirar_tempo.is_stopped():
		atirar_tempo.stop()



func _on_hurtbox_body_entered(body: Node2D) -> void:
	
	if estado_ataque == ESTADOS_ATAQUE.IDEAL and body.is_in_group("jogador"):
		body.perder_vida(1, LOS.target_position.normalized(), knockback_normal)
	if estado_ataque == ESTADOS_ATAQUE.DASH and body.is_in_group("jogador") and not body.invencivel:
		body.perder_vida(1, LOS.target_position.normalized(), knockback_dash)
		estado_ataque = ESTADOS_ATAQUE.ATACANDO
		

		await get_tree().create_timer(atirar_tempo.time_left).timeout
		atirar_tempo.stop()
		estado_ataque = ESTADOS_ATAQUE.APROXIMAR
	if estado_ataque == ESTADOS_ATAQUE.DASH and body.is_in_group("quebraveis"):
		var particula = cena_explosao_props.instantiate()
		particula.position = body.global_position
		get_tree().current_scene.add_child(particula)
		body.queue_free()
	esta_na_area_hurtbox = true

func _on_hurtbox_body_exited(body: Node2D) -> void:
	if ELE_DA_DASH == true:
		if body.is_in_group("jogador") and not body.invencivel:
			esta_na_area_hurtbox = false
