# Tetris for Cromemco Dazzler — Minimal Implementation Spec

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

Each Tetris cell is a 3x3 pixel block. This gives the best visual clarity on the 64x64 grid.

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

- Label: not displayed (no text on Dazzler)
- Preview box: upper-right area
- Box border: X=40 to X=55, Y=2 to Y=17, GREY outline
- Piece drawn inside at 3x3 cell size, centered in box
- The preview area fits a 4x4 cell region (12x12 pixels)

### Level Indicator

- A vertical bar in the lower-right area
- Position: X=48, Y=24 to Y=62
- Height increases with level (1 bar segment per level, up to ~12)
- Color: BCYAN (14)
- This gives a non-textual visual indicator of speed

### Complete Layout Map

```
0         1         2         3         4         5         6
0123456789012345678901234567890123456789012345678901234567890123
+----------------------------------------------------------------+  Y=0
|                                                                |  Y=1
|B==============================B        B===============B       |  Y=2
|B                              B        B               B       |  Y=3
|B                              B        B  Next Piece   B       |  Y=4
|B                              B        B   (3x3 cells) B       |  Y=5
|B        Playfield             B        B               B       |  Y=6-16
|B        10 cols x 20 rows    B        B===============B       |  Y=17
|B        (30 x 60 pixels)     B                                |  Y=18-23
|B                              B          Level Bar             |  Y=24
|B                              B          (grows up             |  Y=25-55
|B                              B           with level)          |
|B                              B                                |
|B==============================B                                |  Y=62
|B==============================B                                |  Y=63
+----------------------------------------------------------------+

B = border pixel (GREY)
= = border line
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

Each piece is defined by 4 cell offsets (dc, dr) relative to a pivot point. The pivot is the logical position tracked by the game.

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

### Rotation States

Each rotation state is 8 bytes: 4 pairs of (dc, dr) offsets. All offsets are signed bytes relative to the pivot position.

**I-piece (2 states):**
```
State 0: (0,0)(1,0)(2,0)(3,0)    horizontal: X X X X
State 1: (1,0)(1,1)(1,2)(1,3)    vertical (column)
```

**O-piece (1 state, rotation is a no-op):**
```
State 0: (0,0)(1,0)(0,1)(1,1)    square: X X
                                          X X
```

**T-piece (4 states):**
```
State 0: (0,0)(1,0)(2,0)(1,1)    X X X
                                    X
State 1: (1,0)(0,1)(1,1)(1,2)      X
                                  X X
                                    X
State 2: (1,0)(0,1)(1,1)(2,1)      X
                                  X X X
State 3: (0,0)(0,1)(1,1)(0,2)    X
                                  X X
                                  X
```

**S-piece (2 states):**
```
State 0: (1,0)(2,0)(0,1)(1,1)      X X
                                  X X
State 1: (0,0)(0,1)(1,1)(1,2)    X
                                  X X
                                    X
```

**Z-piece (2 states):**
```
State 0: (0,0)(1,0)(1,1)(2,1)    X X
                                    X X
State 1: (1,0)(0,1)(1,1)(0,2)      X
                                  X X
                                  X
```

**J-piece (4 states):**
```
State 0: (0,0)(0,1)(1,1)(2,1)    X
                                  X X X
State 1: (0,0)(1,0)(0,1)(0,2)    X X
                                  X
                                  X
State 2: (0,0)(1,0)(2,0)(2,1)    X X X
                                      X
State 3: (1,0)(1,1)(0,2)(1,2)      X
                                    X
                                  X X
```

**L-piece (4 states):**
```
State 0: (2,0)(0,1)(1,1)(2,1)        X
                                  X X X
State 1: (0,0)(0,1)(0,2)(1,2)    X
                                  X
                                  X X
State 2: (0,0)(1,0)(2,0)(0,1)    X X X
                                  X
State 3: (0,0)(1,0)(1,1)(1,2)    X X
                                    X
                                    X
