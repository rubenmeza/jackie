extends RefCounted
class_name Hand

## Represents a player's or dealer's hand. Handles ace flexibility and value calculation.

var cards: Array[Dictionary] = []


func add_card(card: Dictionary) -> void:
	cards.append(card)


## Returns the best hand value (≤21 when possible via ace adjustment).
func get_value() -> int:
	var total := 0
	var aces := 0

	for card in cards:
		total += card.value
		if card.rank == "A":
			aces += 1

	# Convert aces from 11 to 1 as needed to avoid busting
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1

	return total


## True if the hand contains an ace currently counted as 11.
func is_soft() -> bool:
	var total := 0
	for card in cards:
		if card.rank == "A":
			if total + 11 <= 21:
				total += 11
			else:
				total += 1
		else:
			total += card.value
	# If our simplified total matches get_value and it's ≤21, it's soft
	return total <= 21 and total == get_value() and _has_ace()


func _has_ace() -> bool:
	for card in cards:
		if card.rank == "A":
			return true
	return false


func is_bust() -> bool:
	return get_value() > 21


func is_blackjack() -> bool:
	return cards.size() == 2 and get_value() == 21


func can_split() -> bool:
	return cards.size() == 2 and cards[0].rank == cards[1].rank


func size() -> int:
	return cards.size()


func clear() -> void:
	cards.clear()
