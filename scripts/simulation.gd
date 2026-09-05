class_name TrekSimulation
extends RefCounted
## All mission state advances only through accepted commands. No frame time here.
signal changed
signal effect(kind: String, origin: Vector2i, target: Vector2i)
const SIZE = 8
const MAIN_CAP = 5000.0
const SHIELD_CAP = 2500.0
const LASER_CAP = 2000.0
const SYSTEMS = ["converter", "shields", "warp", "impulse", "lasers", "tubes", "short_scan", "long_scan", "computer", "life_support", "transporter", "shuttle"]
var rng = RandomNumberGenerator.new()
var galaxy: Array = []
var chart: Dictionary = {}
var quadrant = Vector2i(3, 3)
var sector = Vector2i(4, 3)
var energy = MAIN_CAP
var shields = 1500.0
var laser_energy = LASER_CAP
var shields_up = false
var heat = 0.0
var warp = 5.0
var stardate = 3200.0
var elapsed = 0.0
var torpedoes = 10
var crew = 430
var reserves = 2.0
var crystals = 0
var rescued = 0
var kills = 0
var level = 3
var mission_seed = 0
var docked = 0
var orbiting = false
var ended = false
var won = false
var sound_enabled = true
var repair_focus = ""
var systems: Dictionary = {}
var messages: Array[String] = []
var history: Array[String] = []

func new_game(seed_value: int = 1994, difficulty: int = 3) -> void:
	mission_seed = seed_value
	rng.seed = seed_value
	level = clampi(difficulty, 1, 5)
	galaxy.clear()
	chart.clear()
	messages.clear()
	history.clear()
	quadrant = Vector2i(3, 3)
	sector = Vector2i(4, 3)
	energy = MAIN_CAP
	shields = 1500
	laser_energy = LASER_CAP
	shields_up = false
	heat = 0
	warp = 5
	stardate = 3200
	elapsed = 0
	torpedoes = 10
	crew = 430
	reserves = 2
	crystals = 0
	rescued = 0
	kills = 0
	docked = 0
	orbiting = false
	ended = false
	won = false
	repair_focus = ""
	for system in SYSTEMS: systems[system] = 100.0
	for i in 64:
		var q: Array = []
		for j in rng.randi_range(2, 7):
			q.append(make_object("star", vacant(q)))
		if rng.randf() < 0.2:
			q.append(make_object("planet", vacant(q)))
		galaxy.append(q)
	for i in (12 + level * 8):
		var index = rng.randi_range(0, 63)
		if enemies_in(galaxy[index]).size() < 6:
			var types = ["cruiser", "cruiser", "cruiser", "scout", "supply", "command"]
			galaxy[index].append(make_object(types[rng.randi_range(0, 5)], vacant(galaxy[index])))
	for i in [0, 11, 27, 45, 62]:
		galaxy[i].append(make_object("base", vacant(galaxy[i]), 1 if i in [0, 27, 62] else (2 if i == 11 else 3)))
	# A reproducible first encounter, with an accessible friendly base.
	galaxy[27] = [make_object("base", Vector2i(5, 2), 1), make_object("cruiser", Vector2i(2, 5)), make_object("scout", Vector2i(5, 6)), make_object("star", Vector2i(1, 1)), make_object("star", Vector2i(6, 4)), make_object("star", Vector2i(0, 6)), make_object("planet", Vector2i(6, 0))]
	scan()
	log_message("COMMAND", "Lexington RCB-92 ready. Secure all 64 quadrants.")
	log_message("TACTICAL", "%d hostile vessels remain. Raise shields before engaging." % remaining())
	changed.emit()

func make_object(kind: String, pos: Vector2i, base_type: int = 0) -> Dictionary:
	var hp = {"cruiser": 450, "command": 800, "scout": 240, "supply": 300}.get(kind, 0)
	return {"kind": kind, "r": pos.x, "c": pos.y, "hp": hp, "max_hp": hp, "base_type": base_type, "crystals": kind == "planet", "population": 50 if kind == "planet" and rng.randf() < 0.3 else 0}

func vacant(objects: Array) -> Vector2i:
	for i in 1000:
		var pos = Vector2i(rng.randi_range(0, 7), rng.randi_range(0, 7))
		if object_at(objects, pos).is_empty(): return pos
	return Vector2i.ZERO

