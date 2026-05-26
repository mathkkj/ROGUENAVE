extends Inimigo_meele
class_name Inimigo_invocado

enum ESTADOS_INVOCADO {
	NORMAL,
	SENDO_INVOCADO
}

var estado_invocado: ESTADOS_INVOCADO = ESTADOS_INVOCADO.NORMAL
