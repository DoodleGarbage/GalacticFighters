extends Control



signal exit()

func _exit_pressed() -> void:
	save_deck_to_file()
	exit.emit()

@onready var card_gui_scene := preload("res://GUI/Card/card.tscn")
@onready var item_gui_scene := preload("res://GUI/item.tscn")
@onready var gadget_gui_scene := preload("res://GUI/gadget.tscn")

@onready var deck_comp_scene := preload("res://GUI/deck_component.tscn")

func _ready() -> void:
	check_current_deck_validity() # Updates the button so it's setup

func load_cards() -> void:
	clear_loaded_cards()
	for chara in Resources.characters:
		var target_container : GridContainer
		match(chara.type):
			0:
				target_container = $"Div/Sep/TabContainer/Special Characters/Special Characters"
			1:
				target_container = $Div/Sep/TabContainer/Characters/Characters
		var new_char : Card_GUI = card_gui_scene.instantiate()
		
		target_container.add_child(new_char)
		new_char.load_card(chara, true)
	for itm in Resources.items:
		var target_container : GridContainer
		var new_inst : Item_GUI
		match(itm.type):
			0:
				target_container = $"Div/Sep/TabContainer/Item and Gadgets/Items & Gadgets"
				new_inst = item_gui_scene.instantiate()
			1:
				target_container = $"Div/Sep/TabContainer/Item and Gadgets/Items & Gadgets"
				new_inst = gadget_gui_scene.instantiate()
			2:
				target_container = $Div/Sep/TabContainer/Swords/Swords
				new_inst = item_gui_scene.instantiate()
		target_container.add_child(new_inst)
		new_inst.load_item(itm)
	load_deck_options()

func load_deck_options() -> void:
	$Div/Scroll/CurrentDeck/LdDlt/LoadDeck.clear()
	$Div/Scroll/CurrentDeck/LdDlt/LoadDeck.add_item("Load Deck")
	for deck in Resources.decks: # The indices of the resources.decks and LoadDeck should line up (-1)
		$Div/Scroll/CurrentDeck/LdDlt/LoadDeck.add_item(deck.name)

func clear_loaded_cards() -> void:
	clear_current_deck()
	interact_viewer_card_gui.hide()
	interact_viewer_item.hide()
	for child in $"Div/Sep/TabContainer/Special Characters/Special Characters".get_children():
		child.queue_free()
	for child in $Div/Sep/TabContainer/Characters/Characters.get_children():
		child.queue_free()
	for child in $"Div/Sep/TabContainer/Item and Gadgets/Items & Gadgets".get_children():
		child.queue_free()
	for child in $Div/Sep/TabContainer/Swords/Swords.get_children():
		child.queue_free()
	$Div/Scroll/CurrentDeck/LdDlt/LoadDeck.clear()

func clear_current_deck() -> void:
	for child in deck_components:
		child.queue_free()
	deck_components = []

var deck_components : Array[Control] = []

func add_card_to_deck(card) -> void:
	if card == null:
		return
	$Div/Scroll/CurrentDeck/LdDlt/Delete.hide()
	$Div/Scroll/CurrentDeck/PanelContainer/HBoxContainer/SaveDeck.text = "*Save"
	var icon : Texture
	var type : int = -1
	var card_name : String = ""
	var full_name : String = ""
	if card is Card_GUI or card is Card:
		var cad : Card
		if card is Card_GUI:
			cad = card.stored_card
		if card is Card:
			cad = card
		icon = cad.mini_profile
		card_name = cad.name
		full_name = cad.mod_name()
		match(cad.type):
			0:
				type = 0
			1:
				type = 1
	if card is Item_GUI or card is Item:
		var item : Item
		if card is Item:
			item = card
		if card is Item_GUI:
			item = card.loaded_item
		icon = item.icon
		card_name = item.name
		full_name = item.mod_name()
		match(item.type):
			0:
				type = 3
			1:
				type = 2
			2:
				type = 4
	
	
	var new_dk_comp := deck_comp_scene.instantiate()
	$Div/Scroll/CurrentDeck.add_child(new_dk_comp)
	
	deck_components.append(new_dk_comp)
	
	new_dk_comp.icon = icon
	new_dk_comp.type = type
	new_dk_comp.card_name = card_name
	new_dk_comp.full_name = full_name
	print("Created deck component, card_name is: ", card_name)
	check_current_deck_validity()
	sort_deck_components()

