class_name Player
extends CharacterBody2D


const GUY_FPS := 50.0
const RUN_SPEED := 3.0 * GUY_FPS
const GROUND_JUMP_SPEED := 8.5 * GUY_FPS
const AIR_JUMP_SPEED := 7.0 * GUY_FPS
const GRAVITY := 0.4 * GUY_FPS * GUY_FPS
const MAX_FALL_SPEED := 9.0 * GUY_FPS
const WATER_FALL_SPEED := 2.0 * GUY_FPS


## The direction the player is facing. 1 is right, -1 is left.
var facing := 1:
	set(value):
		_set_facing(value)
		facing = value
var max_air_jumps := 1
var air_jumps := max_air_jumps


var _sprite_x_offset: float
var _bullet_scene := preload("res://scenes/player/bullet.tscn")


@onready var solid_collision_shape := $CollisionShape2D
@onready var player_area := $PlayerArea
@onready var player_area_shape := $PlayerArea/CollisionShape2D
@onready var player_sprite := $PlayerSprite
@onready var ground_jump_sound := $AudioPlayers/GroundJump
@onready var air_jump_sound := $AudioPlayers/AirJump
@onready var shoot_sound := $AudioPlayers/Shoot


func _ready() -> void:
	_copy_collision_shape()
	_sprite_x_offset = player_sprite.offset.x


func _physics_process(delta: float):
	var h_input := _get_horizontal_input()
	if h_input != 0:
		facing = h_input
	velocity.x = h_input * RUN_SPEED
	
	if is_on_floor():
		refresh_jumps()
	
	if Input.is_action_just_pressed("jump"):
		try_jump()
	if Input.is_action_just_released("jump"):
		release_jump()
	if Input.is_action_just_pressed("shoot"):
		try_shoot()
	
	_check_for_refreshing_water()
	_clamp_vertical_speed()
	_apply_gravity(delta)
	
	move_and_slide()
	_animate_sprite(h_input)


## Attempts to do the appropriate jump depending on depending on whether the
## player is on the ground or has air jumps available.
func try_jump() -> void:
	if is_on_floor() or _is_overlapping_body(&"platforms"):
		do_ground_jump()
	elif air_jumps > 0 or _is_overlapping_area(&"water"):
		do_air_jump()


## Makes the player do a ground jump - even if they are currently in the air.
func do_ground_jump(dont_refresh := false) -> void:
	if not dont_refresh:
		air_jumps = max_air_jumps
	
	velocity.y = -GROUND_JUMP_SPEED
	ground_jump_sound.play()


## Makes the player do an air jump - even if they are currently on the ground.
func do_air_jump() -> void:
	velocity.y = -AIR_JUMP_SPEED
	air_jumps -= 1
	air_jump_sound.play()


func release_jump() -> void:
	if velocity.y < 0:
		velocity.y *= 0.45


## Refreshes the provided number of air jumps, without going over the maximum.
## By default refreshes all jumps.
func refresh_jumps(count := max_air_jumps) -> void:
	air_jumps += count
	air_jumps = min(air_jumps, max_air_jumps)


## Tries to shoot, checking if too many bullets don't already exist.
func try_shoot():
	if get_tree().get_nodes_in_group("player_bullets").size() < 4:
		shoot()


## Fires the gun, without checking the amount of already existsing bullets first.
func shoot():
	var bullet := _bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = Vector2.RIGHT if (facing == 1) else Vector2.LEFT
	get_parent().add_child(bullet)
	
	shoot_sound.play()


func _get_horizontal_input() -> int:
	if Input.is_action_pressed("run_right"):
		return 1
	elif Input.is_action_pressed("run_left"):
		return -1
	return 0


func _apply_gravity(delta: float) -> void:
	velocity.y += delta * GRAVITY


func _clamp_vertical_speed() -> void:
	var max_fall_speed = MAX_FALL_SPEED
	
	if _is_overlapping_area(&"water"):
		max_fall_speed = WATER_FALL_SPEED
	
	velocity.y = min(velocity.y, max_fall_speed)


func _check_for_refreshing_water() -> void:
	for water in _get_overlapping_areas(&"water"):
		if water.refreshing == 1:
			refresh_jumps()


# Plays the appropriate animation.
func _animate_sprite(h_input: float) -> void:
	var animation: String
	if is_on_floor():
		animation = "idle" if h_input == 0 else "run"
	else:
		animation = "jump" if velocity.y < 0 else "fall"
	player_sprite.play(animation)


func _set_facing(direction: int) -> void:
	# Ignore invalid values
	if not [-1, 1].has(direction):
		return
	
	# Don't do anything if not flipping
	if direction == facing:
		return
	
	player_sprite.flip_h = (direction == -1)
	player_sprite.offset.x = direction * _sprite_x_offset


# Copies the collision shape from the Player node to other collision related
# nodes.
func _copy_collision_shape() -> void:
	var shape = solid_collision_shape.shape
	player_area_shape.shape = shape


func _is_overlapping_area(group: StringName) -> bool:
	for area in player_area.get_overlapping_areas():
		if area.is_in_group(group):
			return true
	return false


func _get_overlapping_areas(group: StringName) -> Array:
	var areas := []
	for area in player_area.get_overlapping_areas():
		if area.is_in_group(group):
			areas.push_back(area)
	return areas


func _is_overlapping_body(group: StringName) -> bool:
	for body in player_area.get_overlapping_bodies():
		if body.is_in_group(group):
			return true
	return false
