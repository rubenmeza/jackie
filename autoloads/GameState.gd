extends Node

## Global game state shared across all scenes.
## Handles chips, bets, and the current game phase.

enum Phase { BETTING, DEALING, PLAYER_TURN, DEALER_TURN, RESULT }

var chips: int = 500
var current_bet: int = 0
var phase: Phase = Phase.BETTING

signal chips_changed(new_amount: int)
signal bet_changed(new_bet: int)
signal phase_changed(new_phase: Phase)


func place_bet(amount: int) -> bool:
	if current_bet + amount > chips:
		return false
	current_bet += amount
	bet_changed.emit(current_bet)
	return true


func clear_bet() -> void:
	current_bet = 0
	bet_changed.emit(0)


## Called when the deal button is pressed. Removes the bet from chips.
func commit_bet() -> void:
	chips -= current_bet
	chips_changed.emit(chips)


## Doubles the current bet by deducting the same amount again from chips.
## Returns false if the player cannot afford to double.
func double_bet() -> bool:
	if chips < current_bet:
		return false
	chips -= current_bet
	current_bet *= 2
	chips_changed.emit(chips)
	return true


## Pays out the round result.
## multiplier: 0 = loss, 1 = push, 2 = win, 2.5 = blackjack
func resolve(multiplier: float) -> void:
	var payout := int(current_bet * multiplier)
	chips += payout
	current_bet = 0
	chips_changed.emit(chips)
	bet_changed.emit(0)


func set_phase(new_phase: Phase) -> void:
	phase = new_phase
	phase_changed.emit(new_phase)


func reset() -> void:
	current_bet = 0
	bet_changed.emit(0)
