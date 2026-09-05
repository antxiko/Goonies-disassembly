# Getting started

This repository holds the commented disassembly of Konami's **The Goonies** for
the MSX (RC-734, 1986). It does not hold the cartridge: the ROM image is not
distributed.

## What you need

- `pasmo` — the assembler that reproduces the ROM
- `z80dasm` — the disassembler the listing is generated with
- `python3` — the tools under `tools/`
- `make`
- Your own copy of the cartridge, in the root and named `goonies.rom`

It is **exactly 32,768 bytes** and its fingerprint is:

    sha256  2ba602b1a17e4797da1588afe6e65640331c15746bf5959f4778b404be929dde

To check it:

    make comprueba

## Reproducing the whole thing

    make

That chains the four things that matter:

| step | what it does | what it proves |
|---|---|---|
| `make listado` | builds `src/goonies.asm` from the trace and the notes | that the listing is not hand-written |
| `make verify` | reassembles and compares the sha256 | that the listing **is** the cartridge |
| `make sanity` | checks how the bytes are accounted for | that not one byte is left unexplained |
| `make test` | 44 checks | that what gets published holds up against the bytes |

The one that decides is `make verify`. If the reassembled sha256 is not the one
above, the listing is lying somewhere.

## The numbers

    make densidad

    0 routines below 10 %, out of 1176
    in total: 8774 instructions, 3236 comments, 36.9 %

## The pictures

    make imagenes

Draws into `work/gfx/` the title screen, **all one hundred rooms** plus the
twenty-five level maps with their creatures and hazards, the player's figures in
colour, the tile sheet and the twenty-three inventory icons. None of them is a
capture: they are built by running in Python the same steps the Z80 runs.

## Checking against the emulator

    make vram

Boots openMSX with the cartridge, lets it run **from cold** and dumps VRAM at
five instants; then it subtracts that VRAM from the one `tools/vram.py` builds.
No playing and nothing to load: the intro, the title and the demo come up on
their own and are deterministic, because [the demo is a recorded
game](FINDINGS.html).

Latest measurement, on the latest build:

    screen           colour       spr patt     patterns     names
    title            0/6144       0/2048       0/6144       0/768
    the nine         0/6144       0/2048       0/6144
    level 1 room 1   0/6144       0/2048       0/6144
    level 1 room 2   0/6144       0/2048       0/6144
    level 1 room 3   0/6144       0/2048       0/6144

## How the commenting works

Batches of comments are written into
`work/coment/tanda-NN-whatever.notes`, with lines `C 0xADDR text`,
`L 0xADDR name` and `B 0xADDR HEADING`, and then:

    python3 tools/aplica_comentarios.py src/goonies.asm src/goonies.notes \
            work/coment --escribe && make listado && make verify

There are forty-two batches.
