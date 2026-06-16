# tk/ — CPMEMUTK turnkey build for TETRIS

This directory drives a headless build of TETRIS inside emulated CP/M. The
top-level `build.bat` runs `cpmemutk.exe --script tk/build.tks`, which assembles
all seven .MAC modules with M80, links them with L80, and copies `TETRIS.COM`
back to the project root. The build runs without any keypresses and returns a
real exit code (0 = OK, 1 = tool error, 66 = missing file).

## What's in here

Committed:
- `CPMEMU.CNF` — minimal headless config (no Dazzler/Sound, FIF_LOCAL).
- `diskmap.json` — A: bootable CP/M, B: `src.unpacked` (work disk).
- `build.tks` — the CP/M-side build script (M80 ×7, L80).
- `memon80.hex` — IMSAI MEMON/80 boot ROM.
- This README.

Gitignored — supply your own copy before the first build:
- `cpmemutk.exe` — copy from your CPMEMU build at
  `cpmemu/build-tk/cpmemutk.exe`.
- `qpm22d01.unpacked/` — bootable CP/M 2.2 disk (drive A:). Use any
  CP/M 2.2 `.unpacked` directory; the QPM 2.2 distribution that ships
  with CPMEMU works out of the box. Drop it in as `tk/qpm22d01.unpacked/`.
- `src.unpacked/0/M80.COM` and `L80.COM` — the M80/L80 binaries (the
  20096-byte M80 build; the 20224-byte build has broken MACRO support).
  Source `.MAC` files are staged into this folder by `build.bat` on
  every run and don't need to be checked in.

## Running

From the project root:

    build.bat

Outputs:
- `TETRIS.COM` in the project root and in `D:\CPMEMU\disks\*.unpacked\0\`
- `TETRIS.dsk` (distribution disk image) in the project root
- `tk/build.log` (full CP/M console capture)
- `tk/build.xml` (JUnit report, one test per `.CHECK` / `.EXIST` assertion)

If the build fails, `tk/build.log` is the first place to look. The exit code
from `cpmemutk.exe` is propagated through `build.bat`, so CI can branch on it.