func current() -> Array:
	return galaxy[quadrant.x * 8 + quadrant.y]

func position_of(obj: Dictionary) -> Vector2i:
	return Vector2i(int(obj.r), int(obj.c))

func object_at(objects: Array, pos: Vector2i) -> Dictionary:
	for obj in objects:
		if position_of(obj) == pos: return obj
	return {}

func enemies_in(objects: Array) -> Array:
	return objects.filter(func(o): return o.kind in ["cruiser", "command", "scout", "supply"])

func remaining() -> int:
	var count = 0
	for q in galaxy: count += enemies_in(q).size()
	return count

func visible_objects() -> Array:
	if systems.short_scan < 50: return []
	if systems.short_scan < 90: return current().filter(func(o): return o.kind == "star")
	return current()

func scan() -> void:
	if systems.computer < 50: chart.clear()
	if systems.long_scan < 50: return
	for r in range(maxi(0, quadrant.x - 1), mini(8, quadrant.x + 2)):
		for c in range(maxi(0, quadrant.y - 1), mini(8, quadrant.y + 2)):
			var q: Array = galaxy[r * 8 + c]
			var stars = 0
			var base = 0
			for o in q:
				if o.kind == "star": stars += 1
				if o.kind == "base": base = o.base_type
			chart[str(r * 8 + c)] = "%d%d%d" % [enemies_in(q).size() if systems.long_scan >= 100 else 0, base, stars]

func log_message(department: String, message: String) -> void:
	var line = "%s  /  %s" % [department, message]
	messages.append(line)
	history.append(line)
	if messages.size() > 4: messages.pop_front()
	if history.size() > 160: history.pop_front()

func reject(message: String) -> bool:
	log_message("COMPUTER", message)
	return false

