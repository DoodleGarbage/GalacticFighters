extends PanelContainer

func load_ability(ability:Attribute) -> void:
	
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

#func _init(ability:Ability) -> void:
	#load_ability(ability)
