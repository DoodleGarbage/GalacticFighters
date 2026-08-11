extends Control

## This is loaded by the main_menu script
var deck_list : Array[Deck] = [] :
	get():
		return Resources.decks

func _ready() -> void:
	load_decks()

const deck_gui := preload("res://GUI/mini_deck.tscn")
func load_decks() -> void:
	for deck in deck_list:
		var non_spec_char : int = 0
		for chars in deck.characters:
			if chars.type == 1:
				non_spec_char += 1
		if non_spec_char < 3:
			print("A deck with less than 3 units tried to load! Name: ", deck.name)
			continue
		var new_dgui = deck_gui.instantiate()
		new_dgui.load_deck(deck)
		new_dgui.get_node("Selector").pressed.connect(deck_selected.bind(deck))
		$List/DeckLister.add_child(new_dgui)

signal battle_deck(deck:Deck)
func deck_selected(deck:Deck) -> void:
	battle_deck.emit(deck)
	return
