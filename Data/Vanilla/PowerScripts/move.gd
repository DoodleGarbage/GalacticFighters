extends PowerScript

func _interaction(_targets:Array[Card_GUI]) -> void:
	print("Triggering MOVE powerscript")
	var t_store = _targets[0].manager
	var s_store = source.manager
	var spos : int = source.manager_position
	var tpos : int = _targets[0].manager_position
	#if _targets[0].input_metadata == "empty":
		#if _targets[0].manager.assigned_cards >= _targets[0].manager
	
	source.remove_manager()
	if _targets[0].input_metadata != "empty":
		#print("yup, we are switching with a non-empty")
		_targets[0].remove_manager()
		_targets[0].assign_manager(s_store, spos, true)
	source.assign_manager(t_store, tpos, true)
	
	
