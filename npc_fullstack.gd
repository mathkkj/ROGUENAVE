extends CharacterBody2D
class_name NPC_Falante

signal dialogo_finalizado
@onready var texto = $Label

@export var dialogo: Dialogue

var escrevendo := false
var pular_animacao := false

var dialogo_ocorrendo := false

var indice := 0

func iniciar_dialogo():
	if dialogo == null:
		return
	dialogo_ocorrendo = true
	indice = 0
	mostrar_fala()

func mostrar_fala():
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
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and dialogo_ocorrendo == true:
		
		proxima_fala()

func proxima_fala():
	print("proxima_fala")

	if escrevendo:
		#print("pulando animação")
		pular_animacao = true
		return

	#print("próxima linha")

	indice += 1

	if indice >= dialogo.falas.size():
		dialogo_finalizado.emit()
		dialogo_ocorrendo = false
		texto.text = ""
		return

	mostrar_fala()
