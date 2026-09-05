class_name TrekScanner
extends Control
signal cell_selected(cell: Vector2i)
var sim: TrekSimulation
var galaxy_mode = false
var hover = Vector2i(-1, -1)
var font: Font = ThemeDB.fallback_font
const CYAN = Color("6fd8e8")
const MUTED = Color("496579")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func(): hover = Vector2i(-1, -1); queue_redraw())

func bounds() -> Rect2:
	var side = minf(size.x - 22, size.y - 22)
	return Rect2(Vector2(22, 22), Vector2.ONE * side)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var rect = bounds()
		var local = (event.position - rect.position) / (rect.size.x / 8)
		hover = Vector2i(int(floor(local.y)), int(floor(local.x)))
		queue_redraw()
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and hover.x >= 0 and hover.x < 8 and hover.y >= 0 and hover.y < 8:
			cell_selected.emit(hover)

func _draw() -> void:
	if sim == null or sim.galaxy.is_empty(): return
	var rect = bounds()
	var step = rect.size.x / 8
	for i in 8:
		draw_string(font, Vector2(rect.position.x + i * step + step * 0.38, 13), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
		draw_string(font, Vector2(5, rect.position.y + i * step + step * 0.65), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
	for r in 8:
		for c in 8:
			var cell = Vector2i(r, c)
			var box = Rect2(rect.position + Vector2(c, r) * step, Vector2.ONE * (step - 2))
			var color = Color("0a1723")
			var selected = sim.quadrant if galaxy_mode else sim.sector
			if cell == selected: color = Color("154350")
			elif cell == hover: color = Color("1c3548")
			draw_rect(box, color)
			if cell == selected: draw_rect(box, CYAN, false, 1)
			var center = box.get_center()
			if galaxy_mode:
				var value: String = sim.chart.get(str(r * 8 + c), "···") if sim.systems.computer >= 50 else "---"
				var ink = MUTED if value == "···" else Color("a3b8c7")
				if value[0].is_valid_int() and int(value[0]) > 0: ink = Color("f08485")
				elif value[1].is_valid_int() and int(value[1]) > 0: ink = Color("edc18b")
				var text_size = 10 if step < 36 else 12
				draw_string(font, center - Vector2(font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x / 2, -4), value, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, ink)
			else:
				if cell == sim.sector:
					var ink = Color("f6d098") if sim.shields_up else CYAN
					draw_colored_polygon(PackedVector2Array([center + Vector2(0,-7), center + Vector2(6,5), center + Vector2(0,2), center + Vector2(-6,5)]), ink)
				for obj in sim.visible_objects():
					if sim.position_of(obj) != cell: continue
					match obj.kind:
						"star":
							draw_circle(center, 3, Color("d3b58e"))
							draw_line(center - Vector2(6,0), center + Vector2(6,0), Color("65574d"))
							draw_line(center - Vector2(0,6), center + Vector2(0,6), Color("65574d"))
						"base":
							draw_arc(center, 6, 0, TAU, 24, Color("74d4b0"), 1.5)
							draw_rect(Rect2(center - Vector2.ONE * 2, Vector2.ONE * 4), Color("74d4b0"))
						"planet": draw_circle(center, 5, Color("738fce"))
						_:
							var ink = {"cruiser": Color("80c7f4"), "command": Color("ff717c"), "scout": Color("b292e7"), "supply": Color("71c797")}.get(obj.kind, Color.WHITE)
							draw_polyline(PackedVector2Array([center + Vector2(-6,-4), center + Vector2(0,4), center + Vector2(6,-4)]), ink, 2)
