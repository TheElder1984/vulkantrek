extends SceneTree
const Sim = preload("res://scripts/simulation.gd")
var checks = 0
var failures = 0
func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func fixture() -> TrekSimulation:
	var sim = Sim.new()
	sim.new_game(1994, 3)
	return sim

func _init() -> void:
	var a = fixture()
	var b = fixture()
	expect(a.galaxy == b.galaxy, "seed reproduces galaxy")
	expect(a.galaxy.size() == 64, "64 quadrants")
	for q in a.galaxy:
		var cells: Array = []
		for obj in q:
			expect(not cells.has(a.position_of(obj)), "objects never overlap")
			cells.append(a.position_of(obj))
	expect(a.chart.size() == 9, "automatic adjacent scan")
	var time = a.elapsed
	var power = a.energy
	expect(not a.execute("M99"), "reject invalid coordinates")
	expect(a.elapsed == time and a.energy == power, "invalid move has no resource cost")
	expect(not a.execute("M11"), "obstructed route rejected")
	expect(a.elapsed == time, "blocked movement consumes no time")
	expect(a.execute("MAX"), "max shields")
	expect(a.shields == 2500 and a.energy == power - 1000, "shield transfer conserves energy")
	power = a.energy
	expect(not a.execute("ENERGY LASERS 99999"), "reject overflow transfer")
	expect(a.energy == power, "rejected transfer atomic")
	a.execute("SHUP")
	power = a.energy
	a.execute("SHUP")
	expect(a.energy == power, "raising raised shields does not charge twice")
	expect(a.elapsed == time, "information and shield orders do not advance clock")
	expect(not a.execute("LASERS 999999 1"), "reject excess weapon allocation")
	expect(a.elapsed == time, "invalid weapon order costs no time")
	expect(a.execute("LASERS 900 650"), "laser salvo accepted")
	expect(a.kills == 2, "opening laser salvo destroys both targets")
	expect(is_equal_approx(a.elapsed, 0.1), "salvo consumes one turn")
	expect(a.laser_energy == 450, "laser bank debited")
	var snapshot = a.galaxy.duplicate(true)
	expect(a.save_game("/tmp/vulkantrek-test.save") == OK, "save succeeds")
	expect(b.load_game("/tmp/vulkantrek-test.save") == OK, "load succeeds")
	expect(b.galaxy == snapshot and b.energy == a.energy and b.kills == a.kills, "state roundtrip")
	expect(a.rng.state == b.rng.state, "random continuation preserved")
	a.execute("FIX 0.3")
	b.execute("FIX 0.3")
	expect(a.energy == b.energy and a.systems == b.systems, "save continuation deterministic")
	var bad = FileAccess.open("/tmp/vulkantrek-corrupt.save", FileAccess.WRITE)
	bad.store_string("not a save")
	bad.close()
	expect(b.load_game("/tmp/vulkantrek-corrupt.save") != OK, "corrupt save rejected")
	expect(b.galaxy == a.galaxy, "failed load leaves state intact")
	var valid_file = FileAccess.open("/tmp/vulkantrek-test.save", FileAccess.READ)
	var malformed = valid_file.get_var(false)
	valid_file.close()
	malformed.energy = "invalid"
	bad = FileAccess.open("/tmp/vulkantrek-corrupt.save", FileAccess.WRITE)
	bad.store_var(malformed)
	bad.close()
	expect(b.load_game("/tmp/vulkantrek-corrupt.save") == ERR_FILE_CORRUPT, "typed corruption rejected before state mutation")
	expect(b.galaxy == a.galaxy, "typed corruption cannot partially load state")
	a = fixture()
	var original_focus = a.repair_focus
	expect(not a.execute("FIX computer invalid"), "invalid repair duration rejected")
	expect(a.repair_focus == original_focus, "invalid repair leaves focus unchanged")
	expect(not a.execute("S"), "S requires self-destruct confirmation")
	expect(not a.ended, "unconfirmed self-destruct leaves mission active")
	a.shields = 2500
	a.shields_up = true
	power = a.energy
	a.take_hit(100)
	expect(a.energy == power and a.shields == 2400, "full healthy shields absorb entire first hit")
	a.galaxy[27] = [a.make_object("base", Vector2i(4,2), 2)]
	a.energy = 500
	a.torpedoes = 2
	a.reserves = 0.5
	a.execute("DOCK")
	expect(a.energy == 500 and a.torpedoes == 2 and a.reserves == 2, "research station supplies only life reserves")
	a.galaxy[27][0].base_type = 3
	a.execute("DOCK")
	expect(a.torpedoes == 10 and a.energy == 500, "supply station does not refuel main bank")
	a = fixture()
	a.galaxy[27] = [a.make_object("planet", Vector2i(4,2))]
	expect(not a.execute("LAND"), "cannot land without orbit")
	expect(a.execute("ORBIT"), "adjacent orbit accepted")
	a.execute("SHUP")
	expect(not a.execute("LAND"), "raised shields block landing")
	a.execute("SHDN")
	expect(a.execute("LAND") and a.crystals == 1, "landing retrieves crystal")
	a.execute("LAND")
	expect(a.crystals == 1, "planet supplies cannot be collected twice")
	a = fixture()
	a.sector = Vector2i(4, 2)
	expect(a.execute("DOCK"), "adjacent docking")
	expect(a.docked == 1 and a.energy == 5000 and a.torpedoes == 10, "base refit")
	a.systems.computer = 60
	a.execute("FIX computer 0.5")
	expect(a.systems.computer == 90, "focused docked repair multiplier")
	expect(a.energy == 5000 and a.crew == 430, "base protects against enemy lasers")
	a.systems.computer = 100
	expect(not a.execute("M53"), "same location rejected")
	a = fixture()
	a.galaxy[27] = []
	a.systems.impulse = 49
	expect(not a.execute("M54"), "impulse damage threshold")
	a.systems.impulse = 100
	a.systems.computer = 99
	expect(not a.execute("M54"), "automatic navigation requires healthy computer")
	expect(a.execute("MOVE M 0.0 0.1"), "manual navigation works without computer")
	expect(a.sector == Vector2i(4, 4), "manual sector displacement")
	a = fixture()
	a.systems.tubes = 33
	expect(not a.execute("T36"), "damaged tubes cannot fire")
	a.systems.tubes = 67
	expect(not a.execute("T36 67 12"), "tube count limits salvo")
	expect(a.execute("T36"), "valid torpedo fires")
	expect(a.torpedoes == 9 and a.kills == 1, "close torpedo destroys cruiser")
	a = fixture()
	a.systems.short_scan = 89
	expect(a.visible_objects().all(func(o): return o.kind == "star"), "damaged scanner hides small objects")
	a.systems.short_scan = 49
	expect(a.visible_objects().is_empty(), "failed scanner hides all objects")
	a = fixture()
	a.galaxy[27] = []
	a.systems.life_support = 0
	a.reserves = 0.05
	a.execute("FIX 0.1")
	expect(a.ended and not a.won, "life support loss ends mission")
	a = fixture()
	for q in a.galaxy:
		for obj in q.duplicate():
			if obj.hp > 0: q.erase(obj)
	a.execute("INFO")
	expect(a.ended and a.won, "last hostile eliminated yields victory")
	expect(not a.execute("MOVE 1,2"), "terminal mission rejects actions")
	print("SIMULATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
