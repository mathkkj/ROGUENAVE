extends Inimigo_Projetil
class_name Inimigo_baterista

enum ESTADOS_BAQUETA {
	COM_BAQUETA,
	CACANDO_BAQUETA
}

var estado_baqueta: ESTADOS_BAQUETA = ESTADOS_BAQUETA.COM_BAQUETA
var baqueta_atual: Area2D


func _ready() -> void:
	projetil_instancia = preload("res://cenas_tscn/inimigos_tscn/banda/projetil_baterista.tscn")
	super()


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	if estado_baqueta == ESTADOS_BAQUETA.CACANDO_BAQUETA:
		cacar_baqueta(delta)
		return

	super(delta)


func cacar_baqueta(delta: float) -> void:
	if not is_instance_valid(baqueta_atual):
		baqueta_atual = null
		estado_baqueta = ESTADOS_BAQUETA.COM_BAQUETA
		estado_atual = ESTADOS.CACANDO
		atirar_tempo.start()
		atualizar_animacao()
		return

	var direcao_para_baqueta := (
		baqueta_atual.global_position - global_position
	).normalized()

	var direcao_path := escolher_dir(
		direcao_para_baqueta,
		delta
	)

	var steering := gerar_steering(direcao_path)
	steering = steering.limit_length(max_accel * delta)

	knockback_force = knockback_force.move_toward(
		Vector2.ZERO,
		desaceleracao * delta
	)

	match estado_atual:
		ESTADOS.CACANDO:
			var desired_velocity = steering.normalized() * speed

			velocity = velocity.move_toward(
				desired_velocity,
				max_accel * delta
			)

		ESTADOS.HIT:
			velocity = knockback_force

	move_and_slide()

	if estado_atual == ESTADOS.HIT:
		empurrar_inimigos_colididos()

	atualizar_animacao()


func atirar() -> void:
	if not is_instance_valid(alvo):
		return

	if estado_baqueta != ESTADOS_BAQUETA.COM_BAQUETA:
		return

	var collider = LOS.get_collider()

	if collider != alvo:
		return

	estado_atual = ESTADOS.ATIRANDO
	velocity = Vector2.ZERO
	knockback_force = Vector2.ZERO

	atualizar_animacao()

	var projetil = projetil_instancia.instantiate()

	get_tree().current_scene.add_child(projetil)

	var posicao_inicial = global_position
	var posicao_jogador = alvo.global_position

	var posicao_meio = posicao_inicial.lerp(
		posicao_jogador,
		0.5
	)

	posicao_meio.y -= 80

	projetil.ficou_no_chao.connect(
		_on_baqueta_ficou_no_chao.bind(projetil)
	)

	baqueta_atual = projetil

	projetil.iniciar_curva(
		posicao_inicial,
		posicao_meio,
		posicao_jogador,
		self
	)

	await get_tree().create_timer(0.35).timeout

	if not is_inside_tree():
		return

	if not is_instance_valid(projetil):
		return

	if baqueta_atual != projetil:
		return

	estado_atual = ESTADOS.CACANDO
	atualizar_animacao()


func _on_baqueta_ficou_no_chao(baqueta: Area2D) -> void:
	if not is_instance_valid(baqueta):
		return

	if baqueta != baqueta_atual:
		return

	estado_baqueta = ESTADOS_BAQUETA.CACANDO_BAQUETA
	estado_atual = ESTADOS.CACANDO

	atualizar_animacao()


func pegar_baqueta(baqueta: Area2D) -> void:
	if baqueta != baqueta_atual:
		return

	if not is_instance_valid(baqueta):
		return

	baqueta.queue_free()
	baqueta_atual = null

	estado_baqueta = ESTADOS_BAQUETA.COM_BAQUETA
	estado_atual = ESTADOS.CACANDO

	atirar_tempo.start()

	atualizar_animacao()


func check_posicao_alvo() -> void:
	var collider = LOS.get_collider()

	if collider != null and collider.is_in_group("baquetas"):
		return

	if collider != null and collider.is_in_group("inimigos"):
		return

	if collider == alvo and atirar_tempo.is_stopped():
		atirar_tempo.start()
	elif collider != alvo and not atirar_tempo.is_stopped():
		atirar_tempo.stop()


func mirar() -> void:
	if alvo:
		LOS.target_position = to_local(alvo.position)
