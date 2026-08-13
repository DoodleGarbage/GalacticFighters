extends Resource

class_name Deck

var mod : String = ""

@export var name : String = "DECKNAME"

## Has all characters (including special and mundane characters)
@export var characters : Array[Card] = []
@export var items : Array[Item] = []
@export var gadgets : Array[Item] = []
@export var sword : Item

static func to_str(dk:Deck) -> Array[String]:
	var string : Array[String] = []
	for chara in dk.characters:
		string.append("Character:" + chara.name)
	for gadg in dk.gadgets:
		string.append("Gadget:" + gadg.name)
	for item in dk.items:
		string.append("Item:"+item.name)
	if dk.sword != null:
		string.append("Sword:"+ dk.sword.name)
	return string
