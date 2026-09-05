extends Control
const Simulation = preload("res://scripts/simulation.gd")
const Space = preload("res://scripts/space_view.gd")
const Scanner = preload("res://scripts/scanner.gd")
const CYAN = Color("79d9e9")
const TEXT = Color("dfebf0")
const MUTED = Color("7792a6")
const GOLD = Color("e9bd87")
var sim = Simulation.new()
var space: SpaceView
var command: LineEdit
var comms: RichTextLabel
var status: Label
var location_label: Label
var mission_label: Label
var target_label: Label
var energy_label: Label
var shield_label: Label
var torp_label: Label
var heat_label: Label
var laser_label: Label
var crew_label: Label
var bars: Dictionary = {}
var system_labels: Dictionary = {}
var tactical: TrekScanner
var galaxy: TrekScanner
var dialog: AcceptDialog
var new_dialog: ConfirmationDialog
var difficulty: OptionButton
var seed_input: LineEdit
var pending = ""
var viewport: SubViewport
var soundtrack: AudioStreamPlayer
var submitted_history: Array[String] = []
var history_index = 0

func _ready() -> void:
	build_theme()
	build_ui()
	sim.changed.connect(refresh)
	sim.effect.connect(space.play_effect)
	sim.effect.connect(play_sound)
	sim.new_game()
	command.grab_focus()
	if "--smoke-test" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		sim.execute("MAX")
		sim.execute("SHUP")
		sim.execute("LASERS 900 650")
		await get_tree().create_timer(1.0).timeout
		print("BRIDGE_SMOKE_OK")
		get_tree().quit()
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().create_timer(3.0).timeout
		get_viewport().get_texture().get_image().save_png("res://docs/bridge-preview.png")
		print("CAPTURE_OK")
		get_tree().quit()

func style(bg: Color, border: Color = Color("213848"), radius: int = 8) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

func build_theme() -> void:
	var t = Theme.new()
	t.default_font_size = 15
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_stylebox("normal", "Button", style(Color("102332")))
	t.set_stylebox("hover", "Button", style(Color("1c4050"), CYAN))
	t.set_stylebox("pressed", "Button", style(Color("235569"), CYAN))
	t.set_stylebox("focus", "Button", style(Color(0,0,0,0), CYAN))
	t.set_stylebox("normal", "LineEdit", style(Color("07121e"), Color("345569")))
	t.set_stylebox("focus", "LineEdit", style(Color("0b1d2a"), CYAN))
	t.set_color("font_color", "LineEdit", CYAN)
	t.set_color("font_placeholder_color", "LineEdit", MUTED)
	t.set_stylebox("panel", "AcceptDialog", style(Color("0b1b29")))
	t.set_stylebox("panel", "PopupMenu", style(Color("0b1b29")))
	var bar_bg = style(Color("152936"), Color("152936"), 2)
	bar_bg.content_margin_top = 0
	bar_bg.content_margin_bottom = 0
	t.set_stylebox("background", "ProgressBar", bar_bg)
	theme = t

func label(text: String, font_size: int = 15, color: Color = TEXT) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func button(text: String, action: Callable, parent: Node) -> Button:
	var b = Button.new()
	b.text = text
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func panel(parent: Node, title: String) -> VBoxContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(Color("0b1927")))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	if not title.is_empty(): v.add_child(label(title, 12, MUTED))
	return v

func expanding_spacer(parent: Node) -> void:
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)

