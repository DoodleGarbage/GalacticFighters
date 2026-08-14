extends PanelContainer

## Used by the parent Card_GUI to determine *which* attribute is saved on here
#var ability_index : int = -1 # currently binded in the card_gui initialization
var loaded_ability : Attribute

var duration : int :
	set(value):
		if value < 0:
			$Liner/IandD/Duration.hide()
			return
		$Liner/IandD/Duration.show()
		$Liner/IandD/Duration.text = str(value)


func load_ability(ability:Attribute) -> void:
	
	loaded_ability = ability
	
	$Liner/Sizer/NT/Name.text = tr(ability.name)
	
	match(ability.type):
		0:
			$Liner/Sizer/NT/Type.text = tr("PASSIVE")
			$Button.hide()
		1:
			$Liner/Sizer/NT/Type.text = tr("ABILITY")
			#if has cost: show Cost bar
		2:
			$Liner/Sizer/NT/Type.hide()
			$Liner/Sizer/Desc.hide()
			$Liner/IandD.hide()
		3:
			$Liner/Sizer/NT/Type.text = tr("STATUS")
	if ability.type != 2:
		$Liner/IandD/Img.texture = ability.icon
	
	duration = ability.duration
	
	$Liner/Sizer/Desc.text = tr(ability.desc)

# Note: Can't us INIT as nodes aren't initialized

signal selected()
func _on_button_pressed() -> void:
	selected.emit()
