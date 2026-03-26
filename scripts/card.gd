extends Panel
class_name CardDisplay

## Visual representation of a playing card.
## All children are created in code so Card.tscn stays minimal.
## Size is fixed at 80×120 pixels.

const SIZE := Vector2(80.0, 120.0)

var _rank_top: Label
var _suit: Label
var _rank_bottom: Label
var _back: ColorRect


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE

	# White card face with rounded border
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.75, 0.75, 0.75)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	add_theme_stylebox_override("panel", style)

	_rank_top = Label.new()
	_rank_top.position = Vector2(4, 2)
	_rank_top.size = Vector2(36, 22)
	_rank_top.add_theme_font_size_override("font_size", 14)
	add_child(_rank_top)

	_suit = Label.new()
	_suit.position = Vector2(10, 38)
	_suit.size = Vector2(60, 44)
	_suit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_suit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_suit.add_theme_font_size_override("font_size", 30)
	add_child(_suit)

	_rank_bottom = Label.new()
	_rank_bottom.position = Vector2(40, 96)
	_rank_bottom.size = Vector2(36, 22)
	_rank_bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rank_bottom.add_theme_font_size_override("font_size", 14)
	add_child(_rank_bottom)

	# Card back — solid dark blue with a lighter inner rectangle
	_back = ColorRect.new()
	_back.color = Color(0.1, 0.18, 0.52)
	_back.position = Vector2(0, 0)
	_back.size = SIZE
	_back.visible = false
	add_child(_back)

	var inner := ColorRect.new()
	inner.color = Color(0.18, 0.28, 0.68)
	inner.position = Vector2(8, 8)
	inner.size = Vector2(64, 104)
	_back.add_child(inner)


func setup(card_data: Dictionary, face_up: bool) -> void:
	var rank: String = card_data["rank"]
	var suit: String = card_data["suit"]
	var color := Color(0.78, 0.08, 0.08) if card_data.get("is_red", false) else Color(0.1, 0.1, 0.1)

	_rank_top.text = rank
	_rank_top.add_theme_color_override("font_color", color)

	_suit.text = suit
	_suit.add_theme_color_override("font_color", color)

	_rank_bottom.text = rank
	_rank_bottom.add_theme_color_override("font_color", color)

	_back.visible = not face_up


func flip() -> void:
	_back.visible = false