func _on_save_deck_pressed() -> void:
	var deck_name : String = $Div/Scroll/CurrentDeck/PanelContainer/HBoxContainer/DeckName.text
	if deck_name == "" or deck_components.size() < 1:
		return
	$Div/Scroll/CurrentDeck/PanelContainer/HBoxContainer/SaveDeck.text = "Save"
	var found_identical : bool = false
	var new_deck : Deck = deck_components_to_deck()
	new_deck.name = deck_name
	for deck in Resources.decks.size():
		if Resources.decks[deck].name == deck_name:
			Resources.decks[deck] = new_deck
			found_identical = true
			break
	if not found_identical:
		Resources.decks.append(new_deck)
	save_deck_to_file()
	load_deck_options()

func save_deck_to_file() -> void:
	Resources.save_decks()
	Resources.init_decks()

func _on_load_deck_item_selected(index: int) -> void:
	clear_current_deck()
	load_deck(Resources.decks[index-1])
	$Div/Scroll/CurrentDeck/PanelContainer/HBoxContainer/DeckName.text = Resources.decks[index-1].name
	$Div/Scroll/CurrentDeck/LdDlt/Delete.show()
	$Div/Scroll/CurrentDeck/PanelContainer/HBoxContainer/SaveDeck.text = "Save"

func load_deck(deck:Deck) -> void:
	for card in deck.characters + deck.gadgets + deck.items + [deck.sword]:
		add_card_to_deck(card)

func sort_deck(a, b):
	if a.type < b.type:
		return true # first element needs to be moved before second one
	if a.type == b.type and a.card_name < b.card_name:
		return true
	return false 

func sort_deck_components() -> void:
	deck_components.sort_custom(sort_deck)
	for i in deck_components.size():
		$Div/Scroll/CurrentDeck.move_child(deck_components[i], i+3)

func check_current_deck_validity() -> void:
	var test_deck : Deck = deck_components_to_deck()
	var valid : bool = Resources.is_deck_valid(test_deck)
	if not valid:
		$Div/Scroll/CurrentDeck/PanelContainer/HBoxContainer/SaveDeck.add_theme_color_override("font_color", Color(0.705, 0.0, 0.0, 1.0))
	else:
		$Div/Scroll/CurrentDeck/PanelContainer/HBoxContainer/SaveDeck.add_theme_color_override("font_color", Color(0.0, 0.588, 0.0, 1.0))
	var special_charas : int = 0
	var charas : int = 0
	for chars in test_deck.characters:
		if chars.type == 0:
			special_charas += 1
		if chars.type == 1:
			charas += 1
	$Div/Scroll/CurrentDeck/PanelContainer/HBoxContainer/SaveDeck.tooltip_text = "
	Deck Info:\n
	Special Characters: %s (Max: %s)\n
	Characters: %s (Min: %s, Max: %s)\n
	Gadgets: %s (Max: %s)\n
	Items: %s (Min: %s, Max: %s)\n
	Swords: %s (Max: %s)\n
	" % [special_charas, Resources.max_special_characters, charas, Resources.min_characters, Resources.max_characters, test_deck.gadgets.size(), Resources.max_gadgets, test_deck.items.size(), Resources.min_items, Resources.max_items, 0 if test_deck.sword == null else 1, Resources.max_swords]

func deck_components_to_deck() -> Deck:
	var deck_contents : Array[String] = []
	for comp in deck_components:
		deck_contents.append(comp.deck_valid_name)
	return Deck.from_str(deck_contents)


var menu_open : bool = false
var active_interact_card : DockerChild
@export var interact_viewer_card_gui : Card_GUI
@export var interact_viewer_item : Item_GUI
@export var interact_viewer_gadget : Item_GUI
@export var interact_viewer_sword : Item_GUI

