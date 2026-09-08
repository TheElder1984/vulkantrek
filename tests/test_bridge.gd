extends SceneTree
var failures = 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	check(scene.command != null and scene.space != null, "bridge initialized")
	var time: float = scene.sim.elapsed
	await create_timer(0.1).timeout
	check(scene.sim.elapsed == time, "rendering never advances simulation")
	scene.fill_command("LASERS 900 650")
	check(scene.preview_label.text.contains("1550 main used") and scene.sim.elapsed == time, "visible cost preview does not execute order")
	scene.prepare_command("SHUP")
	check(scene.command.text == "SHUP" and not scene.sim.shields_up and scene.preview_label.text.contains("50 main used"), "shield shortcut prepares a priced order")
	scene.prepare_command("LASERS")
	check(scene.pending == "LASERS", "laser prompt entered")
	scene.submit("900 650")
	check(scene.sim.kills == 2 and scene.pending.is_empty(), "parameter prompt executes salvo")
	scene.fill_command("M53")
	check(scene.command.text == "M53" and scene.sim.sector == Vector2i(4,3), "click preparation never executes navigation")
	scene.submit(scene.command.text)
	check(scene.sim.sector == Vector2i(4,2), "prepared navigation executes")
	scene.submit("DOCK")
	check(scene.sim.docked == 1, "docking through bridge")
	scene.plot_quadrant(Vector2i(0, 0))
	check(scene.sim.preview(scene.command.text).ok, "galaxy click chooses an empty arrival sector")
	check(scene.mission_label.text.contains("days remaining"), "deadline visible on bridge")
	scene.submit("S")
	check(not scene.sim.ended and scene.sim.history.back().contains("SELF CONFIRM"), "S is guarded self-destruct, not save")
	scene.show_help()
	check(scene.dialog.visible, "reference dialog opens")
	scene.dialog.hide()
	scene.show_chart()
	check(scene.dialog.visible, "chart command opens")
	scene.dialog.hide()
	scene.show_new_mission()
	check(scene.new_dialog.visible, "new mission dialog opens")
	scene.new_dialog.hide()
	await process_frame
	for node in scene.find_children("*", "MarginContainer", false, false):
		print("LAYOUT_MIN ", node.get_combined_minimum_size())
		check(node.get_combined_minimum_size().y <= 1000, "bridge fits design height")
	scene.queue_free()
	await process_frame
	await process_frame
	print("BRIDGE: interaction, prompt, layout and clock checks; %d failures" % failures)
	quit(1 if failures else 0)
