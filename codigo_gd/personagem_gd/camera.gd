extends Camera2D

@export var personagem: Node2D
@export var distancia_maxima := Vector2(150, 75)

var alvo_camera: Node2D

var desired_offset := Vector2(0,0)

#SHAKE
@export var decay : float = 0.8
@export var max_offset : Vector2 = Vector2(40, 25)
@export var max_roll : float = 0.1

var trauma = 0.0
var trauma_power = 1

var direcao = Vector2.ZERO

var camera_lock := false

func _ready() -> void:
	alvo_camera = personagem

func _physics_process(delta: float) -> void:
	if personagem == null:
		return

	var zoom_aplicado := Vector2(1,1)
	var alvo_offset := Vector2(0,0)

	#lock e unlock
	if personagem == null:
		return

	if camera_lock:
		global_position = alvo_camera.global_position + desired_offset

		if trauma:
			trauma = max(trauma - decay * delta, 0)
			shake()

		return


	if Global.usando_controle:
		zoom_aplicado = Vector2(1, 1)
		direcao = Input.get_vector("esquerdaAnalogicoDireito", "direitaAnalogicoDireito", "cimaAnalogicoDireito", "baixoAnalogicoDireito")
		alvo_offset = direcao * distancia_maxima
	else:
		zoom_aplicado = Vector2(0.92, 0.92)
		alvo_offset = get_global_mouse_position() - personagem.global_position
		alvo_offset.x = clamp(alvo_offset.x, -distancia_maxima.x, distancia_maxima.x)
		alvo_offset.y = clamp(alvo_offset.y, -distancia_maxima.y, distancia_maxima.y)

	desired_offset = desired_offset.lerp(alvo_offset, 8.0 * delta)
	zoom = zoom.lerp(zoom_aplicado, 10.0 * delta)
	global_position = personagem.global_position + desired_offset
	
		
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()
		

func transitar_personagem(novo_personagem: Node2D, tempo := 1.2):
	if novo_personagem == null:
		return


	var ponto = Node2D.new()
	get_tree().current_scene.add_child(ponto)

	ponto.global_position = global_position
	alvo_camera = ponto

	var zoom_original = zoom

	var tween = create_tween()

	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(
		ponto,
		"global_position",
		novo_personagem.global_position,
		tempo
	)

	tween.parallel().tween_property(
		self,
		"zoom",
		Vector2.ONE * 1.15,
		tempo * 0.4
	)

	await tween.finished

	personagem = novo_personagem
	alvo_camera = personagem

	var tween2 = create_tween()

	tween2.tween_property(
		self,
		"zoom",
		zoom_original,
		0.35
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	ponto.queue_free()


func lock_camera():
	camera_lock = true
	desired_offset = Vector2.ZERO

func unlock_camera():
	camera_lock = false

func add_trauma(amount : float, direcao_ataque: Vector2) -> void:

	trauma = clamp(trauma + amount, 0.0, 1.0)
	direcao = direcao_ataque

func shake() -> void:
	var amount = pow(trauma, trauma_power)
	amount = clamp(amount, 0.0, 1.0)
	
	#if direcao.x == 0:
		#direcao.x = 1
	#if direcao.y == 0:
		#direcao.y = 1
	
	rotation = max_roll * amount * randf_range(-0.5, 0.5)
	offset.x = max_offset.x * amount * randf_range(-direcao.x, direcao.x)
	offset.y = max_offset.y * amount * randf_range(-direcao.y, direcao.y)
	#print("offset x = ", offset.x)
	#print("offset y = ", offset.y)

	

	
