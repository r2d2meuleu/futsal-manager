# SPDX-FileCopyrightText: 2023 Simon Dalvai <info@simondalvai.org>

# SPDX-License-Identifier: AGPL-3.0-or-later

class_name PlayerList
extends VBoxContainer

signal select_player(player: Player)

enum Views {
	GENERAL,
	CONTRACT,
	STATS,
	PHYSICAL,
	TECHNICAL,
	MENTAL,
	GOALKEEPER,
}

const PlayerListColumnScene: PackedScene = preload(Const.SCENE_PLAYER_LIST_COLUMN)

# depending on scale
const PAGE_SIZE_1: int = 36
const PAGE_SIZE_2: int = 22
const PAGE_SIZE_3: int = 12

var active_view: Views
var columns: Array[PlayerListColumn]

var active_team_id: int

var sorting: Dictionary = {}
var filters: Dictionary = {}

var all_players: Array[Player] = []
var players: Array[Player] = []
var visible_players: Array[Player] = []

var page: int
var page_max: int
var page_size: int

@onready var search_line_edit: SearchLineEdit = $Filters1/NameSearch
@onready var active_view_option_button: SwitchOptionButton = $Filters1/ActiveView
@onready var team_select: OptionButton = $Filters2/TeamSelect
@onready var league_select: OptionButton = $Filters2/LeagueSelect
@onready var pos_select: OptionButton = $Filters2/PositionSelect
@onready var footer: HBoxContainer = $Footer
@onready var page_indicator: Label = $Footer/PageIndicator
@onready var last: Button = $Footer/Last
@onready var columns_container: HBoxContainer = %Columns


func _ready() -> void:
	Tests.setup_mock_world()

	columns = []

	# filter and view buttons
	team_select.add_item("All Teams")
	for league: League in Global.world.get_all_leagues():
		for team: Team in league.teams:
			if team == null or Global.team == null or team.name != Global.team.name:
				team_select.add_item(team.name)

	pos_select.add_item("All positions")
	for pos: String in Position.Type.keys():
		pos_select.add_item(pos)

	league_select.add_item("All Leagues")
	for league: League in Global.world.get_all_leagues():
		league_select.add_item(league.name)

	active_view_option_button.setup(Views.keys())
	active_view = Views.GENERAL
	
	# page size scale
	match Global.config.theme_scale:
		Const.SCALE_1:
			page_size = PAGE_SIZE_1
		Const.SCALE_2:
			page_size = PAGE_SIZE_2
		Const.SCALE_3:
			page_size = PAGE_SIZE_3
	
	# setup automatically, if run in editor and is run by 'Run current scene'
	if Tests.is_run_as_current_scene(self):
		setup()


func setup(p_active_team_id: int = -1) -> void:
	active_team_id = p_active_team_id

	if active_team_id != -1:
		team_select.hide()
		league_select.hide()

	_setup_players()
	_update_columns()
	_update_page_indicator()
	_show_active_column()


func update_team(p_active_team_id: int) -> void:
	active_team_id = p_active_team_id
	_setup_players()
	_update_columns()
	_update_page_indicator()
	_show_active_column()


func _update_columns() -> void:
	visible_players = players.slice(page * page_size, (page + 1) * page_size)
	for column: PlayerListColumn in columns:
		column.update_values(visible_players)


func _add_column(col_name: String, map_function: Callable) -> PlayerListColumn:
	var column: PlayerListColumn = PlayerListColumnScene.instantiate()
	columns.append(column)
	columns_container.add_child(column)
	column.setup(col_name, visible_players, map_function)
	column.sort.connect(_sort_players.bind(col_name, map_function))
	return column


func _show_active_column() -> void:
	for column: PlayerListColumn in columns:
		column.queue_free()
	columns.clear()

	for column: Node in columns_container.get_children():
		column.queue_free()
	
	# always add names
	var names: Callable = func(p: Player) -> String: return p.surname
	var name_column: PlayerListColumn = _add_column(Const.SURNAME, names)
	# set minimum size to name column
	name_column.custom_minimum_size.x = 200
	# connect name button pressed signal
	for i: int in visible_players.size():
		name_column.buttons[i].pressed.connect(func() -> void: select_player.emit(visible_players[i]))

	# separator
	columns_container.add_child(VSeparator.new())
	
	match active_view:
		Views.MENTAL:
			_show_attributes("mental")
		Views.PHYSICAL:
			_show_attributes("physical")
		Views.TECHNICAL:
			_show_attributes("technical")
		Views.GOALKEEPER:
			_show_attributes("goalkeeper")
		Views.CONTRACT:
			_show_contract()
		Views.STATS:
			_show_statistics()
		_:
			_show_general()


func _setup_players(p_reset_options: bool = true) -> void:
	if p_reset_options:
		_reset_options()

	all_players = []

	# uncomment to stresstest
	#for i in range(10):
	if active_team_id == -1:
		all_players.append_array(Global.world.get_all_players())
	else:
		for player: Player in Global.world.get_team_by_id(active_team_id).players:
			all_players.append(player)

	players = all_players


func _reset_options() -> void:
	league_select.selected = 0
	pos_select.selected = 0
	team_select.selected = 0


func _on_player_profile_select(player: Player) -> void:
	select_player.emit(player)


func _on_next_2_pressed() -> void:
	page += 5
	if page > page_max:
		page = page_max
	_update_page_indicator()
	_update_columns()


func _on_next_pressed() -> void:
	page += 1
	if page > page_max:
		page = 0
	_update_page_indicator()
	_update_columns()


func _on_prev_pressed() -> void:
	page -= 1
	if page < 0:
		page = page_max
	_update_page_indicator()
	_update_columns()


func _on_prev_2_pressed() -> void:
	page -= 5
	if page < 0:
		page = 0
	_update_page_indicator()
	_update_columns()


