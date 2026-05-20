extends Inimigo
class_name Inimigo_Projetil

@onready var projetil_instancia = preload("res://cenas_tscn/projetil_inimigo.tscn")
@onready var atirar_tempo = get_node("atirar_tempo")



var distancia_maxima = 500
var distancia_minima = 400

@onready var LOS = get_node("RayLOS")
@onready var label = get_node("Label")

enum ESTADOS_DISTANCIA {
	APROXIMAR,
	RECUAR,
	IDEAL,
	PROCURAR
}

var estado_distancia: ESTADOS_DISTANCIA

func check_posicao_alvo():
	if LOS.get_collider() == alvo and atirar_tempo.is_stopped():
		atirar_tempo.start()
	elif LOS.get_collider() != alvo and not atirar_tempo.is_stopped():
		atirar_tempo.stop()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(alvo):
		return

	mirar()
	check_posicao_alvo()

	if estado_atual == ESTADOS.ATIRANDO:
		velocity = Vector2.ZERO
		super(delta)
		move_and_slide()
		return

	var direcao_para_alvo: Vector2 = (alvo.global_position - global_position).normalized()
	var distancia_atual = global_position.distance_to(alvo.global_position)
	var direcao_desejada: Vector2 = Vector2.ZERO

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
			direcao_desejada = Vector2.ZERO
			estado_distancia = ESTADOS_DISTANCIA.IDEAL
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
			if estado_distancia == ESTADOS_DISTANCIA.IDEAL:
				velocity = velocity.move_toward(Vector2.ZERO, desaceleracao * delta)
			else:
				var desired_velocity = steering.normalized() * speed
				velocity = velocity.move_toward(desired_velocity, max_accel * delta)

		ESTADOS.HIT:
			velocity = knockback_force

	mirar()

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

	var projetil = projetil_instancia.instantiate()
	projetil.global_position = global_position
	projetil.direcao = (alvo.global_position - projetil.global_position).normalized()
	projetil.rotation = projetil.direcao.angle()

	get_tree().current_scene.add_child(projetil)

	# Sai do estado de ataque depois do tempo do Timer
	estado_atual = ESTADOS.CACANDO
	atirar_tempo.start()
