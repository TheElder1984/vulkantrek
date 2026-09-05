# Validation record

Tested on 2026-09-05 using the official Godot 4.5.1 Linux x86_64 binary.

## Automated checks

- `tests/test_simulation.gd`: **403 checks passed, zero failures.** Includes seeded generation/non-overlap, scan boundaries, invalid-command atomicity, energy conservation, shield behavior, weapon limits, combat outcomes, docking supply profiles, repairs, manual navigation, damaged devices, landing requirements, depleted planetary supplies, terminal outcomes, save/load continuation and corrupt saves.
- `tests/test_bridge.gd`: **passed, zero failures.** Covers initialization, frame-time independence, parameter prompts, map preparation, navigation execution, docking, original `S` shortcut, help/chart/new-mission dialogs, and minimum layout dimensions.
- Bridge minimum layout: **1068 × 1000 design units**, within the configured 1600 × 1000 canvas. Window minimum is 1280 × 800 with canvas scaling.
- `bash -n tools/run.sh build/play.sh`: passed.

## Rendering

The game launched through **Vulkan 1.4.329 / Forward+** on **NVIDIA GeForce RTX 3060**. The final bridge was captured from Godot’s viewport into `bridge-preview.png`. Shader compilation and initial rendering completed without reported errors.

The screenshot was visually inspected. Earlier clipping at the bottom of the bridge and procedural-model allocation leaks were corrected. Cinematic and tactical overview camera paths are included; animation does not run the simulation.

## Packaging

The included Linux export preset produces `build/VulkanTrek.pck`. `build/play.sh` launches it with the bundled official Godot engine binary. This is a development package, not a signed release export. The runtime is covered by `build/GODOT-LICENSE.txt`.

The final pack was launched from `/tmp`, outside the source tree, with Vulkan Forward+. The automated opening combat sequence completed with `BRIDGE_SMOKE_OK`, exit code 0, and no reported errors or leaks. The bundled runtime was byte-compared with the tested engine binary and matches it.

## Limits of the evidence

These tests demonstrate internal consistency and successful execution on this workstation. They do not establish EGATrek behavioral parity, performance on other GPUs, Windows support, or release readiness. Original combat formulas, timing, enemy events, scoring, and several encounter systems remain unverified or unimplemented; see `PARITY.md`.
