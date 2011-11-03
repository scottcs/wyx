# Wyx - A not-really-a-roguelike game made with Löve

I wanted to try making a roguelike game, and stumbled upon the open
source [Löve][1] framework, which provides Lua functions that abstract
the SDL game library. I decided to use this as well as a couple of Lua
libraries that add some nice OOP syntax to the language.

# Running the game

The easiest way to try the game is to download the package for your
system, however if you have the Löve framework installed, you can clone
the repository and try to run it the hard way.

## Downloads

 * [Wyx 0.1.6 for Windows][2] (tested with Windows 7)
 * [Wyx 0.1.6 for Mac OS X][3] (tested with Snow Leopard and Lion)

## How to run from source

Currently, Wyx will only work on **Mac OS X** and **Windows**, not
Linux. Even though Löve runs on Linux, Wyx uses a C library for random
number generation, which I've only compiled for Windows and OS X.

You can download Löve yourself, and then clone the repo and it should
work. No compilation is necessary, though on OS X you may need to copy
the random.so into the Contents folder of the love.app, and on Windows
you may need to copy the random.dll into the same directory as the love
executable.

# How to play

The objective is to explore the dungeon, kill the monsters, and pick up
items to make your character better. **Currently there is only one level
to the dungeon**, though it is randomly generated (or randomly chosen
from one of the pre-made levels). I just haven't gotten to the staircase
implementation yet.

## Mouse

Mouseover items in the level to see their names. Mouseover enemies to
see their stats. Click items in the floor slots (bottom right corner) to
pick them up and move them into your inventory or your equipped item
slots. You can also move items between inventory and equipped items this
way.

Items only show their names when moused over in the level, but you can
view the item's full stats by hovering over it in any of the bottom row
slots. When hovering over an item that can be equipped, you'll see a
comparison tooltip pop up for any currently equipped item that it might
replace.

## Keys

You can use the arrow keys to move, however I would advise against it,
since there is no easy way to move diagonally.

(Yeah, there are way too many keys mapped to the same thing... I plan on
implementing a keyboard configuration system soon, but until then I
thought it might as well support a few different common configs all at
once).

**Game Controls**

  * Up: E, K, or keypad 8
  * Down: D, J, or keypad 2
  * Left: S, H, or keypad 4
  * Right: F, L, or keypad 6
  * Diagonal Up-left: W, Y, or keypad 7
  * Diagonal Up-right: R, U, or keypad 9
  * Diagonal Down-left: Z, X, B, or keypad 1
  * Diagonal Down-right: C, V, N, or keypad 3
  * Wait a turn: Spacebar, ., or keypad 5
  * Zoom camera out (pauses game): PageUp
  * Zoom camera in: PageDown
  * Bring up the in-game menu: Escape

**Advanced/Debugging Controls**

  * Toggle console: ~
  * Print inventory to console (same as `inv` command): shift-I
  * Print stats to console (same as `stats` command): shift-S
  * Print currently loaded entity info to console (same as `dump` command): shift-D
  * Attach camera to main character: F4
  * Detach camera from main character: F5
  * Display current map name or seed: Backspace
  * Abandon and start a new game: Ctrl-N

**Console Controls**

These are only available when the Console is visible.

  * Clear console: F10
  * Scroll up: PageUp
  * Scroll down: PageDown
  * Scroll to top: Home
  * Scroll to bottom: End
  * Enter command: Return
  * Leave command mode without executing: Escape
  * Return to game: Escape or ~

**Console commands**: there are currently only a few, but type "help" in
the console to see them.



# License

Please see the LICENSE file.

[1]: http://www.love2d.org "A 2D Game Framework for Lua"
[2]: https://github.com/downloads/scottcs/wyx/Wyx-0.1.6-win.zip "Download for Windows"
[3]: https://github.com/downloads/scottcs/wyx/Wyx-0.1.6-osx.zip "Download for OS X"
