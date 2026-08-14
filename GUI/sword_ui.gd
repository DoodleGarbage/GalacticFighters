extends Item_GUI

var loaded_sword : Item :
	set(value):
		loaded_sword = value
		get_node("SwordUI").icon = loaded_sword.icon
		get_node("SwordUI").tooltip_text = loaded_sword.desc