func execute(raw: String) -> bool:
	var text = raw.strip_edges().to_upper()
	if text.is_empty(): return false
	var regex = RegEx.new()
	regex.compile("^([A-Z]+)(.*)$")
	var matched = regex.search(text)
	if matched == null:
		reject("Enter a command. F1 opens the reference.")
		changed.emit()
		return false
	var cmd = matched.get_string(1)
	var args = matched.get_string(2).strip_edges().replace(",", " ")
	var aliases = {"C": "CHART", "M": "MOVE", "W": "WARP", "D": "DOCK", "E": "ENERGY", "F": "FIX", "H": "HAIL", "I": "INFO", "L": "LASERS", "O": "ORBIT", "T": "TORPEDO", "TORPS": "TORPEDO", "U": "USE", "R": "REPAIR", "S": "SELF", "Q": "QUIT"}
	cmd = aliases.get(cmd, cmd)
	if ended and cmd not in ["INFO", "REPAIR", "MSGS", "HELP", "SND", "A", "CHART", "SAVE", "QUIT"]:
		reject("Mission ended. Start a new mission from the bridge menu.")
		changed.emit()
		return false
	var result = true
	match cmd:
		"MOVE": result = move_ship(args)
		"WARP":
			if not args.is_valid_float() or float(args) < 1 or float(args) > minf(8, 1 + 0.09 * systems.warp): result = reject("Warp must be 1–8 and within engine capability.")
			else:
				warp = float(args)
				log_message("HELM", "Warp factor %.1f set." % warp)
		"SHUP":
			if not shields_up:
				if energy < 50: result = reject("Insufficient energy to raise shields.")
				else:
					energy -= 50
					shields_up = true
					log_message("ENGINEERING", "Shields raised.")
		"SHDN":
			shields_up = false
			log_message("ENGINEERING", "Shields lowered.")
		"MAX": transfer("SHIELDS", minf(SHIELD_CAP - shields, energy))
		"ENERGY":
			var bits = args.split(" ", false)
			if bits.size() == 2 and bits[1].is_valid_float(): result = transfer(bits[0], float(bits[1]))
			else: log_message("ENGINEERING", "Main %.0f / Shields %.0f / Lasers %.0f. ENERGY SHIELDS|LASERS amount (negative returns power)." % [energy, shields, laser_energy])
		"LASERS": result = fire_lasers(args)
		"TORPEDO": result = fire_torpedoes(args)
		"DOCK": result = dock()
		"FIX": result = fix_systems(args)
		"REPAIR":
			for key in SYSTEMS: log_message("ENGINEERING", "%s %d%%" % [key.capitalize(), systems[key]])
		"INFO":
			if systems.computer < 100: result = reject("Computer damaged. Repair before requesting target analysis.")
			else:
				for e in enemies_in(current()): log_message("TACTICAL", "%s at %d,%d / range %.1f / shields %d%%" % [e.kind.capitalize(), e.r + 1, e.c + 1, Vector2(sector).distance_to(Vector2(position_of(e))), 100.0 * e.hp / e.max_hp])
		"HAIL":
			var best = 100.0
			var where = Vector2i.ZERO
			for index in 64:
				for o in galaxy[index]:
					if o.kind == "base" and o.base_type == 1:
						var q = Vector2i(index / 8, index % 8)
						var distance = Vector2(q).distance_to(Vector2(quadrant))
						if distance < best:
							best = distance
							where = q
			log_message("COMMS", "Nearest StarBase: quadrant %d,%d." % [where.x + 1, where.y + 1])
			if best > 1: advance(0.1)
		"ORBIT":
			result = false
			for o in current():
				if o.kind == "planet" and adjacent(position_of(o)):
					orbiting = true
					docked = 0
					log_message("SCIENCE", "Standard orbit established. Planet survey available; LAND to explore.")
					advance(0.05)
					result = true
			if not result: reject("Move adjacent to a planet to establish orbit.")
		"LAND": result = land(args)
		"USE":
			if crystals < 1 or energy >= MAIN_CAP * 0.2 or shields >= SHIELD_CAP * 0.5: result = reject("Raw energium requires a crystal, main power below 20%, and shields below 50%.")
			else:
				crystals -= 1
				energy = MAIN_CAP
				log_message("ENGINEERING", "Energium converted. Main power restored.")
		"RAY":
			if rng.randf() < 0.5:
				for e in enemies_in(current()): destroy(e)
				log_message("TACTICAL", "Death ray discharged. Quadrant cleared.")
			else:
				energy *= 0.25
				systems.lasers = 0
				log_message("ENGINEERING", "Death ray failure! Main power lost; laser banks destroyed.")
			advance(0.1)
		"SELF":
			if args != "CONFIRM": result = reject("Enter SELF CONFIRM to destroy the ship.")
			else:
				for e in enemies_in(current()):
					if Vector2(sector).distance_to(Vector2(position_of(e))) < 3: destroy(e)
				energy = 0
				finish(false, "Lexington destroyed by self-destruct.")
		"A":
			if args.is_empty(): messages.clear()
			elif args.is_valid_int() and int(args) >= 1 and int(args) <= messages.size(): messages.remove_at(int(args) - 1)
		"SND":
			sound_enabled = not sound_enabled
			log_message("COMPUTER", "Sound enabled." if sound_enabled else "Sound muted.")
		"HELP", "MSGS", "SAVE", "QUIT", "CHART": pass # Presentation handles these commands.
		_: result = reject("Unknown command. Press F1 for the command reference.")
	scan()
	if not ended and remaining() == 0: finish(true, "All invasion vessels eliminated. Union territory secured.")
	changed.emit()
	return result

func transfer(bank: String, amount: float) -> bool:
	if not is_finite(amount): return reject("Invalid energy amount.")
	var value = shields if bank == "SHIELDS" else laser_energy
	var cap = SHIELD_CAP if bank == "SHIELDS" else LASER_CAP
	if bank not in ["SHIELDS", "LASERS"] or amount > energy or value + amount < 0 or value + amount > cap or energy - amount > MAIN_CAP: return reject("Transfer exceeds available power or bank capacity.")
	energy -= amount
	if bank == "SHIELDS": shields += amount
	else: laser_energy += amount
	log_message("ENGINEERING", "%+.0f units transferred to %s." % [amount, bank.to_lower()])
	return true

func coords(args: String) -> Array[int]:
	var clean = args.replace(" ", "").replace(",", "")
	var result: Array[int] = []
	for digit in clean:
		if not digit.is_valid_int() or int(digit) < 1 or int(digit) > 8: return []
		result.append(int(digit) - 1)
	return result

