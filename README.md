# VulkanTrek

A playable Godot 4 reconstruction of Trek’s command bridge, with Vulkan Forward+, procedural 3D ships, a nebula sky, glowing engines, shield fields, weapon effects, and a modern console.

**Status: playable reconstruction, not yet an exact Trek replacement.** The familiar command loop is implemented. Combat constants, mission generation, timing, scoring, and uncommon encounters still need comparison against the DOS executable. See [the parity register](docs/PARITY.md) and [implementation plan](docs/PLAN.md).

![VulkanTrek bridge](docs/bridge-preview.png)

## Run

Open `project.godot` in **Godot 4.5 or newer**, then press **F6** with the main scene open, or **F5** to run the project.

On this workstation:

```bash
./tools/run.sh
```

The launcher finds `godot4`, `godot`, the runtime downloaded to `/tmp/godot` during development, or a runtime specified with `GODOT_BIN`:

```bash
GODOT_BIN=/path/to/Godot ./tools/run.sh
```

The default desktop renderer is Forward+ with Vulkan. For an older GPU, explicitly request Compatibility; lighting and effects will differ:

```bash
./tools/run.sh --rendering-method gl_compatibility --rendering-driver opengl3
```

A local packaged build is available in `build/` after packaging. Launch `build/play.sh`. It includes a Godot runtime and game pack and does not require the editor or source tree. This development package uses the downloaded official engine binary; production exports should use matching release export templates and the included Linux preset.

## First encounter

The default seed is `1994`, Captain difficulty. The Lexington starts at quadrant 4,4, sector 5,4, near a StarBase and two hostiles.

```text
MAX
SHUP
INFO
LASERS 900 650
DOCK
```

The opening salvo clears this encounter. Docking restores your banks and torpedoes. From there, use the galaxy chart to locate scanned enemies, navigate along a clear course, and clear the invasion fleet. `HAIL` locates a StarBase. Unknown quadrants stay hidden until scanned.

Both charts prepare a movement command when clicked; **Enter executes it**. Coordinates are always **row, column**, starting at 1. `M35` moves locally to sector 3,5; `M6235` travels to quadrant 6,2 sector 3,5. Obstacles block plotted routes; choose intermediate waypoints when needed.

Press **F1** for the in-game command reference. F2–F10 preserve the original function-key roles. Up/down raise/lower shields; Ctrl+up/down browse your command history. Escape cancels parameter entry. `S` is guarded self-destruct; use the full `SAVE` command to save.

Time advances through simulation commands only. Opening help, watching animations, typing, and selecting map cells do not advance combat.

## Project structure

- `scripts/simulation.gd`: seeded mission state, command validation, combat, navigation, repairs, scanning, persistence; independent of the scene tree.
- `scripts/bridge.gd`: bridge controls, command prompts, help, sound, save/restore, mission setup.
- `scripts/scanner.gd`: short-range map and remembered galaxy chart.
- `scripts/space_view.gd`: procedural ships, stations, tactical and cinematic cameras, transient effects.
- `shaders/`: procedural sky and shield surface shaders.
- `tests/`: simulation and bridge regression suites.
- `docs/`: design plan, parity register, validation record, preview.

There are no third-party art assets, plugins, .NET dependencies, or custom Vulkan native bindings. Godot owns the rendering device; the game uses scene nodes, materials, and shaders.

## Validate

Import the project once before running tests from a fresh checkout:

```bash
./tools/run.sh --headless --editor --quit
./tools/run.sh --headless --script res://tests/test_simulation.gd
./tools/run.sh --headless --script res://tests/test_bridge.gd
./tools/run.sh --headless -- --smoke-test
```

Capture the live Vulkan bridge:

```bash
./tools/run.sh --rendering-method forward_plus --rendering-driver vulkan -- --capture
```

This writes `docs/bridge-preview.png` and exits. Saves go to Godot’s `user://mission.save`, separate from the repository. Test fixtures use `/tmp/vulkantrek-*.save`.

## Reference

Trek is Nels Anderson’s game. This project contains new code and procedural artwork, with no original executable, text, or graphics redistributed. The gameplay reference is particularly `TREK.DOC` and `TREK.REF` from its [original shareware archive](https://www.dosgamesarchive.com/file/trek/trk31). Godot’s [renderer documentation](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) describes Forward+ and Vulkan.
