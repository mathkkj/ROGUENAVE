extends CharacterBody2D
class_name Quebravel

@onready var sprite = get_node("Sprite2D")
var vida = 12

@onready var particula_morte_cena = preload("res://particula_caixa.tscn")
@onready var particula_inicio_cena = preload("res://cenas_tscn/inimigos_tscn/explosao_destruiacao_bala.tscn")

var knockback_force : Vector2
@export var desaceleracao: float = 2500.0

func _ready() -> void:
	pass

func animacao_inicial():
	scale = Vector2.ZERO
	modulate.a = 0.0

	var particula_inicio = particula_inicio_cena.instantiate()
	particula_inicio.global_position = global_position
	get_tree().current_scene.add_child(particula_inicio)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.09, 0.09), 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _physics_process(delta: float) -> void:
	knockback_force = knockback_force.move_toward(Vector2.ZERO, desaceleracao * delta)

	velocity = knockback_force

	move_and_slide()

	empurrar_inimigos_colididos()

func empurrar_inimigos_colididos() -> void:
	var direcao_empurrao := velocity.normalized()
	if direcao_empurrao == Vector2.ZERO:
		return

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var outro = col.get_collider()

		if outro != null and outro is Inimigo:
			if outro == self:
				continue

			var forca_empurrao = max(knockback_force.length() * 1, 80.0)
			outro.aplicar_knockback(direcao_empurrao, forca_empurrao)

func aplicar_knockback(direcao: Vector2, forca: float) -> void:
	knockback_force = direcao.normalized() * forca * 1.5

	sprite.modulate = Color(10, 10, 10)

	await get_tree().create_timer(0.15).timeout
	if not is_inside_tree():
		return
	sprite.modulate = Color.WHITE

func receber_dano(dano: int) -> void:
	print("vida: ", vida)

	vida -= dano
	if vida <= 0:
		var particula_morte = particula_morte_cena.instantiate()
		particula_morte.position = global_position
		get_tree().current_scene.add_child(particula_morte)
		queue_free()
