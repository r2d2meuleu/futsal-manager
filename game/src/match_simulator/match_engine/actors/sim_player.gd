# SPDX-FileCopyrightText: 2023 Simon Dalvai <info@simondalvai.org>

# SPDX-License-Identifier: AGPL-3.0-or-later

class_name SimPlayer

signal interception
signal short_pass
signal shoot
signal dribble
signal pass_received

enum State {
	IDLE,
	# attack
	DRIBBLE,
	PASSING,
	RECEIVE_PASS,
	SHOOTING,
	POSITIONING,
	# DEFENSE
	MARKING,
}


var state: State

# resources
var player_res: Player
var ball: SimBall
var field: SimField
# positions
var start_pos: Vector2
var pos: Vector2
# movements
var destination: Vector2
var speed: int
#TODO reduce radius with low stamina
var interception_radius: int 

# distances, calculated by action util
var distance_to_goal: float
var distance_to_own_goal: float
var distance_to_ball: float
var distance_to_enemy: float


func set_up(
	p_player_res: Player,
	p_ball: SimBall,
) -> void:
	player_res = p_player_res
	ball = p_ball

	# initial test values
	interception_radius = 40


func update() -> void:
	match state:
		State.RECEIVE_PASS:
			if is_touching_ball():
				pass_received.emit()
				ball.stop()
				state = State.IDLE
		State.DRIBBLE:
			ball.dribble(destination, speed)
			state = State.IDLE
		State.PASSING:
			short_pass.emit()
			state = State.IDLE
		State.SHOOTING:
			shoot.emit()
			state = State.IDLE
		State.IDLE:
			if is_touching_ball():
				if _should_dribble():
					state = State.DRIBBLE
				elif _should_pass():
					state = State.PASSING
				elif _should_shoot():
					state = State.SHOOTING
	
	_move()


func kick_off(p_pos: Vector2) -> void:
	start_pos = p_pos
	set_pos()


func _move() -> void:
	if state == State.RECEIVE_PASS:
		return
	
	if speed > 0:
		pos = pos.move_toward(destination, speed * Const.SPEED)


func is_touching_ball() -> bool:
	return ball.is_touching(pos, interception_radius)


func is_intercepting_ball() -> bool:
	return (
		Config.match_rng.randi_range(1, 100) < 59 + player_res.attributes.technical.interception * 2
	)


func set_pos(p_pos: Vector2 = pos) -> void:
	pos = p_pos
	destination = pos
	# reset values
	speed = 0


func set_destination(p_destination: Vector2) -> void:
	destination = bound_field(p_destination)
	speed = 20


func stop() -> void:
	speed = 0


func _should_dribble() -> bool:
	# check something, but for now, nothing comes to my mind
	return Config.match_rng.randi_range(1, 100) > 30


func _should_shoot() -> bool:
	if ball.empty_net:
		return true
	if ball.players_in_shoot_trajectory < 2:
		return Config.match_rng.randi_range(1, 100) > 95
	return false


func _should_pass() -> bool:
	if distance_to_enemy < 50:
		return Config.match_rng.randi_range(1, 100) < 60
	return false


func bound_field(p_pos: Vector2) -> Vector2:
	p_pos.x = maxi(mini(p_pos.x, 1200), 1)
	p_pos.y = maxi(mini(p_pos.y, 600), 1)
	return p_pos
