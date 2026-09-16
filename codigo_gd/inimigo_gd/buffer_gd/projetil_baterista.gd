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

var knockback_velocity := Vector2.ZERO

@export var forca_knockback := 500.0
@export var desaceleracao_knockback := 1500.0
@export var velocidade := 3.0
@export var velocidade_rotacao := 10.0


func iniciar_curva(_p0: Vector2,_p1: Vector2,_p2: Vector2,_dono: Node2D) -> void:
	p0 = _p0
	p1 = _p1
	p2 = _p2
	dono = _dono

	direcao = (p2 - p0).normalized()

	global_position = p0
	estado_atual = ESTADOS.JOGANDO
	t = 0.0
	knockback_velocity = Vector2.ZERO


func _quadratic_bezier(p0: Vector2,p1: Vector2,p2: Vector2,t: float) -> Vector2:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)

	return q0.lerp(q1, t)


func _physics_process(delta: float) -> void:
	verificar_dono_para_morrer()
	match estado_atual:
		ESTADOS.JOGANDO:
			t += delta * velocidade
			t = min(t, 1.0)

			global_position = _quadratic_bezier(
				p0,
				p1,
				p2,
				t
			)

			rotation += velocidade_rotacao * delta

			if t >= 1.0:
				estado_atual = ESTADOS.NO_CHAO
				ficou_no_chao.emit()

		ESTADOS.NO_CHAO:
			if knockback_velocity.length() > 0.0:
				global_position += knockback_velocity * delta

				knockback_velocity = knockback_velocity.move_toward(
					Vector2.ZERO,
					desaceleracao_knockback * delta
				)


func _on_body_entered(body: Node2D) -> void:
	if body == dono and estado_atual == ESTADOS.NO_CHAO:
		dono.pegar_baqueta()
		queue_free()
		return

	if body.is_in_group("arma_multimidia"):
		var particula = particula_cena.instantiate()
		particula.position = global_position
		get_tree().current_scene.add_child(particula)
		print(particula)
		return

	if body.is_in_group("jogador") and body.has_method("perder_vida"):
		if body.invencivel:
			return

		# a baqueta sempre da dano no jogador
		body.perder_vida(1, direcao, 900)

		# no ar ela tambem toma knockback
		if estado_atual == ESTADOS.JOGANDO:
			knockback()

		return

	if body.is_in_group("inimigos"):
		return

	if body.is_in_group("buff"):
		return


func knockback() -> void:
	var dir = -direcao.normalized()

	if dir == Vector2.ZERO:
		return

	knockback_velocity = dir * forca_knockback


func _on_area_entered(area: Area2D) -> void:
	super(area)
	
func verificar_dono_para_morrer() -> void:
	if dono != null and not is_instance_valid(dono):
		queue_free()
