# In the emulator

Everything on this page is done by booting the cartridge **from cold**. No
playing, no savestate, no breakpoint: the intro, the title and the demo come up
on their own and always the same, because [the demo is a recorded
game](FINDINGS.html).

## Where each screen is

`tools/omsx_sonda.tcl` looks ninety times, once per emulated second, at which
scene is running. That is how the instants get chosen without guessing:

| second | scene | what you see |
|---:|---|---|
| 5–11 | 0 | the intro, with the sign coming down |
| 12–15 | 1 | the title with the THE GOONIES lettering |
| 16–35 | 2.1 | the nine characters walking |
| 36– | 2.3 | the demo playing itself |

To run it:

    openmsx -machine Philips_VG_8020 -cart goonies.rom \
            -script tools/omsx_sonda.tcl

## Checking against VRAM

    make vram

Boots openMSX with no renderer and no throttle, dumps the 16 KB of VRAM at five
instants — 13, 25, 45, 60 and 75 seconds — and then subtracts that VRAM from the
one `tools/vram.py` builds, which is the Python translation of the cartridge's
loading routines.

The first three tables are static: they are built on entering the screen and not
touched until it changes. **They have to come out at zero.**

    screen           colour       spr patt     patterns
    title            0/6144       0/2048       0/6144      (and names 0/768)
    the nine         0/6144       0/2048       0/6144
    level 1 room 1   0/6144       0/2048       0/6144
    level 1 room 2   0/6144       0/2048       0/6144
    level 1 room 3   0/6144       0/2048       0/6144

## The trap that cost half the work

**The cartridge does not clear patterns or colour when the scene changes. Only
the name table.**

Building the title screen on its own gave hundreds of bytes of difference that
were not a misreading: they were **inheritance that was missing**. The title
screen is painted on top of whatever the intro left behind — the font and the
sign that comes down — and the level is painted on top of whatever the
nine-characters screen left.

That is why `vram.desde_el_encendido()` chains the scenes in the order of the
table at `0x40F6`:

    scene 0.0   the font and the sign coming down     (0x412B)
    scene 0.2   the THE GOONIES lettering             (0x4123)
    scene 1     wait, touches no VRAM                 (0x4139)
    scene 2.0   the bottom two rows cleared and the
                nine-characters scenery               (0x4175)
    scene 2.3   the level                             (0x41B9)

With the whole chain, all five screens close at zero.

## The phase of the water

The water's three tiles stay in whatever phase the last repaint left them, and
that depends on bit 2 of the frame counter **and on whether the previous room
had water**. The check tries both and says which one fits; the two batches are
different, so getting it right by chance is not possible.

You can see it in the dump: room 0 of level 1 has no water (`(0xE345)` is zero)
and the tiles are as the original script left them; room 1 does have water and
they are in the other phase; and room 2, which has none either, **inherits the
phase room 1 left behind**.

## The tiles that move

The name table does not check out at zero, and it should not: that is where the
game repaints creatures, water, cages and the scoreboard every frame. What gets
looked at is how many tiles move and whether they are the ones that should. In
level 1 it is 19, 47 and 29 out of the 640 in each room, and they fall on the
rows where the creatures are.

On the title screen, though, it **does** close at zero: all 768 tiles. Nothing
moves there.

## Tcl traps already paid for in this series

- No brackets inside a `format`.
- Binary files with `-translation binary`.
- `debug read_block`, since `debug save_to_file` does not exist.
- Reschedule the timer **first**, before doing anything else.
