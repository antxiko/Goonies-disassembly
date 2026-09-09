# The Goonies (Konami, MSX1) — a commented disassembly

*(También [en castellano](README.es.md).)* ·
**[Read it on the web](https://antxiko.github.io/Goonies-disassembly/)**

A complete, commented disassembly of Konami's **The Goonies** for the MSX
(RC-734, 32 KB, 1986). Every one of the 32,768 bytes is accounted for, and the
listing reassembles into the ROM **byte for byte**.

    explained          32,768 of 32,768   100 %
    comment density    3,236 of 8,774     36.9 %
    routines below 10 %      0 of 1,176
    tests                   50, green
    reassembly         same sha256 as the cartridge

## What is here

    src/goonies.asm       the commented listing, generated
    src/goonies.notes     the comments and the data blocks, with their measure
    src/goonies.entries   the entry points that cannot be deduced statically
    tools/                the tools: trace, listing, pictures, VRAM check
    tests/                50 checks that do not need the cartridge
    docs/                 the bilingual website

## The cartridge is not here

`goonies.rom` is not distributed. Put your own copy in the root; it is exactly
32,768 bytes and

    sha256  2ba602b1a17e4797da1588afe6e65640331c15746bf5959f4778b404be929dde

## Reproducing it

    make comprueba     # checks your ROM is the same one
    make               # listing, reassembly, sanity checks and tests
    make imagenes      # draws all hundred rooms, and the rest, from the ROM
    make vram          # checks those pictures against openMSX's VRAM

## Not one screen capture

Every picture in this repository is **drawn from the bytes of the ROM**, by
running in Python the same decompressor, figure engine and label interpreter
the Z80 runs. And they are checked byte for byte against the emulator's VRAM:
the five screens come out at **zero differences** in colour, patterns and
sprite patterns.

All **one hundred rooms** are drawn — twenty-five levels of four, and not one
repeats. So are the **twenty-five plans**, with the four rooms placed where the
cartridge places them, plus a **minimap per round** with the doors joined up.

## What turned up

- **The four rooms of a level are a plan, not a column.** The high nibble of
  `0x52DB` is each room's position: column times four plus row. There are
  columns, rows, 2x2 and fourteen odd shapes.
- **All 64 skull doors pair up without a single exception**, and none leaves
  its round: the 25 levels are five closed groups of five.
- **The name of the round is its password.** The same bytes that paint the
  caption are the ones you type. MR SLOTH, GOON DOCKS, DOUBLOON, ONE EYED
  WILLY, GOONIES.
- **64,000 tiles in 2,983 bytes**: 8x4 blocks, a mirror bit, and blocks that
  share tails.
- **Twenty-seven ways to uncover a hidden item**, and all twenty-seven are used.
- **Items are shields with charges**, not trophies.
- **The demo is a recorded game**: 34 joystick states and their durations.
- **Half the artwork is manufactured at boot** by mirroring.

The lot, with its measurements, in
[Findings](https://antxiko.github.io/Goonies-disassembly/FINDINGS.html).

## Licence and credit

The tools, comments, analysis and documentation are MIT — see `LICENSE`. The
game is not ours: read [LEGAL-NOTICE.md](LEGAL-NOTICE.md).

Konami's hidden mark was uncovered by **Manuel Pazos**.
