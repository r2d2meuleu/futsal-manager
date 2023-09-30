# SPDX-FileCopyrightText: 2023 Simon Dalvai <info@simondalvai.org>

# SPDX-License-Identifier: AGPL-3.0-or-later

class_name League
extends Resource

@export var country:String
@export var id:int = 0
@export var name:String
@export var teams:Array[Team]

func add_team(team:Team) -> void:
	teams.append(team)
