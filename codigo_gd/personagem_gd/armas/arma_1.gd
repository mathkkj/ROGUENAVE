class_name ArmasRanged
extends Node2D


@onready var bala_cena = preload("res://cenas_tscn/armas/bala.tscn")
@onready var sair_bala = get_node("sair_bala")
@onready var sprite = get_node("Sprite2D")
@onready var texto = get_node("Label")



var calor = 0.0
var calor_maximo = 100.0
var calor_por_tiro = 20.0
var resfriamento = 50.0

@onready var camera = get_viewport().get_camera_2d()

var atirando: bool
var superaquecida = false
var pode_atirar = true


@export var recoil_offset: Vector2 = Vector2(-8, 0)
@export var recoil_ida: float = 0.04
@export var recoil_volta: float = 0.08

var pos_sprite_original: Vector2
var tween_recoil: Tween

func _ready() -> void:
	
	pos_sprite_original = sprite.position
	
func _physics_process(delta: float) -> void:
	texto.text = str(calor)

	if calor >= 0:
		calor -= resfriamento * delta

	var cor_normal = remap(calor, 0, 100, 255, 0)
	self.modulate = Color.from_rgba8(255, cor_normal, cor_normal, 255)

	if superaquecida and calor <= 0:
		calor = 0
		superaquecida = false

func aplicar_recoil() -> void:
	if tween_recoil:
		tween_recoil.kill()

	tween_recoil = create_tween()
	tween_recoil.tween_property(sprite, "position", pos_sprite_original + recoil_offset, recoil_ida)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	tween_recoil.tween_property(sprite, "position", pos_sprite_original, recoil_volta)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

func atirar():
	if not superaquecida and calor < calor_maximo:
		pode_atirar = true
	else:
		pode_atirar = false
		

	if pode_atirar:
		calor += calor_por_tiro

		if calor >= calor_maximo:
			superaquecida = true
			camera.add_trauma(0.3, Vector2(1,1))
			

		aplicar_recoil()

		var bala = bala_cena.instantiate()
		bala.global_position = sair_bala.global_position
		bala.rotation = sair_bala.global_rotation
		bala.acertou.connect(get_parent()._on_bala_acertou)
		

		get_tree().current_scene.add_child(bala)