```

### Data Format in Memory

Rotation data is stored as a flat lookup table. Each piece has a pointer to its rotation table. Each rotation state is 8 consecutive bytes: dc0, dr0, dc1, dr1, dc2, dr2, dc3, dr3.

Total rotation data: (2+1+4+2+2+4+4) = 19 states x 8 bytes = 152 bytes.

---

## Game Board (Internal State)

### Board Array

- 10 columns x 20 rows = 200 bytes
- One byte per cell: 0 = empty, 1-7 = piece color index
- Stored row-major: byte[row * 10 + col]
- Row 0 = top of playfield, Row 19 = bottom

### Active Piece State

| Variable | Size | Description |
|----------|------|-------------|
| PCTYPE | 1 byte | Current piece type (0-6 for I,O,T,S,Z,J,L) |
| PCROT | 1 byte | Current rotation state (0-3) |
| PCCOL | 1 byte | Pivot column (0-9, may be negative during wall proximity) |
| PCROW | 1 byte | Pivot row (0-19) |
| PCCLR | 1 byte | Piece color value (Dazzler color 0-15) |
| PCNEXT | 1 byte | Next piece type (0-6) |

---

## Game Logic

### Initialization

1. Call DZLINIT with HL=0F000H
2. Clear screen with DZLCLR (BLACK)
3. Draw playfield border (GREY)
4. Draw next-piece box border (GREY)
5. Initialize board array to all zeros
6. Set score=0, level=0, lines=0
7. Generate first two random pieces (current + next)
8. Print initial score/level/lines to console
9. Enter game loop

### Game Loop (Main Tick)

```
GAMELOOP:
    1. Poll keyboard (BDOS function 6, E=0FFH)
    2. If key pressed, process input:
         'a' or 'A' or 4 (ctrl-D)  -> move left
         'd' or 'D' or 19 (ctrl-S) -> move right
         'w' or 'W' or 5 (ctrl-E)  -> rotate clockwise
         's' or 'S' or 24 (ctrl-X) -> soft drop (move down 1 + award 1 point)
         ' ' (space)                -> hard drop (instant drop + lock)
         'q' or 'Q'                 -> quit game
    3. Decrement gravity counter
    4. If gravity counter = 0:
         a. Reset gravity counter to current level's tick value
         b. Attempt to move piece down 1 row
         c. If move fails (collision):
              - Lock piece into board
              - Check and clear completed lines
              - Update score, lines, level on console
              - Spawn next piece
              - If spawn collides -> GAME OVER
    5. Redraw changed cells on Dazzler
    6. JMP GAMELOOP
```

### Collision Detection

To test whether a piece can occupy a given (col, row, rotation):

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

- **Move left**: test (col-1, row, rot). If no collision, update col.
- **Move right**: test (col+1, row, rot). If no collision, update col.
- **Rotate**: test (col, row, rot+1 mod max_rot). If collision, reject (no wall kicks).
- **Soft drop**: test (col, row+1, rot). If no collision, update row and add 1 to score.
- **Hard drop**: repeatedly test (col, row+1, rot) until collision. Add 2 points per row dropped. Lock immediately.

### Locking

When a piece can no longer move down:

1. For each of the 4 cells, write the piece's color index into board[row+dr][col+dc]
2. Check for completed lines (see below)
3. Spawn the next piece

### Line Clearing

After locking a piece, scan all 20 rows (or just the rows the piece occupies):

```
For row = 19 down to 0:
    If all 10 cells in this row are non-zero:
        Mark row for clearing
Count marked rows (1-4)
For each marked row (from top to bottom):
    Shift all rows above it down by 1
    Clear the top row (set to all zeros)
Update lines_cleared total
Redraw affected rows on Dazzler
```

### Scoring

| Lines | Points |
|-------|--------|
| 1 (Single) | 40 x (level + 1) |
| 2 (Double) | 100 x (level + 1) |
| 3 (Triple) | 300 x (level + 1) |
| 4 (Tetris) | 1200 x (level + 1) |

Score is a 16-bit value (max 65535). This is sufficient for a minimal implementation. Displayed on the console in decimal.

### Level Progression

- Level increases by 1 every 10 lines cleared
- Starting level: 0
- Level affects gravity speed (see timing below)

### Gravity Timing

Since the 8080 has no hardware timer, gravity is implemented as a software countdown. The game loop runs a tight poll loop; a counter is decremented each iteration. When it reaches zero, gravity fires and the counter resets.

The counter value determines speed. Approximate values (will need calibration on real hardware):

| Level | Counter Value | Relative Speed |
|-------|--------------|----------------|
| 0 | 255 | Slowest |
| 1 | 225 | |
| 2 | 200 | |
| 3 | 175 | |
| 4 | 150 | |
| 5 | 125 | |
| 6 | 100 | |
| 7 | 75 | |
| 8 | 50 | |
| 9+ | 30 | Fastest |

These are single-byte counters. The main loop body execution time determines the real-world tick rate. A calibration constant or inner delay loop may be needed to achieve playable speeds.

### Piece Spawning

1. Current piece = next piece
2. Generate new random piece for next
3. Set spawn position: col = 3, row = 0 (top of playfield)
4. Test collision at spawn position
5. If collision -> game over
6. Draw new piece on Dazzler
7. Update next-piece preview on Dazzler

### Random Number Generator

A simple 8-bit LFSR (Linear Feedback Shift Register) seeded from the gravity counter value at the moment of the first keypress:

```
RNG:
    LDA SEED
    RLCA
    XOR with taps (bits 7,5,4,3 -> polynomial x^8+x^6+x^5+x^4+1)
    STA SEED
    AND 07H        ; Reduce to 0-7
    CPI 7          ; If >= 7, re-roll (reject and retry)
    JNC RNG        ; This gives uniform 0-6
    RET            ; A = piece index 0-6
