extends Inimigo_Projetil
class_name Inimigo_invocador

@onready var inimigos_invocados_cena: PackedScene = preload("res://cenas_tscn/inimigos_tscn/inimigo_meele_invocado.tscn")
@onready var area = $circulo_de_visao
@onready var collision = $circulo_de_visao/CollisionShape2D
var ja_atirou : bool = false
enum ESTADOS_INVOCADOR {
	NORMAL,
	INVOCANDO
}

var estado_invocador: ESTADOS_INVOCADOR = ESTADOS_INVOCADOR.NORMAL


func pode_invocar() -> bool:
	return is_instance_valid(alvo) and estado_atual == ESTADOS.CACANDO and estado_distancia == ESTADOS_DISTANCIA.IDEAL and LOS.get_collider() == alvo


func _physics_process(delta: float) -> void:
	
	if not is_instance_valid(alvo):
		return

	mirar()
	check_posicao_alvo()

	if estado_invocador == ESTADOS_INVOCADOR.INVOCANDO:
		velocity = Vector2.ZERO
		super._physics_process(delta)
		return
	
	super._physics_process(delta)


func _on_atirar_tempo_timeout() -> void:
	if ja_atirou:
		return
	if not pode_invocar():
		return
	ja_atirou = true
	print("inimigo invocador invocou")
	estado_invocador = ESTADOS_INVOCADOR.INVOCANDO
	velocity = Vector2.ZERO
	

	for i in range(4):
		var inimigo = inimigos_invocados_cena.instantiate()
		inimigo.global_position = pegar_pos_borda()
		get_tree().current_scene.add_child(inimigo)

	estado_invocador = ESTADOS_INVOCADOR.NORMAL
	


func pegar_pos_borda() -> Vector2:
	var raio = collision.shape.radius

	var direcao_aleatoria = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

	var posicao_borda = direcao_aleatoria * raio

	return global_position + posicao_borda
	
	
func check_posicao_alvo():
	var collider = LOS.get_collider()

	if collider == alvo:
		if atirar_tempo.is_stopped():
			atirar_tempo.start()
		return

	if collider != null and collider.is_in_group("inimigos"):
		return

	
func receber_dano(dano: int) -> void:
	if not is_instance_valid(alvo):
		return
	vida -= dano
	if vida <= 0:
			var particula_morte = particula_morte_cena.instantiate()
			particula_morte.position = global_position
			get_tree().current_scene.add_child(particula_morte)
			queue_free()
			for node in get_tree().get_nodes_in_group("inimigos_invocados"):
				node.queue_free()

	dano_processado.emit()
