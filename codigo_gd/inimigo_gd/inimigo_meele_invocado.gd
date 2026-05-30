extends Inimigo_meele
class_name Inimigo_invocado

signal invocadinho_morreu

enum ESTADOS_INVOCADO {
	NORMAL,
	SENDO_INVOCADO
}

var estado_invocado: ESTADOS_INVOCADO = ESTADOS_INVOCADO.NORMAL
func receber_dano(dano: int) -> void:
	vida -= dano
	if vida <= 0:
			morrer()
			emit_signal("invocadinho_morreu")
	dano_processado.emit()

func morrer():
	var particula_morte = particula_morte_cena.instantiate()
	particula_morte.position = global_position
	get_tree().current_scene.add_child(particula_morte)
	queue_free()
