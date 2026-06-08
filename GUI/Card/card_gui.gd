extends Control

class_name Card_GUI

var manager : Node

@export
var stored_card : Card = preload("res://Resources/BasicResources/demo_card.tres")

## Whether or not this card belongs to the current player's screen
var player_owned : bool = false

func _ready() -> void:
	target_position = position
	initilize_interactions()
	load_card(stored_card)
	## We set the 'Screen constant' - used for dragging - to be 100% of the screen per second
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
	$Card/Background.texture = card.full_profile
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
	
	$Card/BStats/Left/Health.stat = card.max_health
	$Card/BStats/Left/Defense.stat = card.defense
	$Card/BStats/Left/Attack.stat = card.attack
	
	$Card/BStats/Mid/ArmorPierce.stat = card.armor_pierce
	$Card/BStats/Mid/Burst.stat = card.burst
	$Card/BStats/Center/Heal.stat = card.heal
	
	if card.armor_pierce <= 0:
		$Card/BStats/Mid/ArmorPierce.hide()
		$Card/BStats/Mid/Empty.size_flags_stretch_ratio += 1.0
	if card.burst <= 0:
		$Card/BStats/Mid/Burst.hide()
		$Card/BStats/Mid/Empty.size_flags_stretch_ratio += 1.0
	if card.heal <= 0:
		$Card/BStats/Center/Heal.hide()
	
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

signal interaction(event)

func _gui_input(event: InputEvent) -> void:
	# Menu Interaction - opens the GUI for interacting
	if event.is_action_released("card_interact"):
		interaction.emit(event)
	
	if not player_owned: ## Disables dragging for non-player cards
		return
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT && get_rect().has_point(get_global_mouse_position()):
			primed_for_drag = true
	if event is InputEventMouseMotion && primed_for_drag:
		start_drag()

# Opens/Closes the actions menu (move, attack, use ability)
func open_interaction_menu() -> void:
	z_index = 5
	$AttachPoint1.show()
	$AttachPoint2.show()
	if player_owned: ## Only show the move/attack/etc for player cards
		$AttachPoint3.show()
func close_interaction_menu() -> void:
	z_index = 0
	$AttachPoint1.hide()
	$AttachPoint2.hide()
	$AttachPoint3.hide()

## Card Dragging

# if we were clicked and are about to try dragging on next mouse movement
var primed_for_drag : bool = false
# whether or not we are actively being dragged
var dragging : bool = false
# The location we will interpolate towards
var target_position : Vector2 = Vector2(0,0)

## The number of pixels before we leave the deadzone and begin dragging
var MOUSE_DEADZONE : float = 10.0

func start_drag() -> void:
	primed_for_drag = false
	if not manager.allow_drag:
		return
	dragging = true
	move_offset = get_local_mouse_position() * scale
	z_index = 2
	_drag()

signal stopped_dragging()
func _drag() -> void:
	if manager == null or not manager.allow_drag:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and dragging:
		move_offset = Vector2(0,0)
		z_index = 0
		dragging = false
		stopped_dragging.emit()
		return
	if not dragging:
		return
	target_position = get_global_mouse_position() - move_offset


# When we start dragging a card, we drag it around the point we 'pulled it'
var move_offset : Vector2 = Vector2(0,0)
# See Ready() for the details of screen constant; it's how much of the screen we travel per second
var SCREEN_CONST : float = 0.0
func _process(_delta: float) -> void:
	_drag()
	position = target_position
	#position.move_toward(target_position, SCREEN_CONST * delta)