func move_ship(args: String) -> bool:
	var q = quadrant
	var target = sector
	if args.begins_with("M "):
		var parts = args.substr(2).split(" ", false)
		if parts.size() != 2: return reject("Manual navigation: MOVE M delta-row delta-column, e.g. M M 1.0 -2.2")
		var global_pos = quadrant * 8 + sector
		for i in 2:
			if not parts[i].is_valid_float(): return reject("Invalid manual displacement.")
			var delta = float(parts[i])
			var whole = int(absf(delta))
			var fraction = roundi((absf(delta) - whole) * 10)
			if whole > 7 or fraction > 7: return reject("Manual digits must be 0–7.")
			global_pos[i] += (whole * 8 + fraction) * (-1 if delta < 0 else 1)
		if global_pos.x < 0 or global_pos.y < 0 or global_pos.x > 63 or global_pos.y > 63: return reject("Course leaves assigned galaxy.")
		q = Vector2i(global_pos.x / 8, global_pos.y / 8)
		target = Vector2i(global_pos.x % 8, global_pos.y % 8)
	else:
		if systems.computer < 100: return reject("Computer damaged. Use MOVE M delta-row delta-column.")
		var values = coords(args)
		if values.size() == 2: target = Vector2i(values[0], values[1])
		elif values.size() == 4:
			q = Vector2i(values[0], values[1])
			target = Vector2i(values[2], values[3])
		else: return reject("MOVE row,column or quadrant-row,quadrant-column,row,column. Coordinates 1–8.")
	if q == quadrant and target == sector: return reject("Already at that position.")
	var interstellar = q != quadrant
	if not interstellar and systems.impulse < 50: return reject("Impulse engines inoperative.")
	if interstellar and warp > minf(8, 1 + 0.09 * systems.warp): return reject("Reduce warp to match damaged engine capability.")
	var origin = quadrant * 8 + sector
	var destination = q * 8 + target
	var distance = Vector2(origin).distance_to(Vector2(destination))
	var steps = int(ceil(distance * 3))
	# Trace intermediate cells; objects obstruct movement rather than teleporting through them.
	for i in range(1, steps + 1):
		var sample = Vector2i(Vector2(origin).lerp(Vector2(destination), float(i) / steps).round())
		var qi = Vector2i(sample.x / 8, sample.y / 8)
		var si = Vector2i(sample.x % 8, sample.y % 8)
		if not object_at(galaxy[qi.x * 8 + qi.y], si).is_empty(): return reject("Course obstructed at quadrant %d,%d sector %d,%d." % [qi.x + 1, qi.y + 1, si.x + 1, si.y + 1])
	var cost = distance * (warp * warp * 0.6 if interstellar else 8.0) * (2 if interstellar and shields_up else 1)
	if energy <= cost: return reject("Insufficient main power for this course.")
	energy -= cost
	var old_sector = sector
	quadrant = q
	sector = target
	docked = 0
	orbiting = false
	effect.emit("warp" if interstellar else "move", old_sector, sector)
	if interstellar and warp > 6 and rng.randf() < 0.25: systems.warp = maxf(10, systems.warp - rng.randf_range(10, 25))
	log_message("HELM", "Arrived Q %d,%d · S %d,%d. Used %.0f energy." % [q.x + 1, q.y + 1, sector.x + 1, sector.y + 1, cost])
	advance(maxf(0.05, distance / (warp * 8) if interstellar else distance * 0.08))
	return true

func fire_lasers(args: String) -> bool:
	var enemies = enemies_in(current())
	if enemies.is_empty(): return reject("No hostile targets in this quadrant.")
	if systems.lasers <= 0: return reject("Laser banks inoperative.")
	var bits = args.split(" ", false)
	var allocations: Array[float] = []
	if bits.size() != enemies.size(): return reject("LASERS: enter energy for each of %d targets, in INFO order (0 skips)." % enemies.size())
	var total = 0.0
	for bit in bits:
		if not bit.is_valid_float() or not is_finite(float(bit)) or float(bit) < 0: return reject("Enter non-negative laser allocations.")
		allocations.append(float(bit))
		total += float(bit)
	if total <= 0 or total > laser_energy: return reject("Laser allocation exceeds bank energy or is zero.")
	laser_energy -= total
	var efficiency = systems.lasers / 100.0 * clampf(1.0 - heat / 140.0, 0.1, 1.0)
	for i in enemies.size():
		if allocations[i] == 0: continue
		var e: Dictionary = enemies[i]
		var damage = allocations[i] * efficiency / (1 + Vector2(sector).distance_to(Vector2(position_of(e))) * 0.16)
		e.hp -= damage
		effect.emit("laser", sector, position_of(e))
		log_message("TACTICAL", "%s hit for %.0f. Enemy shields %.0f." % [e.kind.capitalize(), damage, maxf(e.hp, 0)])
		if e.hp <= 0: destroy(e)
	heat = minf(120, heat + total / 35)
	advance(0.1)
	return true