func build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color("050e18")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	root.add_child(header)
	header.add_child(label("V /", 37, CYAN))
	var brand = VBoxContainer.new()
	header.add_child(brand)
	brand.add_child(label("V U L K A N T R E K", 24))
	brand.add_child(label("U N I O N   F L E E T   /   C O M M A N D   B R I D G E", 10, MUTED))
	expanding_spacer(header)
	status = label("●  CONDITION RED", 13, Color("f18d93"))
	header.add_child(status)
	button("NEW MISSION", show_new_mission, header)
	button("RESTORE", restore_mission, header)
	button("F1  REFERENCE", show_help, header)
	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)
	var left = VBoxContainer.new()
	left.custom_minimum_size.x = 280
	left.add_theme_constant_override("separation", 16)
	body.add_child(left)
	var assignment = panel(left, "01  /  MISSION CONTROL")
	assignment.add_child(label("THE INVASION", 22))
	mission_label = label("")
	assignment.add_child(mission_label)
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	assignment.add_child(label("LEXINGTON  /  RCB-92", 12, CYAN))
	var short_panel = panel(left, "02  /  SHORT-RANGE SCAN")
	tactical = Scanner.new()
	tactical.sim = sim
	tactical.custom_minimum_size = Vector2(248, 245)
	tactical.cell_selected.connect(func(cell): fill_command("MOVE %d,%d" % [cell.x + 1, cell.y + 1]))
	short_panel.add_child(tactical)
	short_panel.add_child(label("Click a sector to plot an impulse course.", 11, MUTED))
	var repair_panel = panel(left, "03  /  SYSTEM INTEGRITY")
	for key in Simulation.SYSTEMS:
		var line = HBoxContainer.new()
		repair_panel.add_child(line)
		line.add_child(label(key.replace("_", " ").capitalize(), 12, MUTED))
		expanding_spacer(line)
		var value = label("100%", 12, CYAN)
		line.add_child(value)
		system_labels[key] = value
	repair_panel.add_theme_constant_override("separation", 5)
	var center = VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 16)
	body.add_child(center)
	var view_panel = panel(center, "04  /  TACTICAL VIEWPORT")
	view_panel.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	var view_header = HBoxContainer.new()
	view_panel.add_child(view_header)
	location_label = label("", 20)
	view_header.add_child(location_label)
	expanding_spacer(view_header)
	button("TACTICAL / CINEMATIC", func(): space.cinematic = not space.cinematic, view_header).add_theme_font_size_override("font_size", 11)
	var container = SubViewportContainer.new()
	container.custom_minimum_size = Vector2(400, 330)
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.stretch = true
	view_panel.add_child(container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(850, 500)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	container.add_child(viewport)
	space = Space.new()
	space.sim = sim
	viewport.add_child(space)
	target_label = label("", 12, MUTED)
	view_panel.add_child(target_label)
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	view_panel.add_child(actions)
	for item in [["F2  LASERS", "LASERS"], ["F3  TORPEDO", "TORPEDO"], ["↑  SHIELDS", "SHUP"], ["F10  DOCK", "DOCK"]]:
		var command_name: String = item[1]
		var b = button(item[0], func(): prepare_command(command_name), actions)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 12)
	var console = panel(center, "05  /  CAPTAIN’S CONSOLE")
	comms = RichTextLabel.new()
	comms.bbcode_enabled = true
	comms.custom_minimum_size.y = 110
	comms.scroll_following = true
	comms.add_theme_font_size_override("normal_font_size", 13)
	console.add_child(comms)
	var input_row = HBoxContainer.new()
	console.add_child(input_row)
	input_row.add_child(label("❯", 24, CYAN))
	command = LineEdit.new()
	command.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command.placeholder_text = "Enter command · e.g. MAX, SHUP, M35"
	command.text_submitted.connect(submit)
	input_row.add_child(command)
	button("EXECUTE ↵", func(): submit(command.text), input_row)
	console.add_child(label("Time advances with orders. Take your time, Captain.", 11, MUTED))
	var right = VBoxContainer.new()
	right.custom_minimum_size.x = 280
	right.add_theme_constant_override("separation", 16)
	body.add_child(right)
	var galaxy_panel = panel(right, "06  /  GALACTIC CARTOGRAPHY")
	galaxy = Scanner.new()
	galaxy.sim = sim
	galaxy.galaxy_mode = true
	galaxy.custom_minimum_size = Vector2(248, 245)
	galaxy.cell_selected.connect(func(cell): fill_command("MOVE %d,%d,4,4" % [cell.x + 1, cell.y + 1]))
	galaxy_panel.add_child(galaxy)
	galaxy_panel.add_child(label("HOSTILES  /  BASE TYPE  /  STARS", 10, MUTED))
	galaxy_panel.add_child(label("··· Uncharted    □ Current quadrant", 11, MUTED))
	var engineering = panel(right, "07  /  POWER & RESERVES")
	energy_label = gauge(engineering, "MAIN ENERGY", "energy", Simulation.MAIN_CAP, CYAN)
	shield_label = gauge(engineering, "SHIELD ENERGY", "shields", Simulation.SHIELD_CAP, Color("7ba8f2"))
	laser_label = gauge(engineering, "LASER BANKS", "lasers", Simulation.LASER_CAP, Color("b697e5"))
	heat_label = gauge(engineering, "LASER TEMPERATURE", "heat", 120, GOLD)
	torp_label = label("", 14, GOLD)
	engineering.add_child(torp_label)
	crew_label = label("", 12, MUTED)
	engineering.add_child(crew_label)
	var tools_row = HBoxContainer.new()
	engineering.add_child(tools_row)
	button("F5  MAX", func(): submit("MAX"), tools_row).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("F6  FIX", func(): prepare_command("FIX"), tools_row).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var orders = panel(right, "QUICK ORDERS")
	var row = HBoxContainer.new()
	orders.add_child(row)
	button("HAIL", func(): submit("HAIL"), row).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("SAVE", save_mission, row).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("LOG", show_log, row).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var footer = HBoxContainer.new()
	root.add_child(footer)
	footer.add_child(label("RCB-92   /   DEEP SPACE OPERATIONS", 10, MUTED))
	expanding_spacer(footer)
	footer.add_child(label("COMMAND STRATEGY    ·    EGATREK 3.1 RECONSTRUCTION", 10, MUTED))
	dialog = AcceptDialog.new()
	dialog.min_size = Vector2i(720, 580)
	add_child(dialog)
	new_dialog = ConfirmationDialog.new()
	new_dialog.title = "Commission a new mission"
	new_dialog.dialog_text = "A new mission replaces your current bridge session. Save first to keep it."
	new_dialog.min_size = Vector2i(520, 260)
	add_child(new_dialog)
	var new_options = VBoxContainer.new()
	new_options.position = Vector2(20, 65)
	new_options.custom_minimum_size.x = 470
	new_dialog.add_child(new_options)
	new_options.add_child(label("Command level"))
	difficulty = OptionButton.new()
	for rank_name in ["1 · Lieutenant Commander", "2 · Commander", "3 · Captain", "4 · Commodore", "5 · Admiral"]: difficulty.add_item(rank_name)
	difficulty.select(2)
	new_options.add_child(difficulty)
	new_options.add_child(label("Mission seed · replay the same galaxy"))
	seed_input = LineEdit.new()
	seed_input.text = "1994"
	new_options.add_child(seed_input)
	new_dialog.confirmed.connect(func():
		if not seed_input.text.is_valid_int():
			show_text("Invalid seed", "Enter an integer mission seed.")
			return
		sim.new_game(int(seed_input.text), difficulty.selected + 1)
		pending = ""
		command.clear()
		command.grab_focus())
	soundtrack = AudioStreamPlayer.new()
	soundtrack.volume_db = -24
	add_child(soundtrack)

