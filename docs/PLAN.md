# VulkanTrek implementation plan

## Product target

Build a complete, balanced command strategy game inspired by EGATrek. Familiar
commands, scanning, shields, navigation and station resupply serve our own
explicit rules. DOS observations remain historical design references; exact
behavioral parity is no longer a release criterion.

## Milestone 2 — a complete Captain mission (implemented)

1. **Document the rules.** One main energy pool powers movement and lasers;
   shields retain their own reserve. Information, typing and menus are free.
   Movement and weapons permit an enemy response; repairs permit one per 0.1 day.
2. **Make navigation and costs clear.** Preview commands without changing state.
   Route local moves around obstacles, allow warp through intervening quadrants,
   and expose fleet intelligence so finding the last enemy is not a guessing game.
3. **Build the opposition.** Generate a finite, rank-scaled fleet. Cruisers close
   range; scouts retreat and call an existing ally once; supply ships restore
   nearby shields; commanders strengthen nearby attacks. All movement respects
   occupied sectors, and reinforcements never create an endless invasion.
4. **Complete the mission arc.** Show the mission deadline and a timed, optional
   base-relief call. Preserve a dependable opening base. Win by clearing the fleet;
   lose through ship destruction or deadline expiry. Report score and relief outcome.
5. **Preserve continuity.** Save new mission and enemy state with deterministic
   continuation. Migrate existing saves explicitly to the new resource rules.
6. **Validate and deliver.** Test tactical rules, previews, persistence, deadline
   and relief outcomes. Run a command-only pilot over multiple seeded Captain
   missions using public navigation and combat commands, then exercise bridge
   layout and the packaged game. Record balance results and limitations.

Acceptance: the opening remains approachable; costs are visible before orders;
all surviving hostiles are discoverable; the finite fleet can be defeated through
normal commands across a seed sample; defeat and emergency outcomes work; saves
resume reproducibly. Automated pilots assess feasibility, not human enjoyment.
Human playtesting remains necessary to tune pacing and difficulty.

## Architecture

The scene-independent deterministic simulation owns rules and state. The bridge
prepares commands and renders pure cost previews; animation never advances time.
The scanner shows remembered local scans plus fleet intelligence. Godot Forward+
owns Vulkan rendering. No native renderer or external art pipeline is required.

Delivered: shared power and pure command previews, navigable finite fleets, class
behavior, timed relief and deadline outcomes, save migration, and the updated
bridge. Five seeded Captain missions pass through public commands; see
[validation](VALIDATION.md) for results and remaining human playtesting.

## Milestone 3 — playtest and release polish

Observe human Captain playthroughs, tune resources and pacing, then refine the
other ranks. Use the [playtest protocol](PLAYTEST.md) to record those sessions.
Add accessibility/audio/render options, richer effects and models,
benchmark Vulkan performance, and exercise native Linux and Windows releases.
Rare encounters are optional expansion work, not prerequisites for a complete game.
