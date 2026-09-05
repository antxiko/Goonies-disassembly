# The code

## The main loop

`0x40BF` counts the frame, checks pause and dispatches by scene. `(0xE000)` is
the scene and `(0xE001)` the subscene, and every scene splits into its subscenes
with a chain of `djnz`: register `b` arrives holding the subscene and counts
down until it lands on the right piece.

The nine scenes are in the table at `0x40F6`:

| scene | what it does |
|---|---|
| 0 | the intro: the sign coming down, and the caption |
| 1 | wait, touches no VRAM |
| 2 | the title, the nine walking, and the game |
| 3 | the countdown |
| 4 | the level starts |
| 5 | the game |
| 6 | a life lost |
| 7 | game over |
| 8 | round cleared |

## The table dispatcher

Twenty-six times over, this shows up:

    call 04060h
    defw target_0, target_1, ...

`0x4060` does a `pop hl` to recover its own return address — which is the start
of the table — then `add a,a`, and jumps to entry number `a`. The `pop` also
removes the return, so **the target finishes on its own account**.

How many entries each table has is not estimated: they are closed, in this
order, by the `ld hl,<nnnn> / push hl` that manufactures the return address, by
the fit that no entry points inside the table itself, and in one case by a
`call`. All twenty-six are in `src/goonies.entries` with their arithmetic.

## The three drawing interpreters

The cartridge does not store screens: it stores scripts, and it has three ways
of reading them.

**`0x4682`, literal script.** `[vramAddr][bytes...]`, with `0xFE` to change
address and carry on and `0xFF` to close. Written byte by byte with WRTVRM.

**`0x4699`, the same script but erasing.** It is the same routine with `c = 0`
instead of `0xFF`, so the `and c` at `0x4692` turns every byte into a zero. The
same script paints and erases, with nothing stored on the side.

**`0x469D`, RLE script**, straight through the VDP port:

    0x00        end
    0x80        change address and carry on
    0x01..0x7F  the next byte, repeated n times
    0x81..0xFF  n & 0x7F literal bytes

And **it reads backwards from what it looks like**. What separates the two cases
is where the `djnz` jumps back to: the one at `0x46BA` returns to `ld a,(de) /
inc de` — so it **re-reads**, and that is why bit 7 set is the literal — and
the one at `0x46C4` returns only to `out (c),a`, so bit 7 clear is the run.

That the reading is right is proved by the fit: **every script ends exactly
where the next one begins**, with not a byte to spare. `tools/formatos.py` walks
them and `tools/cobertura.py` checks the fit.

## How 64,000 tiles fit in 2,983 bytes

A hundred rooms of 32x20 tiles: **64,000 tiles**. And they take this:

| |bytes|
|---|---:|
|the 25 maps, 80 bytes each|2,000|
|the definitions of the 108 blocks|717|
|the block pointer table|216|
|the map pointer table|50|
|**total**|**2,983**|

Which is **twenty-one tiles per byte**. Three layers make it possible:

**One.** A level is eighty bytes: four columns by twenty rows of **8x4 tile
blocks**. That gives 32 columns by 80 rows, which is the same as saying the four
rooms one after another. They are built in RAM at `0xE600`, `0xE880`, `0xEB00`
and `0xED80` — 640 bytes each — and `0x5F13` dumps whichever one is current into
the name table from row 2 on, since the top two rows are the scoreboard.

**Two.** **Bit 7 of the byte asks for the block mirrored**, and that is used
**615 times out of 2,000**. Mirroring a block is free: it is read backwards.

**Three.** The 108 blocks **share tails**. When two end with the same rows, the
second one's pointer starts halfway into the first and those bytes serve both.
Counting each byte once they take **717** instead of **841**. Block 9, for
instance, is two bytes of its own (`0x39 0x03`) with the whole of block 10 tucked
in behind.

And on top of that each block is compressed. `0x5A05` decompresses it onto
`0xE1F0` and stops when the pointer reaches `0xE210`, that is at exactly 32
tiles:

    0x0n        n zeroes
    0x1n        n times 0x40
    0x2n <b>    n times <b>
    0x3n <b>    the pair factory at 0x5A50
    anything    that tile, as is

**All 108 blocks are used.** Not one is spare.

## How the four rooms link up

Two twin tables of **19 rows by 4 columns**, at `0x52DB` and `0x5327`. `0x52CD`
enters with `(0xE06A)*4 + the current room`: the row is picked by the level's
*room layout* and the column by the room you are in.

The 19 rows are not an estimate. The 25 bytes at `0x9D67` — one per level, the
ones that go into `(0xE06A)` — top out at 18, so 19 rows are needed and not one
more. And 19×4 = 76 bytes is exactly what there is from `0x52DB` to `0x5327`,
and as much again from `0x5327` to `0x5373`.

Which of the two gets consulted depends on which side you leave by: at `0x5290`,
if the column drops below `0x15` it goes to the first; at `0x5296`, if it
reaches `0xC0`, to the second. One is the left-hand exit and the other the
right.

## The sprites

`0x586A` assembles **three sprites in one go** from a nine-byte entry: y offset,
x offset and pattern number, three times over. The entry is picked by
`(ix+005h)` times nine.

And there is a rotation so the same ones do not always flicker. Sprite
attributes are copied into VRAM starting **each frame at a different spot** in
the buffer at `0xE0AC`. Eleven positions, and each entry brings where it starts
and how many bytes go before wrapping: `0xE0AC+8n` and `0x54-8n`, with n from 0
to 10. Those `0x54` bytes are 21 sprites.

But the first eleven sprites are out of the rotation: they always go in the same
place, because they are **the scoreboard and the player**, which cannot be
allowed to flicker.

## The sound

The engine lives at `0xB585..0xB80A` and plays through the PSG with WRTPSG. You
ask for a piece with `ld a,<n> / call 0B590h`, and the `and 03fh` at `0xB59F`
says the number fits in six bits. Before playing it checks the priority of
whatever is already sounding (`cp e / ret c`), so **a weak effect does not
trample the music**.

Each voice is a pointer, and the voices of a piece are **consecutive** in the
table: `0x5BCB` does `add a,a` and takes 2 or 3 entries from `0xB814 + n*2`. That
is why the table is not split into pieces: it is a bag of 47 pointers. The last
three are `0xBFEE`, which is where the padding starts: they are empty voices.

And mind where that table begins, which very nearly slipped through. It looks
like it runs from `0xB814` to `0xB874` with 48 entries, and then the first one
is `0x393C`, which is nowhere near the music. It does not. **The period table
has twelve bytes, not ten** — it is a whole chromatic octave, and the twelve
come out in a ratio of 1.059 to each other, which is the twelfth root of two —
so it reaches `0xB816` and the pointers are 47. That the sum is `0xB814 + n*2`
only means **the first piece is number 1**: there is no piece 0.