func gauge(parent: Node, title: String, key: String, maximum: float, tint: Color) -> Label:
	var row = HBoxContainer.new()
	parent.add_child(row)
	row.add_child(label(title, 10, MUTED))
	expanding_spacer(row)
	var value = label("", 12, tint)
	row.add_child(value)
	var progress = ProgressBar.new()
	progress.max_value = maximum
	progress.show_percentage = false
	progress.custom_minimum_size.y = 5
	var fill = style(tint, tint, 2)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	progress.add_theme_stylebox_override("fill", fill)
	parent.add_child(progress)
	bars[key] = progress
	return value

func refresh() -> void:
	if not is_instance_valid(command): return
	mission_label.text = "%02d hostile vessels remaining\nStardate %.2f\nMission time  %.2f days" % [sim.remaining(), sim.stardate, sim.elapsed]
	location_label.text = "QUADRANT %02d.%02d" % [sim.quadrant.x + 1, sim.quadrant.y + 1]
	var condition = "DOCKED" if sim.docked > 0 else ("RED" if not sim.enemies_in(sim.current()).is_empty() else "GREEN")
	if sim.ended: condition = "MISSION COMPLETE" if sim.won else "SHIP LOST"
	status.text = "●  " + condition
	status.add_theme_color_override("font_color", Color("f18d93") if condition in ["RED", "SHIP LOST"] else CYAN)
	energy_label.text = "%04d / 5000" % sim.energy
	shield_label.text = "%04d  ·  %s" % [sim.shields, "UP" if sim.shields_up else "DOWN"]
	laser_label.text = "%04d / 2000" % sim.laser_energy
	heat_label.text = "%d%%" % (sim.heat / 120 * 100)
	torp_label.text = "%02d  ENTORPS    /    WARP %.1f" % [sim.torpedoes, sim.warp]
	crew_label.text = "%d crew  ·  %.1fd life reserves\n%d energium  ·  %d rescued" % [sim.crew, sim.reserves, sim.crystals, sim.rescued]
	bars.energy.value = sim.energy
	bars.shields.value = sim.shields
	bars.lasers.value = sim.laser_energy
	bars.heat.value = sim.heat
	for key in system_labels:
		system_labels[key].text = "%d%%" % sim.systems[key]
		system_labels[key].add_theme_color_override("font_color", CYAN if sim.systems[key] >= 100 else GOLD)
	comms.clear()
	for line in sim.messages:
		var split = line.split("  /  ", true, 1)
		comms.append_text("[color=#79d9e9]" + split[0] + "[/color]  " + escape_bbcode(split[1]) + "\n")
	target_label.text = "SECTOR %d.%d   /   %d LOCAL CONTACTS   /   %s" % [sim.sector.x + 1, sim.sector.y + 1, sim.enemies_in(sim.visible_objects()).size(), "ORBIT ESTABLISHED" if sim.orbiting else "AWAITING ORDERS"]
	if sim.ended: target_label.text = "MISSION %s  /  SCORE %d  /  NEW MISSION TO REDEPLOY" % ["COMPLETE" if sim.won else "FAILED", sim.score()]
	tactical.queue_redraw()
	galaxy.queue_redraw()
	space.refresh()

