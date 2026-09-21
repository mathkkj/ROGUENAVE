extends Inimigo_meele
class_name InimigoDummy

@export var ativo: bool = false
var demonstracao := false


func _ready() -> void:
	super()


func ativar_dummy() -> void:
	ativo = true
	process_mode = Node.PROCESS_MODE_INHERIT


func desativar_dummy() -> void:
	ativo = false
	velocity = Vector2.ZERO
	process_mode = Node.PROCESS_MODE_INHERIT


func receber_dano(dano: int) -> void:
	if not ativo:
		return
	super(dano)


func dash():
	if not ativo:
		return
	super()


func _on_atirar_tempo_timeout() -> void:
	if not ativo:
		return
	super()


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if not ativo:
		return
	super(body)


func _physics_process(delta: float) -> void:
	if is_instance_valid(alvo):
		sprite.flip_h = alvo.global_position.x > global_position.x

	if demonstracao:
		tocar_animacao("idle")
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not ativo:
		tocar_animacao("dormindo")

		# nao anda nem ataca, mas ainda pode reagir a knockback
		knockback_force = knockback_force.move_toward(
			Vector2.ZERO,
			desaceleracao * delta
		)

		if estado_atual == ESTADOS.HIT:
			velocity = knockback_force
		else:
			velocity = Vector2.ZERO

		move_and_slide()
		return

	super(delta)

func definir_demonstracao(valor: bool) -> void:
	demonstracao = valor
