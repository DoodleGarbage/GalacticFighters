extends Control

@export
var player_deck : Array[Card] = []

@export
var enemy_deck : Array[Card] = []

const ui_scale = 0.5

const card_ui_scene := preload("res://GUI/Card/card.tscn")

func _ready() -> void:
	load_deck(player_deck, $PlayerField, true)
	load_deck(enemy_deck, $EnemyField)
	update_scale()

# Destination could also be the saferoom.
func load_deck(deck:Array[Card], destination:Control, player_owned:bool=false) -> void:
	for card in deck:
		var new_card = card_ui_scene.instantiate()
		new_card.stored_card = card
		new_card.player_owned = player_owned
		new_card.scale = Vector2(ui_scale, ui_scale)
		add_child(new_card)
		new_card.docker = destination
		destination.main_nodes.append(new_card)


func update_scale() -> void:
	for child:Control in get_children():
		child.scale = Vector2(ui_scale, ui_scale)