func escape_bbcode(value: String) -> String:
	return value.replace("[", "[lb]")

func fill_command(text: String) -> void:
	pending = ""
	command.text = text
	command.caret_column = text.length()
	command.grab_focus()

func prepare_command(cmd: String) -> void:
	if cmd in ["SHUP", "SHDN", "DOCK", "MAX", "REPAIR", "HAIL"]:
		submit(cmd)
		return
	pending = cmd
	var instructions = {"MOVE": "Destination row,column or q-row,q-column,row,column", "LASERS": "Energy for each target in INFO order, separated by spaces", "TORPEDO": "Target row,column · up to three pairs", "FIX": "System name or all, then stardays (e.g. all 0.5)", "ENERGY": "SHIELDS or LASERS, then signed energy amount", "WARP": "Warp factor 1–8"}
	command.clear()
	command.placeholder_text = instructions.get(cmd, "Parameters")
	sim.log_message("COMPUTER", cmd + " / " + instructions.get(cmd, "Enter parameters."))
	if cmd == "LASERS": sim.execute("INFO")
	refresh()
	command.grab_focus()

func submit(text: String) -> void:
	if text.strip_edges().is_empty(): return
	var full = text.strip_edges()
	if pending != "": full = pending + " " + full
	pending = ""
	command.placeholder_text = "Enter command · e.g. MAX, SHUP, M35"
	command.clear()
	submitted_history.append(full)
	history_index = submitted_history.size()
	match full.to_upper():
		"HELP": show_help()
		"MSGS": show_log()
		"CHART", "C": show_chart()
		"SAVE": save_mission()
		"QUIT", "Q": get_tree().quit()
		"MOVE", "M": prepare_command("MOVE")
		"LASERS", "L": prepare_command("LASERS")
		"TORPEDO", "T": prepare_command("TORPEDO")
		"FIX", "F": prepare_command("FIX")
		"WARP", "W": prepare_command("WARP")
		_: sim.execute(full)
	command.grab_focus()

func show_text(title: String, text: String) -> void:
	dialog.title = title
	for child in dialog.get_children():
		if child is RichTextLabel:
			dialog.remove_child(child)
			child.queue_free()
	dialog.dialog_text = ""
	var content = RichTextLabel.new()
	content.bbcode_enabled = true
	content.text = text
	content.custom_minimum_size = Vector2(700, 510)
	content.add_theme_color_override("default_color", TEXT)
	dialog.add_child(content)
	dialog.popup_centered()

