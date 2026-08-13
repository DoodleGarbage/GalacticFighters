extends HBoxContainer

var player_name : String :
	set(value):
		$Backplate/PlayerName.text = value

var icon : Texture :
	set(value):
		$PlayerIcon.texture = value
