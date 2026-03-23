extends Node

func _start_pressed() -> void:
	$Menu/VBoxContainer/Start.hide()
	#$VBoxContainer/MenuSpacer.hide()
	$Menu/VBoxContainer/AccessedMenu.show()

func hide_all() -> void:
	$Menu.hide()
	$Deck.hide()
	$BattleSelect.hide()
	$Playfield.hide()
	$Waiting.hide()

func _on_deck_pressed() -> void:
	hide_all()
	$Deck.show()

func return_to_menu() -> void:
	hide_all()
	$Menu.show()

func prepare_battle() -> void:
	hide_all()
	$BattleSelect.show()

var prepared_deck : Deck
func ready_for_battle(deck:Deck) -> void:
	hide_all()
	# Show "Waiting on other player. Your Deck: DECK"
	# Multiplayer stuff
	prepared_deck = deck
	#local_peer_send "I am ready" message
	$Waiting/VBoxContainer/MiniDeck.load_deck(deck)
	$Waiting.show()
