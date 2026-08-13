extends DockerChild
class_name Item_GUI

var loaded_item : Item

func load_item(item:Item) -> void:
	
	loaded_item = item
	
	$List/Name.text = tr(loaded_item.name)
	$List/PanelContainer/Desc.text = tr(loaded_item.desc)
	$List/Icon.texture = item.icon
	
	
