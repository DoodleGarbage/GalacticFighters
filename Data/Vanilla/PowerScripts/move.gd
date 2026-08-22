extends PowerScript

func _interaction(_targets:Array[Card_GUI]) -> void:
	#print("Triggering MOVE powerscript")
	#print("Player assignments: target: ", _targets[0].player_id, " source: ", source.player_id)
	var t_store = _targets[0].manager
	var s_store = source.manager
	var spos : int = source.manager_position
	var tpos : int = _targets[0].manager_position
	#if _targets[0].input_metadata == "empty":
		#if _targets[0].manager.assigned_cards >= _targets[0].manager
	
	source.remove_manager()
	if not _targets[0].input_metadata & 2:
		#print("yup, we are switching with a non-empty")
		_targets[0].remove_manager()
		_targets[0].assign_manager(s_store, spos, true)
	#print("Assigning to manager; player_id: ", t_store.player, " identifier: ", t_store.identifier)
	source.assign_manager(t_store, tpos, true)
	
	
