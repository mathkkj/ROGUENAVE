extends CharacterBody2D
class_name Inimigo

@export var desaceleracao: float = 2500.0
@export var speed: float = 100.0
@export var alvo: CharacterBody2D
@export var max_speed := 300.0
@export var max_accel := 1200.0

@onready var cor_dominante := Color.WHITE


var explosao_cena = preload("res://cenas_tscn/explosao.tscn")
var vida: int = 25
var knockback_force: Vector2 = Vector2.ZERO

@onready var sprite := $Sprite2D
@onready var navagent = $NavigationAgent2D


var ultima_direcao := Vector2.ZERO
var tempo_memoria := 0.0

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
	CACANDO,
	ATIRANDO,
	HIT,
}

var estado_atual: ESTADOS = ESTADOS.CACANDO


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
			
			if ray.get_collider().is_in_group("inimigos"):
				score -= 5.0
			else:
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
		tempo_memoria = 0.1
	
	return melhor_direcao





#func cachear_cor():
	#var sprite := $Sprite2D
	#var img = sprite.texture.get_image()
	#img.resize(1, 1, Image.INTERPOLATE_NEAREST)
	#cor_dominante = img.get_pixel(0, 0)

func gerar_steering(direcao_path) -> Vector2:
	
	var desired_velocity = direcao_path * max_speed
	# steering force 
	var steering = desired_velocity - velocity
	return steering

func _physics_process(delta: float) -> void:
	
	if not is_instance_valid(alvo):
		return
	
	var direcao_para_alvo: Vector2 = (alvo.global_position - global_position).normalized()
	var direcao_path: Vector2 = escolher_dir(direcao_para_alvo, delta)

	

	

	# steering force 
	var steering = gerar_steering(direcao_path)
	steering = steering.limit_length(max_accel * delta)

	# aplica knockback sem apagar o steering
	knockback_force = knockback_force.move_toward(Vector2.ZERO, desaceleracao * delta)

	
	
	
	
	match estado_atual:
		ESTADOS.CACANDO:
			velocity += steering
			#if LOS.get_collider() != alvo:
				#estado_atual = ESTADOS.NAO_CACANDO

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
	estado_atual = ESTADOS.CACANDO
	sprite.modulate = Color.WHITE

func receber_dano(dano: int) -> void:
	vida -= dano
