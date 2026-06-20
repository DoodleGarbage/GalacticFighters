extends PowerScript

func _interaction(_targets:Array[Card_GUI]) -> void:
	var store = _targets[0].manager
	var spos : int = source.get_manager_position()
	var tpos : int = _targets[0].get_manager_position()
	_targets[0].assign_manager(source.manager, spos)
	source.assign_manager(store, tpos)