func fire_torpedoes(args: String) -> bool:
	var values = coords(args)
	var tubes = 3 if systems.tubes >= 100 else (2 if systems.tubes >= 67 else (1 if systems.tubes >= 34 else 0))
	if values.is_empty() or values.size() % 2 != 0 or values.size() / 2 > tubes: return reject("TORPEDO row,column [row,column ...]. %d tubes operational." % tubes)
	if values.size() / 2 > torpedoes: return reject("Insufficient torpedoes.")
	for i in range(0, values.size(), 2):
		if Vector2i(values[i], values[i + 1]) == sector: return reject("Cannot target your own sector.")
	for i in range(0, values.size(), 2):
		torpedoes -= 1
		var target = Vector2(values[i], values[i + 1])
		if shields_up and rng.randf() < 0.25: target += Vector2(rng.randi_range(-1, 1), rng.randi_range(-1, 1))
		var direction = (target - Vector2(sector)).normalized()
		var hit: Dictionary = {}
		var end = sector
		for step in range(1, 100):
			end = Vector2i((Vector2(sector) + direction * step * 0.15).round())
			if end.x < 0 or end.y < 0 or end.x > 7 or end.y > 7: break
			if end != sector:
				hit = object_at(current(), end)
				if not hit.is_empty(): break
		effect.emit("torpedo", sector, end)
		if hit.is_empty(): log_message("TACTICAL", "Torpedo exited quadrant without impact.")
		elif hit.kind in ["star", "planet", "base"]:
			log_message("TACTICAL", "Torpedo struck %s." % hit.kind)
			if hit.kind == "star": nova(hit)
			else:
				current().erase(hit)
				rescued -= 50
		else:
			hit.hp -= 750.0 / (1 + Vector2(sector).distance_to(Vector2(position_of(hit))) * 0.08)
			if hit.hp <= 0: destroy(hit)
			else: log_message("TACTICAL", "Torpedo impact. Target shields %.0f." % hit.hp)
	advance(0.1)
	return true

func nova(star: Dictionary) -> void:
	var center = position_of(star)
	current().erase(star)
	effect.emit("explosion", center, center)
	for obj in current().duplicate():
		if Vector2(position_of(obj)).distance_to(Vector2(center)) < 1.5:
			if obj.hp > 0: destroy(obj)
			else: current().erase(obj)
	if Vector2(sector).distance_to(Vector2(center)) < 1.5: take_hit(900)
	log_message("SCIENCE", "Stellar nova! Adjacent sectors devastated.")

func destroy(enemy: Dictionary) -> void:
	if not current().has(enemy): return
	effect.emit("explosion", position_of(enemy), position_of(enemy))
	current().erase(enemy)
	kills += 1
	log_message("TACTICAL", "%s destroyed." % enemy.kind.capitalize())

func adjacent(pos: Vector2i) -> bool:
	return maxi(absi(pos.x - sector.x), absi(pos.y - sector.y)) <= 1

func dock() -> bool:
	for obj in current():
		if obj.kind == "base" and adjacent(position_of(obj)):
			docked = obj.base_type
			orbiting = false
			reserves = 2
			if docked != 2: torpedoes = 10
			if docked == 1:
				energy = MAIN_CAP
				shields = SHIELD_CAP
				laser_energy = LASER_CAP
				crew = 430
			log_message("COMMS", "Docking complete. %s" % ("All supplies restored. StarBase shields protect us." if docked == 1 else "Station supplies transferred; full refit requires a StarBase."))
			return true
	return reject("Docking requires a sector adjacent to a friendly station.")