func _input(event: InputEvent) -> void:
	if not get_parent().visible:
		return
	if event.is_action_pressed("save_deck"):
		_on_save_deck_pressed()
	if event is InputEventMouseButton:
		if menu_open and event.is_action_pressed("card_interact"):
			close_interaction_menu()
			return
		## Get all cards being hovered during this button click:
		var hovered_cards : Array[DockerChild] = []
		# Reminder that the card shadows are inside the cards array
		for card in $Div/Sep/TabContainer.get_current_tab_control().get_child(0).get_children():
			var rect : Rect2 = Rect2(card.global_position, card.size * card.scale)
			if rect.has_point(get_global_mouse_position()):
				print("Adding card as possible: ", card.name)
				hovered_cards.append(card)
		var hovered_deck_comp : Array[Control] = []
		for comp in deck_components:
			var rect : Rect2 = Rect2(comp.global_position, comp.size * comp.scale)
			if rect.has_point(get_global_mouse_position()):
				hovered_deck_comp.append(comp)
		if event.is_action_pressed("card_select"):
			if menu_open:
				close_interaction_menu()
				return
			if hovered_cards.size() <= 0 and hovered_deck_comp.size() > 0:
				var f_val : int = deck_components.find(hovered_deck_comp[0])
				$Div/Scroll/CurrentDeck.remove_child(deck_components[f_val])
				deck_components[f_val].queue_free()
				deck_components.remove_at(f_val)
				$Div/Scroll/CurrentDeck/LdDlt/Delete.hide()
				$Div/Scroll/CurrentDeck/PanelContainer/HBoxContainer/SaveDeck.text = "*Save"
				check_current_deck_validity()
			for card in hovered_cards:
				add_card_to_deck(card)
			return
		if not menu_open and event.is_action_pressed("card_interact"):
			for card in hovered_cards:
				open_interaction_menu(card)
				break
			return

func open_interaction_menu(card:DockerChild) -> void:
	if card == null:
		push_warning("Tried to open the interaction menu for a null card!")
		return
	active_interact_card = card
	if card is Card_GUI:
		interact_viewer_card_gui.load_card(card.stored_card)
		interact_viewer_card_gui.open_interaction_menu()
		interact_viewer_card_gui.show()
	elif card is Item_GUI:
		var viewer : Item_GUI
		match(card.loaded_item.type):
			0:
				viewer = interact_viewer_item
			1:
				viewer = interact_viewer_gadget
			2:
				viewer = interact_viewer_sword
		
		viewer.load_item(card.loaded_item)
		viewer.open_interaction_menu()
		viewer.show()
	menu_open = true
	#allow_drag = false
	interact_viewer_card_gui.position = get_viewport_rect().size * 0.5 - interact_viewer_card_gui.size * 0.5
	interact_viewer_item.position = get_viewport_rect().size * 0.5 - interact_viewer_item.size * 0.5
	$Dimmer.show()
	interact_viewer_gadget.position = get_viewport_rect().size * 0.5 - interact_viewer_gadget.size * 0.5
	$Dimmer.show()

## Close the interaction menu
func close_interaction_menu() -> void:
	if active_interact_card != null and not active_interact_card.is_queued_for_deletion():
		active_interact_card.close_interaction_menu()
	interact_viewer_card_gui.hide()
	interact_viewer_item.hide()
	interact_viewer_gadget.hide()
	active_interact_card = null
	menu_open = false
	$Dimmer.hide()



func _on_clear_pressed() -> void:
	clear_current_deck()


func show_all_cards() -> void:
	for child in $"Div/Sep/TabContainer/Special Characters/Special Characters".get_children():
		child.show()
	for child in $Div/Sep/TabContainer/Characters/Characters.get_children():
		child.show()
	for child in $"Div/Sep/TabContainer/Item and Gadgets/Items & Gadgets".get_children():
		child.show()
	for child in $Div/Sep/TabContainer/Swords/Swords.get_children():
		child.show()

func _on_search_box_text_changed() -> void:
	show_all_cards()
	var txt : String = $Div/Sep/PanelContainer/SearchBox.text
	if txt == "":
		return
	for child in $"Div/Sep/TabContainer/Special Characters/Special Characters".get_children():
		if child is Card_GUI and not child.stored_card.name.containsn(txt):
			child.hide()
	for child in $Div/Sep/TabContainer/Characters/Characters.get_children():
		if child is Card_GUI and not child.stored_card.name.containsn(txt):
			child.hide()
	for child in $"Div/Sep/TabContainer/Item and Gadgets/Items & Gadgets".get_children():
		if child is Item_GUI and not child.loaded_item.name.containsn(txt):
			child.hide()
	for child in $Div/Sep/TabContainer/Swords/Swords.get_children():
		if child is Item_GUI and not child.loaded_item.name.containsn(txt):
			child.hide()


func _on_delete_pressed() -> void:
	var deck_indice : int = $Div/Scroll/CurrentDeck/LdDlt/LoadDeck.selected
	if $Div/Scroll/CurrentDeck/LdDlt/LoadDeck.selected < 1:
		return
	Resources.decks.remove_at(deck_indice-1)
	clear_current_deck()
	load_deck_options()
