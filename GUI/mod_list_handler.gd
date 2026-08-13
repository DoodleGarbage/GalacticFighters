extends CanvasLayer

var temporary_mod_changes : Array[Control] = []

func _on_mod_toggled(mod:Control) -> void:
	if not temporary_mod_changes.has(mod):
		temporary_mod_changes.append(mod)
	else:
		temporary_mod_changes.remove_at(temporary_mod_changes.find(mod))
	$BG/List/AcceptCancel/Apply.disabled = not temporary_mod_changes


signal reload_scene
func _on_apply_pressed() -> void:
	for mod in temporary_mod_changes:
		mod.mod.enabled = mod.state
	temporary_mod_changes = []
	$BG/List/AcceptCancel/Apply.disabled = true
	Resources.reload_mods()
	reload_scene.emit()


func _on_cancel_pressed() -> void:
	for mod in temporary_mod_changes:
		mod.state = not mod.state
	temporary_mod_changes = []
	$BG/List/AcceptCancel/Apply.disabled = true
	hide()
