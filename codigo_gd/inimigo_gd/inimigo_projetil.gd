extends Inimigo
class_name Inimigo_Projetil

@onready var projetil_instancia = preload("res://cenas_tscn/projetil_inimigo.tscn")


@export var distancia_maxima = 600
@export var distancia_minima = 200

@export var knockback = 700

@onready var LOS = get_node("RayLOS")
@onready var label = get_node("Label")
@onready var animacao = get_node("Sprite2D")

var ultima_animacao := ""

enum ESTADOS_DISTANCIA {
	APROXIMAR,
	RECUAR,
	IDEAL,
	PROCURAR
}

var estado_distancia: ESTADOS_DISTANCIA


func atualizar_animacao():
	if estado_atual == ESTADOS.HIT:
		tocar_animacao("hit")
		return

	if estado_atual == ESTADOS.ATIRANDO:
		tocar_animacao("atirar")
		return

	if velocity.length() > 10:
		tocar_animacao("andar")
		return

	tocar_animacao("idle")


func tocar_animacao(nome: String):
	if ultima_animacao == nome:
		return

	ultima_animacao = nome
	animacao.play(nome)


func check_posicao_alvo():
	var collider = LOS.get_collider()

	if collider != null and collider.is_in_group("inimigos"):
		return

	if collider == alvo and atirar_tempo.is_stopped():
		atirar_tempo.start()
	elif collider != alvo and not atirar_tempo.is_stopped():
		atirar_tempo.stop()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(alvo):
		return

	if estado_atual == ESTADOS.ATIRANDO:
		velocity = Vector2.ZERO
		atualizar_animacao()
		return

	var direcao_para_alvo: Vector2 = round((alvo.global_position - global_position).normalized())

	var distancia_atual = global_position.distance_to(alvo.global_position)
	var direcao_desejada: Vector2 = Vector2.ZERO

	mirar()
	check_posicao_alvo()

	var estado_texto = {
		ESTADOS_DISTANCIA.APROXIMAR: "aproximar",
		ESTADOS_DISTANCIA.RECUAR: "recuar",
		ESTADOS_DISTANCIA.IDEAL: "ideal",
		ESTADOS_DISTANCIA.PROCURAR: "procurar"
	}

	var collider = LOS.get_collider()

	if collider != null and collider.is_in_group("inimigos"):
		collider = alvo

	if collider == alvo:
		if distancia_atual >= distancia_maxima:
			direcao_desejada = direcao_para_alvo
			estado_distancia = ESTADOS_DISTANCIA.APROXIMAR

		elif distancia_atual <= distancia_minima:
			direcao_desejada = -direcao_para_alvo
			estado_distancia = ESTADOS_DISTANCIA.RECUAR

		else:
			estado_distancia = ESTADOS_DISTANCIA.IDEAL

			# movimento lateral ao redor do jogador
			var direcao_lateral = Vector2(
				-direcao_para_alvo.y,
				direcao_para_alvo.x
			)

			direcao_desejada = direcao_lateral
	else:
		direcao_desejada = direcao_para_alvo
		estado_distancia = ESTADOS_DISTANCIA.PROCURAR

	label.text = estado_texto[estado_distancia]

	var direcao_path: Vector2 = escolher_dir(direcao_desejada.normalized(), delta)

	var steering = gerar_steering(direcao_path)
	steering = steering.limit_length(max_accel * delta)

	super(delta)

	match estado_atual:
		ESTADOS.CACANDO:
			var desired_velocity = steering.normalized() * speed
			velocity = velocity.move_toward(
				desired_velocity,
				max_accel * delta
			)

		ESTADOS.HIT:
			velocity = knockback_force

	mirar()
	atualizar_animacao()


func _on_atirar_tempo_timeout() -> void:
	atirar()


func mirar():
	if alvo:
		LOS.target_position = to_local(alvo.position)


func atirar():
	if not is_instance_valid(alvo):
		return

	estado_atual = ESTADOS.ATIRANDO
	velocity = Vector2.ZERO
	knockback_force = Vector2.ZERO

	atualizar_animacao()

	var projetil = projetil_instancia.instantiate()

	projetil.global_position = global_position
	projetil.direcao = (alvo.global_position - projetil.global_position).normalized()
	projetil.rotation = projetil.direcao.angle()
	projetil.speed = 400

	get_tree().current_scene.add_child(projetil)

	await get_tree().create_timer(0.35).timeout

	if not is_inside_tree():
		return

	estado_atual = ESTADOS.CACANDO
	atirar_tempo.start()
	atualizar_animacao()


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		body.perder_vida(1, LOS.target_position.normalized(), knockback)
