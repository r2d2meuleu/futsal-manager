# SPDX-FileCopyrightText: 2023 Simon Dalvai <info@simondalvai.org>

# SPDX-License-Identifier: AGPL-3.0-or-later

class_name MatchScreen
extends Control

const MAX_COMMENTS: int = 16

var last_active_view: Control

var home_team: Team
var away_team: Team

var match_started: bool = false

var matchz: Match

var home_stats: MatchStatistics
var away_stats: MatchStatistics

# views
@onready var match_simulator: MatchSimulator = $MatchSimulator
@onready var views: MarginContainer = %Views
@onready var stats: VisualMatchStats = %Stats
@onready var comments: VBoxContainer = %Log
@onready var events: MatchEvents = %Events
@onready var formation: VisualFormation = %Formation

# top bar
@onready var time_label: Label = %Time
@onready var result_label: Label = %Result
@onready var home_color: ColorRect = %HomeColor
@onready var away_color: ColorRect = %AwayColor
@onready var home_name: Label = %HomeNameLabel
@onready var away_name: Label = %AwayNameLabel
@onready var home_fouls: Label = %HomeFouls
@onready var away_fouls: Label = %AwayFouls
@onready var time_bar: ProgressBar = %TimeBar

# bottom bar
@onready var possess_bar: ProgressBar = %PossessBar
@onready var home_possession: Label = %HomePossessionLabel
@onready var away_possession: Label = %AwayPossessionLabel

# buttons
@onready var pause_button: Button = %PauseButton
@onready var faster_button: Button = %FasterButton
@onready var slower_button: Button = %SlowerButton
@onready var match_speed_label: Label = %SpeedFactor
@onready var events_button: Button = %EventsButton
@onready var stats_button: Button = %StatsButton
@onready var formation_button: Button = %FormationButton
@onready var simulate_button: Button = %SimulateButton
@onready var dashboard_button: Button = %DashboardButton

@onready var bottom_bar: VBoxContainer = %BottomBar
@onready var players_bar: PlayersBar = %PlayersBar
@onready var penalties_bar: PenaltiesBar = %PenaltiesBar

var minutes: int
var seconds: int


func _ready() -> void:
	InputUtil.start_focus(self)

	if Global.world:
		matchz = Global.world.calendar.get_next_match()
	elif Tests.is_run_as_current_scene(self):
		matchz = Match.new()
		# games needs to be started at least once with a valid save state
		matchz.home = Tests.create_mock_team()
		matchz.away = Tests.create_mock_team()

		# if running match scene, set Global team to home team
		if not Global.team:
			Global.team = matchz.home

	home_team = matchz.home.duplicate(true)
	away_team = matchz.away.duplicate(true)

	match_simulator.setup(matchz)

	home_name.text = matchz.home.name
	away_name.text = matchz.away.name

	# set up formations with player controlled teams copy	
	if home_team.id == Global.team.id:
		formation.setup(true, home_team)
		players_bar.setup(home_team)
		# connect change players signals to visuals
		match_simulator.engine.home_team.player_changed.connect(
			func() -> void:
				players_bar.update_players()
				formation.set_players()
		)
	else:
		formation.setup(true, away_team)
		players_bar.setup(away_team)
		# connect change players signals to visuals
		match_simulator.engine.away_team.player_changed.connect(
			func() -> void:
				players_bar.update_players()
				formation.set_players()
	)
	
	# set colors
	home_color.color = home_team.get_home_color()
	away_color.color = away_team.get_away_color(home_color.color)

	match_speed_label.text = Enum.get_match_speed_text()

	# to easier access stats
	home_stats = match_simulator.engine.home_team.stats
	away_stats = match_simulator.engine.away_team.stats
	
	last_active_view = stats
	_hide_views()

	# connect match engine signals
	match_simulator.engine.half_time.connect(_on_half_time)
	match_simulator.engine.full_time.connect(_on_full_time)
	match_simulator.engine.match_finish.connect(_on_match_finsh)
	# match_simulator.show_me.connect(_on_match_simulator_show)
	# match_simulator.hide_me.connect(_on_match_simulator_hide)
	match_simulator.engine.home_team.penalties_shot.connect(func() -> void: penalties_bar.update())
	match_simulator.engine.away_team.penalties_shot.connect(func() -> void: penalties_bar.update())

	match_simulator.engine.penalties_start.connect(_on_engine_penalties_start)

	if DebugUtil.penalties_test:
		_on_engine_penalties_start()


