extends CharacterBody2D


@export var desaceleracao: float = 2500.0
@export var speed: float = 100.0
@export var alvo: CharacterBody2D

var explosao_cena = preload("res://cenas_tscn/explosao.tscn")
var vida: int = 25
var knockback_force: Vector2 = Vector2.ZERO

@onready var sprite := $Sprite2D
@onready var navagent = $NavigationAgent2D

@onready var projetil_instancia = preload("res://cenas_tscn/projetil_inimigo.tscn")

@onready var atirar_tempo = get_node("atirar_tempo")


var ultima_direcao := Vector2.ZERO
var tempo_memoria := 0.0
@onready var LOS = get_node("RayLOS")
@onready var arr_cast: Array[RayCast2D] = [
	get_node("Raycast/RayDireita"),
	get_node("Raycast/RayBaixoDireita"),
	get_node("Raycast/RayBaixo"),
	get_node("Raycast/RayBaixoEsquerda"),
	get_node("Raycast/RayEsquerda"),
	get_node("Raycast/RayCimaEsquerda"),
	get_node("Raycast/RayCima"),
	get_node("Raycast/RayCimaDireita"),
]


enum ESTADOS {
	NAO_CACANDO,
	CACANDO,
	ATIRANDO,
	HIT,
}

var estado_atual: ESTADOS = ESTADOS.NAO_CACANDO


#func escolher_direcao(direcao_alvo: Vector2) -> Vector2:
	#var melhor_direcao := Vector2.ZERO
	#var melhor_pontuacao := -INF
	#
	#for i in range(arr_cast.size()):
		#var ray = arr_cast[i]
		#var esq = arr_cast[(i - 1 + arr_cast.size()) % arr_cast.size()]
		#var dir = arr_cast[(i + 1) % arr_cast.size()]
#
		#ray.force_raycast_update()
		#
		###SISTEMA DE PONTUACAO PARA PEGAR O MELHOR RAY
		#var direcao = ray.target_position.normalized()
		#var pontuacao := 0.0
		## estabilidade
		##da mais pontuacao de forma gradual a posicao diferente da ultima
		#if ultima_direcao != Vector2.ZERO:
			#pontuacao += direcao.dot(ultima_direcao) * 3
			#
		#
		#var alinhamento = direcao.dot(direcao_alvo) #linha pro alvo
		#
		## colisão
		#if ray.is_colliding():
			#var dist = ray.get_collision_point().distance_to(ray.global_position)
			#alinhamento *= 0.5
			#pontuacao -= (1/ max(dist, 0.1)) * 4
		#else:
			#pontuacao += 2.0
			#
		#pontuacao += alinhamento * 6
		## detectar parede longa
		#var bloqueados = 0
		#
			#
		#
		#if ray.is_colliding():
			#bloqueados += 1
		#if esq.is_colliding():
			#bloqueados += 1
		#if dir.is_colliding():
			#bloqueados += 1
	#
		#if bloqueados >= 1:
			#pontuacao *= 0.1
		#
		#
		#if pontuacao > melhor_pontuacao:
			#melhor_pontuacao = pontuacao
			#melhor_direcao = direcao
#
	#if melhor_direcao == Vector2.ZERO:
		#return direcao_alvo
#
	#ultima_direcao = melhor_direcao.normalized()
#
	#return ultima_direcao


