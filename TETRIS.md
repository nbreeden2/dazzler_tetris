# Tetris for Cromemco Dazzler — Implementation Spec (v1.11)

## Target Platform

- CPU: Intel 8080 (2-4 MHz, S-100 bus)
- Display: Cromemco Dazzler, 64x64 pixels, 16 colors
- Graphics: D64X64 library (d64x64.mac, d64x64a.mac, d64x64b.mac)
- OS: CP/M 2.2
- Assembler: Microsoft M80 / L80
- Input: CP/M console keyboard (BDOS function 6, direct I/O)
- Text output: CP/M console terminal (score, level, lines display)

## Dual Display

The Dazzler shows the game graphics. The CP/M console terminal shows text information (score, level, lines cleared, game over message). This avoids the need for bitmap font rendering on the 64x64 display.

---

## Screen Layout (64x64 pixels)

### Cell Size: 3x3 pixels

Each Tetris cell is a 3x3 pixel block.

### Playfield

- Standard Tetris: 10 columns x 20 rows
- Pixel dimensions: 30 wide x 60 tall
- Position: playfield interior from X=1,Y=3 to X=30,Y=62

### Borders

- Left wall: X=0, Y=2 to Y=63 (1-pixel-wide vertical line)
- Right wall: X=31, Y=2 to Y=63
- Bottom wall: Y=63, X=0 to X=31
- Top edge: Y=2, X=0 to X=31
- Color: GREY (7)

### Next Piece Preview

- Preview box: upper-right area
- Box border: X=40 to X=55, Y=2 to Y=17, GREY outline
- Piece drawn inside at 3x3 cell size, origin at X=42, Y=5
- Shows upcoming piece in rotation state 0

### Hold Piece Box

- Hold box: below next box
- Box border: X=40 to X=55, Y=19 to Y=34, GREY outline
- Held piece drawn inside at 3x3 cell size, origin at X=42, Y=22
- Shows held piece in rotation state 0
- Disableable via /HD command-line switch

### Level Indicator

- A vertical bar between the playfield and the preview/hold boxes
- Position: X=33 to X=37, Y=2 to Y=37
- Height increases with level (3 pixels per level, max 12 segments)
- Bar grows upward from Y=37
- Color: BCYAN (14)

### TETRIS Logo

- Pixel art logo in the bottom-right area
- Position: X=34, Y=45 (6 characters, each 4x7 pixels)
- 1-pixel gap between characters, total 29x7 pixels
- Each letter has a unique color: T=red, E=cyan, T=yellow, R=green, I=blue, S=purple
- Characters stored as bitmap data (7 bytes per character, upper nibble = 4 pixels)

### Complete Layout Map

```
0         1         2         3         4         5         6
0123456789012345678901234567890123456789012345678901234567890123
+----------------------------------------------------------------+  Y=0
|                                                                |  Y=1
|B==============================B L  B===============B           |  Y=2
|B                              B L  B               B           |  Y=3
|B                              B L  B  Next Piece   B           |  Y=4
|B                              B L  B   (3x3 cells) B           |  Y=5
|B        Playfield             B L  B               B           |  Y=6-16
|B        10 cols x 20 rows    B L  B===============B           |  Y=17
|B        (30 x 60 pixels)     B L                              |  Y=18
|B                              B L  B===============B           |  Y=19
|B                              B L  B               B           |  Y=20
|B                              B L  B  Hold Piece   B           |  Y=21-33
|B                              B L  B               B           |  Y=34
|B                              B L  B===============B           |  Y=35-37
|B                              B                                |  Y=38-44
|B                              B    TETRIS logo (4x7 chars)     |  Y=45-51
|B                              B                                |  Y=52-62
|B==============================B                                |  Y=63
+----------------------------------------------------------------+

B = border pixel (GREY)
L = level bar (BCYAN, grows upward)
```

### Coordinate Mapping

To convert from game grid (col, row) to pixel position:
```
pixel_x = 1 + (col * 3)      ; col 0-9 -> pixel X 1,4,7,10,...,28
pixel_y = 3 + (row * 3)      ; row 0-19 -> pixel Y 3,6,9,12,...,60
```

Each cell is drawn as a filled 3x3 rectangle:
```
DZLFRECT: B=pixel_x, C=pixel_y, D=pixel_x+2, E=pixel_y+2, A=color
```

---

## Tetrominoes

### The 7 Pieces

| Piece | Name | Color | Dazzler Color | Rotations |
|-------|------|-------|---------------|-----------|
| I | Line | Cyan | BCYAN (14) | 2 |
| O | Square | Yellow | BYELLOW (11) | 1 |
| T | T-shape | Purple | BPURPLE (13) | 4 |
| S | S-skew | Green | BGREEN (10) | 2 |
| Z | Z-skew | Red | BRED (9) | 2 |
| J | J-shape | Blue | BBLUE (12) | 4 |
| L | L-shape | Orange | DYELLOW (3) | 4 |

