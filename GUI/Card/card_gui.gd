extends Control

@export
var stored_card : Card

func _ready() -> void:
	initilize_interactions()
	load_card(stored_card)

const default_move = preload("res://Resources/BasicResources/default_move.tres")
const default_attack = preload("res://Resources/BasicResources/default_attack.tres")

func initilize_interactions() -> void:
	var abg := abil_gui.instantiate()
	
	abg = abil_gui.instantiate()
	abg.load_ability(default_move)
	#abg.pressed.connect(on_move_trigger)
	$AttachPoint3/Interactions.add_child(abg)
	
	abg = abil_gui.instantiate()
	abg.load_ability(default_attack)
	#abg.pressed.connect(on_attack_trigger)
	$AttachPoint3/Interactions.add_child(abg)
	



func load_card(card:Card) -> void:
	stored_card = card
	$Card/Name.text = card.name
	var txttype : String = ""
	match(card.type):
		0:
			$Card/CardIdent/Special.show()
			$Card/CardIdent/Special.text = tr("SPECIAL")
			txttype = "CHARACTER"
		1:
			txttype = "CHARACTER"
	
	$Card/CardIdent/Type.show()
	$Card/CardIdent/Type.text = tr(txttype)
	
	## Sorts the abilities to be Passives first
	for ab in card.abilities:
		if ab.type == 0:
			var abg := abil_gui.instantiate()
			abg.load_ability(ab)
			$AttachPoint1/Abilities.add_child(abg)
	for ab in card.abilities:
		if ab.type != 0:
			var abg := abil_gui.instantiate()
			abg.load_ability(ab)
			$AttachPoint1/Abilities.add_child(abg)
	
	


var menu_open : bool = false
const abil_gui := preload("res://GUI/Card/ability_display.tscn")

func open_interaction_menu() -> void:
	menu_open = true
	printerr("Send Signal to Global Screen-Dimmer here")
	$AttachPoint1.show()
	$AttachPoint2.show()
	$AttachPoint3.show()

func close_interaction_menu() -> void:
	menu_open = false
	$AttachPoint1.hide()
	$AttachPoint2.hide()
	$AttachPoint3.hide()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("card_interact"):
		var area := Rect2(Vector2(0,0), self.size)
		if area.has_point(get_local_mouse_position()):
			if menu_open:
				close_interaction_menu()
			else:
				open_interaction_menu()
		elif menu_open:
			close_interaction_menu()