```

---

## Rendering

### Strategy: Differential Redraw

Do NOT clear and redraw the entire screen every frame. Instead:

1. **Erase active piece** at its old position (draw 4 cells in BLACK)
2. **Move/rotate the piece** (update game state)
3. **Draw active piece** at its new position (draw 4 cells in piece color)
4. **Line clear**: when lines are cleared, redraw all affected rows from the board array

### Drawing a Cell

A single cell at grid position (col, row) with color:
```
pixel_x = 1 + (col * 3)
pixel_y = 3 + (row * 3)
DZLFRECT: B=pixel_x, C=pixel_y, D=pixel_x+2, E=pixel_y+2, A=color
```

Since the 8080 has no multiply instruction, `col * 3` is computed as `col + col + col` (two ADD instructions).

### Drawing the Active Piece

```
For each of the 4 cells (dc, dr) in current rotation:
    draw_col = PCCOL + dc
    draw_row = PCROW + dr
    If draw_col in [0,9] and draw_row in [0,19]:
        draw cell at (draw_col, draw_row) with PCCLR
```

### Drawing the Next Piece Preview

Erase the preview area interior (fill with BLACK), then draw the next piece centered in the preview box using the same 3x3 cell rendering.

Preview center: approximately X=44, Y=7 as the origin, then offset by the piece's cell coordinates * 3.

### Redrawing After Line Clear

After removing lines and shifting the board array:

```
For each row that changed (from the cleared line up to the top):
    For col = 0 to 9:
        draw cell at (col, row) with board[row][col] color (or BLACK if 0)
```

This redraws at most 20 rows x 10 cells = 200 DZLFRECT calls in the worst case. In practice, typically 1-4 rows shift.

---

## Memory Budget

| Item | Size |
|------|------|
| Frame buffer (Dazzler) | 2048 bytes at F000H |
| Board array (10x20) | 200 bytes |
| Rotation tables (19 states x 8 bytes) | 152 bytes |
| Game variables (score, level, piece state, etc.) | ~40 bytes |
| Speed table (10 entries) | 10 bytes |
| Score point table (4 entries x 2 bytes) | 8 bytes |
| Color table (7 entries) | 7 bytes |
| Console message strings | ~100 bytes |
| Stack | ~128 bytes |
| Program code | ~2-3 KB estimated |
| D64X64 library code | ~2 KB estimated |
| **Total estimated** | **~5-6 KB** |

CP/M TPA is approximately 0100H to BFFFH (~48 KB). Memory is not a concern.

---

## Console Output

The CP/M console displays text alongside the Dazzler graphics:

### On Start
```
TETRIS for Cromemco Dazzler
Controls: A=Left D=Right W=Rotate S=Drop SPACE=HardDrop Q=Quit
Score: 00000  Lines: 000  Level: 00
```

### During Play
Update the score/lines/level line in-place using CR (0DH) without LF:
```
Score: 01200  Lines: 010  Level: 01
```

### On Game Over
```
GAME OVER!  Final Score: 12345
Press any key to exit...
```

---

## Module Structure

The game should be a single assembly file that links with the D64X64 library:

### File: TETRIS.MAC

**Sections:**
1. Header (TITLE, EXTRN declarations, EQU constants)
2. Main program (START, initialization, game loop)
3. Input handler (poll keyboard, dispatch actions)
4. Piece movement (move left/right/down, rotate, hard drop)
5. Collision detection
6. Line clearing
7. Locking
8. Rendering (draw/erase cell, draw piece, draw preview, redraw rows)
9. Scoring and level management
10. Random number generator
11. Console output helpers (print score, print decimal number)
12. Data tables (rotation data, color table, speed table, score table)
13. Variables (board array, piece state, counters)

### Build
```
M80 =TETRIS
M80 =D64X64
M80 =D64X64A
M80 =D64X64B
L80 TETRIS,D64X64,D64X64A,D64X64B,TETRIS/N/E
```

### Run
```
A>TETRIS
```

---

## Simplifications (vs. Full Tetris)

This minimal implementation omits:
- **Wall kicks**: rotation that would collide is simply rejected
- **Lock delay**: pieces lock immediately when they cannot fall
- **DAS (auto-repeat)**: each keypress moves once; no hold-to-repeat
- **Ghost piece**: no shadow showing where the piece will land
- **Hold piece**: no piece-hold mechanic
- **T-spin scoring**: no special scoring for T-spins
- **Starting level selection**: always starts at level 0
- **High score persistence**: score is not saved to disk
- **Sound**: the Dazzler has no audio capability
- **Pause**: no pause function (could be added as 'p' key)
