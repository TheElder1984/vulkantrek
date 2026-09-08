# Validation record — ruleset 2

Tested on 2026-09-05 with official Godot 4.5.1 Linux x86_64.

Rechecked on 2026-09-07: simulation (410 checks), campaign (43 checks), bridge
and all five Captain playthroughs passed with the same results below. Shell
syntax and diff whitespace checks also passed. The sandbox initially prevented
Godot from opening its user-data log; the checks passed when rerun with the
existing runtime permission. The packaged game also passed its headless smoke
check from `/tmp` (`BRIDGE_SMOKE_OK`, exit 0). No new graphical validation was
performed.

## Automated checks

- Simulation: **410 checks, zero failures**. Generation/non-overlap, initial
  defaults, resources, combat, docking, repair, navigation, terminal states,
  deterministic persistence and malformed saves. The old count was 424; fewer
  generated objects means fewer per-object overlap assertions, not removed coverage.
- Campaign: **43 checks, zero failures**. Pure cost previews, shared laser power,
  finite fleet, routed impulse movement, class behavior, one-use ray, timed docking,
  relief success/failure, mission deadline, repair during transit, immediate lethal
  damage, version-1 migration, event validation and active enemy/RNG continuation.
- Bridge: **passed, zero failures**. Command preparation and visible costs,
  map plotting, combat, docking, dialogs and independence from rendering time.
  Minimum layout remains **1068 × 1000 design units**, within the 1600 × 1000 canvas.
- `bash -n tools/run.sh build/play.sh` and `git diff --check`: passed.

## Full Captain missions

The pilot uses public commands for all state changes. It receives fleet/station
intelligence, local contacts and the laser solutions exposed by INFO. It does
not grant resources, teleport, edit the RNG, remove enemies or extend deadlines.
It returns to bases, cools weapons, focuses life-support repair when necessary,
and prioritizes the optional relief call.

| Seed | Result | Elapsed / 36 days | Kills | Crew | Relief | Orders |
|---|---|---:|---:|---:|---|---:|
| 1994 | Win | 17.82 | 24 | 430 | Saved | 119 |
| 7 | Win | 16.55 | 24 | 429 | Saved | 123 |
| 42 | Win | 18.58 | 24 | 430 | Saved | 122 |
| 123 | Win | 19.52 | 24 | 430 | Saved | 125 |
| 2026 | Win | 20.56 | 24 | 430 | Saved | 133 |

Transcripts are generated at `/tmp/vulkantrek-pilot-<seed>.json`; a compact result
record is retained in `tests/fixtures/captain_playthroughs.json`. The pilot exposed
an overly sensitive computer failure threshold and incorrect life-reserve use
during long travel. Both were corrected. A later low-reserve loss demonstrated
why focused life-support repair matters before travel; the cost preview now
communicates that risk, and the pilot uses the same repair command available to players.

## Rendering and packaging

The updated bridge ran with **Vulkan 1.4.329 / Forward+ on NVIDIA RTX 3060**.
The initial state was captured into `bridge-preview.png` and visually inspected.
A second live view exercised the gold relief marker, countdown and a prepared
warp order's energy/time preview; no clipping or runtime errors were observed.
This is a functional visual check, not a frame-time benchmark.

The local `build/VulkanTrek.pck` development package is rebuilt with the current
rules. The bundled runtime remains the official development engine, not a signed
release export. The smoke mode asserts the opening kills, remaining fleet and
shared power balance before reporting success. The rebuilt pack passed from
`/tmp`, outside the source tree: **BRIDGE_SMOKE_OK**, exit 0, no reported errors.

## Limits and next playtest

Five successful automated missions establish a feasible loop across this sample;
they do not establish human enjoyment, every-seed solvability, difficulty balance
at other ranks, performance on other GPUs, or Windows support. The experienced
pilot has exact INFO solutions and does not represent a first-time player.

Next, watch human Captain playthroughs: measure how often players consult help,
misunderstand the forecast, run out of power, miss relief, or fail to locate a
refit station. Tune pacing from those observations. Original DOS research is
historical reference work, not the correctness standard for this ruleset.
Use [PLAYTEST.md](PLAYTEST.md) for the session procedure and observation record.
