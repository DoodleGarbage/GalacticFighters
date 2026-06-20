extends Control

class_name Card_GUI

var manager : Docker

func assign_manager(new_manager:Docker, pos:int=-1) -> void:
	var check : int = get_manager_position()
	if check > -1:
		manager.assigned_cards.pop_at(check)
	manager = new_manager
	if pos > -1:
		manager.assigned_cards.insert(pos, self)
	else:
		manager.assigned_cards.append(self)

## -1 means it either wasn't assigned as a card (which should not be happening) or no manager exists
func get_manager_position() -> int:
	return manager.assigned_cards.find(self) if manager != null else -1

## These values are set when the card is generated on the playfield
var unique_id : int = 0 # a unique identifier for synchronization/communication
var player_id : int = 0 # who is the 'owner' of this card

@export
var stored_card : Card

## Card data storage - so that it isn't stored on the Card Resource, but rather the Card_GUI - which is synced

# Note: to get the card's default values for health atk and defense, just check the Card resource

var max_health : int = 0
var health : int = 0 :
	set(value):
		if value > max_health:
			health = max_health
		health = value
		$Card/BStats/Left/Health.stat = value
var defense : int = 0 :
	set(value):
		defense = value
		$Card/BStats/Left/Defense.stat = value
var attack : int = 0 :
	set(value):
		attack = value
		$Card/BStats/Left/Attack.stat = value

var burst : int = 0 :
	set(value):
		burst = value
		$Card/BStats/Mid/Burst.stat = value
var heal : int = 0 :
	set(value):
		heal = value
		$Card/BStats/Center/Heal.stat = value
var armor_pierce : int = 0 :
	set(value):
		armor_pierce = value
		$Card/BStats/Mid/ArmorPierce.stat = value


var attributes : Array[Attribute] = []

var statuses : Array[Attribute] = []

var script_instance

func get_stats() -> Array:
	var stat : Array = [max_health, health, defense, attack, burst, heal, armor_pierce]
	return stat
## Uses the array obtained to perform the inverse operation of applying it
func apply_stats(stats:Array) -> void:
	max_health = stats[0]
	health = stats[1]
	defense = stats[2]
	attack = stats[3]
	burst = stats[4]
	heal = stats[5]
	armor_pierce = stats[6]





## Card interaction functions

const dmg_effect := preload("res://ParticleEffects/damage_effect.tscn")

func damage(amnt:int) -> void:
	## Trigger any attached passives, play visual effects, etc.
	var dmg : int = max(amnt - defense, 0)
	print("suffering damage! amnt: ", dmg)
	health -= dmg
	if dmg > 0:
		var new_particle := dmg_effect.instantiate()
		new_particle.finished.connect(new_particle.queue_free)
		new_particle.amount = amnt - defense
		new_particle.emitting = true
		new_particle.position = Vector2(150, 250)
		add_child(new_particle)







## Whether or not this card belongs to the current client/is controllable (aka, could be switched off under the "controlled" status effect)
var controlled : bool = false

func _ready() -> void:
	target_position = position
	initilize_interactions()
	## We set the 'Screen constant' - used for dragging - to be 100% of the screen per second
	SCREEN_CONST = DisplayServer.screen_get_size().length() * 1.0

const abi_gui = preload("res://GUI/Card/ability_display.tscn")
const default_move = preload("res://Resources/BasicResources/default_move.tres")
const default_attack = preload("res://Resources/BasicResources/default_attack.tres")

# Initial loading of the card; adds the Move, Attack, etc. buttons.
func initilize_interactions() -> void:
	var abg : Control
	
	abg = abi_gui.instantiate()
	abg.load_ability(default_move)
	abg.selected.connect(ability_trigger)
	$AttachPoint3/Interactions.add_child(abg)
	
	abg = abi_gui.instantiate()
	abg.load_ability(default_attack)
	abg.selected.connect(ability_trigger)
	$AttachPoint3/Interactions.add_child(abg)


signal ability_triggered(ability:Attribute, us:Card_GUI)
func ability_trigger(ability:Attribute) -> void:
	ability_triggered.emit(ability, self)

const special_character_background := preload("res://Art/SpecialCharacterCardBack.png")
const character_background := preload("res://Art/NormalCharacterCardBack.png")


func load_card(card:Card) -> void:
	stored_card = card
	$Card/Name.text = card.name
	$Card/Character.texture = card.full_profile
	$Card/CardIdent/Special.hide()
	
	
	var txttype : String = ""
	match(card.type):
		0:
			$Card/CardIdent/Special.show()
			$Card/CardIdent/Special.text = tr("SPECIAL")
			$Card/Background.texture = special_character_background
			txttype = "CHARACTER"
		1:
			$Card/Background.texture = character_background
			txttype = "CHARACTER"
	
	$Card/CardIdent/Type.show()
	$Card/CardIdent/Type.text = tr(txttype)
	
	max_health = card.max_health
	health = max_health
	defense = card.defense
	attack = card.attack
	
	armor_pierce = card.armor_pierce
	burst = card.burst
	heal = card.heal
	
	
	if armor_pierce <= 0:
		$Card/BStats/Mid/ArmorPierce.hide()
		$Card/BStats/Mid/Empty.size_flags_stretch_ratio += 1.0
	if burst <= 0:
		$Card/BStats/Mid/Burst.hide()
		$Card/BStats/Mid/Empty.size_flags_stretch_ratio += 1.0
	if heal <= 0:
		$Card/BStats/Center/Heal.hide()
	
	## Load Passives (places them above abilities)
	for ab in card.attributes:
		if ab.type == 0:
			var abg := abil_gui.instantiate()
			abg.load_ability(ab)
			abg.selected.connect(ability_trigger)
			$AttachPoint1/Abilities.add_child(abg)
	## Load Abilities
	for ab in card.attributes:
		if ab.type == 1:
			var abg := abil_gui.instantiate()
			abg.load_ability(ab)
			abg.selected.connect(ability_trigger)
			$AttachPoint1/Abilities.add_child(abg)
	
	


var menu_open : bool = false
const abil_gui := preload("res://GUI/Card/ability_display.tscn")

signal interaction(event)

func _gui_input(event: InputEvent) -> void:
	# Menu Interaction - opens the GUI for interacting
	if event is InputEventMouseButton:
		interaction.emit(event)
		if not controlled: ## Disables dragging for non-player cards
			return
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT && get_rect().has_point(get_global_mouse_position()):
			primed_for_drag = true
	if event is InputEventMouseMotion && primed_for_drag:
		start_drag()

# Opens/Closes the actions menu (move, attack, use ability)
func open_interaction_menu() -> void:
	z_index = 5
	$AttachPoint1.show()
	$AttachPoint2.show()
	if controlled: ## Only show the move/attack/etc for player cards
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
	if not get_parent().allow_drag:
		return
	dragging = true
	move_offset = get_local_mouse_position() * scale
	z_index = 2
	_drag()

signal stopped_dragging()
func _drag() -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and dragging:
		move_offset = Vector2(0,0)
		z_index = 0
		dragging = false
		stopped_dragging.emit()
		return
	# get_parent should always get the Playfield (game_manager.gd)
	if get_parent().allow_drag:
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

func set_selection(mode:bool) -> void:
	$Card/Selected.visible = mode
