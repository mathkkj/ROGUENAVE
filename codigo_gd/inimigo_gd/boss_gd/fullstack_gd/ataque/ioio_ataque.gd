extends Projetil_do_inimigo
class_name Ioio_ataque

@export var efeito_explosao := preload("res://cenas_tscn/inimigos_tscn/explosao_destruiacao_bala.tscn")

signal acertou_alvo
signal voltou

var dono: Node2D
var origem: Node2D
var alvo: Node2D

enum ESTADOS {
	INDO,
	SAINDO_MEIA_LUA,
	MEIA_LUA,
	ENTRANDO_JOGADOR,
	VOLTANDO,
	BLOQUEIO
}

var tempo_saida_meia_lua := 0.0
@export var duracao_saida_meia_lua := 0.18

var ponto_inicio_meia_lua := Vector2.ZERO
var ponto_saida_meia_lua := Vector2.ZERO

var estado: ESTADOS = ESTADOS.INDO


# meia lua
@export var limite_raio_meia_lua := 200.0

var centro_meia_lua := Vector2.ZERO
var raio_meia_lua := 0.0

var angulo_meia_lua := 0.0
var angulo_inicio := 0.0

var velocidade_angular := 0.0
@export var velocidade_angular_inicial := 2.5
@export var aceleracao_angular := 22.0
@export var velocidade_angular_max := 10.0


# bloqueio
var raio_bloqueio := 0.0
var angulo_bloqueio := 0.0

@export var velocidade_bloqueio := 6.0
@export var aceleracao_bloqueio := 30.0
@export var tempo_bloqueio := 0.9

var tempo_bloqueio_atual := 0.0
var velocidade_bloqueio_atual := 0.0

var objetos_rebatidos: Dictionary = {}


# movimento normal
var posicao_alvo := Vector2.ZERO

@export var velocidade_ida := 1000.0
@export var aceleracao_ida := 5000.0

@export var velocidade_volta := 500.0
@export var velocidade_entrada := 1000.0
@export var aceleracao_entrada := 4500.0

var velocidade_ida_atual := Vector2.ZERO
var velocidade_entrada_atual := 0.0

var ja_acertou := false

# movimento de volta
var velocidade_volta_atual := Vector2.ZERO

@export var aceleracao_volta := 5000.0
@export var velocidade_maxima_volta := 1200.0
@export var taxa_giro_volta := 11.0


func _ready() -> void:
	monitoring = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func iniciar(
	novo_alvo: Node2D,
	novo_dono: Node2D,
	distancia: float
) -> void:
	alvo = novo_alvo
	dono = novo_dono
	origem = novo_dono

	if not is_instance_valid(alvo):
		queue_free()
		return

	posicao_alvo = alvo.global_position
	direcao = global_position.direction_to(posicao_alvo)

	velocidade_ida_atual = direcao * velocidade_ida


func iniciar_meia_lua(
	novo_alvo: Node2D,
	novo_dono: Node2D,
	raio: float = 0.0
) -> void:
	alvo = novo_alvo
	dono = novo_dono
	origem = novo_dono

	if not is_instance_valid(alvo):
		queue_free()
		return

	# salva de onde o projetil realmente saiu
	ponto_saida_meia_lua = global_position

	# o jogador vira o centro da meia lua
	centro_meia_lua = alvo.global_position

	var distancia_jogador := centro_meia_lua.distance_to(
		dono.global_position
	)

	if raio <= 0.0:
		raio_meia_lua = distancia_jogador
	else:
		raio_meia_lua = raio

	raio_meia_lua = min(
		raio_meia_lua,
		limite_raio_meia_lua
	)

	raio_meia_lua = max(
		raio_meia_lua - 25.0,
		35.0
	)

	# direcao do jogador para o boss
	var direcao_jogador_boss := centro_meia_lua.direction_to(
		dono.global_position
	)

	# começa 90 graus para o lado
	angulo_inicio = direcao_jogador_boss.angle() + PI / 2.0
	angulo_meia_lua = angulo_inicio

	ponto_inicio_meia_lua = centro_meia_lua + (
		Vector2.RIGHT.rotated(angulo_inicio)
		* raio_meia_lua
	)

	velocidade_angular = velocidade_angular_inicial
	velocidade_entrada_atual = 0.0

	ja_acertou = false

	estado = ESTADOS.SAINDO_MEIA_LUA


