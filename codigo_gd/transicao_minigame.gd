extends CanvasLayer

signal minigame_fechado

var textura_tutorial_retorno: ImageTexture

@onready var shader_glass: ColorRect = $ColorRect2
@onready var subviewport: SubViewport = $SubViewportContainer/SubViewport
@onready var subviewport_container: Control = $SubViewportContainer

@onready var camera: Camera2D = get_viewport().get_camera_2d()

var material_transicao: ShaderMaterial
var minigame_atual: Node

var em_transicao := false
var minigame_aberto := false


@export var duracao_entrada := 2.5
@export var pausa_inicio := 0.25
@export var duracao_blend_final := 0.08


func _ready() -> void:
	layer = 100

	subviewport_container.z_index = 0
	shader_glass.z_index = 1

	shader_glass.visible = false
	shader_glass.modulate.a = 0.0
	shader_glass.scale = Vector2.ONE

	subviewport_container.visible = false

	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	subviewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	subviewport.transparent_bg = false

	material_transicao = shader_glass.material as ShaderMaterial

	if material_transicao == null:
		push_error("o ColorRect nao possui um ShaderMaterial")
		return

	material_transicao.set_shader_parameter("fall_progress", 0.0)
	material_transicao.set_shader_parameter("final_blend", 0.0)


func capturar_tela() -> ImageTexture:
	await RenderingServer.frame_post_draw

	var imagem := get_viewport().get_texture().get_image()

	return ImageTexture.create_from_image(imagem)


func chacoalhar_camera(camera_alvo: Camera2D, duracao: float = 0.18, intensidade: float = 8.0) -> void:
	if camera_alvo == null:
		return

	var offset_original := camera_alvo.offset
	var rotacao_original := camera_alvo.rotation
	var tempo := 0.0

	while tempo < duracao:
		var tremor_x := randf_range(-intensidade, intensidade)
		var tremor_y := randf_range(-intensidade, intensidade)

		tremor_x += sin(tempo * 90.0) * intensidade * 0.5
		tremor_y += cos(tempo * 110.0) * intensidade * 0.5

		camera_alvo.offset = offset_original + Vector2(
			tremor_x,
			tremor_y
		)

		camera_alvo.rotation = rotacao_original + deg_to_rad(
			randf_range(-intensidade * 0.12, intensidade * 0.12)
		)

		await get_tree().process_frame
		tempo += get_process_delta_time()

	
	camera_alvo.offset = offset_original
	camera_alvo.rotation = rotacao_original