func land(args: String) -> bool:
	if not orbiting: return reject("Establish ORBIT first.")
	if shields_up: return reject("Lower shields before landing.")
	var shuttle = args == "SHUTTLE"
	if systems.shuttle < 100 if shuttle else systems.transporter < 100: return reject("Selected landing system requires full repair.")
	for obj in current():
		if obj.kind == "planet" and adjacent(position_of(obj)):
			if obj.crystals:
				crystals += 1
				obj.crystals = false
			rescued += int(obj.population)
			obj.population = 0
	log_message("SCIENCE", "Landing party returned. Energium %d / rescued %d." % [crystals, rescued])
	advance(0.2 if shuttle else 0.001)
	return true

func fix_systems(args: String) -> bool:
	var bits = args.to_lower().split(" ", false)
	var duration = 0.5
	var requested_focus = repair_focus
	if bits.size() > 2: return reject("FIX takes a system and a duration.")
	if bits.size() > 0:
		if bits[0].is_valid_float(): duration = float(bits[0])
		elif bits[0] in SYSTEMS: requested_focus = bits[0]
		elif bits[0] == "all": requested_focus = ""
		else: return reject("FIX [system|all] [stardays]. See REPAIR for system names.")
	if bits.size() > 1:
		if not bits[1].is_valid_float(): return reject("Invalid repair duration.")
		duration = float(bits[1])
	if not is_finite(duration) or duration <= 0 or duration > 10: return reject("Repair duration must be above 0 and at most 10 stardays.")
	repair_focus = requested_focus
	log_message("ENGINEERING", "Repair teams assigned for %.2f stardays." % duration)
	# Split waiting into turns: long repairs cannot suppress enemy fire.
	while duration > 0.00001 and not ended:
		var step = minf(0.1, duration)
		advance(step)
		duration -= step
	return true

func advance(days: float) -> void:
	elapsed += days
	stardate += days
	energy = minf(MAIN_CAP, energy + 400 * days * systems.converter / 100)
	heat = maxf(0, heat - 35 * days)
	if systems.life_support < 100: reserves -= days
	else: reserves = minf(2, reserves + days)
	var damaged: Array = []
	for key in SYSTEMS:
		if systems[key] < 100: damaged.append(key)
	if repair_focus != "" and systems[repair_focus] >= 100: repair_focus = ""
	for key in damaged:
		if repair_focus != "" and key != repair_focus: continue
		var rate = (5.0 if docked == 1 else 3.0) if repair_focus != "" else (2.5 if docked == 1 else 1.0) / maxf(1, damaged.size())
		systems[key] = minf(100, systems[key] + 12 * days * rate)
	if docked != 1:
		for e in enemies_in(current()):
			var distance = Vector2(sector).distance_to(Vector2(position_of(e)))
			var damage = rng.randf_range(55, 100) * (0.6 + level * 0.2) * (1.5 if e.kind == "command" else 1.0) / (1 + distance * 0.12)
			effect.emit("enemy_laser", position_of(e), sector)
			take_hit(damage)
	if energy <= 0 or crew <= 0 or reserves <= 0: finish(false, "Ship lost. Mission terminated.")

func take_hit(amount: float) -> void:
	var absorption = clampf(shields / SHIELD_CAP * systems.shields / 100, 0, 1) if shields_up else 0.0
	var absorbed = minf(shields, amount * absorption)
	shields = maxf(0, shields - absorbed)
	var penetration = amount - absorbed
	energy -= penetration
	if penetration > 20:
		var key: String = SYSTEMS[rng.randi_range(0, SYSTEMS.size() - 1)]
		systems[key] = maxf(0, systems[key] - penetration * 0.12)
		crew = maxi(0, crew - int(penetration / 35))
	log_message("DAMAGE", "Incoming %.0f / absorbed %.0f / penetration %.0f." % [amount, absorbed, penetration])

func finish(success: bool, reason: String) -> void:
	ended = true
	won = success
	log_message("COMMAND", reason)

func score() -> int:
	return maxi(0, int(kills * 100 + rescued * 2 - elapsed * 20 + (1000 if won else 0)))

func save_game(path: String = "user://mission.save") -> Error:
	var state: Dictionary = {"version": 1, "rng": str(rng.state)}
	for key in saved_fields(): state[key] = get(key)
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_var(state)
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path)

