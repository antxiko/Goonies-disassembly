# Findings

## The four rooms of a level are not a column: they are a plan

`empieza_el_nivel` (`0x4F82`) takes one byte per level from `0x9D67` and leaves
it in `(0xE06A)`. That byte picks one of **nineteen** rows at `0x52DB`, four
bytes, one per room.

In each byte the **low nibble** is the room you pass into leaving through the
left (`0xF`: none), and the **high one is THE POSITION** of that room in the
plan. That it is the position is not a guess: the chaser settles it. `0x74C0`
compares that nibble with `0xC0` -the top two bits- to decide whether it has to
move horizontally, and `0x74C4` with `0x30` -the bottom two- for the vertical.
So the nibble is **column times four plus row**.

And it fits everything else: `0x5327` gives the room to the right, and the ones
above and below are the current one minus and plus one -the `dec b` at `0x529A`
and the two `inc b` at `0x52A2`-.

The twenty-five arrangements, counted off those bytes:

| shape | levels |
| --- | --- |
| a column of four | 1, 10, 15 |
| a row of four | 2, 19 |
| 2x2 | 3, 9, 13, 17, 24, 25 |
| three columns by two rows | 4, 6, 8, 11, 14, 21 |
| two columns by three rows | 5, 7, 12, 16, 18, 20, 22, 23 |

The proof that the arrangement is right is in the picture: put together like
this, **platforms and ladders carry on from one room into the next**, and the
water at the bottom runs through.

![Level 8](imagenes/mapa-nivel-08.png)

All twenty-five maps in [The 100 rooms](THE-LEVELS.html) are redrawn with it.

## All 64 skull doors pair up without a single exception

Each skull door is three bytes, and out of the third `0x8DA8` takes **two
things**: the low six bits are the level it leads to and the **top two the
ENTRANCE**, which is the number of the door you come out of over there.

That turns the doors into checkable pairs: if door *j* of level A says (B, *k*),
then door *k* of level B has to say (A, *j*). **All 64 in the cartridge do**,
without one exception, and on top of that **none leaves its round**: the 25
levels are five closed groups of five.

![Round 1](imagenes/ronda-1.png)

Every line on that minimap joins two doors that really pair up. There is one
per round in [The 100 rooms](THE-LEVELS.html).

## The name of the round is its password

You can type on the title screen. `0x53C8` reads the keyboard with SNSMAT and
piles what you type into `0xE4C0` — up to sixteen letters, with the index in
`(0xE074)` — and on release it calls `0x5444`, which matches those sixteen bytes
against **five names**, from `0x546E` onwards and **nineteen bytes apart**.

If one matches, `0x5421` uses which it was as an index into the table at
`0x543A`:

| password | level | round |
|---|---:|---:|
| MR SLOTH | 6 | 2 |
| GOON DOCKS | 11 | 3 |
| DOUBLOON | 16 | 4 |
| ONE EYED WILLY | 21 | 5 |
| GOONIES | 1 | 1 |

And here is the detail: **those very bytes are also the caption painted on
screen**. Each of the five is a complete literal script — VRAM address, sixteen
tiles and the closing `0xFF` — and the comparison enters two bytes further in,
skipping the address. There are not two tables: there is one.

That is why `0x53A7` shows you the password when you clear a round, under the
`KEYWORD` caption: it is showing you the name of the round you have just left.

The names for rounds 2 to 5 have their pointers at `0x53C0`, indexed by
`(0xE06C)-2`. The fifth, ONE EYED WILLY, is **the only one without a closing
`0xFF`**, and that fits: it is the round you reach, never one that gets
announced.

## Sixty-four thousand tiles in 2,983 bytes

A hundred rooms of 32x20, all of them different, in under three thousand bytes:
twenty-one tiles per byte. It is taken apart in [The code](THE-CODE.html) — 8x4
blocks, the mirror bit and the shared tails — and the result is on show in [The
100 rooms](THE-LEVELS.html).

## The twenty-seven ways to uncover a hidden item

The longest table in the cartridge is the one at `0x6DBD`: **twenty-seven**
entries. Each is a condition that uncovers one of the hidden items.

Hit the same spot twice in a row. Kick once to each side. Stand still for
`0x60` frames. Keep both bars above `0x28`. Kick the boulder, or the flame.

Nearly all of them lean on `(0xE126)` and `(0xE127)`, which hold **the player's
last two hits**, kept up to date frame by frame by `0x8005`.

And none is spare. Walking the lists of all twenty-five levels turns up
**twenty-seven hidden items with twenty-seven distinct indices, 0 to 26**: each
condition is used exactly once. Twenty-three levels carry one and **two carry
two, levels 5 and 16**.

All twenty-seven, mind you, look exactly alike: a single tile, `0x91`, blinking.
That is `0x6E14`.

## Items are shields with charges

The list at `0x7D9B` is eight bytes, one per hazard, and it says **which
inventory item stops each one** — or `0xFF` if none does. Carrying it, the hit
does not take energy: it spends **one charge** of `(0xE150+item)`, and when they
run out `0x8B37` drops the item from the inventory.