Note: The Dazzler palette has no orange. Dim yellow (3) is the closest substitute for the L-piece.

### Rotation States (SRS)

Each rotation state is 8 bytes: 4 pairs of (dc, dr) offsets relative to the piece origin. The T-piece spawns with flat side down (SRS-correct).

### Data Format in Memory

Rotation data is stored as a flat lookup table. Each piece has a pointer to its rotation table via ROTIDX. Each rotation state is 8 consecutive bytes: dc0, dr0, dc1, dr1, dc2, dr2, dc3, dr3.

### Wall Kicks (SRS)

Full Super Rotation System wall kicks are implemented with 5 test positions per rotation transition:
- **JLSTZ pieces**: shared kick table (symmetric across 0↔2 and 1↔3 state swaps)
- **I-piece**: separate unique kick table with larger offsets
- **O-piece**: no kicks (1 rotation state)
- Both CW and CCW rotation supported with separate kick tables (KICKTBL, KICKCCW)

---

## Game Board (Internal State)

### Board Array

- 10 columns x 20 rows = 200 bytes
- One byte per cell: 0 = empty, non-zero = Dazzler color of locked piece
- Stored row-major: byte[row * 10 + col]
- Row 0 = top of playfield, Row 19 = bottom

### Active Piece State

| Variable | Size | Description |
|----------|------|-------------|
| PCTYPE | 1 byte | Current piece type (0-6 for I,O,T,S,Z,J,L) |
| PCROT | 1 byte | Current rotation state (0-3) |
| PCCOL | 1 byte | Pivot column |
| PCROW | 1 byte | Pivot row |
| PCCLR | 1 byte | Piece color value (Dazzler color 0-15) |
| PCNEXT | 1 byte | Next piece type (0-6) |
| PCHOLD | 1 byte | Held piece type (0-6, FFH = empty) |
| HOLDOK | 1 byte | Hold allowed flag (0 = already held this turn) |

### Ghost Piece State

| Variable | Size | Description |
|----------|------|-------------|
| GSTROW | 1 byte | Ghost piece display row |
| GSTMOD | 1 byte | Ghost mode: 0=grey, 1=per-piece color, 2=disabled |
| GSTCLR | 1 byte | Ghost piece display color |

### Game State

| Variable | Size | Description |
|----------|------|-------------|
| SCORE | 2 bytes | Current score (16-bit) |
| LINES | 2 bytes | Total lines cleared (16-bit) |
| LEVEL | 1 byte | Current level |
| GAMOVR | 1 byte | Game over flag |
| COMBO | 1 byte | Consecutive line clear counter |
| LOCKING | 1 byte | Lock delay active flag |
| LOCKCNT | 1 byte | Lock delay counter |
| LOCKMVS | 1 byte | Lock delay move counter (max 15) |

### Configuration Flags

| Variable | Size | Description |
|----------|------|-------------|
| HLDDIS | 1 byte | Hold feature disabled (set by /HD) |
| SCRDIS | 1 byte | Real-time score display disabled (set by /SD) |
| PRESCL | 1 byte | CPU speed prescaler (5=2MHz, 10=4MHz) |

---

## Game Logic

### Initialization

1. Pre-scan command line for /? (display help and exit)
2. Display ASCII art title screen on console
3. Display controls and "Press any key to start..."
4. Wait for keypress (keypress timing seeds RNG)
5. Parse command-line switches (/4, /GC, /GD, /HD, /SD)
6. Call DZLINIT with HL=8000H (48K-safe frame buffer)
7. Clear screen with DZLCLR (BLACK)
8. Draw playfield border, next-piece box, hold-piece box (GREY)
9. Initialize board array to all zeros
10. Set score=0, level=0, lines=0, combo=0
11. Reset 7-bag randomizer (BAGIDX=7 forces refill)
12. Generate first piece, spawn, draw next preview
13. Draw level indicator bar and TETRIS logo
14. Print initial score/level/lines to console
15. Enter game loop

### Controls (Two Key Sets)

| Action | Primary | Alternate |
|--------|---------|-----------|
| Move left | A | J |
| Move right | D | L |
| Rotate CCW | W | I |
| Rotate CW | R | P |
| Soft drop | S | K |
| Hold piece | E | O |
| Hard drop | SPACE | SPACE |
| Quit | Q | U |

All keys are case-insensitive.

### Game Loop (Main Tick)

