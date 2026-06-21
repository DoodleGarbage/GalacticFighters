extends PanelContainer

## Used by the parent Card_GUI to determine *which* attribute is saved on here
var ability_index : int = -1
var loaded_ability : Attribute

func load_ability(ability:Attribute) -> void:
	
	loaded_ability = ability
	
	$Sizer/NT/Name.text = tr(ability.name)
	
	match(ability.type):
		0:
			$Sizer/NT/Type.text = tr("PASSIVE")
			$Button.hide()
		1:
			$Sizer/NT/Type.text = tr("ABILITY")
			#if has cost: show Cost bar
		2:
			$Sizer/NT/Type.hide()
			$Sizer/Desc.hide()
	
	$Sizer/Desc.text = tr(ability.desc)

# Note: Can't us INIT as nodes aren't initialized

signal selected()
func _on_button_pressed() -> void:
	selected.emit(ability_index)
