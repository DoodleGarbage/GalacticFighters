extends Control

## This is loaded by the main_menu script
var deck_list : Array[Deck] = [] :
	set(value):
		deck_list = value
		load_decks()

func _ready() -> void:
	load_decks()

const deck_gui := preload("res://GUI/mini_deck.tscn")
func load_decks() -> void:
	for deck in deck_list:
		var new_dgui = deck_gui.instantiate()
		new_dgui.load_deck(deck)
		new_dgui.get_node("Selector").pressed.connect(deck_selected.bind(deck))
		$List/DeckLister.add_child(new_dgui)

signal battle_deck(deck:Deck)
func deck_selected(deck:Deck) -> void:
	battle_deck.emit(deck)
	return