func show_help() -> void:
	show_text("Captain’s reference", "[font_size=25][color=#79d9e9]YOUR BRIDGE. YOUR COMMAND.[/color][/font_size]\n\nEliminate the invasion fleet. Your orders advance time; the graphics do not. All coordinates are row first, from 1 to 8.\n\n[color=#e9bd87]FIRST ENCOUNTER[/color]\nMAX → SHUP → INFO → LASERS 900 650\nReplenish laser energy with ENERGY LASERS 1000. Plot a clear course adjacent to the green station and DOCK to resupply.\n\n[color=#e9bd87]NAVIGATION[/color]\nF4 / MOVE 3,5 (or M35): local impulse movement.\nMOVE 6,2,3,5: warp to quadrant 6,2 sector 3,5.\nMOVE M 1.0 -2.2: manual relative navigation.\nF9 / WARP 5.2: set speed; above warp 6 risks damage.\n↑ SHUP / ↓ SHDN: raise or lower shields.\n\n[color=#e9bd87]TACTICAL[/color]\nINFO: target list, in firing order.\nF2 / LASERS: prompts for energy allocated to each target; 0 skips.\nF3 / TORPEDO 3,6 6,7: fire at up to three sector pairs.\nTorpedoes follow a ray and can strike intervening objects.\nRAY: experimental weapon with unpredictable failure.\nSELF CONFIRM: self-destruct.\n\n[color=#e9bd87]ENGINEERING[/color]\nF5 / MAX: fill shield bank from main energy.\nF7 / ENERGY SHIELDS 500 or ENERGY LASERS -200.\nF6 / FIX all 0.5: wait and repair; enemies continue firing.\nFIX computer 1: focus repairs on one system.\nF8 / REPAIR: list system condition (MSGS shows full report).\nF10 / DOCK: resupply from an adjacent station.\nHAIL: locate nearest StarBase.\n\n[color=#e9bd87]SCIENCE & OPERATIONS[/color]\nORBIT: orbit an adjacent planet. SHDN before LAND.\nLAND / LAND SHUTTLE: collect energium and rescue colonists.\nUSE: consume energium in a low-energy emergency.\nA / A1: acknowledge all messages or one message.\nMSGS: message history. SAVE: save mission. SND: toggle effects.\nEscape: cancel parameter entry. Ctrl+↑/↓: command history.\n\n[color=#7792a6]Reconstruction build: combat balance and rare events are not yet verified against the original executable. See docs/PARITY.md.[/color]")

func show_log() -> void:
	show_text("Communications archive", escape_bbcode("\n\n".join(sim.history)))

func show_chart() -> void:
	var chart_text = "[font_size=24]GALACTIC CARTOGRAPHY[/font_size]\n\n[code]       1     2     3     4     5     6     7     8\n"
	for r in 8:
		chart_text += " %d    " % (r + 1)
		for c in 8:
			chart_text += str(sim.chart.get(str(r * 8 + c), "...")) + "   " if sim.systems.computer >= 50 else "---   "
		chart_text += "\n\n"
	chart_text += "[/code]\nClick the bridge chart to prepare a course. Enter reviews and executes it."
	show_text("Galaxy chart", chart_text)

func show_new_mission() -> void:
	new_dialog.popup_centered()

func save_mission() -> void:
	var result = sim.save_game()
	sim.log_message("COMPUTER", "Mission saved." if result == OK else "Save failed: " + error_string(result))
	refresh()

func restore_mission() -> void:
	var result = sim.load_game()
	sim.log_message("COMPUTER", "Mission restored." if result == OK else "Restore failed: " + error_string(result))
	refresh()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if dialog.visible or new_dialog.visible: return
	var keys = {KEY_F2: "LASERS", KEY_F3: "TORPEDO", KEY_F4: "MOVE", KEY_F5: "MAX", KEY_F6: "FIX", KEY_F7: "ENERGY", KEY_F8: "REPAIR", KEY_F9: "WARP", KEY_F10: "DOCK"}
	if event.keycode == KEY_F1:
		show_help()
		get_viewport().set_input_as_handled()
	elif event.keycode in keys:
		prepare_command(keys[event.keycode])
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE:
		pending = ""
		command.clear()
		command.placeholder_text = "Enter command · e.g. MAX, SHUP, M35"
	elif event.keycode in [KEY_UP, KEY_DOWN]:
		if event.ctrl_pressed and not submitted_history.is_empty():
			history_index = clampi(history_index + (-1 if event.keycode == KEY_UP else 1), 0, submitted_history.size())
			fill_command(submitted_history[history_index] if history_index < submitted_history.size() else "")
		else: sim.execute("SHUP" if event.keycode == KEY_UP else "SHDN")
		get_viewport().set_input_as_handled()

func play_sound(kind: String, _origin: Vector2i, _target: Vector2i) -> void:
	if not sim.sound_enabled or kind == "move" or DisplayServer.get_name() == "headless": return
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data = PackedByteArray()
	var duration = 0.22
	data.resize(int(22050 * duration) * 2)
	var frequency = 170.0 if kind == "explosion" else (600.0 if kind == "laser" else 330.0)
	for i in data.size() / 2:
		var time = i / 22050.0
		var envelope = pow(1 - time / duration, 2)
		var sample = sin(TAU * frequency * time * (1 - time * 1.8)) * envelope * 11000
		data.encode_s16(i * 2, int(sample))
	wav.data = data
	soundtrack.stop()
	soundtrack.stream = wav
	soundtrack.play()
