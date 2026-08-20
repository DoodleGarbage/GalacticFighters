extends DockerChild

class_name Card_GUI



## Used to prevent killing a card multiple times
var flagged_for_death : bool = false

@export
var stored_card : Card

## Card data storage - so that it isn't stored on the Card Resource, but rather the Card_GUI - which is synced

# Note: to get the card's default values for health atk and defense, just check the Card resource

var max_health : int = 0
var health : int = 0 :
	set(value):
		if value > max_health:
			health = max_health
		else:
			health = value
		$Card/BStats/Left/Health.stat = health
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
var heal_stat : int = 0 :
	set(value):
		heal_stat = value
		$Card/BStats/Center/Heal.stat = value
var armor_pierce : int = 0 :
	set(value):
		armor_pierce = value
		$Card/BStats/Mid/ArmorPierce.stat = value

var attributes : Array[Attribute] = []

## The scripts associated with each attribute - this is also how details such as duration/length/turns left/etc etc are tracked - plus any "script defined variables" (this will need to be implemented - thing get_var, set_var stuff)
var attribute_scripts : Array = []

#var status_trackers : Array[Attribute] = []

## Returns information of this card for the purposes of internet sync code
func get_stats() -> Array:
	var stat : Array = [max_health, health, defense, attack, burst, heal_stat, armor_pierce]
	return stat
func get_script_data() -> Array:
	var return_data : Array = []
	for script in attribute_scripts:
		return_data.append(script.get_data())
	return return_data
func get_attributes() -> Array[String]:
	var return_data : Array[String] = []
	for attr in attributes:
		return_data.append(attr.mod_name())
	return return_data




## Uses the array obtained to perform the inverse operation of applying it
func apply_stats(stats:Array) -> void:
	max_health = stats[0]
	health = stats[1]
	defense = stats[2]
	attack = stats[3]
	burst = stats[4]
	heal_stat = stats[5]
	armor_pierce = stats[6]


## WARNING: Ensure that the script data is the same between attributes and the associateds script instances
func load_attributes(attribute_names:Array[String]) -> void:
	attributes = []
	for attr in attribute_names:
		var true_attribute = Resources.find_resource("Attribute", attr)
		attributes.append(true_attribute)
	attribute_scripts = []
	for attribute in attributes:
		attribute_scripts.append(init_script(attribute))

## WARNING: Need safeguards to prevent the number of script instances in the script array from changing between get_data and set_data - well, this shouldn't happen since it gets immediately fed back in
func update_scripts(data:Array) -> void:
	var i : int = 0
	for script in attribute_scripts:
		script.set_data(data[i])
		i += 1
	update_ability_buttons()


func init_script(attribute:Attribute) -> GDScript:
	var new_script = null
	if attribute.pscript != null:
		new_script = attribute.pscript.new(self, attribute.script_variables)
	else:
		new_script = empty_script.new([self])
	new_script.ability = attribute
	new_script.source = self
	new_script._initialized()
	return new_script




## Card interaction functions

const dmg_effect := preload("res://Data/Vanilla/VFX/damage_effect.tscn")
signal dead()

func damage(trigger : Attribute, amnt:int, pierce:int=0) -> void:
	if amnt < 0:
		heal(trigger, amnt)
	var dmg_vfx = dmg_effect
	if trigger != null and trigger.VFX_damage != null and trigger.VFX_damage != Resources.VFX_null:
		dmg_vfx = trigger.VFX_damage
	var true_defense : int = max(0, defense-pierce) if defense >= 0 else defense
	## Trigger any attached passives, play visual effects, etc.
	var dmg : int = max(amnt - true_defense, 0)
	print("suffering damage! amnt: ", dmg)
	health -= dmg
	if health <= 0:
		dead.emit()
	if dmg > 0:
		var new_particle = dmg_vfx.instantiate()
		new_particle.finished.connect(new_particle.queue_free)
		new_particle.amount = dmg
		new_particle.emitting = true
		new_particle.position = Vector2(150, 250)
		add_child(new_particle)

