extends RefCounted
class_name Dealer

## Encapsulates the dealer AI. Dealer hits on hard ≤16 and soft 17.

var hand: Hand = Hand.new()


func should_hit() -> bool:
	var value := hand.get_value()
	if value < 17:
		return true
	# Hit on soft 17 (ace counted as 11, total is exactly 17)
	if value == 17 and hand.is_soft():
		return true
	return false


func reset() -> void:
	hand.clear()
