# SPDX-FileCopyrightText: 2023 Simon Dalvai <info@simondalvai.org>

# SPDX-License-Identifier: AGPL-3.0-or-later

class_name PlayerList
extends VBoxContainer


signal select_player(player: Player)

const PAGE_SIZE:int = 20

@onready var player_rows: VBoxContainer = $PlayerRows

# select filters
@onready var team_select: OptionButton = $Filters/TeamSelect
@onready var league_select: OptionButton = $Filters/LeagueSelect
@onready var pos_select: OptionButton = $Filters/PositionSelect

var active_filters: Dictionary = {}
var active_info_type: int = 0
var team_search: String = ""

var all_players: Array[Player] = []
var visible_players: Array[Player] = []


func _ready() -> void:
	set_up_players()

	team_select.add_item("NO_TEAM")
	for league: League in Config.leagues.list:
		for team: Team in league.teams:
			if team == null or team.name != Config.team.name:
				team_select.add_item(team.name)

	pos_select.add_item("NO_POS")
	for pos: String in Player.Position.keys():
		pos_select.add_item(pos)

	league_select.add_item("ALL_LEAGUES")
	for league: League in Config.leagues.list:
		league_select.add_item(league.name)
	
	var index: int = 0
	for player_row: PlayerListRow in player_rows.get_children() as Array[PlayerListRow]:
		player_row.set_player(visible_players[index])
		index += 1


func set_up_players(p_reset_options: bool = true) -> void:
	if p_reset_options:
		_reset_options()

	all_players = []
	for league: League in Config.leagues.list:
		for team in league.teams:
			for player in team.players:
				all_players.append(player)
	
	visible_players = all_players.slice(0, PAGE_SIZE)
	

func remove_player(player_id: int) -> void:
	active_filters["id"] = player_id
	_filter_table()


func _on_NameSearch_text_changed(text: String) -> void:
	if text.length() > 2:
		active_filters["surname"] = text
		_filter_table()
	elif "surname" in active_filters and (active_filters["surname"] as String).length() > 0:
		active_filters["surname"] = ""
		_filter_table()


func _on_TeamSelect_item_selected(index: int) -> void:
	if index > 0:
		active_filters["team"] = team_select.get_item_text(index)
	else:
		active_filters["team"] = ""
	_filter_table()


func _on_league_select_item_selected(index: int) -> void:
	if index > 0:
		active_filters["league"] = league_select.get_item_text(index)
	else:
		active_filters["league"] = ""

	# clean team selector
	team_select.clear()
	team_select.add_item("NO_TEAM")

	# adjust team picker according to selected league
	for league: League in Config.leagues.list:
		if active_filters["league"] == "" or active_filters["league"] == league.name:
			for team: Team in league.teams:
				if team == null or team.name != Config.team.name:
					team_select.add_item(team.name)

	_filter_table()


func _on_PositionSelect_item_selected(index: int) -> void:
	if index > 0:
		active_filters["position"] = Player.Position.values()[index - 1]
	else:
		active_filters["position"] = ""

	_filter_table()


func _filter_table() -> void:
	pass


func _reset_options() -> void:
	league_select.selected = 0
	pos_select.selected = 0
	team_select.selected = 0
	active_info_type = 0


func _on_player_profile_select(player: Player) -> void:
	select_player.emit(player)


