extends Inimigo
class_name Inimigo_meele

@onready var LOS = get_node("RayLOS")
@onready var atirar_tempo = get_node("atirar_tempo")
@onready var label = get_node("Label")

@export var dash_vel = 450
@export var aceleracao = 1400

var esta_na_area: bool = false

enum ESTADOS_ATAQUE {
	APROXIMAR,
	IDEAL,
	DASH,
	ATACAR,
	ATACANDO,
	PARRY,
}

var estado_ataque: ESTADOS_ATAQUE = ESTADOS_ATAQUE.APROXIMAR


func check_posicao_alvo():
	if LOS.get_collider() == alvo and atirar_tempo.is_stopped():
		atirar_tempo.start()
	elif LOS.get_collider() != alvo and not atirar_tempo.is_stopped():
		atirar_tempo.stop()


func mirar():
	if alvo:
		LOS.target_position = to_local(alvo.global_position)


func _on_atirar_tempo_timeout() -> void:
	if not esta_na_area:
		return
	dash()


func dash():
	if not is_instance_valid(alvo):
		return
	if not esta_na_area:
		return

	estado_ataque = ESTADOS_ATAQUE.DASH

	var direcao = LOS.target_position.normalized()
	var velocidade_dash = direcao * dash_vel

	velocity = velocidade_dash


func _physics_process(delta: float) -> void:
	if not is_instance_valid(alvo):
		return

	if esta_na_area:
		if estado_ataque == ESTADOS_ATAQUE.APROXIMAR:
			estado_ataque = ESTADOS_ATAQUE.IDEAL

		mirar()
		check_posicao_alvo()
	else:
		estado_ataque = ESTADOS_ATAQUE.APROXIMAR
		atirar_tempo.stop()

	# DEBUG
	var estado_texto = {
		ESTADOS_ATAQUE.APROXIMAR: "aproximar",
		ESTADOS_ATAQUE.IDEAL: "ideal",
		ESTADOS_ATAQUE.DASH: "dash",
		ESTADOS_ATAQUE.ATACAR: "atacar",
		ESTADOS_ATAQUE.PARRY: "parry",
		ESTADOS_ATAQUE.ATACANDO: "atacando"
	}

	label.text = estado_texto[estado_ataque]

	# MOVIMENTO PADRÃO (se não estiver em dash) INIMIGO NORMAL
	if estado_ataque != ESTADOS_ATAQUE.DASH or estado_ataque == ESTADOS_ATAQUE.ATACANDO:
		var direcao_path: Vector2 = escolher_dir(Vector2.ZERO, delta)
		var steering = gerar_steering(direcao_path)
		steering = steering.limit_length(max_accel * delta)

		var desired_velocity = steering.normalized() * speed
		velocity = velocity.move_toward(desired_velocity, max_accel * delta)
	if estado_ataque == ESTADOS_ATAQUE.ATACANDO:
		velocity = Vector2.ZERO
	super(delta)


func _on_circulo_de_visao_body_entered(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		esta_na_area = true


func _on_circulo_de_visao_body_exited(body: Node2D) -> void:
	if body.is_in_group("jogador"):

		esta_na_area = false
		await get_tree().create_timer(atirar_tempo.time_left).timeout
		atirar_tempo.stop()
		estado_ataque = ESTADOS_ATAQUE.APROXIMAR


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if estado_ataque == ESTADOS_ATAQUE.DASH and body.is_in_group("jogador"):
		body.perder_vida(1, LOS.target_position.normalized(), 1100)
		estado_ataque = ESTADOS_ATAQUE.ATACANDO

		await get_tree().create_timer(atirar_tempo.time_left).timeout
		atirar_tempo.stop()
		estado_ataque = ESTADOS_ATAQUE.APROXIMAR
	if estado_ataque == ESTADOS_ATAQUE.IDEAL and body.is_in_group("jogador"):
		body.perder_vida(1, LOS.target_position.normalized(), 700)

func _on_hurtbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("jogador") and estado_ataque != ESTADOS_ATAQUE.DASH:
		estado_ataque = ESTADOS_ATAQUE.IDEAL



	