The seven hazards and their bit, which `0x7A9E` leaves in `(ix+00Ah)` — also
where the player's colour comes from:

| hazard | bit |
|---|---|
| water jet | `0x01` |
| stalactite | `0x02` |
| drip | `0x04` |
| flame | `0x08` |
| rising column | `0x10` |
| pipe leak | `0x20` |
| boulder | `0x40` |

The energy bar is sixteen bits — `(0xE063)` the fraction and `(0xE064)` what you
see — and it is drawn to **one eighth of a tile**.

There are twenty-three items, and the table at `0x5576` says which level each is
in: twenty-three distinct values between 0 and 24, and **5 and 14 are exactly
the ones missing**. Levels 6 and 15 are the only two with no item.

## The demo is a recorded game

`0x51D5` simulates nobody: it **plays back a tape**. `0x472D` starts by reading
the joystick and keyboard with `0x4742`, but `0x5206` jumps in at `0x4730`,
which is the very next byte, with `a` already loaded from a table. So the input
routine runs from halfway through and hands back whatever it was fed.

Two parallel tables, both indexed by `(0xE00B)`: at `0x520E`, **34 joystick
states** and the closing `0xFF`; at `0x5231`, **how many frames each lasts**.
When `(0xE00C)` reaches the duration, on to the next. The `0xFF` closes the
recording and clears `(0xE066)`.

This is what makes it possible to check VRAM by booting the cartridge **from
cold**: the intro, the title and the demo come up on their own, always the same,
with no savestates and no breakpoints.

## The chaser counts tiles to pick a rope

When the chaser wants to change height, `0x756D` and `0x7577` walk its row
**tile by tile in both directions**, counting how many there are until they hit
`0x41` — the foot of a rope — or `0x53` — the head — and it heads for the
shorter count.

And **bit 0 of `(ix+00Fh)`** decides which side is tried first, consumed by
rotating it on each query. That is why two identical chasers on the same row do
not both make for the same rope.

The green ropes are the same for everyone. `0x66E4` says so: the player climbs
`0x41` pressing up and goes down `0x53` pressing down.

## The water keeps a notebook of what it covers

The water jet runs down the room standing on tiles. So it can retract without
leaving holes, whenever it meets an occupied tile it **writes down at `0xE1D0`
the row and the three tiles that were there**, and puts them back on the way
out. The map is never touched: the map is read-only.

The current, on the other hand, moves nothing. `0x854E` rewrites **three
patterns** — tiles `0x6D`, `0xCF` and `0xF1` — across all three banks, swapping
two sixteen-byte batches with **bit 2 of the frame counter**. The water appears
to flow and not one tile on screen has changed.

Each record in those batches is four bytes of pattern and two of jump to the
next tile. The third jump **is read and then not used**: that is why each batch
takes sixteen bytes and not eighteen.

## Half the artwork is manufactured at boot

Of the 42 16x16 sprite patterns the cartridge carries (`0x927F`), **22 are not
drawn**: `0x4CDF` manufactures them by mirroring the others. Same with tiles: 34
are made by reversing the eight bits of another 34.

Mirroring a 16x16 sprite **is not just flipping bits**: you have to swap its two
columns, because a 16x16 pattern is two columns of sixteen bytes laid one behind
the other. The cartridge does it by entering with the destination pointing at
the second half (`0x1D50`, not `0x1D40`) and with the `inc e / sub 020h` dance
on the low byte of the address, at `0x46E6`.

Getting that wrong gives you figures split down the middle, and the VRAM check
says so plainly: with the fix, **0 bytes different out of the 2,048** of sprite
patterns.

The table at `0x6996` confirms it too: the mirrored drawing is painted twelve
pixels to the left and the normal one four.

## The geometry is upside down, and so is the RLE

The eight bytes at `0x4720` put **colour low and patterns high**, which is the
opposite of what nearly everyone does. It is in [The
cartridge](THE-CARTRIDGE.html).

And the decompressor at `0x46A6` runs backwards from what it looks like too:
**bit 7 set means literal** and clear means run. It is decided by where the
`djnz` jumps back to.

## The title screen and the ending are the same screen

`0x558D` builds a single scene, with nine characters walking, and both come out
of it: it only differs on `(0xE06C)==6`, that is after you finish the game. The
THE GOONIES lettering is painted **on top** of that scenery and is not erased
when you enter it, because between scenes the cartridge only clears the name
table.

## A sprite is switched off with a 0xC0 in the row

At `0x6576`, a sprite is removed by putting `0xC0` in its **row** byte, which is
the VDP convention. Not in the pattern byte — and `0xC0` is a perfectly valid
pattern number too. Checking the wrong byte eats good sprites: the player's
seventh pose came out with no body.

## The caption says 1986

No outside catalogue entry needed: the title-screen caption, drawn from the ROM,
reads **© KONAMI 1986**, with the 1985 Warner Bros. trademark notice below it.
The film is from 1985; the cartridge, from 1986.

## The house's hidden mark

It is covered in [The cartridge](THE-CARTRIDGE.html). The finding is **Manuel
Pazos**'s, and this cartridge pins down a character that was still unconfirmed.
