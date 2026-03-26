extends RefCounted
class_name Deck

## A standard 52-card deck that reshuffles when exhausted.

const SUITS: Array[String] = ["♠", "♥", "♦", "♣"]
const RANKS: Array[String] = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const VALUES: Dictionary = {
	"A": 11, "2": 2, "3": 3, "4": 4, "5": 5,
	"6": 6, "7": 7, "8": 8, "9": 9, "10": 10,
	"J": 10, "Q": 10, "K": 10
}
const RED_SUITS: Array[String] = ["♥", "♦"]

var _cards: Array[Dictionary] = []


func _init(num_decks: int = 1) -> void:
	build(num_decks)


func build(num_decks: int = 1) -> void:
	_cards.clear()
	for _d in range(num_decks):
		for suit in SUITS:
			for rank in RANKS:
				_cards.append({
					"rank": rank,
					"suit": suit,
					"value": VALUES[rank],
					"is_red": suit in RED_SUITS
				})
	_cards.shuffle()


func deal() -> Dictionary:
	if _cards.is_empty():
		build()
	return _cards.pop_back()


func cards_remaining() -> int:
	return _cards.size()
