extends Inimigo_Projetil
class_name Inimigo_Teleportador

@onready var area_tp = get_node("area_tp/CollisionShape2D")
@onready var timer_tp = get_node("timer_tp")

@onready var cena_particula_teleporte = preload("res://cenas_tscn/inimigos_tscn/teleportador_tscn/teleportador_particula.tscn")

const MAX_TENTATIVAS = 50


@export var tp_distancia_minima: float = 100.0
@export var tp_distancia_maxima: float = 300.0
@export var tp_angulo_desvio: float = 35.0 #cone


func _on_timer_tp_timeout():
	if is_instance_valid(alvo) and estado_atual == ESTADOS.CACANDO:
		executar_teletransporte_tendencioso()
		
		await get_tree().create_timer(1).timeout
		atirar()

func atirar():
	if not is_instance_valid(alvo):
		return

	estado_atual = ESTADOS.ATIRANDO
	velocity = Vector2.ZERO
	
	var projetil = projetil_instancia.instantiate()
	projetil.global_position = global_position
	projetil.direcao = (alvo.global_position - projetil.global_position).normalized()
	projetil.rotation = projetil.direcao.angle()
	projetil.speed = 500

	get_tree().current_scene.add_child(projetil)

	# sai do estado de ataque depois do tempo do Timer
	estado_atual = ESTADOS.CACANDO
	atirar_tempo.start()

func executar_teletransporte_tendencioso():
	if not is_instance_valid(alvo) or not is_instance_valid(area_tp):
		return

	var area_pos = area_tp.global_position
	var raio_area = area_tp.shape.radius

	var direcao_base = LOS.target_position
	if direcao_base.length_squared() == 0:
		direcao_base = alvo.global_position - global_position
	direcao_base = direcao_base.normalized()

	if estado_distancia == ESTADOS_DISTANCIA.RECUAR:
		direcao_base = -direcao_base

	for tentativa in range(MAX_TENTATIVAS):
		var desvio_radianos = deg_to_rad(randf_range(-tp_angulo_desvio, tp_angulo_desvio))
		var direcao_sorteada = direcao_base.rotated(desvio_radianos)

		var distancia_sorteada = randf_range(tp_distancia_minima, tp_distancia_maxima)
		var posicao_candidata = global_position + (direcao_sorteada * distancia_sorteada)

		if posicao_candidata.distance_to(area_pos) > raio_area:
			continue

		# testa colisão só com o corpo do inimigo
		var teste = test_move(global_transform, posicao_candidata - global_position)

		if not teste:
			visible = false
			instanciar_particula(global_position)
			
			await get_tree().create_timer(0.5).timeout
			instanciar_particula(posicao_candidata)
			visible = true
			global_position = posicao_candidata
			
			return




func instanciar_particula(posicao):
	var particula = cena_particula_teleporte.instantiate()
	particula.position = posicao
	get_tree().current_scene.add_child(particula)
