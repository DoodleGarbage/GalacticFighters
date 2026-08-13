extends HBoxContainer

var state : bool :
	get():
		return $Enabled.button_pressed

var mod : Mod :
	set(value):
		mod = value
		$Enabled.button_pressed = mod.enabled
		$BG/Width/VBoxContainer/Name.text = mod.name
		$BG/Width/VBoxContainer/hashholder/VerVal.text = mod.version_as_string()
		$BG/Width/VBoxContainer/hashholder/HashVal.text = mod.hash.hex_encode()

signal mod_toggled(us:Control)



func _on_enabled_pressed() -> void:
	mod_toggled.emit(self)
