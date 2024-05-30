# SPDX-FileCopyrightText: 2023 Simon Dalvai <info@simondalvai.org>

# SPDX-License-Identifier: AGPL-3.0-or-later

class_name PlayerList
extends VBoxContainer

signal select_player(player: Player)

@onready var filter_container: HBoxContainer = $Filters
@onready var player_rows: VBoxContainer = $PlayerRows
@onready var team_select: OptionButton = $Filters/TeamSelect
@onready var league_select: OptionButton = $Filters/LeagueSelect
@onready var pos_select: OptionButton = $Filters/PositionSelect
@onready var footer: HBoxContainer = $Footer
@onready var page_indicator: Label = $Footer/PageIndicator

var active_team_id: int

var filters: Dictionary = {}
var active_info_type: int = 0
var team_search: String = ""

var all_players: Array[Player] = []
var players: Array[Player] = []
var visible_players: Array[Player] = []

var page:int
var page_max:int
var page_size:int


func _ready() -> void:
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
	
	# setup automatically, if run in editor and is run by 'Run current scene'
	if OS.has_feature("editor") and get_parent() == get_tree().root:
		set_up()

func set_up(p_active_team_id:int = -1) -> void:
	active_team_id = p_active_team_id
	
	if active_team_id != -1:
		filter_container.hide()
	
	_set_up_players()
	
	page_size = player_rows.get_child_count()
	page_max = players.size() / page_size

	_set_player_rows()
	_update_page_indicator()
	

func _set_player_rows() -> void:
	visible_players = players.slice(page * page_size, (page + 1) * page_size)
	
	var index: int = 0
	for player_row: PlayerListRow in player_rows.get_children() as Array[PlayerListRow]:
		if index < visible_players.size():
			player_row.visible = true
			player_row.set_player(visible_players[index])
		else:
			player_row.visible = false
		index += 1


func _set_up_players(p_reset_options: bool = true) -> void:
	if p_reset_options:
		_reset_options()

	all_players = []
	
	# uncomment to stresstest
	#for i in range(100):
	for league: League in Config.leagues.list:
		for team in league.teams:
			if active_team_id == -1 or active_team_id == team.id:
				for player in team.players:
					all_players.append(player)
	
	players = all_players


func _reset_options() -> void:
	league_select.selected = 0
	pos_select.selected = 0
	team_select.selected = 0
	active_info_type = 0


func _on_player_profile_select(player: Player) -> void:
	select_player.emit(player)


func _on_next_2_pressed() -> void:
	page += 5
	if page > page_max:
		page = page_max
	_update_page_indicator()
	_set_player_rows()


func _on_next_pressed() -> void:
	page += 1
	if page > page_max:
		page = 0
	_update_page_indicator()
	_set_player_rows()


func _on_prev_pressed() -> void:
	page -= 1
	if page < 0:
		page = page_max
	_update_page_indicator()
	_set_player_rows()


func _on_prev_2_pressed() -> void:
	page -= 5
	if page < 0:
		page = 0
	_update_page_indicator()
	_set_player_rows()


func _update_page_indicator() -> void:
	page_max = players.size() / page_size
	page_indicator.text = "%d / %d" % [page + 1, page_max + 1]


func _filter() -> void:
	_filter_players(players)


func _unfilter() -> void:
	_filter_players(all_players)


func _filter_players(player_base: Array[Player]) -> void:
	page = 0
	
	if filters.size() > 0:
		var filtered_players: Array[Player] = []
		var filter_counter: int = 0
		var value: String
		var key: String
		
		for player in player_base:
			filter_counter = 0
			for i:int in filters.keys().size():
				key = filters.keys()[i]
				filter_counter += 1
				value = filters[key] as String
				value = value.to_upper()
				if not (player[key] as String).to_upper().contains(value):
					filter_counter += 1
			if filter_counter == filters.size():
				filtered_players.append(player)
		players = filtered_players
	else:
		players = all_players

	_set_player_rows()
	_update_page_indicator()


func _on_name_search_text_changed(new_text: String) -> void:
	if new_text.length() > 0:
		if not "surname" in filters:
			filters["surname"] = new_text
			_filter()
		elif new_text.length() > (filters["surname"] as String).length():
			filters["surname"] = new_text
			_filter()
		else:
			filters["surname"] = new_text
			_unfilter()
	else:
		filters.erase("surname")
		_unfilter()


func _on_position_select_item_selected(index: int) -> void:
	if index > 0:
		filters["position"] = Player.Position.values()[index - 1]
		_filter()
	else:
		filters["position"] = ""
		_unfilter()


func _on_league_select_item_selected(index: int) -> void:
	if index > 0:
		filters["league"] = league_select.get_item_text(index)
		_filter()
	else:
		filters.erase("league")
		_unfilter()

	# clean team selector
	team_select.clear()
	team_select.add_item("NO_TEAM")

	# adjust team picker according to selected league
	for league: League in Config.leagues.list:
		if not "league" in filters or filters["league"] == league.name:
			for team: Team in league.teams:
				if team == null or team.name != Config.team.name:
					team_select.add_item(team.name)


func _on_team_select_item_selected(index: int) -> void:
	if index > 0:
		filters["team"] = team_select.get_item_text(index)
		_filter()
	else:
		filters["team"] = ""
		_unfilter()