func _on_last_pressed() -> void:
	page = page_max
	_update_page_indicator()
	_update_columns()


func _on_first_pressed() -> void:
	page = 0
	_update_page_indicator()
	_update_columns()


func _update_page_indicator() -> void:
	page_max = players.size() / page_size
	page_indicator.text = "%d / %d" % [page + 1, page_max + 1]
	last.text = str(page_max + 1)


func _sort_players(value: String, map_function: Callable) -> void:
	var sort_key: String = value
	if sort_key in sorting:
		sorting[sort_key] = not sorting[sort_key]
	else:
		sorting[sort_key] = true

	if "date" in value.to_lower():
		# dates
		all_players.sort_custom(
			func(a:Player, b:Player) -> bool:
				var a_unix: int = Time.get_unix_time_from_datetime_dict(map_function.call(a))
				var b_unix: int = Time.get_unix_time_from_datetime_dict(map_function.call(b))
				if sorting[sort_key]:
					return a_unix > b_unix
				else:
					return a_unix < b_unix
		)
	else:
		# normal props
		all_players.sort_custom(
			func(a:Player, b:Player) -> bool:
				if sorting[sort_key]:
					return map_function.call(a) > map_function.call(b)
				else:
					return map_function.call(a) < map_function.call(b)
		)

	# after sorting, apply filters
	# so if filters a removed, sort order is kept
	_filter()


func _filter() -> void:
	page = 0

	if filters.size() > 0:
		var filtered_players: Array[Player] = []
		var filter_counter: int = 0
		var value: String
		var key: String

		for player: Player in all_players:
			filter_counter = 0
			for i: int in filters.keys().size():
				key = filters.keys()[i]
				filter_counter += 1
				value = str(filters[key])
				value = value.to_upper()

				if key == Const.POSITION:
					if not str(player.position.type) == value:
						filter_counter += 1
				elif not str(player[key.to_lower()]).to_lower().contains(value.to_lower()):
					filter_counter += 1

			if filter_counter == filters.size():
				filtered_players.append(player)
		players = filtered_players
	else:
		players = all_players

	_update_columns()
	_update_page_indicator()


func _on_name_search_text_changed(new_text: String) -> void:
	if new_text.length() > 0:
		if not Const.SURNAME in filters:
			filters[Const.SURNAME] = new_text
		elif new_text.length() > (filters[Const.SURNAME] as String).length():
			filters[Const.SURNAME] = new_text
		else:
			filters[Const.SURNAME] = new_text
	else:
		filters.erase(Const.SURNAME)
	_filter()


func _on_position_select_item_selected(index: int) -> void:
	if index > 0:
		filters[Const.POSITION] = Position.Type.values()[index - 1]
	else:
		filters.erase(Const.POSITION)
	_filter()


func _on_league_select_item_selected(index: int) -> void:
	if index > 0:
		filters["league"] = league_select.get_item_text(index)
	else:
		filters.erase("league")

	# clean team selector
	filters.erase("team")
	team_select.clear()
	team_select.add_item("All Teams")

	# adjust team picker according to selected league
	for league: League in Global.world.get_all_leagues():
		if not "league" in filters or filters["league"] == league.name:
			for team: Team in league.teams:
				if team == null or team.name != Global.team.name:
					team_select.add_item(team.name)
	
	_filter()


func _on_team_select_item_selected(index: int) -> void:
	if index > 0:
		filters["team"] = team_select.get_item_text(index)
	else:
		filters.erase("team")
	_filter()


func _on_active_view_item_selected(index: int) -> void:
	active_view = index as Views
	_show_active_column()


func _show_general() -> void:
	var positions: Callable = func(p: Player) -> String: return Position.Type.keys()[p.position.type]
	_add_column(Const.POSITION, positions)
	var values: Callable = func(p: Player) -> String: return FormatUtil.currency(p.value)
	_add_column("VALUE", values)
	var presitge_stars: Callable = func(p: Player) -> String: return p.get_prestige_stars()
	_add_column("PRESTIGE", presitge_stars)
	var moralities: Callable = func(p: Player) -> String: return Enum.get_morality_text(p)
	_add_column("MORALITY", moralities)
	var birth_dates: Callable = func(p: Player) -> Dictionary: return p.birth_date
	_add_column("BIRTH_DATE", birth_dates)
	var nationalities: Callable = func(p: Player) -> String: return p.nation
	_add_column("NATION", nationalities)
	var team_names: Callable = func(p: Player) -> String: return p.team
	_add_column("TEAM", team_names)


func _show_contract() -> void:
	for c: Dictionary in Contract.new().get_property_list():
		if c.usage == Const.CUSTOM_PROPERTY_EXPORT:
			var stats: Callable = func(p: Player) -> Variant:
				var value: Variant = p.contract.get(c.name)
				# for dates
				if typeof(value) == Variant.Type.TYPE_DICTIONARY:
					return value
				# for income
				if "income" in c.name:
					return FormatUtil.currency(value)
				return str(value)
			_add_column(c.name, stats)


func _show_statistics() -> void:
	for s: Dictionary in Statistics.new().get_property_list():
		if s.usage == Const.CUSTOM_PROPERTY_EXPORT:
			var stats: Callable = func(p: Player) -> String: return str(p.statistics.get(s.name))
			_add_column(s.name, stats)


func _show_attributes(p_key: String) -> void:
	var attribute_names: Dictionary = Attributes.new().get_all_attributes()
	for key: String in attribute_names.keys():
		if key == p_key:
			for value: String in attribute_names[key]:
				var value_path: Array[String] = ["attributes", key, value]
				var attributes: Callable = func(p: Player) -> int: return p.get_res_value(value_path)
				_add_column(value, attributes)
			return


