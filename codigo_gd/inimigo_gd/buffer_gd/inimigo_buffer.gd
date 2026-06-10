extends Inimigo_Projetil
class_name Inimigo_Buffer

@onready var buffer_area: Area2D = $buffer_area
@onready var seguir_inimigo_area: Area2D = $seguir_inimigo

@onready var cena_projetil_buff = preload("res://cenas_tscn/inimigos_tscn/buff_tscn/projetil_buff.tscn")

@export var buff_velocidade := 1.5
@export var buff_escudo := 6
@export var duracao_buff := 5

var knockback_dir := Vector2.ZERO
var knockback_speed := 0.0

enum ESTADOS_BUFFER {
	FUGIR_DO_PLAYER,
	IR_PARA_INIMIGO,
	BUFFAR
}

var estado_buffer_atual: ESTADOS_BUFFER = ESTADOS_BUFFER.FUGIR_DO_PLAYER
var alvo_inimigo: Node2D = null
var esta_buffando := false


func atualizar_estado_buffer() -> void:
	if esta_buffando:
		estado_buffer_atual = ESTADOS_BUFFER.BUFFAR
		return

	if not is_instance_valid(alvo_inimigo):
		alvo_inimigo = pegar_inimigo_mais_proximo()

	if is_instance_valid(alvo_inimigo):
		estado_buffer_atual = ESTADOS_BUFFER.IR_PARA_INIMIGO
	else:
		estado_buffer_atual = ESTADOS_BUFFER.FUGIR_DO_PLAYER


func pegar_inimigo_mais_proximo() -> Node2D:
	var melhor: Node2D = null
	var menor_dist := INF

	for corpo in seguir_inimigo_area.get_overlapping_bodies():
		if corpo == self:
			continue

		if corpo is Node2D and corpo.is_in_group("inimigos"):
			var dist := global_position.distance_to(corpo.global_position)
			if dist < menor_dist:
				menor_dist = dist
				melhor = corpo

	return melhor


func _physics_process(delta: float) -> void:
	if not is_instance_valid(alvo):
		return

	atualizar_estado_buffer()

	knockback_force = knockback_force.move_toward(Vector2.ZERO, desaceleracao * delta)

	var direcao_desejada := Vector2.ZERO
	var distancia_atual := global_position.distance_to(alvo.global_position)
	var direcao_para_alvo := (alvo.global_position - global_position).normalized()

	match estado_buffer_atual:
		ESTADOS_BUFFER.IR_PARA_INIMIGO:
			if is_instance_valid(alvo_inimigo):
				direcao_desejada = (alvo_inimigo.global_position - global_position).normalized()

		ESTADOS_BUFFER.FUGIR_DO_PLAYER:
			if distancia_atual <= distancia_minima:
				direcao_desejada = -direcao_para_alvo
				estado_distancia = ESTADOS_DISTANCIA.RECUAR
			elif distancia_atual >= distancia_maxima:
				direcao_desejada = direcao_para_alvo
				estado_distancia = ESTADOS_DISTANCIA.APROXIMAR
			else:
				direcao_desejada = Vector2.ZERO
				estado_distancia = ESTADOS_DISTANCIA.IDEAL

		ESTADOS_BUFFER.BUFFAR:
			direcao_desejada = Vector2.ZERO

	var direcao_path := escolher_dir(direcao_desejada, delta)
	var steering := gerar_steering(direcao_path)
	steering = steering.limit_length(max_accel * delta)

	match estado_atual:
		ESTADOS.CACANDO:
			if estado_buffer_atual == ESTADOS_BUFFER.BUFFAR:
				velocity = velocity.move_toward(Vector2.ZERO, max_accel * delta)
			elif estado_buffer_atual == ESTADOS_BUFFER.IR_PARA_INIMIGO:
				var desired_velocity := steering.normalized() * speed
				velocity = velocity.move_toward(desired_velocity, max_accel * delta)
			else:
				if estado_distancia == ESTADOS_DISTANCIA.IDEAL:
					velocity = velocity.move_toward(Vector2.ZERO, desaceleracao * delta)
				else:
					var desired_velocity := steering.normalized() * speed
					velocity = velocity.move_toward(desired_velocity, max_accel * delta)

		ESTADOS.ATIRANDO:
			velocity = Vector2.ZERO

		ESTADOS.HIT:
			velocity = knockback_force

	var estados_buffer_texto := {
		ESTADOS_BUFFER.FUGIR_DO_PLAYER: "FUGIR",
		ESTADOS_BUFFER.IR_PARA_INIMIGO: "SEGUIR",
		ESTADOS_BUFFER.BUFFAR: "BUFFAR"
	}

	var estados_texto := {
		ESTADOS.CACANDO: "CACANDO",
		ESTADOS.ATIRANDO: "BUFFANDO",
		ESTADOS.HIT: "HIT"
	}

	label.text = estados_texto.get(estado_atual, "?") + "\n" + estados_buffer_texto.get(estado_buffer_atual, "?")

	if estado_atual == ESTADOS.HIT:
		atirar_tempo.stop()
		velocity = knockback_dir * knockback_speed
		knockback_speed = move_toward(knockback_speed, 0.0, desaceleracao * delta)
		empurrar_inimigos_colididos()

		if knockback_speed <= 0.1:
			knockback_speed = 0.0
			estado_atual = ESTADOS.CACANDO

	move_and_slide()


func atirar() -> void:
	if not is_instance_valid(alvo):
		return

	if not is_instance_valid(alvo_inimigo):
		alvo_inimigo = pegar_inimigo_mais_proximo()
		if not is_instance_valid(alvo_inimigo):
			return

	estado_atual = ESTADOS.ATIRANDO
	estado_buffer_atual = ESTADOS_BUFFER.BUFFAR
	esta_buffando = true
	velocity = Vector2.ZERO
	atirar_tempo.stop()


	for corpo in buffer_area.get_overlapping_bodies():
		if corpo == self:
			continue
		var sorteado = randi_range(0, 1)
		if corpo.is_in_group("inimigos") and corpo.has_method("receber_buff"):
			var projetil_buff = cena_projetil_buff.instantiate()
			get_tree().current_scene.add_child(projetil_buff)
			var p0 = global_position
			var p2 = corpo.global_position
			var p1 = (p0 + p2) / 2 + Vector2(0, -100)
			projetil_buff.tipo_buff = sorteado
			projetil_buff.iniciar_curva(p0, p1, p2)
			
			
			

	await get_tree().create_timer(1.5).timeout #animacao

	esta_buffando = false
	estado_atual = ESTADOS.CACANDO
	estado_buffer_atual = ESTADOS_BUFFER.FUGIR_DO_PLAYER
	atirar_tempo.start()

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	return r
 

func receber_dano(dano: int) -> void:
	print("vida: ", vida, " escudo: ", escudo  )
	if escudo <= 0:
		vida -= dano
	else:
		escudo -= dano
	if vida <= 0:
			var particula_morte = particula_morte_cena.instantiate()
			particula_morte.position = global_position
			get_tree().current_scene.add_child(particula_morte)
			queue_free()
	dano_processado.emit()
	
func aplicar_knockback(direcao: Vector2, forca: float) -> void:
	estado_atual = ESTADOS.HIT
	knockback_dir = direcao.normalized()
	knockback_speed = forca