func heal(trigger : Attribute, amnt:int) -> void:
	var heal_vfx = dmg_effect
	if trigger != null and trigger.VFX_damage != null and trigger.VFX_damage != Resources.VFX_null:
		heal_vfx = trigger.VFX_damage
	print("Healing! Amount: ", amnt)
	health += amnt
	var new_particle = heal_vfx.instantiate()
	new_particle.finished.connect(new_particle.queue_free)
	new_particle.amount = amnt
	new_particle.emitting = true
	new_particle.position = Vector2(150, 250)
	add_child(new_particle)

func apply_status(status:String) -> void:
	var status_effect : Attribute = Resources.find_resource("Attribute", status)
	if status_effect == null:
		return
	print("We're applying status: ", status)
	attributes.append(status_effect)
	attribute_scripts.append(init_script(status_effect))
	attribute_scripts[-1].duration_tracker = status_effect.duration
	
	
	update_ability_buttons()







func _ready() -> void:
	target_position = position
	
	## We set the 'Screen constant' - used for dragging - to be 100% of the screen per second
	#SCREEN_CONST = DisplayServer.screen_get_size().length() * 1.0

const abi_gui = preload("res://GUI/Card/ability_display.tscn")
#var default_move = preload("res://Resources/BasicResources/default_move.tres")
#var default_attack = preload("res://Resources/BasicResources/default_attack.tres")

# Initial loading of the card; adds the Move, Attack, etc. buttons.
func initilize_interactions() -> void:
	var abg : Control
	
	var move : Attribute = Resources.find_resource("Attribute", "vanilla:MOVE")
	attributes.append(move)
	var m_script = move.pscript.new(self, move.script_variables)
	m_script.ability = move
	attribute_scripts.append(m_script)
	var aattack : Attribute = Resources.find_resource("Attribute", "vanilla:ATTACK")
	attributes.append(aattack)
	var a_script = aattack.pscript.new(self, move.script_variables)
	attribute_scripts.append(a_script)
	
	var ability_index : int = -1
	
	abg = abi_gui.instantiate()
	ability_index = attributes.find(move)
	abg.load_ability(move)
	abg.selected.connect(ability_trigger.bind(ability_index))
	$AttachPoint3/Interactions.add_child(abg)
	
	abg = abi_gui.instantiate()
	ability_index = attributes.find(aattack)
	abg.load_ability(aattack)
	abg.selected.connect(ability_trigger.bind(ability_index))
	$AttachPoint3/Interactions.add_child(abg)


func update_ability_buttons() -> void:
	## Added because empty cards crash because of this
	var abg_point : Control = get_node_or_null("AttachPoint1/Abilities")
	if abg_point != null:
		for child in abg_point.get_children():
			child.queue_free()
	else:
		return ## I think this will only be called on the empty cards
	
	## Load Passives (places them above abilities)
	for ab in attributes.size():
		if attributes[ab].type == 0:
			var abg := abil_gui.instantiate()
			abg.load_ability(attributes[ab])
			abg.selected.connect(ability_trigger.bind(ab))
			abg_point.add_child(abg)
			abg.duration = attribute_scripts[ab].duration_tracker
	## Load Abilities
	for ab in attributes.size():
		if attributes[ab].type == 1:
			var abg := abil_gui.instantiate()
			abg.load_ability(attributes[ab])
			abg.selected.connect(ability_trigger.bind(ab))
			abg_point.add_child(abg)
			abg.duration = attribute_scripts[ab].duration_tracker
	## Load Status Effects
	for ab in attributes.size():
		if attributes[ab].type == 3:
			var abg := abil_gui.instantiate()
			abg.load_ability(attributes[ab])
			abg.selected.connect(ability_trigger.bind(ab))
			abg_point.add_child(abg)
			abg.duration = attribute_scripts[ab].duration_tracker