func _physics_process(_delta: float) -> void:
	var stats_entry: MatchBufferEntryStats = match_simulator.stats_entry
	if stats_entry:
		stats.update_stats(stats_entry.home_stats, stats_entry.away_stats)

		minutes = int(stats_entry.time) / 60
		seconds = int(stats_entry.time) % 60
		time_label.text = "%02d:%02d" % [minutes, seconds]
		time_bar.value = stats_entry.time

		possess_bar.value = stats_entry.home_stats.possession

		home_possession.text = str(stats_entry.home_stats.possession) + " %"
		away_possession.text = str(stats_entry.away_stats.possession) + " %"
		result_label.text = "%d - %d" % [stats_entry.home_stats.goals, stats_entry.away_stats.goals]
		
		home_fouls.text = "(%d)" % stats_entry.home_stats.fouls
		away_fouls.text = "(%d)" % stats_entry.away_stats.fouls


func _on_match_simulator_show() -> void:
	_hide_views()


func _on_match_simulator_hide() -> void:
	views.show()
	last_active_view.show()


func _on_half_time() -> void:
	_on_pause_button_pressed()


func _on_full_time() -> void:
	_on_pause_button_pressed()


func _on_match_finsh() -> void:
	faster_button.hide()
	slower_button.hide()
	match_speed_label.hide()
	pause_button.hide()
	simulate_button.hide()
	dashboard_button.show()

	#assign result
	matchz.set_result(home_stats.goals, away_stats.goals)


func _on_commentary_button_pressed() -> void:
	_toggle_view(comments)


func _on_stats_button_pressed() -> void:
	_toggle_view(stats)


func _on_events_button_pressed() -> void:
	_toggle_view(events)


func _on_formation_button_pressed() -> void:
	_toggle_view(formation)
	# match_simulator.pause()
	# pause_button.text = tr("Continue")


func _hide_views() -> void:
	views.hide()
	comments.hide()
	stats.hide()
	events.hide()
	formation.hide()


func _toggle_view_buttons() -> void:
	events_button.disabled = not events_button.disabled
	stats_button.disabled = not stats_button.disabled
	formation_button.disabled = not formation_button.disabled


func _toggle_view(view: Control) -> void:
	if match_simulator.is_match_visible() and view.visible:
		view.hide()
		views.hide()
	else:
		_hide_views()
		view.show()
		views.show()
	last_active_view = view


func _on_dashboard_button_pressed() -> void:
	Main.change_scene(Const.SCREEN_DASHBOARD)


func _on_faster_button_pressed() -> void:
	if Global.match_speed < Enum.MatchSpeed.values().size() - 1:
		Global.match_speed = (Global.match_speed + 1) as Enum.MatchSpeed 
	match_speed_label.text = Enum.get_match_speed_text()


func _on_slower_button_pressed() -> void:
	if Global.match_speed > 0:
		Global.match_speed = (Global.match_speed - 1) as Enum.MatchSpeed 
	match_speed_label.text = Enum.get_match_speed_text()


func _on_pause_button_pressed() -> void:
	var paused: bool = match_simulator.pause_toggle()
	if paused:
		pause_button.text = tr("Continue")
	else:
		pause_button.text = tr("Pause")
		_hide_views()
		# show last view, only if not showing match currently
		if not match_simulator.is_match_visible():
			views.show()
			last_active_view.show()


func _on_simulate_button_pressed() -> void:
	match_simulator.simulate()


func _on_match_simulator_action_message(message: String) -> void:
	if comments.get_child_count() > MAX_COMMENTS:
		comments.remove_child(comments.get_child(0))
	var new_line: Label = Label.new()
	new_line.text = time_label.text + " " + message
	comments.add_child(new_line)


func _on_formation_change_request() -> void:
	# players_bar.update_players()
	match_simulator.engine.home_team.change_players_request()
	match_simulator.engine.away_team.change_players_request()


func _on_players_bar_change_request() -> void:
	# formation.set_players()
	match_simulator.engine.home_team.change_players_request()
	match_simulator.engine.away_team.change_players_request()


func _on_engine_penalties_start() -> void:
	formation_button.disabled = true
	slower_button.disabled = true
	faster_button.disabled = true
	bottom_bar.hide()
	penalties_bar.show()
	penalties_bar.setup(match_simulator.engine.home_team, match_simulator.engine.away_team)