```
GAMELOOP:
    1. Check game over flag
    2. Poll keyboard (BDOS function 6, E=0FFH)
    3. If key pressed:
         - Perturb RNG seed
         - Dispatch to appropriate handler
    4. Decrement gravity prescaler
    5. If prescaler reaches 0, decrement gravity counter
    6. If gravity counter = 0:
         a. Reset gravity counter to current level's speed
         b. If in lock state (piece resting on surface):
              - Decrement lock delay counter
              - If expired or 15 moves exceeded: lock piece
         c. Else attempt to move piece down 1 row
              - If move fails: enter lock state
    7. JMP GAMELOOP
```

### Collision Detection

```
For each of the 4 cells (dc, dr) in the rotation state:
    test_col = col + dc
    test_row = row + dr
    If test_col < 0 or test_col >= 10 -> collision
    If test_row < 0 or test_row >= 20 -> collision
    If board[test_row * 10 + test_col] != 0 -> collision
Return: no collision
```

### Movement

- **Move left/right**: test new position, update if no collision, reset lock delay if successful
- **Rotate CW/CCW**: test rotation with SRS wall kicks (5 positions), update if any succeeds, reset lock delay
- **Soft drop**: move down 1 row, award 1 point per row
- **Hard drop**: drop to lowest valid position, award 2 points per row, lock immediately

### Lock Delay

- **Type**: Move Reset (resets timer on successful move or rotation)
- **Timer**: 128 gravity ticks (LCKMAX)
- **Move limit**: 15 moves/rotations per piece before forced lock
- Piece enters lock state when gravity cannot move it down
- Moving off a surface exits lock state

### Hold Piece

- Press E/O to swap current piece with held piece
- If no piece held: current piece stored, next piece spawned
- If piece held: current and held pieces swap, piece respawns at top
- Hold is locked until the next piece locks (one swap per piece)
- Disableable via /HD switch

### Ghost Piece

- Semi-transparent preview showing where the current piece will land
- Computed by dropping the piece position until collision
- Three modes controlled by command-line switches:
  - Default: grey (color 7)
  - /GC: per-piece colors (dim variants)
  - /GD: disabled (no ghost drawn)

### Locking

When the lock delay expires:

1. Write piece color into board array for each of the 4 cells
2. Check for lock-out: if any cell locked at row 0, game over
3. Check and clear completed lines
4. Score line clears, combo bonus, perfect clear bonus
5. Update level if lines threshold crossed
6. Redraw board, update level bar
7. Spawn next piece
8. If spawn collides: game over (block-out)

### Line Clearing

After locking a piece, scan rows 19 down to 0:

```
For each full row (all 10 cells non-zero):
    Shift all rows above down by 1
    Clear top row
    Increment line count
    Re-check same row (in case multiple adjacent)
```

### Scoring (Guideline-Compatible)

#### Line Clears

| Lines | Base Points |
|-------|-------------|
| 1 (Single) | 100 × (level + 1) |
| 2 (Double) | 300 × (level + 1) |
| 3 (Triple) | 500 × (level + 1) |
| 4 (Tetris) | 800 × (level + 1) |

#### Perfect Clear Bonus (added to line clear score)

| Lines | Bonus Points |
|-------|-------------|
| 1-line PC | 800 × (level + 1) |
| 2-line PC | 1200 × (level + 1) |
| 3-line PC | 1800 × (level + 1) |
| 4-line PC | 2000 × (level + 1) |

A perfect clear occurs when all 200 board cells are empty after line clearing.

#### Combo Bonus

50 × combo_count × (level + 1) for each consecutive line-clearing lock. Combo resets to 0 when a piece locks without clearing lines.

#### Drop Scoring

- Soft drop: 1 point per cell
- Hard drop: 2 points per cell

Score is a 16-bit value (max 65535).

### Level Progression

- Level = total_lines / 10
- Level cap: 15
- Level affects gravity speed via SPDTBL lookup

### Gravity Timing

Gravity is a software countdown. A prescaler accounts for CPU speed (5 for 2MHz, 10 for 4MHz). The gravity counter decrements each prescaler cycle.

| Level | Counter Value | Relative Speed |
|-------|--------------|----------------|
| 0 | 70 | Slowest |
| 1 | 60 | |
| 2 | 52 | |
| 3 | 44 | |
| 4 | 38 | |
| 5 | 32 | |
| 6 | 26 | |
| 7 | 20 | |
| 8 | 16 | |
| 9 | 12 | |
| 10+ | 12 | Fastest |

### Piece Spawning

1. Current piece = next piece (type, color, rotation data)
2. Generate new random piece via 7-bag randomizer
3. Set spawn position: col from SPNCOL table (3 for most pieces, 4 for O), row = 0
4. Test collision at spawn position
5. If collision: game over (block-out)
6. Set hold allowed flag

### 7-Bag Randomizer

Uses the standard 7-bag system: one of each piece type per bag, shuffled with Fisher-Yates algorithm. When the bag is exhausted (BAGIDX=7), it refills and reshuffles. The LFSR provides entropy for the shuffle.