signal ability_triggered(ability:int, us:Card_GUI)
func ability_trigger(ability:int) -> void:
	print("Triggering ability: ", ability)
	ability_triggered.emit(ability, self)

const special_character_background := preload("res://Art/SpecialCharacterCardBack.png")
const character_background := preload("res://Art/NormalCharacterCardBack.png")
const empty_script := preload("res://Resources/BasicResources/empty_script.gd")

func load_card(card:Card, deck_loaded:bool=false) -> void:
	
	attributes = []
	attribute_scripts = []
	
	for child in $AttachPoint1/Abilities.get_children():
		child.queue_free()
	for child in $AttachPoint2/Statuses.get_children():
		child.queue_free()
	for child in $AttachPoint3/Interactions.get_children():
		child.queue_free()
	
	stored_card = card
	$Card/Name.text = card.name
	$Card/Character.texture = card.full_profile
	$Card/CardIdent/Special.hide()
	
	if not deck_loaded:
		initilize_interactions()
	
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
	heal_stat = card.heal
	
	if not deck_loaded:
		## Initialize scripts for the first time
		for attr in stored_card.attributes:
			attributes.append(attr)
			attribute_scripts.append(init_script(attr))
	
	if armor_pierce <= 0:
		$Card/BStats/Mid/ArmorPierce.hide()
		$Card/BStats/Mid/Empty.size_flags_stretch_ratio += 1.0
	if burst <= 0:
		$Card/BStats/Mid/Burst.hide()
		$Card/BStats/Mid/Empty.size_flags_stretch_ratio += 1.0
	if heal_stat <= 0:
		$Card/BStats/Center/Heal.hide()
	
	update_ability_buttons()


var menu_open : bool = false
const abil_gui := preload("res://GUI/Card/ability_display.tscn")

#signal interaction(event)

#func _gui_input(event: InputEvent) -> void:
	## Menu Interaction - opens the GUI for interacting
	#if event is InputEventMouseButton:
		#interaction.emit(event)
		#if not controlled: ## Disables dragging for non-player cards
			#return
		#if event.button_index == MouseButton.MOUSE_BUTTON_LEFT && get_rect().has_point(get_global_mouse_position()):
			#primed_for_drag = true
	#if event is InputEventMouseMotion && primed_for_drag:
		#start_drag()

# Opens/Closes the actions menu (move, attack, use ability)
func open_interaction_menu() -> void:
	z_index = 5 + manager.z_index if manager != null else 5
	$AttachPoint1.show()
	$AttachPoint2.show()
	if controlled: ## Only show the move/attack/etc for player cards
		$AttachPoint3.show()
func close_interaction_menu() -> void:
	z_index = 0 + manager.z_index if manager != null else 0
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

## All the code to implement dragging is here and should be functional with minimal fixing - currently unused and unneed by the current design

#func start_drag() -> void:
	#primed_for_drag = false
	#if not get_parent().allow_drag:
		#return
	#dragging = true
	#move_offset = get_local_mouse_position() * scale
	#z_index = 2 + manager.z_index
	#_drag()

#signal stopped_dragging()
#func _drag() -> void:
	#if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and dragging:
		#move_offset = Vector2(0,0)
		#z_index = 0 + manager.z_index
		#dragging = false
		#stopped_dragging.emit()
		#return
	## get_parent should always get the Playfield (game_manager.gd)
	#if get_parent().allow_drag:
		#return
	#if not dragging:
		#return
	#target_position = get_global_mouse_position() - move_offset


# When we start dragging a card, we drag it around the point we 'pulled it'
var move_offset : Vector2 = Vector2(0,0)
# See Ready() for the details of screen constant; it's how much of the screen we travel per second
#var SCREEN_CONST : float = 0.0
#func _process(_delta: float) -> void:
	#_drag()
	#position = target_position
	#position.move_toward(target_position, SCREEN_CONST * delta)

func set_selection(mode:bool) -> void:
	$Card/Selected.visible = mode
