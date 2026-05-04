extends Camera2D

@export var personagem: Node2D
@export var distancia_maxima := Vector2(200, 100)

var desired_offset := Vector2(0,0)

func _process(delta: float) -> void:
	if personagem == null:
		return

	var zoom_aplicado := Vector2(1,1)
	var alvo_offset := Vector2(0,0)

	if Global.usando_controle:
		zoom_aplicado = Vector2(1, 1)
		var direcao := Input.get_vector("esquerdaAnalogicoDireito", "direitaAnalogicoDireito", "cimaAnalogicoDireito", "baixoAnalogicoDireito")
		alvo_offset = direcao * distancia_maxima
	else:
		zoom_aplicado = Vector2(0.92, 0.92)
		alvo_offset = get_global_mouse_position() - personagem.global_position
		alvo_offset.x = clamp(alvo_offset.x, -distancia_maxima.x, distancia_maxima.x)
		alvo_offset.y = clamp(alvo_offset.y, -distancia_maxima.y, distancia_maxima.y)

	desired_offset = desired_offset.lerp(alvo_offset, 8.0 * delta)
	zoom = zoom.lerp(zoom_aplicado, 10.0 * delta)
	global_position = personagem.global_position + desired_offset
