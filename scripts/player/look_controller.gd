class_name LookController
extends Node3D

signal mouse_capture_changed(is_captured: bool)

@export var mouse_sensitivity: float = 0.0025
@export_range(30.0, 89.0, 1.0) var pitch_limit_degrees: float = 85.0

@onready var yaw_target: Node3D = get_parent()


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.TOGGLE_MOUSE):
		_set_mouse_captured(false)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_set_mouse_captured(true)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw_target.rotate_y(-event.relative.x * mouse_sensitivity)
		rotation.x = clamp(
			rotation.x - event.relative.y * mouse_sensitivity,
			deg_to_rad(-pitch_limit_degrees),
			deg_to_rad(pitch_limit_degrees)
		)
		get_viewport().set_input_as_handled()


func _set_mouse_captured(is_captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if is_captured else Input.MOUSE_MODE_VISIBLE
	mouse_capture_changed.emit(is_captured)
