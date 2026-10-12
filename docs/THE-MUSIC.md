# The music

Everything you hear here comes from running the cartridge's own sound engine (`suena_el_cuadro`, 0xB641, and `pide_pieza`, 0xB590, which hands it the voices; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- tune 0x9B, its first 219 frames and, as the game asks for it, another 390 of 2,993;
- the open door (0xA1), whole, 212 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`pide_pieza` takes the number in A. Low numbers are effects and from 0x91 up there is music. Each voice takes fourteen bytes from 0xE010 and 0xE048 holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`; 0x9A, 0x9C and 0x9D, minutes long, are left out.

## The tunes

**The tune at 0x41B0** (0x9B)

Asked for by `L_41B0`; lasts 49.9 s and starts again at second 11.8.

<audio controls preload="none" src="audio/musica_9B.mp3?v=7953aac3"></audio>

**The open door** (0xA1)

Asked for by `puerta_abierta`; lasts 3.5 s.

<audio controls preload="none" src="audio/musica_A1.mp3?v=08b92e59"></audio>

**The level tune** (0x91)

Asked for by `pieza_del_nivel`; lasts 2.5 s and starts again at second 1.4.

<audio controls preload="none" src="audio/musica_91.mp3?v=ebf752ef"></audio>

**The title and the stage cleared** (0xA4)

Asked for by `titulo_borra` y `escena_ronda_pasada`; lasts 8.6 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_A4.mp3?v=f440aef4"></audio>

**The tune at 0x4367** (0xA7)

Asked for by `L_4367`; lasts 4.0 s.

<audio controls preload="none" src="audio/musica_A7.mp3?v=b45079a8"></audio>

**The tune at 0x82AB** (0x98)

Asked for by `L_82AB`; lasts 1.1 s.

<audio controls preload="none" src="audio/musica_98.mp3?v=80cd8f45"></audio>

**Time is running out** (0xAA)

Asked for by `se_acaba_el_tiempo`; lasts 0.9 s and starts again at second 0.8.

<audio controls preload="none" src="audio/musica_AA.mp3?v=89b0d19e"></audio>

**Table track 0x92** (0x92)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 25.6 s and starts again at second 4.3.

<audio controls preload="none" src="audio/musica_92.mp3?v=58f9bef1"></audio>

**Table track 0x96** (0x96)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 38.1 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_96.mp3?v=b51a1965"></audio>

**Table track 0x97** (0x97)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 39.1 s and starts again at second 1.0.

<audio controls preload="none" src="audio/musica_97.mp3?v=ce29b8f6"></audio>

**Table track 0x99** (0x99)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 16.8 s and starts again at second 16.0.

<audio controls preload="none" src="audio/musica_99.mp3?v=ca90ad61"></audio>

**Table track 0xA2** (0xA2)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 11.6 s and starts again at second 3.0.

<audio controls preload="none" src="audio/musica_A2.mp3?v=72ea4524"></audio>

**Table track 0xA3** (0xA3)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 11.6 s and starts again at second 3.0.

<audio controls preload="none" src="audio/musica_A3.mp3?v=aad58e98"></audio>

**Table track 0xA5** (0xA5)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 12.4 s and starts again at second 3.9.

<audio controls preload="none" src="audio/musica_A5.mp3?v=75d2575f"></audio>

**Table track 0xA6** (0xA6)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 12.6 s and starts again at second 4.0.

<audio controls preload="none" src="audio/musica_A6.mp3?v=ee136a84"></audio>

**Table track 0xA8** (0xA8)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.0 s.

<audio controls preload="none" src="audio/musica_A8.mp3?v=e10663ac"></audio>

**Table track 0xA9** (0xA9)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.9 s.

<audio controls preload="none" src="audio/musica_A9.mp3?v=31d77aa4"></audio>
