extends Control

@export
var stored_card : Card = preload("res://Resources/BasicResources/demo_card.tres")

func _ready() -> void:
	initilize_interactions()
	load_card(stored_card)
	## We set the 'Screen constant' - used for dragging - to be 80% of the screen per second
	SCREEN_CONST = DisplayServer.screen_get_size().length() * 1.0

const default_move = preload("res://Resources/BasicResources/default_move.tres")
const default_attack = preload("res://Resources/BasicResources/default_attack.tres")

# Initial loading of the card; adds the Move, Attack, etc. buttons.
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
	
	## Load Passives (places them above abilities)
	for ab in card.attributes:
		if ab.type == 0:
			var abg := abil_gui.instantiate()
			abg.load_ability(ab)
			$AttachPoint1/Abilities.add_child(abg)
	## Load Abilities
	for ab in card.attributes:
		if ab.type == 1:
			var abg := abil_gui.instantiate()
			abg.load_ability(ab)
			$AttachPoint1/Abilities.add_child(abg)
	
	


var menu_open : bool = false
const abil_gui := preload("res://GUI/Card/ability_display.tscn")



func _input(event: InputEvent) -> void:
	# Menu Interaction Code - opens the GUI for interacting
	if event.is_action_released("card_interact"):
		var area := Rect2(Vector2(0,0), self.size)
		if area.has_point(get_local_mouse_position()):
			if menu_open:
				close_interaction_menu()
			else:
				open_interaction_menu()
		elif menu_open:
			close_interaction_menu()
	
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			primed_for_drag = true
			drag_deadzone = get_local_mouse_position()
	if event is InputEventMouseMotion && primed_for_drag:
		if not event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			primed_for_drag = false
			return # THERE IS A RETURN HERE WARNING
		if drag_deadzone.distance_to(get_local_mouse_position()) > MOUSE_DEADZONE:
			start_drag()

# Opens/Closes the actions menu (move, attack, use ability)
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

## Card Dragging

# The current node who "owns" us, since we can't use the scene tree to check this. Our card GUI code shouldn't touch or care about this, and it should only be used by managing nodes.
var docker : Node
# For use by the current managing 'docker' to determine if we are being dragged or should resort to the docker's position management
var docked : bool = false
var primed_for_drag : bool = false
# The location we will interpolate towards
var target_position : Vector2 = Vector2(0,0)

## The number of pixels before we leave the deadzone and begin dragging
var MOUSE_DEADZONE : float = 10.0

func start_drag() -> void:
	## ADD CHECK TO MAKE SURE NO ONE ELSE IS BEING DRAGGED/WILL BE
	primed_for_drag = false
	docked = false
	move_offset = get_local_mouse_position()
	_drag()

func _drag() -> void:
	if docked:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		docked = true
		move_offset = Vector2(0,0)
		return
	
	target_position = get_global_mouse_position() - move_offset

# When we press left click, we create a point; if we move past the 'deadzone' we begin dragging the card.
var drag_deadzone : Vector2
# When we start dragging a card, we drag it around the point we 'pulled it'
var move_offset : Vector2 = Vector2(0,0)
# See Ready() for the details of screen constant; it's how much of the screen we travel per second
var SCREEN_CONST : float = 0.0
func _process(delta: float) -> void:
	_drag()
	position = position.move_toward(target_position, SCREEN_CONST * delta)
