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
		string.append("Character:" + chara.mod_name())
	for gadg in dk.gadgets:
		string.append("Gadget:" + gadg.mod_name())
	for item in dk.items:
		string.append("Item:"+item.mod_name())
	if dk.sword != null:
		string.append("Sword:"+dk.sword.mod_name())
	return string

static func from_str(deck:Array[String]) -> Deck:
	var zombie : Deck = Deck.new()
	for card in deck:
		var split := card.split(":",false,1)
		match(split[0]):
			"Character":
				var chara = Resources.find_resource(split[0], split[1])
				if chara != null:
					zombie.characters.append(chara)
			"Item":
				var item = Resources.find_resource(split[0], split[1])
				if item != null:
					zombie.items.append(item)
			"Gadget":
				var gadget = Resources.find_resource("Item", split[1])
				if gadget != null:
					zombie.gadgets.append(gadget)
			"Sword":
				var swrd = Resources.find_resource("Item", split[1])
				if swrd != null:
					zombie.sword = swrd
	return zombie

static func to_dict(deck:Deck) -> Dictionary:
	var dict : Dictionary = {}
	dict.get_or_add("Name", deck.name)
	dict.get_or_add("Deck", Deck.to_str(deck))
	return dict
