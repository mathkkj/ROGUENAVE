extends Node

@export var arma_atual = -1

@export var personagem : CharacterBody2D

var usando_controle = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		usando_controle = false
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.2: #deadzone
			usando_controle = true
	elif event is InputEventJoypadButton:
		usando_controle = true





var ja_vi := false
@onready var fullstack = get_node("NPC Fullstack")
func quando_ver_o_npc_fullstack_tutorial_comecar_tutorial() -> void:
	if ja_vi:
		return

	ja_vi = true

	personagem.lock_movimentacao()

	
	get_viewport().get_camera_2d().lock_camera()
	await get_viewport().get_camera_2d().transitar_personagem(get_node("NPC Fullstack"), 2)
	fullstack.iniciar_dialogo()
	await fullstack.dialogo_finalizado

	await get_viewport().get_camera_2d().transitar_personagem(get_node("personagem"), 1.5)

	get_viewport().get_camera_2d().unlock_camera()
	personagem.unlock_movimentacao()
