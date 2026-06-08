extends Control

@export
var player_deck : Array[Card] = []

@export
var enemy_deck : Array[Card] = []

var cards : Array[Control] = []

## Gets every docker in the scene
func get_dockers() -> Array[Docker]:
	var retr : Array[Docker] = []
	for child in get_children():
		if child is Docker:
			retr.append(child)
	return retr




const ui_scale = 0.5

const card_ui_scene := preload("res://GUI/Card/card.tscn")

func _ready() -> void:
	load_deck(player_deck, $PlayerField, true)
	load_deck(enemy_deck, $EnemyField)
	update_scale()
	update_dockers()

# Destination could also be the saferoom.
func load_deck(deck:Array[Card], docker:Docker, player_owned:bool=false) -> void:
	for card in deck:
		var new_card := card_ui_scene.instantiate()
		new_card.stored_card = card
		new_card.player_owned = player_owned
		new_card.scale = Vector2(ui_scale, ui_scale)
		new_card.interaction.connect(card_clicked.bind(new_card))
		add_child(new_card)
		new_card.stopped_dragging.connect(update_dockers)
		new_card.manager = self
		docker.assigned_cards.append(new_card)

var menu_open : bool = false
var active_interact_card : Card_GUI
var allow_drag : bool = true

# Called when a card is clicked with the interaction menu key/mouse
func card_clicked(_event: InputEvent, who:Control) -> void:
	var area := Rect2(Vector2(0,0), self.size)
	if area.has_point(get_local_mouse_position()):
		if not menu_open:
			active_interact_card = who
			open_interaction_menu()
			who.open_interaction_menu()
	return

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if menu_open and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			close_interaction_menu()
			active_interact_card.close_interaction_menu()


# Open the interaction menu!
func open_interaction_menu() -> void:
	menu_open = true
	allow_drag = false
	active_interact_card.position = get_viewport_rect().size * 0.5 - active_interact_card.size * 0.5
	active_interact_card.target_position = get_viewport_rect().size * 0.5 - active_interact_card.size * 0.5
	$Dimmer.show()
# Close it!
func close_interaction_menu() -> void:
	menu_open = false
	allow_drag = true
	update_dockers(true)
	$Dimmer.hide()

func update_dockers(force_movement:bool=false) -> void:
	for docker in get_dockers():
		var positions := docker.get_placements()
		for card in docker.assigned_cards.size():
			if force_movement:
				docker.assigned_cards[card].position = positions[card]
			docker.assigned_cards[card].target_position = positions[card]
	return

func update_scale(target:Node=self, ignore_restrictions:bool = false) -> void:
	for child:Control in target.get_children():
		if child is Card_GUI or ignore_restrictions:
			child.scale = Vector2(ui_scale, ui_scale)
