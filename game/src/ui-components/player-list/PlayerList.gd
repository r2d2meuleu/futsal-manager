extends Control

signal select_player

const PlayerProfile = preload("res://src/ui-components/player-profile/PlayerProfile.tscn")

func add_players(players):
	for player in players:
		var player_profile = PlayerProfile.instance()
		player_profile.connect("player_select",self,"select_player",[player])
		$Container/ItemList.add_child(player_profile)
		player_profile.set_up_info(player)
		
		
func select_player(player):
	print("change in lst")
	emit_signal("select_player",[player])
		