func escolher_dir(direcao_alvo: Vector2, delta: float) -> Vector2:
	tempo_memoria -= delta

	var melhor_score := -INF
	var melhor_direcao := ultima_direcao

	for i in range(arr_cast.size()):
		var ray: RayCast2D = arr_cast[i]
		var dir = ray.target_position.normalized()
		var score = dir.dot(direcao_alvo)
		
		# memoria da ultima direcao pra nao trocar de diracao toda hora
		if ultima_direcao != Vector2.ZERO:
			score += dir.dot(ultima_direcao) * 1.25
		
		
		if ray.is_colliding():

			# direcao da parede (basicamente)
			var normal = ray.get_collision_normal() 
			score += normal.dot(direcao_alvo) * 3.0
			
			#peguei a tangente por conta de serem perpendiculares
			var tangente_esquerda = Vector2(-normal.y, normal.x)
			var tangente_direita = Vector2(normal.y, -normal.x)

			# escolhe tangente melhor
			var score_esquerda = tangente_esquerda.dot(direcao_alvo)
			var score_direita = tangente_direita.dot(direcao_alvo)
			
			#mudar a tangente dependendo da pontuacao
			var tangente = tangente_esquerda
			if score_direita > score_esquerda:
				tangente = tangente_direita

			# favorece deslizar na parede
			score += tangente.dot(direcao_alvo) * 4.0

			# penalidade da colisão
			score -= 4.0

		
		# ray da esquerda e direita
		var ray_esquerda: RayCast2D = arr_cast[(i - 1 + arr_cast.size()) % arr_cast.size()]

		var ray_direita: RayCast2D = arr_cast[(i + 1) % arr_cast.size()]
		#score do ray da esquerda e direita
		if ray_esquerda.is_colliding():
			score -= 1.0
		if ray_direita.is_colliding():
			score -= 1.0

		# MELHOR DIREÇÃO
		if score > melhor_score:
			melhor_score = score
			melhor_direcao = dir

	# atualizar os valores e resetar a memoria
	if tempo_memoria <= 0.0:
		ultima_direcao = melhor_direcao
		tempo_memoria = 0.2
	
	return melhor_direcao



@export var max_speed := 300.0
@export var max_accel := 1200.0


@onready var cor_dominante := Color.WHITE

func cachear_cor():
	var sprite := $Sprite2D
	var img = sprite.texture.get_image()
	img.resize(1, 1, Image.INTERPOLATE_NEAREST)
	cor_dominante = img.get_pixel(0, 0)

func _physics_process(delta: float) -> void:
	mirar()
	check_posicao_alvo()
	if not is_instance_valid(alvo):
		return

	var direcao_para_alvo: Vector2 = (alvo.global_position - global_position).normalized()
	var direcao_path: Vector2 = escolher_dir(direcao_para_alvo, delta)

	

	var desired_velocity := direcao_path * max_speed

	# steering force 
	var steering = desired_velocity - velocity
	steering = steering.limit_length(max_accel * delta)

	# aplica knockback sem apagar o steering
	knockback_force = knockback_force.move_toward(Vector2.ZERO, desaceleracao * delta)

	velocity += steering
	
	print(estado_atual)
	
	match estado_atual:
		ESTADOS.NAO_CACANDO:
			#velocity = Vector2.ZERO
			if LOS.get_collider() == alvo:
				estado_atual = ESTADOS.CACANDO
				

		ESTADOS.CACANDO:
			velocity += steering
			if LOS.get_collider() != alvo:
				estado_atual = ESTADOS.NAO_CACANDO

		ESTADOS.ATIRANDO:
			pass

		ESTADOS.HIT:
			velocity = knockback_force

	move_and_slide()

	if vida <= 0:
		queue_free()

func aplicar_knockback(direcao: Vector2, forca: float) -> void:
	estado_atual = ESTADOS.HIT
	knockback_force = direcao.normalized() * forca

	sprite.modulate = Color(10, 10, 10)

	await get_tree().create_timer(0.15).timeout
	estado_atual = ESTADOS.NAO_CACANDO
	sprite.modulate = Color.WHITE

func receber_dano(dano: int) -> void:
	vida -= dano

func check_posicao_alvo():
	if LOS.get_collider() == alvo and atirar_tempo.is_stopped():
		estado_atual = ESTADOS.ATIRANDO
		atirar_tempo.start()
	elif LOS.get_collider() != alvo and not atirar_tempo.is_stopped():
		estado_atual = ESTADOS.CACANDO
		atirar_tempo.stop()
			
func mirar():
	LOS.target_position = to_local(alvo.position)


func _on_atirar_tempo_timeout() -> void:
	
	atirar()

func atirar():
	var projetil = projetil_instancia.instantiate()
	if not is_instance_valid(alvo):
		return

	projetil.global_position = global_position
	projetil.direcao = (alvo.global_position - projetil.global_position).normalized()
	projetil.rotation = projetil.direcao.angle()


	get_tree().current_scene.add_child(projetil)
