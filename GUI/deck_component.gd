extends PanelContainer

var full_name : String = ""
var deck_valid_name : String :
	get():
		var prefix : String = ""
		match(type):
			0, 1: prefix = "Character"
			2: prefix = "Gadget"
			3: prefix = "Item"
			4: prefix = "Sword"
		return prefix + ":" + full_name

var type : int :
	set(value):
		type = value
		var txt : String = ""
		match(value):
			0:
				theme = load("res://Themes/card_theme.tres")
				txt = "SPECIAL CHARACTER"
			1:
				theme = load("res://Themes/card_theme.tres")
				txt = "CHARACTER"
			2:
				theme = load("res://Themes/gadget_theme.tres")
				txt = "GADGET"
				
			3:
				theme = load("res://Themes/item_theme.tres")
				txt = "ITEM"
			4:
				theme = load("res://Themes/item_theme.tres")
				txt = "SWORD"
		$VBoxContainer/Type.text = txt

var card_name : String :
	set(value):
		card_name = value
		$VBoxContainer/Name.text = value

var icon : Texture :
	set(value):
		icon = value
		$VBoxContainer/Icon.texture = value
