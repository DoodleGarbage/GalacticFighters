extends Resource

class_name Deck

@export
var name : String = "DECKNAME"

@export
var special_characters : Array[Card] = []
#@export
#var items : Array[Item] = []
#@export
#var gadgets : Array[Gadget] = []
#@export
#var sword : Sword

func to_text() -> Array[String]:
	var output : Array[String] = []
	for card in special_characters:
		output.append("SpecialCharacter:" + card.name)
	return output
