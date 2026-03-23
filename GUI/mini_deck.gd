extends PanelContainer

var loaded_deck : Deck

func load_deck(d:Deck) -> void:
	if d.special_characters.size() < 3:
		printerr("Tried to load deck but deck %s but it doesn't have 3 special characters!" % d.name)
	$VBoxContainer/HBoxContainer/S1.texture = d.special_characters[0].mini_profile
	$VBoxContainer/HBoxContainer/S2.texture = d.special_characters[1].mini_profile
	$VBoxContainer/HBoxContainer/S3.texture = d.special_characters[2].mini_profile
	$VBoxContainer/Name.text = d.name
