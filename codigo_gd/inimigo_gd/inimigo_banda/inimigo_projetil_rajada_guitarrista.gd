extends Inimigo_projetil_rajada
class_name Inimigo_guitarrista

func morrer():
	var particula_morte = particula_morte_cena.instantiate()
	particula_morte.position = global_position
	get_tree().current_scene.add_child(particula_morte)
	queue_free()
