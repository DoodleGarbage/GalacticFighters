extends PanelContainer

var loaded_deck : Deck

var player : String :
	set(value):
		$HH/V/Name.text = value

func load_deck(d:Deck) -> void:
	if d.special_characters.size() < 3:
		printerr("Tried to load deck but deck %s but it doesn't have 3 special characters!" % d.name)
	$HH/V/H/S1.texture = d.special_characters[0].mini_profile
	$HH/V/H/S2.texture = d.special_characters[1].mini_profile
	$HH/V/H/S3.texture = d.special_characters[2].mini_profile