func iniciar_bloqueio(
	novo_dono: Node2D,
	raio: float,
	duracao: float
) -> void:
	dono = novo_dono
	origem = novo_dono
	alvo = null

	raio_bloqueio = raio
	tempo_bloqueio = duracao

	angulo_bloqueio = 0.0
	tempo_bloqueio_atual = 0.0
	velocidade_bloqueio_atual = 0.0

	objetos_rebatidos.clear()

	estado = ESTADOS.BLOQUEIO


func _physics_process(delta: float) -> void:
	if not is_instance_valid(origem):
		queue_free()
		return

	match estado:
		ESTADOS.INDO:
			mover_indo(delta)

		ESTADOS.SAINDO_MEIA_LUA:
			mover_saindo_meia_lua(delta)

		ESTADOS.MEIA_LUA:
			mover_meia_lua(delta)

		ESTADOS.ENTRANDO_JOGADOR:
			mover_entrando_jogador(delta)

		ESTADOS.VOLTANDO:
			mover_voltando(delta)

		ESTADOS.BLOQUEIO:
			mover_bloqueio(delta)


func mover_indo(delta: float) -> void:
	if not is_instance_valid(alvo):
		queue_free()
		return

	posicao_alvo = alvo.global_position

	var distancia := global_position.distance_to(posicao_alvo)

	if distancia <= 15.0:
		global_position = posicao_alvo
		comecar_volta()
		return

	var direcao_alvo := global_position.direction_to(posicao_alvo)
	var velocidade_desejada := direcao_alvo * velocidade_ida

	# faz a direcao virar suavemente em vez de mudar de uma vez
	velocidade_ida_atual = velocidade_ida_atual.move_toward(
		velocidade_desejada,
		aceleracao_ida * delta
	)

	direcao = velocidade_ida_atual.normalized()

	var passo := velocidade_ida_atual.length() * delta

	if passo >= distancia:
		global_position = posicao_alvo
		comecar_volta()
		return

	global_position += velocidade_ida_atual * delta


func mover_saindo_meia_lua(delta: float) -> void:
	if not is_instance_valid(dono):
		queue_free()
		return

	tempo_saida_meia_lua += delta

	var progresso = min(
		tempo_saida_meia_lua / duracao_saida_meia_lua,
		1.0
	)

	# acelera no inicio e suaviza no final
	var progresso_suave := 1.0 - pow(
		1.0 - progresso,
		3.0
	)

	global_position = ponto_saida_meia_lua.lerp(
		ponto_inicio_meia_lua,
		progresso_suave
	)

	direcao = ponto_saida_meia_lua.direction_to(
		ponto_inicio_meia_lua
	)

	if progresso >= 1.0:
		global_position = ponto_inicio_meia_lua
		angulo_meia_lua = angulo_inicio
		velocidade_angular = velocidade_angular_inicial
		estado = ESTADOS.MEIA_LUA


func mover_meia_lua(delta: float) -> void:
	if not is_instance_valid(alvo):
		comecar_volta()
		return

	velocidade_angular = move_toward(
		velocidade_angular,
		velocidade_angular_max,
		aceleracao_angular * delta
	)

	angulo_meia_lua += velocidade_angular * delta

	var nova_posicao := centro_meia_lua + (
		Vector2.RIGHT.rotated(angulo_meia_lua)
		* raio_meia_lua
	)

	direcao = global_position.direction_to(nova_posicao)

	global_position = nova_posicao

	if angulo_meia_lua - angulo_inicio >= PI:
		velocidade_entrada_atual = velocidade_entrada * 0.25
		estado = ESTADOS.ENTRANDO_JOGADOR


func mover_entrando_jogador(delta: float) -> void:
	if not is_instance_valid(alvo):
		comecar_volta()
		return

	var posicao_jogador := alvo.global_position
	var distancia := global_position.distance_to(posicao_jogador)

	if distancia <= 10.0:
		global_position = posicao_jogador
		comecar_volta()
		return

	velocidade_entrada_atual = move_toward(
		velocidade_entrada_atual,
		velocidade_entrada,
		aceleracao_entrada * delta
	)

	var direcao_jogador := global_position.direction_to(
		posicao_jogador
	)

	direcao = direcao_jogador

	var passo := velocidade_entrada_atual * delta

	if passo >= distancia:
		global_position = posicao_jogador
		comecar_volta()
		return

	global_position += direcao_jogador * velocidade_entrada_atual * delta


