# SPDX-FileCopyrightText: 2023 Simon Dalvai <info@simondalvai.org>

# SPDX-License-Identifier: AGPL-3.0-or-later

class_name SaveStates
extends Resource

@export var list: Array[SaveState]
@export var active_id: String
# for temporary save state, when creating new save state
# becomes active_save_state, once setup is completed
@export var temp_state: SaveState


func _init(
		p_list:Array[SaveState] = [],
		p_active_id:String = "",
	) -> void:
	list = p_list
	active_id = p_active_id


func new_temp_state() -> void:
	var temp_id: String = str(int(Time.get_unix_time_from_system()))
	print("temp_id: ",temp_id)
	temp_state = SaveState.new()
	temp_state.id = temp_id


func reset_temp() -> void:
	temp_state = null


func get_active() -> SaveState:
	# use temp, if exists
	if temp_state:
		return temp_state
	
	for state:SaveState in list:
		if state.id == active_id:
			return state

	return null


func get_active_path(relative_path:String = "") -> String:
	if get_active():
		return "user://" + get_active().id + "/" + relative_path
	return ""


func make_temp_active() -> void:
	# assign values
	temp_state.team_name = Config.team.name
	# make active
	list.append(temp_state)
	active_id = temp_state.id
	
	# create save state directory, if not exist yet
	var user_dir:DirAccess = DirAccess.open("user://")
	if not user_dir.dir_exists(active_id):
		var err:int = user_dir.make_dir(active_id)
		if err != OK:
			print("error while creating save state dir")