func abrir_minigame(caminho_cena: String) -> void:
	
	
	if caminho_cena.is_empty():
		return

	if em_transicao or minigame_aberto:
		return

	var cena := load(caminho_cena) as PackedScene

	if cena == null:
		push_error("nao foi possivel carregar o minigame: " + caminho_cena)
		return

	em_transicao = true
	minigame_aberto = true

	# primeiro da o impacto
	var camera_principal := get_viewport().get_camera_2d()

	if camera_principal != null:
		await chacoalhar_camera(camera_principal, 0.1, 8.0)

	# salva a imagem da cena atual para usar quando fechar o minigame
	textura_tutorial_retorno = await capturar_tela()

	material_transicao.set_shader_parameter(
		"current_tex",
		textura_tutorial_retorno
	)

	subviewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	for filho in subviewport.get_children():
		filho.free()

	minigame_atual = cena.instantiate()

	if not is_instance_valid(minigame_atual):
		push_error("nao foi possivel instanciar o minigame")

		em_transicao = false
		minigame_aberto = false
		return

	subviewport.add_child(minigame_atual)

	minigame_atual.process_mode = Node.PROCESS_MODE_ALWAYS

	await RenderingServer.frame_post_draw

	material_transicao.set_shader_parameter(
		"background_tex",
		subviewport.get_texture()
	)

	material_transicao.set_shader_parameter("fall_progress", 0.0)
	material_transicao.set_shader_parameter("final_blend", 0.0)

	shader_glass.visible = true
	shader_glass.modulate.a = 1.0
	shader_glass.scale = Vector2.ONE

	subviewport_container.visible = true

	await RenderingServer.frame_post_draw

	material_transicao.set_shader_parameter(
		"fall_progress",
		0.01
	)

	await get_tree().create_timer(pausa_inicio).timeout

	var duracao_queda = max(
		0.01,
		duracao_entrada - pausa_inicio
	)

	var tween_queda := create_tween()

	tween_queda.tween_method(
		mudar_progresso,
		0.01,
		1.0,
		duracao_queda
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween_queda.finished

	var tween_blend := create_tween()

	tween_blend.tween_method(
		mudar_blend_final,
		0.0,
		1.0,
		duracao_blend_final
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween_blend.finished

	shader_glass.visible = false
	shader_glass.modulate.a = 0.0
	shader_glass.scale = Vector2.ONE

	material_transicao.set_shader_parameter(
		"fall_progress",
		0.0
	)

	material_transicao.set_shader_parameter(
		"final_blend",
		0.0
	)

	em_transicao = false


func fechar_minigame() -> void:
	if em_transicao:
		return

	if not minigame_aberto:
		return

	if not is_instance_valid(minigame_atual):
		minigame_aberto = false
		return

	em_transicao = true

	# primeiro da o impacto
	var camera_minigame := minigame_atual.get_viewport().get_camera_2d()

	if camera_minigame != null:
		await chacoalhar_camera(camera_minigame, 0.1, 8.0)

	# captura o minigame enquanto ele ainda esta visivel
	var textura_minigame := await capturar_tela()

	material_transicao.set_shader_parameter(
		"current_tex",
		textura_minigame
	)

	# usa a imagem salva do tutorial
	material_transicao.set_shader_parameter(
		"background_tex",
		textura_tutorial_retorno
	)

	material_transicao.set_shader_parameter(
		"fall_progress",
		0.0
	)

	material_transicao.set_shader_parameter(
		"final_blend",
		0.0
	)

	# coloca o shader na frente antes de esconder o minigame
	shader_glass.visible = true
	shader_glass.modulate.a = 1.0
	shader_glass.scale = Vector2.ONE

	await RenderingServer.frame_post_draw

	# agora podemos esconder o minigame sem expor o tutorial
	subviewport_container.visible = false

	material_transicao.set_shader_parameter(
		"fall_progress",
		0.01
	)

	await get_tree().create_timer(pausa_inicio).timeout

	var duracao_queda = max(
		0.01,
		duracao_entrada - pausa_inicio
	)

	var tween_queda := create_tween()

	tween_queda.tween_method(
		mudar_progresso,
		0.01,
		1.0,
		duracao_queda
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween_queda.finished

	var tween_blend := create_tween()

	tween_blend.tween_method(
		mudar_blend_final,
		0.0,
		1.0,
		duracao_blend_final
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween_blend.finished

	# agora a transicao ja terminou
	# o tutorial esta sendo mostrado pelo shader
	if is_instance_valid(minigame_atual):
		minigame_atual.queue_free()

	minigame_atual = null

	shader_glass.visible = false
	shader_glass.modulate.a = 0.0
	shader_glass.scale = Vector2.ONE

	subviewport_container.visible = false

	material_transicao.set_shader_parameter(
		"fall_progress",
		0.0
	)

	material_transicao.set_shader_parameter(
		"final_blend",
		0.0
	)

	textura_tutorial_retorno = null

	minigame_aberto = false
	em_transicao = false
	minigame_fechado.emit()


func mudar_progresso(valor: float) -> void:
	material_transicao.set_shader_parameter(
		"fall_progress",
		valor
	)


func mudar_blend_final(valor: float) -> void:
	material_transicao.set_shader_parameter(
		"final_blend",
		valor
	)
