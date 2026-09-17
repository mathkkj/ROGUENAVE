extends Projetil_do_inimigo

signal ficou_no_chao

enum ESTADOS {
	JOGANDO,
	NO_CHAO
}

var estado_atual: ESTADOS = ESTADOS.JOGANDO

var p0: Vector2
var p1: Vector2
var p2: Vector2
var dono: Node2D

var t := 0.0
var tamanho_curva := 1.0

var velocidade_chao := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var velocidade_voo := Vector2.ZERO

var rotacao_velocity := 0.0

var da_dano := true
var jogador_atingido := false


@export var velocidade := 650.0
@export var altura_arco := 80.0
@export var velocidade_rotacao := 12.0

@export var velocidade_pouso := 90.0
@export var desaceleracao_chao := 500.0

@export var forca_knockback := 500.0
@export var desaceleracao_knockback := 1500.0

@export var fator_impacto := 0.65
@export var velocidade_minima_impacto := 180.0
@export var velocidade_maxima_impacto := 900.0

@export var fator_knockback_jogador := 0.9
@export var knockback_minimo_jogador := 250.0
@export var knockback_maximo_jogador := 700.0


func iniciar_curva(_p0: Vector2, _p1: Vector2, _p2: Vector2, _dono: Node2D) -> void:
	p0 = _p0
	p1 = _p1
	p2 = _p2
	dono = _dono

	global_position = p0

	direcao = (p2 - p0).normalized()

	if direcao == Vector2.ZERO:
		direcao = Vector2.RIGHT

	estado_atual = ESTADOS.JOGANDO

	t = 0.0
	knockback_velocity = Vector2.ZERO
	velocidade_chao = Vector2.ZERO
	velocidade_voo = Vector2.ZERO

	da_dano = true
	jogador_atingido = false

	rotacao_velocity = velocidade_rotacao

	tamanho_curva = _calcular_tamanho_curva()


func _quadratic_bezier(_p0: Vector2, _p1: Vector2, _p2: Vector2, _t: float) -> Vector2:
	var q0 = _p0.lerp(_p1, _t)
	var q1 = _p1.lerp(_p2, _t)

	return q0.lerp(q1, _t)


func _calcular_tamanho_curva() -> float:
	var tamanho := 0.0
	var ponto_anterior := p0
	var quantidade_pontos := 100

	for i in range(1, quantidade_pontos + 1):
		var ponto_t := float(i) / float(quantidade_pontos)
		var ponto := _quadratic_bezier(p0, p1, p2, ponto_t)

		tamanho += ponto_anterior.distance_to(ponto)
		ponto_anterior = ponto

	return max(tamanho, 1.0)


func _physics_process(delta: float) -> void:
	verificar_dono_para_morrer()

	match estado_atual:
		ESTADOS.JOGANDO:
			_processar_voo(delta)

		ESTADOS.NO_CHAO:
			_processar_chao(delta)

	rotacao_velocity = move_toward(
		rotacao_velocity,
		0.0 if estado_atual == ESTADOS.NO_CHAO else velocidade_rotacao,
		18.0 * delta
	)

	rotation += rotacao_velocity * delta


func _processar_voo(delta: float) -> void:
	var posicao_anterior := global_position

	var distancia_por_frame := velocidade * delta

	t += distancia_por_frame / tamanho_curva
	t = min(t, 1.0)

	global_position = _quadratic_bezier(
		p0,
		p1,
		p2,
		t
	)

	if delta > 0.0:
		velocidade_voo = (global_position - posicao_anterior) / delta

	if velocidade_voo.length_squared() > 0.0:
		direcao = velocidade_voo.normalized()

	if t >= 1.0:
		entrar_no_chao()


func entrar_no_chao() -> void:
	if estado_atual == ESTADOS.NO_CHAO:
		return

	estado_atual = ESTADOS.NO_CHAO

	velocidade_chao = direcao * velocidade_pouso
	knockback_velocity = Vector2.ZERO
	velocidade_voo = Vector2.ZERO

	ficou_no_chao.emit()


func _processar_chao(delta: float) -> void:
	var movimento := velocidade_chao + knockback_velocity

	if movimento.length_squared() > 0.0:
		global_position += movimento * delta

	velocidade_chao = velocidade_chao.move_toward(
		Vector2.ZERO,
		desaceleracao_chao * delta
	)

	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		desaceleracao_knockback * delta
	)


func _on_body_entered(body: Node2D) -> void:
	if body == RayCast2D:
		return

	if body.is_in_group("raycast"):
		return

	if body == dono:
		if estado_atual == ESTADOS.NO_CHAO:
			dono.pegar_baqueta(self)

		return

	if body.is_in_group("arma_multimidia"):
		var particula = particula_cena.instantiate()
		particula.position = global_position
		get_tree().current_scene.add_child(particula)
		return

	if eh_jogador(body):
		processar_colisao_jogador(body)
		return

	if body.is_in_group("inimigos"):
		return

	if body.is_in_group("buff"):
		return


func processar_colisao_jogador(body: Node2D) -> void:
	if estado_atual != ESTADOS.JOGANDO:
		return

	if jogador_atingido:
		return

	if body.invencivel:
		return

	jogador_atingido = true
	da_dano = false

	var velocidade_impacto = clamp(
		velocidade_voo.length(),
		velocidade_minima_impacto,
		velocidade_maxima_impacto
	)

	var forca_jogador = clamp(
		velocidade_impacto * fator_knockback_jogador,
		knockback_minimo_jogador,
		knockback_maximo_jogador
	)

	body.perder_vida(
		1,
		direcao,
		forca_jogador
	)

	impacto(velocidade_impacto)


func eh_jogador(body: Node) -> bool:
	var atual: Node = body

	while atual != null:
		if atual.is_in_group("jogador"):
			return true

		atual = atual.get_parent()

	return false


func impacto(velocidade_impacto: float) -> void:
	if estado_atual == ESTADOS.NO_CHAO:
		return

	var dir := -direcao.normalized()

	if dir == Vector2.ZERO:
		return

	velocidade_impacto = clamp(
		velocidade_impacto,
		velocidade_minima_impacto,
		velocidade_maxima_impacto
	)

	var forca_impacto := velocidade_impacto * fator_impacto

	entrar_no_chao()

	velocidade_chao = Vector2.ZERO
	knockback_velocity = dir * forca_impacto

	rotacao_velocity = velocidade_rotacao * 1.5


func knockback() -> void:
	impacto(forca_knockback)


func _on_area_entered(area: Area2D) -> void:
	super(area)


func verificar_dono_para_morrer() -> void:
	if dono != null and not is_instance_valid(dono):
		queue_free()
