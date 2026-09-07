extends SceneTree
const Sim = preload("res://scripts/simulation.gd")
var failures = 0
var checks = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func fixture() -> TrekSimulation:
	var sim = Sim.new()
	sim.new_game(1994, 3)
	sim.galaxy[27] = []
	return sim

func snapshot(sim: TrekSimulation) -> Array:
	var values = [sim.rng.state]
	for key in sim.saved_fields():
		var value = sim.get(key)
		values.append(value.duplicate(true) if value is Array or value is Dictionary else value)
	return values

func _init() -> void:
	var sim = Sim.new()
	sim.new_game()
	check(sim.remaining() == 24 and sim.mission_deadline == 36, "Captain has finite 24-ship, 36-day mission")
	var before = snapshot(sim)
	for order in ["LASERS 900 650", "RAY CONFIRM", "FIX all 10", "M53", "DOCK", "SELF CONFIRM", "ENERGY LASERS 100", "REPORT"]:
		sim.preview(order)
	check(snapshot(sim) == before, "previews preserve every field and random state")
	var quote = sim.preview("LASERS 900 650")
	check(quote.ok and quote.energy == 1550 and is_equal_approx(quote.days, 0.1), "laser quote shows main debit and time")
	check(sim.execute("LASERS 900 650") and sim.energy == 3490, "opening salvo consumes shared main energy with regeneration")
	check(not sim.execute("ENERGY LASERS 50"), "old laser transfer is explained and rejected")
	check(not sim.execute("RAY"), "death ray requires explicit destructive order")
	before = snapshot(sim)
	for order in ["INFO", "REPORT", "HAIL", "REPAIR"]: sim.execute(order)
	check(sim.elapsed == before[sim.saved_fields().find("elapsed") + 1], "all information commands cost no time")
	var ray = fixture()
	ray.current().append(ray.make_object("cruiser", Vector2i(1, 1)))
	check(ray.execute("RAY CONFIRM") and ray.ray_used, "experimental ray consumes its single use")
	check(not ray.execute("RAY CONFIRM"), "ray cannot be spammed after failure or success")
	check(ray.save_game("/tmp/vulkantrek-ray.save") == OK, "single-use ability saved")
	var ray_restored = fixture()
	check(ray_restored.load_game("/tmp/vulkantrek-ray.save") == OK and ray_restored.ray_used, "spent ray remains spent after restore")
	var transit = fixture()
	transit.systems.life_support = 99
	transit.advance(3)
	check(not transit.ended and transit.systems.life_support == 100 and transit.reserves > 1, "life support repaired during long journey does not exhaust reserves")

	sim = fixture()
	sim.current().append(sim.make_object("star", Vector2i(3, 3)))
	check(sim.local_path(Vector2i(2, 3)).size() == 4, "impulse routes around an obstacle")
	quote = sim.preview("MOVE 3,4")
	check(quote.ok and quote.energy == 32 and is_equal_approx(quote.days, 0.16), "route quote uses actual path length")
	check(sim.execute("MOVE 3,4") and sim.sector == Vector2i(2, 3), "routed move executes")
	check(not sim.execute("MOVE 4,4"), "occupied destination rejected")
	sim = fixture()
	var cruiser = sim.make_object("cruiser", Vector2i(1, 3))
	sim.current().append(cruiser)
	sim.shields_up = true
	sim.execute("FIX 0.2")
	check(sim.position_of(cruiser) == Vector2i(2, 3), "cruiser closes on its second response")
	check(sim.position_of(cruiser) != sim.sector, "enemy never occupies captain sector")

	sim = fixture()
	var scout = sim.make_object("scout", Vector2i(3, 3))
	sim.current().append(scout)
	sim.galaxy[26] = [sim.make_object("cruiser", Vector2i(0, 0))]
	var total = sim.remaining()
	sim.shields_up = true
	sim.execute("FIX 0.1")
	check(sim.position_of(scout) == Vector2i(2, 3) and scout.rallied, "scout retreats and signals once")
	check(sim.enemies_in(sim.current()).size() == 2 and sim.remaining() == total, "rally moves an existing ally, preserving finite fleet")
	sim.execute("FIX 0.1")
	check(sim.enemies_in(sim.current()).size() == 2, "scout cannot repeatedly summon allies")
	check(sim.save_game("/tmp/vulkantrek-scout.save") == OK, "active enemy abilities saved")
	var scout_restored = fixture()
	check(scout_restored.load_game("/tmp/vulkantrek-scout.save") == OK, "restore active enemy abilities")
	sim.execute("FIX 0.1")
	scout_restored.execute("FIX 0.1")
	check(snapshot(sim) == snapshot(scout_restored), "scout rally and movement counters resume deterministically")

	sim = fixture()
	cruiser = sim.make_object("cruiser", Vector2i(1, 1))
	cruiser.hp = 100
	sim.current().append(cruiser)
	sim.current().append(sim.make_object("supply", Vector2i(1, 2)))
	sim.enemy_turn()
	check(cruiser.hp == 135, "supply restores nearby ally shields")
	var solo = fixture()
	var led = fixture()
	for state in [solo, led]:
		state.current().append(state.make_object("cruiser", Vector2i(1, 1)))
		state.shields_up = true
	led.current().append(led.make_object("command", Vector2i(1, 2)))
	# First shot has identical RNG and range; command bonus makes it stronger.
	solo.enemy_turn()
	led.enemy_turn()
	check(float(led.history[2].split("Incoming ")[1].split(" /")[0]) > float(solo.history[2].split("Incoming ")[1].split(" /")[0]), "commander strengthens nearby ally shot")

	sim = fixture()
	sim.sector = Vector2i(4, 2)
	sim.current().append(sim.make_object("base", Vector2i(5, 2), 1))
	sim.current().append(sim.make_object("cruiser", Vector2i(1, 1)))
	sim.energy = 500
	check(sim.execute("DOCK") and is_equal_approx(sim.elapsed, 0.3) and sim.energy == 5000, "StarBase refit has time cost")
	var shields_before = sim.shields
	sim.execute("FIX 0.1")
	check(sim.shields == shields_before, "docked repairs protected")
	sim.execute("LASERS 1")
	check(sim.docked == 0 and sim.energy < 5000, "firing leaves base protection")

	sim = fixture()
	total = sim.remaining()
	sim.execute("FIX 6.1")
	check(sim.relief.state == "active" and sim.relief.quadrant != 27 and sim.remaining() == total, "timed relief moves finite fleet away from opening base")
	var relief_index = int(sim.relief.quadrant)
	check(sim.chart_value(relief_index)[0] != "0", "relief hostiles visible in fleet intelligence")
	check(sim.save_game("/tmp/vulkantrek-campaign.save") == OK, "save active relief")
	var restored = fixture()
	check(restored.load_game("/tmp/vulkantrek-campaign.save") == OK, "restore active relief")
	sim.execute("FIX 0.2")
	restored.execute("FIX 0.2")
	check(snapshot(sim) == snapshot(restored), "save preserves event and RNG continuation")
	for enemy in sim.enemies_in(sim.galaxy[relief_index]): sim.galaxy[relief_index].erase(enemy)
	sim.execute("REPORT")
	check(sim.relief.state == "saved" and sim.score() >= 300, "cleared relief awards score")
	restored.execute("FIX 6.1")
	check(restored.relief.state == "lost" and not restored.ended, "missed relief loses base but not mission")
	check(restored.galaxy[relief_index].all(func(o): return o.kind != "base"), "missed relief removes station")

	sim = fixture()
	sim.mission_deadline = 0.15
	sim.execute("FIX 1")
	check(sim.ended and not sim.won and is_equal_approx(sim.elapsed, 0.15), "deadline truncates long repair and ends mission")
	check(not sim.execute("MOVE 1,1"), "deadline defeat is terminal")
	var destroyed = fixture()
	destroyed.energy = 10
	destroyed.take_hit(20)
	destroyed.advance(1)
	check(destroyed.ended and not destroyed.won and destroyed.energy == -10, "lethal damage cannot be reversed by regeneration on the next advance")

	# Version-1 migration preserves galaxy and RNG while merging the removed bank.
	sim = fixture()
	var legacy = {"version": 1, "rng": str(sim.rng.state), "laser_energy": 900.0}
	for key in sim.saved_fields(): legacy[key] = sim.get(key)
	legacy.erase("mission_deadline")
	legacy.erase("relief")
	legacy.energy = 1000.0
	for q in legacy.galaxy:
		for o in q:
			o.erase("turns")
			o.erase("rallied")
	var file = FileAccess.open("/tmp/vulkantrek-legacy.save", FileAccess.WRITE)
	file.store_var(legacy)
	file.close()
	restored = fixture()
	check(restored.load_game("/tmp/vulkantrek-legacy.save") == OK and restored.energy == 1900 and restored.mission_deadline == 36, "legacy bank migrated with full deadline window")
	check(restored.save_game("/tmp/vulkantrek-campaign.save") == OK, "migrated save can be written in new format")
	file = FileAccess.open("/tmp/vulkantrek-campaign.save", FileAccess.READ)
	var corrupt = file.get_var(false)
	file.close()
	corrupt.relief.quadrant = 100
	file = FileAccess.open("/tmp/vulkantrek-corrupt-campaign.save", FileAccess.WRITE)
	file.store_var(corrupt)
	file.close()
	before = snapshot(restored)
	check(restored.load_game("/tmp/vulkantrek-corrupt-campaign.save") == ERR_FILE_CORRUPT and snapshot(restored) == before, "invalid event save rejected atomically")
	print("CAMPAIGN: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
