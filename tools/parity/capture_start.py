#!/usr/bin/env python3
"""Capture an EGATrek 3.1 start through DOSBox 0.74's SDL 1.2 interface.

Requires Linux, gcc, DOSBox and a separately obtained original game directory.
Screenshots are observations, not assertions: inspect them before transcribing.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
from datetime import datetime, timezone


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game-dir", required=True, type=Path)
    parser.add_argument("--dosbox", default="dosbox")
    parser.add_argument("--rank", required=True, type=int, choices=range(1, 6))
    parser.add_argument("--output", required=True, type=Path,
                        help="New directory for private reference artifacts")
    args = parser.parse_args()
    source = args.game_dir.resolve()
    executable = source / "EGATREK.EXE"
    if not executable.is_file():
        parser.error("game directory must contain EGATREK.EXE")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    game = output / "game"
    game.mkdir()
    # Each run starts independently of any existing saves or score files.
    shutil.copy2(executable, game / executable.name)
    captures = output / "captures"
    captures.mkdir()
    library = output / "input.so"
    subprocess.run(["gcc", "-shared", "-fPIC", "-Wall", "-Wextra",
                    str(Path(__file__).with_name("sdl_input.c")), "-ldl",
                    "-o", str(library)], check=True)
    events = []
    time_ms = 800

    def type_text(value):
        nonlocal time_ms
        for char in value:
            events.extend([(time_ms, ord(char), 1, 0),
                           (time_ms + 60, ord(char), 0, 0)])
            time_ms += 140
        time_ms += 500

    def capture():
        nonlocal time_ms
        # SDL 1.2 key symbols: left Ctrl=306, F5=286. DOSBox screenshot.
        events.extend([(time_ms, 306, 1, 64), (time_ms + 60, 286, 1, 64),
                       (time_ms + 120, 286, 0, 64), (time_ms + 180, 306, 0, 0)])
        time_ms += 500

    inputs = ["\r", "n\r", "n\r", "parity\r", f"{args.rank}\r", "\r"]
    for value in inputs:
        type_text(value)
    capture()
    type_text("energy\r")
    capture()
    keys = output / "input.txt"
    keys.write_text("\n".join(" ".join(map(str, event)) for event in events) + "\n")
    config = output / "dosbox.conf"
    config.write_text(
        "[sdl]\noutput=surface\n[dosbox]\nmachine=ega\n"
        f"captures={captures}\n[cpu]\ncycles=fixed 10000\n"
        "[mixer]\nnosound=true\n[midi]\nmididevice=none\n"
        f'[autoexec]\nmount c "{game}"\nc:\negatrek\nexit\n')
    env = dict(os.environ, SDL_VIDEODRIVER="dummy", SDL_AUDIODRIVER="dummy",
               LD_PRELOAD=str(library), TREK_INPUT=str(keys))
    timed_out = False
    with (output / "dosbox.log").open("w") as log:
        try:
            result = subprocess.run([args.dosbox, "-conf", str(config)], env=env,
                                    stdout=log, stderr=log,
                                    timeout=(time_ms + 1000) / 1000)
            result.check_returncode()
        except subprocess.TimeoutExpired:
            # This interactive program remains at the energy prompt.
            timed_out = True
    screenshots = sorted(captures.glob("*.png"))
    metadata = {
        "captured_utc": datetime.now(timezone.utc).isoformat(),
        "executable_sha256": hashlib.sha256(executable.read_bytes()).hexdigest(),
        "rank": args.rank, "inputs": inputs + ["<capture>", "energy\r", "<capture>"],
        "machine": "ega", "cycles": 10000, "stopped_after_capture": timed_out,
        "screenshots": {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in screenshots},
        "note": "Inspect screenshots; startup RNG and enemy activity are not controlled."
    }
    (output / "manifest.json").write_text(json.dumps(metadata, indent=2) + "\n")
    if len(screenshots) != 2:
        raise SystemExit(f"Expected two screenshots, found {len(screenshots)}; inspect {output}")
    print(output / "manifest.json")


if __name__ == "__main__":
    main()
