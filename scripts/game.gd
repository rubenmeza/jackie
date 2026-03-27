extends Control

## Orchestrates a full Blackjack round:
##   BETTING → DEALING → PLAYER_TURN → DEALER_TURN → RESULT

const CARD_SCENE := preload("res://scenes/components/Card.tscn")

# Node references
@onready var _dealer_score: Label = $DealerArea/DealerScoreLabel
@onready var _dealer_hand: HBoxContainer = $DealerArea/DealerHand
@onready var _player_hand: HBoxContainer = $PlayerArea/PlayerHand
@onready var _player_score: Label = $PlayerArea/PlayerScoreLabel
@onready var _chips_label: Label = $HUD/ChipsLabel
@onready var _bet_label: Label = $HUD/BetLabel
@onready var _bet_buttons: HBoxContainer = $HUD/BetButtons
@onready var _deal_btn: Button = $HUD/ActionButtons/DealBtn
@onready var _hit_btn: Button = $HUD/ActionButtons/HitBtn
@onready var _stand_btn: Button = $HUD/ActionButtons/StandBtn
@onready var _double_btn: Button = $HUD/ActionButtons/DoubleBtn
@onready var _hint_bar: Label = $HUD/HintBar
@onready var _result_overlay: PanelContainer = $HUD/ResultOverlay
@onready var _result_label: Label = $HUD/ResultOverlay/ResultVBox/ResultLabel
@onready var _next_round_btn: Button = $HUD/ResultOverlay/ResultVBox/NextRoundBtn
@onready var _menu_btn: Button = $HUD/ResultOverlay/ResultVBox/MenuBtn

# Logic objects
var _deck: Deck
var _player: Hand
var _dealer: Dealer


func _ready() -> void:
	_deck = Deck.new()
	_player = Hand.new()
	_dealer = Dealer.new()

	# Bet buttons
	$HUD/BetButtons/Bet10Btn.pressed.connect(func(): _add_bet(10))
	$HUD/BetButtons/Bet50Btn.pressed.connect(func(): _add_bet(50))
	$HUD/BetButtons/Bet100Btn.pressed.connect(func(): _add_bet(100))
	$HUD/BetButtons/ClearBetBtn.pressed.connect(_on_clear_bet_pressed)

	# Action buttons
	_deal_btn.pressed.connect(_on_deal_pressed)
	_hit_btn.pressed.connect(_on_hit_pressed)
	_stand_btn.pressed.connect(_on_stand_pressed)
	_double_btn.pressed.connect(_on_double_pressed)

	# Result buttons
	_next_round_btn.pressed.connect(_on_next_round_pressed)
	_menu_btn.pressed.connect(_on_menu_pressed)

	# GameState signals
	GameState.chips_changed.connect(func(v): _chips_label.text = "Chips: %d" % v)
	GameState.bet_changed.connect(func(v): _bet_label.text = "Bet: %d" % v)

	_chips_label.text = "Chips: %d" % GameState.chips
	_bet_label.text = "Bet: 0"

	_enter_betting_phase()


# ─── BETTING PHASE ───────────────────────────────────────────────────────────

func _enter_betting_phase() -> void:
	GameState.set_phase(GameState.Phase.BETTING)
	GameState.reset()

	_clear_hands()

	_bet_buttons.show()
	_deal_btn.show()
	_deal_btn.disabled = true
	_hit_btn.hide()
	_stand_btn.hide()
	_double_btn.hide()
	_result_overlay.hide()

	_dealer_score.text = "Dealer"
	_player_score.text = "Your Hand"
	_hint_bar.text = "Place your bet, then press DEAL."


func _add_bet(amount: int) -> void:
	if not GameState.place_bet(amount):
		_hint_bar.text = "Not enough chips!"
		return
	_deal_btn.disabled = false
	_hint_bar.text = "Bet: %d — add more or press DEAL." % GameState.current_bet


func _on_clear_bet_pressed() -> void:
	GameState.clear_bet()
	_deal_btn.disabled = true
	_hint_bar.text = "Bet cleared. Place a new bet."


# ─── DEALING ─────────────────────────────────────────────────────────────────

func _on_deal_pressed() -> void:
	if GameState.current_bet <= 0:
		return

	GameState.commit_bet()
	GameState.set_phase(GameState.Phase.DEALING)

	_player.clear()
	_dealer.reset()

	# Deal: player, dealer, player, dealer(face-down)
	_deal_to(_player, _player_hand, true)
	_deal_to(_dealer.hand, _dealer_hand, true)
	_deal_to(_player, _player_hand, true)
	_deal_to(_dealer.hand, _dealer_hand, false)  # hole card

	_bet_buttons.hide()
	_deal_btn.hide()
	_update_scores()

	if _player.is_blackjack():
		_hint_bar.text = "Blackjack! Let's see the dealer..."
		_run_dealer_turn()
		return

	_enter_player_turn()


func _deal_to(hand: Hand, node: HBoxContainer, face_up: bool) -> void:
	var data := _deck.deal()
	hand.add_card(data)
	var card: CardDisplay = CARD_SCENE.instantiate()
	node.add_child(card)
	card.setup(data, face_up)


# ─── PLAYER TURN ─────────────────────────────────────────────────────────────