func mover_bloqueio(delta: float) -> void:
	if not is_instance_valid(dono):
		queue_free()
		return

	tempo_bloqueio_atual += delta

	# acelera o giro em vez de aparecer girando instantaneamente
	velocidade_bloqueio_atual = move_toward(
		velocidade_bloqueio_atual,
		velocidade_bloqueio,
		aceleracao_bloqueio * delta
	)

	angulo_bloqueio += velocidade_bloqueio_atual * delta

	global_position = dono.global_position + (
		Vector2.RIGHT.rotated(angulo_bloqueio)
		* raio_bloqueio
	)

	if tempo_bloqueio_atual >= tempo_bloqueio:
		comecar_volta()


func mover_voltando(delta: float) -> void:
	if not is_instance_valid(origem):
		queue_free()
		return

	var distancia := global_position.distance_to(
		origem.global_position
	)

	if distancia <= 30.0:
		global_position = origem.global_position
		voltou.emit()
		queue_free()
		return

	var direcao_boss := global_position.direction_to(
		origem.global_position
	)

	if velocidade_volta_atual.is_zero_approx():
		velocidade_volta_atual = direcao_boss * velocidade_volta

	var velocidade := velocidade_volta_atual.length()

	velocidade = move_toward(
		velocidade,
		velocidade_maxima_volta,
		aceleracao_volta * delta
	)

	# faz o projetil virar gradualmente para o boss
	var direcao_atual := velocidade_volta_atual.normalized()

	var angulo_necessario := direcao_atual.angle_to(
		direcao_boss
	)

	var giro_maximo := taxa_giro_volta * delta

	var giro = clamp(
		angulo_necessario,
		-giro_maximo,
		giro_maximo
	)

	direcao_atual = direcao_atual.rotated(giro)

	velocidade_volta_atual = direcao_atual * velocidade
	direcao = direcao_atual

	var passo := velocidade * delta

	if passo >= distancia:
		global_position = origem.global_position
		voltou.emit()
		queue_free()
		return

	global_position += velocidade_volta_atual * delta


func comecar_volta() -> void:
	if estado == ESTADOS.VOLTANDO:
		return

	estado = ESTADOS.VOLTANDO

	if not is_instance_valid(origem):
		queue_free()
		return

	var direcao_boss := global_position.direction_to(
		origem.global_position
	)

	var tangente := Vector2(
		-direcao_boss.y,
		direcao_boss.x
	)

	# impulso inicial levemente de lado
	# isso faz o retorno parecer uma puxada de ioio
	# em vez de simplesmente voltar em linha reta
	var direcao_saida := (
		direcao_boss * 0.87
		+ tangente * 0.50
	).normalized()

	var velocidade_inicial = min(
		velocidade_volta,
		velocidade_maxima_volta
	)

	velocidade_volta_atual = (
		direcao_saida
		* velocidade_inicial
	)

	direcao = direcao_saida


func _on_body_entered(body: Node2D) -> void:
	if estado == ESTADOS.BLOQUEIO:
		if body == dono:
			return

		if body.is_in_group("arma_multimidia"):
			parry_arma(body)
			return

		if body.is_in_group("bala_player"):
			body.queue_free()
			return

		if body.is_in_group("jogador") and body.has_method("perder_vida"):
			var direcao_impacto = -direcao
			var knockback := 1000

			body.perder_vida(
				1,
				direcao_impacto,
				knockback
			)

		return

	if body == dono:
		return

	if body.is_in_group("fullstack"):
		return

	if body != alvo:
		return

	if body.invencivel:
		return

	if ja_acertou:
		return

	ja_acertou = true

	if body.is_in_group("jogador") and body.has_method("perder_vida"):
		var direcao_impacto = -direcao
		var knockback := 1000

		if estado == ESTADOS.ENTRANDO_JOGADOR:
			direcao_impacto = direcao
			knockback = 700

		body.perder_vida(
			1,
			direcao_impacto,
			knockback
		)

	acertou_alvo.emit()


func _on_area_entered(area: Area2D) -> void:
	if estado != ESTADOS.BLOQUEIO:
		return

	if area.is_in_group("arma_multimidia"):
		parry_arma(area)
		return

	if area.is_in_group("bala_player"):
		var particula = efeito_explosao.instantiate()
		particula.global_position = area.global_position
		get_tree().current_scene.add_child(particula)
		area.queue_free()
		return


func parry_arma(arma: Node2D) -> void:
	if not is_instance_valid(Global.personagem):
		return

	var jogador: Node2D = Global.personagem

	if jogador.invencivel:
		return

	jogador.perder_vida(
		0,
		dono.global_position.direction_to(jogador.global_position),
		900
	)
