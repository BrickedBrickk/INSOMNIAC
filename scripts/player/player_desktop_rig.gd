class_name PlayerDesktopRig
extends CharacterBody3D

@export var move_speed: float = 4.0
@export var acceleration: float = 18.0
@export var jump_velocity: float = 4.5

@onready var inventory: Inventory = $Inventory
@onready var wallet: Wallet = $Wallet
@onready var look_controller: LookController = $CameraPivot
@onready var interaction_controller: InteractionController = $CameraPivot/Camera3D/RayCast3D

var player_stats: PlayerStats


func _ready() -> void:
	_ensure_player_stats()
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed(InputActions.JUMP):
		_try_jump()

	var input_vector := Input.get_vector(
		InputActions.MOVE_LEFT,
		InputActions.MOVE_RIGHT,
		InputActions.MOVE_FORWARD,
		InputActions.MOVE_BACK
	)
	var move_direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()

	velocity.x = move_toward(velocity.x, move_direction.x * move_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, move_direction.z * move_speed, acceleration * delta)
	move_and_slide()


func get_inventory() -> Inventory:
	return inventory


func get_wallet() -> Wallet:
	return wallet


func get_player_stats() -> PlayerStats:
	_ensure_player_stats()
	return player_stats


func get_interaction_controller() -> InteractionController:
	return interaction_controller


func get_look_controller() -> LookController:
	return look_controller


func _try_jump() -> void:
	if is_on_floor():
		velocity.y = jump_velocity


func _ensure_player_stats() -> void:
	if player_stats != null:
		return

	player_stats = get_node_or_null("PlayerStats") as PlayerStats
	if player_stats == null:
		player_stats = PlayerStats.new()
		player_stats.name = "PlayerStats"
		add_child(player_stats)
