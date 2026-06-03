# Z80PACK Compatible Disk Images

This repository contains Z80PACK compatible `.dsk` disk images containing software that isn't included in Z80PACK. All of these programs are newly developed starting in Jan, 2026.

This repository is meant as a distribution point for these disk images. Source code for the programs on these disks may be found in other repositories if I have published that source.

## Compatibility

These disks have been lightly tested. They should work with:

1. Z80PACK emulation
2. The High Nibbles IMSAI 8080, VT100, DAZZLER and Tek4010 emulators
3. The RTR CP/M Emulation system (CPMEMU)
4. Physical hardware / real S-100 systems that meet the requirements

The disk images typically have a `README.TXT` file with instructions etc.

> **Note:** Files marked with `@` haven't been published yet.

## File Index

| File | Description |
|------|-------------|
| `TETRIS.DSK` | TETRIS written for the DAZZLER video card. Requires a DAZZLER, DAZZLER II or emulated video card. |
| `@SEDIT.DSK` | Full screen text editor (VT100/VT52/ANSI/other terminals) |
| `@HEDIT.DSK` | Full screen HEX editor (VT100/VT52/ANSI/other terminals) |
| `@SUTILS.DSK` | A collection of utilities for CP/M |
| `@SCOPY.DSK` | File copier, understands user spaces and has `<TAB>` expansion for filenames |
| `@MUSIC.DSK` | A music player and music files. Requires the Cromemco D+7AIO card (or emulated card). |
| `@TALK.DSK` | A port of the SAY program from the 6502 to the Z80. Requires the Cromemco D+7AIO card (or emulated card). |
| `@HD_PLOT_1.DSK` | Collection of Tektronix 4010 terminal images and the player program |
| `@HD_PLOT_2.DSK` | Collection of Tektronix 4010 terminal images and the player program |
| `@HD_PLOT_3.DSK` | Collection of Tektronix 4010 terminal images and the player program |
| `@MANDEL.DSK` | Mandelbrot program for the Tektronix 4010 terminal. Requires a Tektronix 4010 terminal (or emulated terminal). |
