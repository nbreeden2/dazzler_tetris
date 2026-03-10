# TETRIS for Cromemco Dazzler — User Manual

## Requirements

- S-100 systems or emulators
- Cromemco Dazzler graphics board (64x64, color mode)
- 48K RAM minimum
- CP/M 2.2
- Serial terminal (80-column) for text display

## Getting Started

Load the program from the CP/M command line:

```
A>TETRIS
```

The title screen displays the TETRIS banner, version, and controls.
Press any key to start playing.

## Command-Line Options

```
TETRIS [/4] [/GC] [/GD] [/HD] [/SD] [/VS]
```

| Switch | Description |
|--------|-------------|
| /4 | 4MHz CPU mode (default assumes 2MHz) |
| /GC | Show ghost pieces in per-piece colors (default is grey) |
| /GD | Disable ghost pieces entirely |
| /HD | Disable the hold feature |
| /SD | Disable the real-time score display on the terminal |
| /VS | Enable vertical sync (synchronize drawing to Dazzler refresh) |
| /? | Display help and exit |

Switches may be combined in any order:

```
A>TETRIS /4 /GC
A>TETRIS /HD /SD
A>TETRIS /?
```

If both /GC and /GD are specified, /GC takes priority (ghosts shown in color).

## Controls

Two equivalent key sets are provided. Use whichever is more comfortable.

```
  Left Hand                Right Hand
  ---------                ----------
  W = Rotate CCW           I = Rotate CCW
  A = Move Left            J = Move Left
  S = Soft Drop            K = Soft Drop
  D = Move Right           L = Move Right
  R = Rotate CW            P = Rotate CW
  E = Hold Piece           O = Hold Piece

              SPACE = Hard Drop
                ESC = Quit
```

All letter keys are case-insensitive. Quit is the ESC key.

## How to Play

### Objective

Arrange falling pieces (tetrominoes) to fill complete horizontal rows.
Completed rows are cleared from the board and award points. The game
ends when new pieces can no longer enter the playfield.

### The Playfield

The Dazzler displays a 10-column by 20-row playfield on the left side
of the screen. Locked pieces remain on the board until their row is
cleared.

### Pieces

Seven piece shapes fall one at a time:

| Piece | Shape | Color |
|-------|-------|-------|
| I | Four in a line | Cyan |
| O | 2x2 square | Yellow |
| T | T-shape | Purple |
| S | S-skew | Green |
| Z | Z-skew | Red |
| J | J-shape | Blue |
| L | L-shape | Orange |

Pieces are dealt from a shuffled bag of all seven types. Once all seven
have appeared, the bag is reshuffled. This guarantees you will never go
more than 12 pieces without seeing a specific type.

### Movement

- **Move Left/Right**: Slide the piece one column sideways.
- **Rotate CW/CCW**: Rotate the piece 90 degrees. If the rotation
  would cause a collision, the game attempts up to 4 alternative
  positions (wall kicks) to fit the piece.
- **Soft Drop**: Move the piece down one row. Awards 1 point per row.
- **Hard Drop**: Instantly drop the piece to its landing position and
  lock it. Awards 2 points per row dropped.

### Ghost Piece

A ghost piece appears at the bottom of the playfield showing where
your piece will land if hard-dropped. By default the ghost is grey.
Use /GC for colored ghosts, or /GD to hide them entirely.

### Hold Piece

Press Hold to store your current piece for later use. The held piece
appears in the hold box on the right side of the screen. Press Hold
again to swap the current piece with the held piece. You may only
hold once per piece — you must lock a piece before holding again.

### Lock Delay

When a piece lands on the stack, it does not lock immediately. You
have a brief window to slide or rotate it into position. Moving or
rotating the piece resets the lock timer, up to a maximum of 15
adjustments. After that, the piece locks on the next timer expiry.

### Next Piece

The next piece to appear is shown in the preview box in the upper
right of the Dazzler display.

### Level Indicator

A vertical cyan bar between the playfield and the preview boxes
shows your current level. The bar grows upward as you advance.

## Scoring

### Line Clears

| Lines Cleared | Points |
|---------------|--------|
| 1 (Single) | 100 × (level + 1) |
| 2 (Double) | 300 × (level + 1) |
| 3 (Triple) | 500 × (level + 1) |
| 4 (Tetris) | 800 × (level + 1) |

### Perfect Clear Bonus

If the entire board is empty after clearing lines, a bonus is awarded
in addition to the normal line clear score:

| Lines Cleared | Bonus |
|---------------|-------|
| 1-line perfect clear | 800 × (level + 1) |
| 2-line perfect clear | 1200 × (level + 1) |
| 3-line perfect clear | 1800 × (level + 1) |
| 4-line perfect clear | 2000 × (level + 1) |

### Combos

Clearing lines on consecutive piece locks builds a combo. Each
successive combo awards a bonus of 50 × combo × (level + 1). The
combo resets when a piece locks without clearing any lines.

### Drop Points

- Soft drop: 1 point per row
- Hard drop: 2 points per row

### Score Display

During play, the current score, total lines, and level are shown on
the terminal. Use the /SD switch to suppress this if the terminal
output causes performance issues.

The maximum displayable score is 65,535.

## Levels

The game starts at level 0. Every 10 lines cleared advances one
level, up to a maximum of level 15. Higher levels increase the
falling speed of pieces.

## Game Over

The game ends when:

- A new piece cannot be placed at the top of the playfield, or
- A piece locks entirely at the top row

The terminal displays your final score, total lines cleared, and
final level. You are prompted to play again or exit to CP/M.

## Display Setup

### Dazzler

The Dazzler must be connected and configured for 64x64 color mode.
The program initializes the Dazzler automatically at startup and
shuts it down cleanly on exit.

The frame buffer is located at 8000H (requires 48K RAM).

### Terminal

Connect a serial terminal to the console port. The terminal displays
the title screen, score updates during play, and the game-over
summary. An 80-column terminal is recommended for proper formatting
of the title screen.

## Tips

- Use the ghost piece to aim hard drops precisely.
- Build up from one side, leaving a column open for Tetrises (4-line
  clears) which award the most points.
- Use the hold feature to save a useful piece (like an I-piece) for
  when you need it.
- Combos can significantly boost your score — try to clear lines on
  every piece lock.
- A perfect clear (emptying the entire board) awards a large bonus.
- At higher levels, the lock delay window lets you slide pieces into
  position even when they fall very quickly.
