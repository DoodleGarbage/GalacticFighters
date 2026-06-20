extends PanelContainer

var loaded_card : Card

var allow_drag : bool = true

func load_card(card:Card) -> void:
	loaded_card = card
	$Div/Icon.texture = loaded_card.mini_profile
	$Div/Name.text = tr(loaded_card.name)
	$FullCard.load_card(loaded_card)

func switch(mode:bool=false) -> void:
	if mode:
		$FullCard.show()
		$Div.hide()
		return
	$FullCard.hide()
	$Div.show()

#func _gui_input(event: InputEvent) -> void:
	## Menu Interaction - opens the GUI for interacting
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and get_rect().has_point(get_global_mouse_position()):
			#$FullCard.primed_to_drag = true
			#return
	#if event is InputEventMouseMotion && $FullCard.primed_for_drag:
		#start_drag()

#func start_drag() -> void:
	#$FullCard.start_drag()

#func _physics_process(delta: float) -> void:
	#if $FullCard.dragging:
		#position = $FullCard.position


#func _on_full_card_stopped_dragging() -> void:
	#$FullCard.position = position
	#$FullCard.target_position = position
