# EGATrek 3.1 parity register

**Exact gameplay has not been established.** This register prevents an attractive reconstruction from being mistaken for a verified port.

Reference baseline: the author’s `EGATREK.DOC` and `EGATREK.REF` in the [EGATrek 3.1 shareware package](https://www.dosgamesarchive.com/file/egatrek/egatrk31). A [readable manual mirror](https://www.scribd.com/document/552541416/EGA-Trek-Manual) was used initially; the original archive was subsequently downloaded to `/tmp/egatrek-reference` for local command-reference checks. It is not included in the repository.

## Implemented, with documented interface or threshold evidence

| Area | Current implementation | Remaining work |
|---|---|---|
| Coordinate conventions | 8×8 quadrants, 8×8 sectors, row first, compact and separated input | Compare path interruption, rounding and intermediate-quadrant behavior |
| Navigation computer | Automatic and relative manual movement | Exact prompt flow and displacement parsing edge cases |
| Ship operations | Warp, impulse, shields, energy transfer, repair focus | Verify costs and elapsed time |
| Sensors | Automatic neighboring scans and persistent chart; damage reduces information | Exact chart-loss behavior and display thresholds at boundaries |
| Weapons | Laser allocations, heat, up to three torpedo targets; tube damage limits salvo | Exact damage, heat curve, flight/spread and prompt behavior |
| Stations | Three supply profiles, adjacent docking, StarBase protection | Service timing and enemy siege behavior |
| Exploration | Orbit, transporter/shuttle landing, supplies and rescues | Survey content, rescue triggers and evacuation deadlines |
| Commands | Reference shortcuts and F1–F10 roles; S maps to SELF, SAVE remains explicit | DOS shell/boss mode intentionally omitted |
| Time | Order-driven progression, no real-time combat | Per-command turn cadence still provisional |

## Provisional rules: do not treat these as original constants

These numbers are choices in this implementation, not measurements from EGATrek:

- Main energy capacity 5000, laser capacity 2000, initial shield energy 1500, torpedo inventory 10.
- Enemy shield capacities 240/300/450/800 and generation counts `12 + 8 × rank`, capped at six hostiles in a quadrant.
- A deliberately fixed opening encounter and friendly base for repeatable onboarding.
- Linear route sampling that rejects the entire move when any occupied cell is encountered.
- Impulse and warp cost formulas; minimum movement duration; warp damage probability and severity.
- Laser range attenuation, heat gain/cooling, and efficiency floor.
- Torpedo hit strength, distance falloff and shield-raised inaccuracy.
- Enemy fire on accepted combat/movement/wait actions, damage range, subsystem hits and crew losses.
- Repair rate baseline, regeneration integration order, and step size during waiting.
- Deterministic local nova blast radius, death-ray success chance/failure outcome, raw energium restoration.
- Mission score formula and generated colony population.

## Missing gameplay systems

- Hostile movement, class-specific tactics, escape/reinforcement/supply behavior.
- Vandal encounters and the Mongol base.
- Black holes and galactic supernova events.
- Base distress/attacks, timed rescues, and broader random event scheduling.
- Original scoring, promotion and persistent hall of fame.
- Full original viewer modes and precise prompts/acknowledgement behavior.

The current mission is playable from start to win or loss, but these omissions and provisional formulas mean it is **not yet gameplay-identical**. Their implementation requires observation of the DOS program; the manual does not define enough detail to reconstruct them exactly.

## Modern presentation choices

The map can prepare commands by mouse; orders still require Enter. A cinematic camera complements the tactical overview. The game can restore from the running bridge and displays a visible reference button. Procedural meshes, shaders, UI, audio and saves are new. These choices can coexist with exact rules once the simulation is verified.
