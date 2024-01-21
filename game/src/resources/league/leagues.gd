# SPDX-FileCopyrightText: 2023 Simon Dalvai <info@simondalvai.org>

# SPDX-License-Identifier: AGPL-3.0-or-later

class_name Leagues
extends Resource

@export var list:Array[League]
@export var active:RID

func _init(
		p_list:Array[League] = [],
	) -> void:
	list = p_list

func add_league(league:League) -> void:
	list.append(league)
	
func get_active() -> League:
	return get_league_by_rid(active)
	
func get_league_by_rid(rid:RID) -> League:
	for league:League in list:
		if league.get_rid() == rid:
			return league
	return null
	
func get_team_by_name(p_name:String) -> Team:
	for league:League in list:
		var found_team:Team = league.get_team_by_name(p_name)
		if found_team:
			return found_team
	print("ERROR: team not found with name: " + p_name)
	return null
	