### Game Over

Two game-over conditions:
- **Block-out**: newly spawned piece overlaps existing blocks
- **Lock-out**: piece locks with any cell at row 0

On game over:
1. Print "GAME OVER!" to console
2. Print final score, lines, and level
3. Prompt "Play again? (Y/N)"
4. If Y: clear screen, reinitialize all game state, start new game
5. If not Y: close Dazzler, exit to CP/M

---

## Command-Line Switches

```
Usage: TETRIS [/4] [/GC] [/GD] [/HD] [/SD]

  /4   4MHz CPU mode (default = 2MHz CPU)
  /GC  Enable color ghosts (default = Grey)
  /GD  Disable ghost pieces
  /HD  Disable hold feature
  /SD  Disable real-time score display
  /?   Display help and exit
```

- Multiple switches can be combined: `TETRIS /4 /GC`
- /GC overrides /GD if both specified (ghosts shown in color)
- Parser handles case-insensitive input
- /? is detected before the title screen is displayed

---

## Rendering

### Strategy: Differential Redraw

Do NOT clear and redraw the entire screen every frame. Instead:

1. **Erase active piece** at its old position (draw 4 cells in BLACK)
2. **Erase ghost piece** at its old position
3. **Move/rotate the piece** (update game state)
4. **Draw ghost piece** at new landing position
5. **Draw active piece** at its new position (draw 4 cells in piece color)
6. **Line clear**: redraw all non-empty cells from the board array

### Drawing a Cell

A single cell at grid position (col, row) with color:
```
pixel_x = 1 + (col * 3)
pixel_y = 3 + (row * 3)
DZLFRECT: B=pixel_x, C=pixel_y, D=pixel_x+2, E=pixel_y+2, A=color
```

Since the 8080 has no multiply instruction, `col * 3` is computed as `col + col + col`.

### TETRIS Logo Rendering

The logo is drawn pixel-by-pixel using DZLPSET. Each character is stored as 7 bytes (one per row), with the upper nibble encoding 4 pixels. A triple-nested loop iterates: 6 characters × 7 rows × 4 pixels. Only set pixels are drawn; the background is already black.

---

## Module Structure

The game is split across four assembly source files plus the D64X64 graphics library:

### Source Files

| File | Purpose |
|------|---------|
| tetris.mac | Main program, game loop, input dispatch, console I/O, command-line parser, 7-bag randomizer |
| tetmove.mac | Movement, collision detection, rotation with wall kicks, hard drop, locking, line clearing, scoring (ADDSCORE, ADDPC), level updates |
| tetdraw.mac | All Dazzler rendering: border, cells, pieces, next/hold preview, ghost piece, board redraw, level bar, TETRIS logo |
| tetdata.mac | Data tables (rotation, kicks, colors, speeds, scores, perfect clear, logo bitmaps) and all shared game variables |

### Build

```
M80 =TETRIS
M80 =TETMOVE
M80 =TETDRAW
M80 =TETDATA
M80 =D64X64
M80 =D64X64A
M80 =D64X64B
L80 TETRIS,TETMOVE,TETDRAW,TETDATA,D64X64,D64X64A,D64X64B,TETRIS/N/E
```

### Run
```
A>TETRIS
A>TETRIS /4 /GC
A>TETRIS /?
```

---

## Console Output

### Title Screen
```
                    TTTTT  EEEEE  TTTTT  RRRRR  IIIII  SSSSS
                      T    E        T    R   R    I    S
                      T    EEEE     T    RRRRR    I    SSSSS
                      T    E        T    R  R     I        S
                      T    EEEEE    T    R   R  IIIII  SSSSS

                             Cromemco Dazzler v1.11


            Q=Quit W=CCW  E=Hold R=CW      U=Quit I=CCW  O=Hold P=CW
            A=Left S=Drop D=Right          J=Left K=Drop L=Right
                               SPACE=Hard Drop

Press any key to start...
```

### During Play
Score/lines/level updated in-place using CR (0DH) without LF:
```
Score: 01200  Lines: 00010  Level: 00001
```
Disableable via /SD switch.

### On Game Over
```
GAME OVER!
Final Score: 12345
Final Lines: 42
Final Level: 4
Play again? (Y/N)
```

---

## Not Implemented

- **T-spin detection/scoring**: no 3-corner detection, too invasive for the architecture
- **Back-to-back bonus**: no tracking of consecutive difficult clears
- **DAS (auto-repeat)**: each keypress moves once; no hold-to-repeat
- **Entry delay (ARE)**: spawn is immediate after lock
- **Starting level selection**: always starts at level 0
- **High score persistence**: score is not saved to disk
- **Sound**: the Dazzler has no audio capability
- **Pause**: no pause function
- **20-row buffer zone**: playfield is flat 10x20, no hidden rows above
