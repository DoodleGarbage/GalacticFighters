extends PanelContainer

var loaded_card : Card

func load_card(card:Card) -> void:
	loaded_card = card
	$Div/Icon.texture = loaded_card.mini_profile
	$Div/Name.text = tr(loaded_card.name)
	$FullCard.load_card(loaded_card)

func switch(mode:bool=false) -> void:
	if mode:
		$FullCard.show()
		$Div.hide()
		return
	$FullCard.hide()
	$Div.show()
