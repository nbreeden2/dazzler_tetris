==============================================================================
                  TETRIS for Cromemco Dazzler
                  Version 2.0  --  User Manual
==============================================================================


REQUIREMENTS
------------

Hardware:
  - Intel 8080 CPU (or compatible: Z80, IMSAI 8080, Altair 8800, etc.)
  - 48K RAM minimum
  - Cromemco Dazzler graphics board, 64x64 color mode
  - Serial console terminal, 80-column recommended

Software:
  - CP/M 2.2 or compatible


GETTING STARTED
---------------

Load the program from the CP/M command line:

    A>TETRIS

A title screen displays the TETRIS banner, version, and the controls.
Press any key to start playing.


COMMAND-LINE SWITCHES
---------------------

    TETRIS [/2] [/GC] [/GD] [/HD] [/ED] [/?]

    /2   2MHz CPU mode (default assumes 4MHz)
    /GC  Show ghost pieces in per-piece colors (default is grey)
    /GD  Disable ghost pieces entirely
    /HD  Disable the hold feature
    /ED  Enable the real-time score display on the terminal
         (default is off)
    /?   Display the help screen and exit

Switches may be combined in any order. Examples:

    A>TETRIS /2 /GC
    A>TETRIS /HD /ED
    A>TETRIS /?

If both /GC and /GD are specified, /GC takes priority (ghosts in
color).


CONTROLS
--------

Two equivalent key sets are provided. Use whichever is more comfortable.

    Left Hand                Right Hand
    ---------                ----------
    W = Rotate CCW           I = Rotate CCW
    A = Move Left            J = Move Left
    S = Soft Drop            K = Soft Drop
    D = Move Right           L = Move Right
    R = Rotate CW            P = Rotate CW
    E = Hold Piece           O = Hold Piece

                SPACE = Hard Drop
                  ESC = Quit to CP/M

All letter keys are case-insensitive.


HOW TO PLAY
-----------

Objective:
  Arrange falling pieces (tetrominoes) to fill complete horizontal
  rows. Completed rows are cleared from the board and award points.
  The game ends when new pieces can no longer enter the playfield.

The Playfield:
  The Dazzler displays a 10-column by 20-row playfield on the left
  side of the screen. Locked pieces remain on the board until their
  row is cleared.

Pieces:
  Seven piece shapes fall one at a time:

    I   Four in a line    Cyan
    O   2x2 square        Yellow
    T   T-shape           Purple
    S   S-skew            Green
    Z   Z-skew            Red
    J   J-shape           Blue
    L   L-shape           Orange

  Pieces are dealt from a shuffled bag of all seven types. Once all
  seven have appeared, the bag is reshuffled. This guarantees you
  will never go more than 12 pieces without seeing a specific type.

Movement:
  Move Left/Right  Slide the piece one column sideways.
  Rotate CW/CCW    Rotate 90 degrees. If the rotation would cause a
                   collision, up to 4 alternative positions (wall
                   kicks) are attempted.
  Soft Drop        Move the piece down one row. 1 point per row.
  Hard Drop        Instantly drop and lock. 2 points per row.

Ghost Piece:
  A ghost piece appears at the bottom of the playfield showing where
  the current piece will land if hard-dropped. Grey by default. Use
  /GC for colored ghosts, or /GD to hide them entirely.

Hold Piece:
  Press Hold to store the current piece for later. The held piece
  appears in the hold box on the right side of the screen. Press
  Hold again to swap. You may only hold once per piece -- you must
  lock a piece before holding again. The /HD switch disables hold.

Lock Delay:
  When a piece lands on the stack, it does not lock immediately.
  You have a brief window to slide or rotate it. Moving or rotating
  resets the lock timer, up to 15 adjustments. After that, the piece
  locks on the next timer expiry.

Next Piece:
  The next piece to appear is shown in the preview box in the upper
  right of the Dazzler display.

Level Indicator:
  A vertical cyan bar between the playfield and the preview boxes
  shows the current level. The bar grows upward as you advance.


SCORING
-------

Line Clears:

    1 line  (Single)    100 x (level + 1)
    2 lines (Double)    300 x (level + 1)
    3 lines (Triple)    500 x (level + 1)
    4 lines (Tetris)    800 x (level + 1)

Perfect Clear Bonus:
  If the entire board is empty after clearing lines, a bonus is
  awarded on top of the normal line-clear score:

    1-line perfect clear     800 x (level + 1)
    2-line perfect clear    1200 x (level + 1)
    3-line perfect clear    1800 x (level + 1)
    4-line perfect clear    2000 x (level + 1)

Combos:
  Clearing lines on consecutive piece locks builds a combo. Each
  successive combo awards a bonus of 50 x combo x (level + 1). The
  combo resets when a piece locks without clearing any lines.

Drop Points:
  Soft drop: 1 point per row.
  Hard drop: 2 points per row.

Score Display:
  By default the real-time score is not shown on the terminal. Use
  the /ED switch to enable the live score, lines, and level display
  during play. The maximum displayable score is 65,535.


LEVELS
------

The game starts at level 0. Every 10 lines cleared advances one
level, up to a maximum of level 15. Higher levels increase the
falling speed of pieces.


GAME OVER
---------

The game ends when:
  - A new piece cannot be placed at the top of the playfield, or
  - A piece locks entirely at the top row

The terminal displays the final score, total lines cleared, and
final level. You are prompted to play again or exit to CP/M.


DISPLAY SETUP
-------------

Dazzler:
  The Dazzler must be connected and configured for 64x64 color
  mode. TETRIS initializes the Dazzler automatically at startup and
  shuts it down cleanly on exit. The frame buffer is located at
  8000H (requires 48K RAM).

Terminal:
  Connect a serial terminal to the console port. The terminal
  displays the title screen, optional score updates during play,
  and the game-over summary. An 80-column terminal is recommended
  for proper formatting of the title screen.


CPU SPEED
---------

TETRIS assumes a 4MHz CPU clock by default. If your system runs at
2MHz, add the /2 switch on the command line so that gravity and
lock-delay timing remain correct. Without /2 on a 2MHz machine the
pieces will fall at half the intended rate.


TIPS
----

  - Use the ghost piece to aim hard drops precisely.
  - Build up from one side, leaving a column open for Tetrises
    (4-line clears) which award the most points.
  - Use the hold feature to save a useful piece (like an I-piece)
    for when you need it.
  - Combos can significantly boost your score -- try to clear lines
    on every piece lock.
  - A perfect clear (emptying the entire board) awards a large
    bonus.
  - At higher levels, the lock delay window lets you slide pieces
    into position even when they fall very quickly.


==============================================================================
                            End of README
==============================================================================
