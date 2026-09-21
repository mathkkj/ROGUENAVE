extends CharacterBody2D
class_name NPC_Falante

signal dialogo_finalizado
@onready var texto = $Label

@export var dialogo: Dialogue
@export var limite_dialogo: int = -1  # -1 = mostra tudo

var escrevendo := false
var pular_animacao := false
var dialogo_ocorrendo := false
@export var indice := 0

func iniciar_dialogo(indice_inicial := 0):
	if dialogo == null:
		return

	dialogo_ocorrendo = true
	indice = indice_inicial
	mostrar_fala()

func mostrar_fala():
	if limite_dialogo != -1 and indice >= limite_dialogo:
		dialogo_finalizado.emit()
		dialogo_ocorrendo = false
		texto.text = ""
		return

	if indice >= dialogo.falas.size():
		texto.text = ""
		return

	var fala := dialogo.falas[indice]

	escrevendo = true
	pular_animacao = false

	texto.text = fala.texto
	texto.visible_characters = 0

	for i in fala.texto.length():
		if pular_animacao:
			break

		texto.visible_characters = i + 1
		await get_tree().create_timer(fala.velocidade_texto).timeout

	texto.visible_characters = fala.texto.length()
	escrevendo = false

func _input(event):
	if not dialogo_ocorrendo:
		return

	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		proxima_fala()
		return

	if event.is_action_pressed("ui_accept") \
	or event.is_action_pressed("ui_select") \
	or event.is_action_pressed("pular_dialogo"):
		proxima_fala()

func proxima_fala():
	if escrevendo:
		pular_animacao = true
		return

	indice += 1
	mostrar_fala()









# TELEPORTE

@onready var particula_inicio_cena = preload(
	"res://cenas_tscn/inimigos_tscn/explosao_destruiacao_bala.tscn"
)


func teleportar_para(marker: Marker2D):
	if marker == null:
		return

	velocity = Vector2.ZERO

	# some do local atual
	scale = Vector2.ZERO
	modulate.a = 0.0

	# partícula no local de origem
	var particula_inicio = particula_inicio_cena.instantiate()
	particula_inicio.global_position = global_position
	get_tree().current_scene.add_child(particula_inicio)

	# teleporta
	global_position = marker.global_position

	# partícula no destino
	var particula_fim = particula_inicio_cena.instantiate()
	particula_fim.global_position = global_position
	get_tree().current_scene.add_child(particula_fim)

	# mesma animação da caixa
	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.25
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.2
	)

	await tween.finished

	scale = Vector2.ONE
	modulate.a = 1.0
