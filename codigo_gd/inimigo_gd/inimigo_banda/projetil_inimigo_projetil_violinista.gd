extends Inimigo_Projetil
class_name Inimigo_Violinista

@onready var cena_explosao = preload("res://cenas_tscn/inimigos_tscn/explosao_destruiacao_bala.tscn")

@export var tempo_minimo_tocando: float = 1.0
@export var tempo_maximo_tocando: float = 2.5

@export var velocidade_bala_minima: float = 900.0
@export var velocidade_bala_maxima: float = 1200.0

var tocando := false
var toque_cancelado := false
var particula_carregando: Node = null


func _physics_process(delta: float) -> void:
	if tocando:
		velocity = Vector2.ZERO
		knockback_force = Vector2.ZERO
		atualizar_animacao()
		return

	super._physics_process(delta)


func pode_atirar() -> bool:
	return is_instance_valid(alvo) \
		and estado_atual == ESTADOS.CACANDO \
		and estado_distancia == ESTADOS_DISTANCIA.IDEAL \
		and LOS.get_collider() == alvo


func _on_atirar_tempo_timeout() -> void:
	if tocando:
		return

	if not pode_atirar():
		return

	tocando = true
	toque_cancelado = false
	estado_atual = ESTADOS.ATIRANDO
	velocity = Vector2.ZERO
	knockback_force = Vector2.ZERO

	var tempo_tocando = randf_range(
		tempo_minimo_tocando,
		tempo_maximo_tocando
	)

	# particula comeca o carregamento
	if is_instance_valid(particula_carregando):
		particula_carregando.queue_free()

	particula_carregando = cena_explosao.instantiate()
	particula_carregando.global_position = global_position
	particula_carregando.z_index = 100
	get_tree().current_scene.add_child(particula_carregando)

	atualizar_animacao()

	await get_tree().create_timer(tempo_tocando).timeout

	if not is_inside_tree():
		return

	# foi interrompido por um hit
	if toque_cancelado:
		return

	if not is_instance_valid(alvo):
		tocando = false
		estado_atual = ESTADOS.CACANDO
		atirar_tempo.start()
		return

	var porcentagem = inverse_lerp(
		tempo_minimo_tocando,
		tempo_maximo_tocando,
		tempo_tocando
	)

	var velocidade_bala = lerp(
		velocidade_bala_minima,
		velocidade_bala_maxima,
		porcentagem
	)

	# remove a particula de carregamento
	if is_instance_valid(particula_carregando):
		particula_carregando.queue_free()
		particula_carregando = null

	disparar_bala(velocidade_bala)

	tocando = false
	estado_atual = ESTADOS.CACANDO
	atualizar_animacao()
	atirar_tempo.start()


func disparar_bala(velocidade_bala: float) -> void:
	if not is_instance_valid(alvo):
		return

	var projetil = projetil_instancia.instantiate()

	projetil.global_position = global_position

	var direcao = (
		alvo.global_position - projetil.global_position
	).normalized()

	projetil.direcao = direcao
	projetil.rotation = direcao.angle()
	projetil.speed = velocidade_bala

	get_tree().current_scene.add_child(projetil)

	# explosao no momento do disparo
	var explosao = cena_explosao.instantiate()
	explosao.global_position = global_position
	explosao.z_index = 100
	get_tree().current_scene.add_child(explosao)


func receber_dano(dano: int) -> void:
	# se estiver tocando, cancela o disparo
	if tocando:
		tocando = false
		toque_cancelado = true

		# remove a particula de carregamento
		if is_instance_valid(particula_carregando):
			particula_carregando.queue_free()
			particula_carregando = null

		# aplica knockback
		if is_instance_valid(alvo):
			var direcao_knockback = (
				global_position - alvo.global_position
			).normalized()

			knockback_force = direcao_knockback * knockback

		estado_atual = ESTADOS.HIT
		atualizar_animacao()

	# aplica o dano normal
	vida -= dano

	if vida <= 0:
		morrer()


func atualizar_animacao():
	if estado_atual == ESTADOS.HIT:
		tocar_animacao("hit")
		return

	if tocando:
		tocar_animacao("tocando")
		return

	if velocity.length() > 10:
		tocar_animacao("andar")
		return

	tocar_animacao("idle")


func morrer():
	var particula_morte = particula_morte_cena.instantiate()
	particula_morte.position = global_position
	get_tree().current_scene.add_child(particula_morte)
	queue_free()