func _enter_player_turn() -> void:
	GameState.set_phase(GameState.Phase.PLAYER_TURN)
	_hit_btn.show()
	_stand_btn.show()
	_double_btn.show()
	_double_btn.disabled = GameState.chips < (GameState.current_bet / 2)
	_show_hint()


func _on_hit_pressed() -> void:
	_deal_to(_player, _player_hand, true)
	_update_scores()
	_double_btn.disabled = true  # can't double after hitting

	if _player.is_bust():
		_hint_bar.text = "Bust! You went over 21."
		_end_round()
		return

	_show_hint()


func _on_stand_pressed() -> void:
	_run_dealer_turn()


func _on_double_pressed() -> void:
	if not GameState.double_bet():
		_hint_bar.text = "Not enough chips to double!"
		return
	_deal_to(_player, _player_hand, true)
	_update_scores()
	if _player.is_bust():
		_hint_bar.text = "Bust after double!"
		_end_round()
		return
	_run_dealer_turn()


# ─── DEALER TURN ─────────────────────────────────────────────────────────────

func _run_dealer_turn() -> void:
	GameState.set_phase(GameState.Phase.DEALER_TURN)
	_hit_btn.hide()
	_stand_btn.hide()
	_double_btn.hide()

	# Reveal hole card
	var hole := _dealer_hand.get_child(1) as CardDisplay
	if hole:
		hole.flip()

	# Dealer draws until standing
	while _dealer.should_hit():
		_deal_to(_dealer.hand, _dealer_hand, true)

	_update_scores(true)
	_end_round()


# ─── RESULT ──────────────────────────────────────────────────────────────────

func _end_round() -> void:
	GameState.set_phase(GameState.Phase.RESULT)

	var pv := _player.get_value()
	var dv := _dealer.hand.get_value()
	var result_text := ""

	if _player.is_blackjack() and not _dealer.hand.is_blackjack():
		result_text = "BLACKJACK!\n+%d chips" % int(GameState.current_bet * 1.5)
		GameState.resolve(2.5)
	elif _player.is_bust():
		result_text = "BUST!\n–%d chips" % GameState.current_bet
		GameState.resolve(0.0)
	elif _dealer.hand.is_blackjack() and not _player.is_blackjack():
		result_text = "DEALER BLACKJACK!\n–%d chips" % GameState.current_bet
		GameState.resolve(0.0)
	elif _dealer.hand.is_bust():
		result_text = "DEALER BUSTS!\n+%d chips" % GameState.current_bet
		GameState.resolve(2.0)
	elif pv > dv:
		result_text = "YOU WIN!\n+%d chips" % GameState.current_bet
		GameState.resolve(2.0)
	elif pv < dv:
		result_text = "YOU LOSE!\n–%d chips" % GameState.current_bet
		GameState.resolve(0.0)
	else:
		result_text = "PUSH\nBet returned"
		GameState.resolve(1.0)

	_result_label.text = result_text
	_result_overlay.show()

	if GameState.chips <= 0:
		_next_round_btn.text = "PLAY AGAIN"
		_hint_bar.text = "Out of chips! Starting over with 500."
	else:
		_next_round_btn.text = "NEXT ROUND"


func _on_next_round_pressed() -> void:
	if GameState.chips <= 0:
		GameState.chips = 500
		GameState.chips_changed.emit(500)
	_enter_betting_phase()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


# ─── HELPERS ─────────────────────────────────────────────────────────────────

func _clear_hands() -> void:
	for child in _dealer_hand.get_children():
		child.queue_free()
	for child in _player_hand.get_children():
		child.queue_free()


func _update_scores(reveal_dealer: bool = false) -> void:
	_player_score.text = "Your Hand: %d" % _player.get_value()
	if reveal_dealer:
		_dealer_score.text = "Dealer: %d" % _dealer.hand.get_value()
	elif _dealer.hand.size() > 0:
		var up_value: int = _dealer.hand.cards[0].value
		_dealer_score.text = "Dealer: %d + ?" % up_value


func _show_hint() -> void:
	var pv := _player.get_value()
	var dealer_up: int = _dealer.hand.cards[0].value if _dealer.hand.size() > 0 else 0
	_hint_bar.text = _basic_strategy_hint(pv, dealer_up, _player.is_soft())


func _basic_strategy_hint(pv: int, dealer_up: int, soft: bool) -> String:
	if soft:
		if pv >= 19:
			return "Soft %d → Stand." % pv
		if pv == 18:
			return "Soft 18 → Stand vs 2–8, Hit vs 9–A." % {}
		return "Soft %d → Hit to improve." % pv

	if pv >= 17:
		return "Hard %d → Stand. Don't risk busting." % pv
	if pv == 16 and dealer_up >= 7:
		return "Hard 16 vs dealer %d → Hit (dealer is strong)." % dealer_up
	if pv >= 13 and dealer_up <= 6:
		return "Hard %d vs dealer %d → Stand (dealer likely busts)." % [pv, dealer_up]
	if pv == 11:
		return "11 → Double Down for maximum value!"
	if pv == 10 and dealer_up <= 9:
		return "10 → Double Down — great spot!"
	if pv == 9 and dealer_up >= 3 and dealer_up <= 6:
		return "9 vs dealer %d → Double Down." % dealer_up
	if pv <= 8:
		return "Hard %d → Always Hit." % pv
	return "Hard %d → Hit." % pv