func load_game(path: String = "user://mission.save") -> Error:
	if not FileAccess.file_exists(path): return ERR_FILE_NOT_FOUND
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null: return FileAccess.get_open_error()
	if file.get_length() < 4: return ERR_FILE_CORRUPT
	var data_length = file.get_32()
	if data_length != file.get_length() - 4 or data_length > 1048576: return ERR_FILE_CORRUPT
	file.seek(0)
	var state = file.get_var(false)
	if not state is Dictionary or state.get("version") != 1: return ERR_FILE_CORRUPT
	for key in saved_fields():
		if not state.has(key): return ERR_FILE_CORRUPT
		var expected = typeof(get(key))
		if expected in [TYPE_INT, TYPE_FLOAT]:
			if not typeof(state[key]) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(state[key])): return ERR_FILE_CORRUPT
		elif typeof(state[key]) != expected: return ERR_FILE_CORRUPT
	if not state.get("rng") is String or not state.rng.is_valid_int(): return ERR_FILE_CORRUPT
	if state.level < 1 or state.level > 5 or state.torpedoes < 0 or state.torpedoes > 10 or state.docked < 0 or state.docked > 3: return ERR_FILE_CORRUPT
	if state.repair_focus != "" and state.repair_focus not in SYSTEMS: return ERR_FILE_CORRUPT
	for lines in [state.messages, state.history]:
		if lines.size() > 160: return ERR_FILE_CORRUPT
		for line in lines:
			if not line is String or not line.contains("  /  "): return ERR_FILE_CORRUPT
	if not state.galaxy is Array or state.galaxy.size() != 64 or not state.quadrant is Vector2i or not state.sector is Vector2i: return ERR_FILE_CORRUPT
	for pos in [state.quadrant, state.sector]:
		if pos.x < 0 or pos.x > 7 or pos.y < 0 or pos.y > 7: return ERR_FILE_CORRUPT
	for q in state.galaxy:
		if not q is Array: return ERR_FILE_CORRUPT
		var occupied: Array = []
		for obj in q:
			if not obj is Dictionary: return ERR_FILE_CORRUPT
			for key in ["kind", "r", "c", "hp", "max_hp", "base_type", "crystals", "population"]:
				if not obj.has(key): return ERR_FILE_CORRUPT
			if obj.kind not in ["star", "planet", "base", "cruiser", "command", "scout", "supply"]: return ERR_FILE_CORRUPT
			for key in ["r", "c", "hp", "max_hp", "base_type", "population"]:
				if typeof(obj[key]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(obj[key])): return ERR_FILE_CORRUPT
			if obj.r < 0 or obj.r > 7 or obj.c < 0 or obj.c > 7 or obj.r != int(obj.r) or obj.c != int(obj.c): return ERR_FILE_CORRUPT
			if obj.hp < 0 or obj.max_hp < 0 or obj.base_type < 0 or obj.base_type > 3 or not obj.crystals is bool: return ERR_FILE_CORRUPT
			var pos = position_of(obj)
			if pos in occupied: return ERR_FILE_CORRUPT
			occupied.append(pos)
	if not state.systems is Dictionary: return ERR_FILE_CORRUPT
	for key in SYSTEMS:
		if not state.systems.has(key): return ERR_FILE_CORRUPT
		if typeof(state.systems[key]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(state.systems[key])) or state.systems[key] < 0 or state.systems[key] > 100: return ERR_FILE_CORRUPT
	for key in state.chart:
		if not key is String or not key.is_valid_int() or int(key) < 0 or int(key) > 63: return ERR_FILE_CORRUPT
		if not state.chart[key] is String or state.chart[key].length() != 3 or not state.chart[key].is_valid_int(): return ERR_FILE_CORRUPT
	for key in saved_fields(): set(key, state[key])
	rng.state = int(state.rng)
	changed.emit()
	return OK

func saved_fields() -> Array:
	return ["galaxy", "chart", "quadrant", "sector", "energy", "shields", "laser_energy", "shields_up", "heat", "warp", "stardate", "elapsed", "torpedoes", "crew", "reserves", "crystals", "rescued", "kills", "level", "mission_seed", "docked", "orbiting", "ended", "won", "sound_enabled", "repair_focus", "systems", "messages", "history"]
