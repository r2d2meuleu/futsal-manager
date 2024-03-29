# SPDX-FileCopyrightText: 2023 Simon Dalvai <info@simondalvai.org>

# SPDX-License-Identifier: AGPL-3.0-or-later

extends Node2D

@onready var field:SimField = $SimField
@onready var ball:SimBall = $SimBall
@onready var home_team:SimTeam = $HomeTeam
@onready var away_team:SimTeam = $AwayTeam


func set_up(p_home_team:Team, p_away_team:Team) -> void:
	field.set_up()
	ball.set_up(field.center)
	# TODO add coin toss
	home_team.has_ball = true
	away_team.has_ball = false
		# set colors
	var home_color:Color = p_home_team.get_home_color()
	var away_color:Color = p_away_team.get_away_color(home_color)
	home_team.set_up(p_home_team, field, ball, true, home_color)
	away_team.set_up(p_away_team, field, ball, false, away_color)
	
	ball.kick(home_team.players[3].pos, 10, SimBall.State.PASS)
	

func update() -> void:
	ball.update()
	home_team.update()
	away_team.update()
