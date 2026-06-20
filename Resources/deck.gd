extends Resource

class_name Deck

@export
var name : String = "DECKNAME"

## Has all characters (including special and mundane characters)
@export
var characters : Array[Card] = []
@export
var items : Array[Item] = []
@export
var gadgets : Array[Item] = []
@export
var sword : Item
