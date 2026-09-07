extends SceneTree
## Feasibility pilot: all mutations go through public commands; no resource grants,
## teleporting, enemy removal, RNG edits or deadline extensions.
const Sim = preload("res://scripts/simulation.gd")
var commands: Array[String] = []
var failures = 0

func order(sim: TrekSimulation, text: String) -> bool:
	commands.append(text)
	return sim.execute(text)

func station(sim: TrekSimulation) -> Dictionary:
	var result: Dictionary = {}
	var best = INF
	# Friendly stations are public fleet intelligence on the chart.
	for index in 64:
		for obj in sim.galaxy[index]:
			if obj.kind != "base" or obj.base_type != 1: continue
			var q = Vector2i(index / 8, index % 8)
			var distance = Vector2(q).distance_to(Vector2(sim.quadrant))
			if distance < best:
				best = distance
				result = {"quadrant": q, "sector": sim.position_of(obj)}
	return result

func travel(sim: TrekSimulation, q: Vector2i) -> void:
	if q == sim.quadrant: return
	if sim.systems.life_support < 100:
		order(sim, "FIX life_support 0.2")
		return
	if sim.systems.computer < 50:
		order(sim, "FIX computer 0.2")
		return
	var target = sim.arrival_sector(q)
	var hostiles = int(sim.chart_value(q.x * 8 + q.y)[0])
	order(sim, "SHUP" if hostiles > 0 else "SHDN")
	order(sim, "WARP 4")
	var move = "MOVE %d,%d,%d,%d" % [q.x + 1, q.y + 1, target.x + 1, target.y + 1]
	if not sim.preview(move).ok:
		order(sim, "WARP 1")
	if not sim.preview(move).ok:
		order(sim, "FIX all 0.5")
	else:
		order(sim, move)

func refit(sim: TrekSimulation) -> void:
	var base = station(sim)
	if base.is_empty():
		order(sim, "FIX all 1")
		return
	if sim.quadrant != base.quadrant:
		travel(sim, base.quadrant)
		return
	if not sim.adjacent(base.sector):
		var best: Array = []
		var destination = sim.sector
		for r in range(maxi(0, base.sector.x - 1), mini(8, base.sector.x + 2)):
			for c in range(maxi(0, base.sector.y - 1), mini(8, base.sector.y + 2)):
				var cell = Vector2i(r, c)
				var path = sim.local_path(cell)
				if not path.is_empty() and (best.is_empty() or path.size() < best.size()):
					best = path
					destination = cell
		if not best.is_empty():
			order(sim, "MOVE %d,%d" % [destination.x + 1, destination.y + 1])
			return
	if sim.docked != 1 or sim.energy < 4999 or sim.torpedoes < 10:
		order(sim, "DOCK")
	elif sim.systems.values().any(func(v): return v < 100) or sim.heat > 25:
		order(sim, "FIX all 0.5")

func clear_torpedo(sim: TrekSimulation, target: Vector2i) -> bool:
	var direction = (Vector2(target) - Vector2(sim.sector)).normalized()
	for i in range(1, 100):
		var cell = Vector2i((Vector2(sim.sector) + direction * i * 0.15).round())
		if cell.x < 0 or cell.y < 0 or cell.x > 7 or cell.y > 7: return false
		if cell == sim.sector: continue
		var obj = sim.object_at(sim.visible_objects(), cell)
		if not obj.is_empty(): return obj.hp > 0
	return false

func fight(sim: TrekSimulation) -> void:
	var enemies = sim.enemies_in(sim.visible_objects())
	if enemies.is_empty():
		refit(sim)
		return
	order(sim, "SHUP")
	if sim.shields < 1700 and sim.energy > 3000: order(sim, "MAX")
	if sim.torpedoes > 0 and (sim.heat > 45 or sim.energy < 2200):
		for enemy in enemies:
			var target = sim.position_of(enemy)
			if clear_torpedo(sim, target):
				order(sim, "SHDN") # Prevent scatter into neutral objects.
				order(sim, "TORPEDO %d,%d" % [target.x + 1, target.y + 1])
				return
	if sim.energy < 700 or sim.systems.lasers < 30:
		refit(sim)
		return
	var allocations: Array[int] = []
	allocations.resize(enemies.size())
	allocations.fill(0)
	var budget = minf(2000, sim.energy - 400)
	for kind in ["supply", "command", "scout", "cruiser"]:
		for i in enemies.size():
			var enemy: Dictionary = enemies[i]
			if enemy.kind != kind: continue
			var required = sim.laser_solution(enemy)
			var allocation = mini(required, int(budget))
			allocations[i] = allocation
			budget -= allocation
	var args: Array[String] = []
	for allocation in allocations: args.append(str(allocation))
	order(sim, "LASERS " + " ".join(args))

func run_seed(seed_value: int) -> void:
	var sim = Sim.new()
	sim.new_game(seed_value, 3)
	commands.clear()
	var refitting = false
	for step in 700:
		if sim.ended: break
		if refitting:
			if sim.docked == 1 and sim.energy >= 4999 and sim.heat <= 25 and sim.systems.values().all(func(v): return v >= 100):
				refitting = false
			else:
				refit(sim)
				continue
		if not sim.enemies_in(sim.current()).is_empty():
			fight(sim)
			continue
		if sim.energy < 2800 or sim.torpedoes < 3 or sim.systems.values().any(func(v): return v < 90):
			refitting = true
			refit(sim)
			continue
		if sim.heat > 50:
			order(sim, "FIX all 0.5")
			continue
		var target = -1
		var best = INF
		for index in sim.fleet_contacts():
			var distance = Vector2(sim.quadrant).distance_to(Vector2(index / 8, index % 8))
			if distance < best:
				target = index
				best = distance
		if sim.relief.state == "active": target = sim.relief.quadrant
		if target < 0:
			order(sim, "REPORT")
			continue
		travel(sim, Vector2i(target / 8, target % 8))
	var outcome = "WIN" if sim.won else ("LOSS" if sim.ended else "STALLED")
	print("PILOT seed=%d %s days=%.2f/%.0f kills=%d remaining=%d crew=%d relief=%s orders=%d" % [seed_value, outcome, sim.elapsed, sim.mission_deadline, sim.kills, sim.remaining(), sim.crew, sim.relief.state, commands.size()])
	var record = FileAccess.open("/tmp/vulkantrek-pilot-%d.json" % seed_value, FileAccess.WRITE)
	record.store_string(JSON.stringify({"seed": seed_value, "won": sim.won, "elapsed": sim.elapsed, "orders": commands, "history": sim.history}, "  "))
	if not sim.won:
		failures += 1
		printerr("Last orders: ", commands.slice(maxi(0, commands.size() - 8)))
		printerr("Last messages: ", sim.messages)

func _init() -> void:
	for seed_value in [1994, 7, 42, 123, 2026]: run_seed(seed_value)
	print("PLAYTHROUGHS: 5 Captain missions, %d failures" % failures)
	quit(1 if failures else 0)
