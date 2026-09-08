# EGATrek 3.1 observations — 2026-09-05

Historical research pass, retained for provenance. The project subsequently
adopted its own ruleset; exact parity is no longer the milestone target. These are direct
screen observations of the original executable, not inferred combat formulas.
The source is the [original shareware archive](https://www.dosgamesarchive.com/file/egatrek/egatrk31).
Archive and executable SHA-256 hashes, sample coordinates and screenshot hashes
are recorded in [the machine-readable fixture](../tests/fixtures/egatrek31_starts.json).

## Starting state

DOSBox 0.74-3, EGA, fixed 10,000 cycles. Enter through the title screen, decline
briefing and restore, enter captain name `parity`, select rank, submit an empty
self-destruct password, then issue `ENERGY`. Each row is an independent start.
Rank 4 was repeated until a quiet quadrant allowed an undamaged reading.

| Rank | Stardate | Warp | Main bank | Impulse bank | Shield bank | Hostiles in this sample |
|---|---|---|---|---|---|---|
| 1 | 3500.0 | 1.0 | 5000, 100% | 500, 100% | 2500, 100% | 25 |
| 2 | 3500.0 | 1.0 | 5000, 100% | 500, 100% | 2500, 100% | 26 |
| 3 | 3500.0 | 1.0 | 5000, 100% | 500, 100% | 2500, 100% | 42 |
| 4 | 3500.0 | 1.0 | 5000, 100% | 500, 100% | 2500, 100% | 47 |
| 5 | 3500.0 | 1.0 | 5000, 100% | 500, 100% | 2500, 100% | 55 |

The simulation now starts at warp 1, stardate 3500 and full shield charge.
Its existing 5000 main-bank and 2500 shield-bank limits agree with the display.
Regression checks read the external fixture for all five ranks. Existing saves
retain their stored values; the save format is unchanged.

## Discrepancies requiring controlled follow-up

- The engineering report contains main, impulse and shield banks. Our simulation
  lacks the separate impulse bank and provides a provisional laser bank. The
  laser panel's 0–1500 scale is temperature, not an observed energy capacity.
  Measure transfer destinations, movement debits, regeneration and laser power
  sourcing before changing the resource model and save format together.
- Original starting quadrants, sectors and hostile counts vary. Another rank-1
  start had 17 hostiles; a rank-4 start had 56. These few samples do not establish
  ranges, distributions, or generation formulas. Our fixed opening is still a
  deliberate departure.
- Two hostile rank-4 starts took shield damage before the energy report could be
  captured, without issuing a weapon or movement order. One showed main 4994.2,
  shields 1743.8 and messages at 3500.1–3500.3. This establishes a timing mismatch
  with our command-only loop, but does not distinguish startup reactions, typed
  input, informational orders or idle-time advancement. Compare controlled
  waits and identical keystrokes from DOS saved states next.
- Torpedo count, initial raised/lowered shield state, scores, promotions and
  complete galaxy contents have not been reliably transcribed in this pass.

## Repeat a capture

On Linux, provide DOSBox **0.74 with SDL 1.2**, GCC and an independently obtained
directory containing `EGATREK.EXE`. DOSBox-X and SDL 2 event layouts are not
supported by this adapter. No desktop access is needed.

```bash
python3 tools/parity/capture_start.py \
  --game-dir /path/to/egatrek31 \
  --rank 3 \
  --output /tmp/egatrek-rank3-new
```

Use `--dosbox /path/to/dosbox` for a local runtime, with `LD_LIBRARY_PATH` if its
libraries are not installed. Output must be a new directory. The tool copies
only the executable into an isolated DOS drive, builds a small SDL input adapter,
captures the bridge and engineering report, then stops the interactive process.
It records input timing, logs and hashes in `manifest.json`. Inspect both PNGs:
two screenshots alone do not prove that the expected prompts were reached.
The adapter injects keyboard events and does not modify game memory or RNG.

Private reference material from this session is retained under the ignored
`.reference/egatrek31/` directory. The original archive, executable and graphics
are not part of the tracked project. Observation hashes identify those local
artifacts; fresh runs will differ because the original RNG is uncontrolled.

## Next experiment

Create DOS saves in a quiet quadrant and in a single-hostile encounter. Compare
idle intervals, information orders and one-step movement from the same save.
Record banks, dates, damage and command prompts before and after each action.
Then reconstruct impulse/laser resource use and reaction cadence before moving
on to class-specific behavior and rare encounters.
