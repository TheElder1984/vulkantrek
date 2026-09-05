# VulkanTrek implementation plan

## Product target

Recreate EGATrek 3.1 gameplay in a modern desktop Godot game. Preserve the command decisions, information available to the captain, resource tradeoffs, turn sequencing, and outcomes. Modernize presentation: original ship designs, 3D lighting, effects, typography, layout, and optional mouse input.

The completion criterion is **behavioral parity**, not merely a similar Star Trek game. The current playable build is the first implementation milestone; it does not satisfy that final criterion yet.

## Architecture

```text
Keyboard / function keys / map selection
                   │
                   ▼
        Bridge command adapter
                   │
                   ▼
     Deterministic mission simulation
       │          │            │
   state view   effect events  versioned save
       │          │
       ▼          ▼
  Console/maps   Godot 3D / shaders / audio
```

The simulation is a `RefCounted` object with no `_process` callback. It accepts complete commands and emits state and visual events. Frame rate, camera position, and animation duration cannot alter the outcome. Saves retain generator state for reproducible continuation.

Rendering uses Godot’s Forward+ backend and Vulkan driver. A separate native Vulkan wrapper would duplicate Godot’s device ownership and is unnecessary for this game. Add RenderingDevice compute work only if profiling finds a rendering requirement that scene-level APIs cannot meet.

## Milestone 1 — runnable command bridge (implemented)

- Seeded galaxy, persistent quadrants, obstacles, scanned chart, terminal victory/loss.
- Command validation, coordinates, manual navigation, resource allocation, combat and repair loops.
- Station resupply, planetary exploration, emergency energium, guarded destructive orders.
- Keyboard and click-to-prepare controls, original function-key mapping, command history, help and communications.
- Procedural ships and stations, cinematic/overview cameras, sky shader, engine emission, shields, beams, torpedoes, explosions, synthesized sound.
- Versioned atomic save, restore validation, RNG continuation.
- Tests, real Vulkan launch, live screenshot, local development package.

## Milestone 2 — exact rules reconstruction (outstanding)

1. Run the original 3.1 executable under a DOS emulator and record rank-specific starts. Capture all energy bank capacities, initial values, torpedo inventory, galaxy distributions, and scoring outputs.
2. Construct controlled encounters using repeatable DOS saved states. Measure impulse/warp cost and elapsed time, path interruption behavior, laser attenuation and heat, shield penetration, torpedo spread and collision, repair rate and enemy reaction timing.
3. Trace hostile movement and special abilities by ship class. Implement commander actions, supply/scout behavior, Vandal encounters, hostile bases, black holes, supernovas, distress calls, timed base attacks, and evacuation events using observed rules.
4. Replace provisional coefficients and event selection with verified rules. Preserve observations and discrepancy notes alongside executable tests; do not bless current values merely because their tests pass.
5. Compare complete mission transcripts at all five ranks, including losses, rescues, self-destruct, and death-ray failure. Reproduce scoring, promotions and the two best scores per rank.
6. Resolve presentation departures: staged torpedo prompts, manual-navigation prompts, original restore flow, and viewer selection. Keep optional mouse conveniences equivalent to the original command path.

Acceptance: for each observable DOS fixture, the same actions produce the same movement, resources, damage, elapsed time, information and result, subject only to the captured random input. Every remaining mismatch must be documented; zero unexplained differences before calling the game “exact.”

## Milestone 3 — presentation finish and release (outstanding)

- Replace procedural first-pass geometry with authored high-detail original models, materials and LODs while preserving silhouettes and scanner readability.
- Choreograph weapon impact timing, engine trails and localized shield strikes; add layered sound and configurable volume.
- Add options for font scaling, reduced motion, audio, render quality, full screen, and accessible faction indicators.
- Test long sessions and state compatibility; benchmark 1080p/1440p frame time on several Vulkan GPUs. Target stable 60 fps with adjustable quality.
- Create signed/reproducible native builds with Godot release templates; test clean Linux and Windows installs. Add platform-specific export presets after those targets are exercised.

## Verification already performed

See [VALIDATION.md](VALIDATION.md). Passing current tests validates this implementation’s invariants; it does not establish DOS parity.
