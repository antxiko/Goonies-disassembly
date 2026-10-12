#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `pide_pieza` (0xB590, A = numero) y corre `suena_el_cuadro`
(0xB641), que la interrupcion llama cada cuadro. Tres voces de 14 bytes desde
0xE010; la copia del registro 7 del PSG, en 0xE048. El cartucho es de 32 KB,
sin mapper, en 0x4000-0xBFFF.
Uso:  musica.py registros 0x9B [cuadros] | mp3 0x9B f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xBF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x9B, "La pieza del 0x41B0", "The tune at 0x41B0", "`L_41B0`"),
    P(0xA1, "La puerta abierta", "The open door", "`puerta_abierta`"),
    P(0x91, "La pieza del nivel", "The level tune", "`pieza_del_nivel`"),
    P(0xA4, "El título y la ronda pasada", "The title and the stage cleared",
      "`titulo_borra` y `escena_ronda_pasada`"),
    P(0xA7, "La pieza del 0x4367", "The tune at 0x4367", "`L_4367`"),
    P(0x98, "La pieza del 0x82AB", "The tune at 0x82AB", "`L_82AB`"),
    P(0xAA, "Se acaba el tiempo", "Time is running out", "`se_acaba_el_tiempo`"),
] + [P(n, "Pista 0x%02X de la tabla" % n, "Table track 0x%02X" % n, TABLA)
     for n in (0x92, 0x96, 0x97, 0x99, 0xA2, 0xA3, 0xA5, 0xA6, 0xA8, 0xA9)]

PAGINA = motor_musica.pagina_basica(
    "`suena_el_cuadro`, 0xB641, y `pide_pieza`, 0xB590, que le reparte las "
    "voces; lo llama la interrupción",
    "`suena_el_cuadro`, 0xB641, and `pide_pieza`, 0xB590, which hands it the "
    "voices; the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("la pieza 0x9B, sus primeros 219 cuadros y, tal como el juego la pide, "
      "otros 390 de 2.993",
      "tune 0x9B, its first 219 frames and, as the game asks for it, another "
      "390 of 2,993"),
     ("la puerta abierta (0xA1) entera, 212 cuadros",
      "the open door (0xA1), whole, 212 frames")],
    [("Cómo se pide una pieza",
      "`pide_pieza` recibe el número en A. Los números bajos son efectos y "
      "del 0x91 en adelante hay música. Cada voz ocupa catorce bytes desde "
      "0xE010 y 0xE048 guarda la copia del mezclador del PSG, que el "
      "arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de "
      "pistas pero ninguna rutina las pide con un `ld a`; se omiten las "
      "0x9A, 0x9C y 0x9D, de minutos de duración.",
      "How a piece is asked for",
      "`pide_pieza` takes the number in A. Low numbers are effects and from "
      "0x91 up there is music. Each voice takes fourteen bytes from 0xE010 "
      "and 0xE048 holds the copy of the PSG mixer, which start-up leaves at "
      "0xB8. The tracks marked «in the table» are in the track table but no "
      "routine asks for them with an `ld a`; 0x9A, 0x9C and 0x9D, minutes "
      "long, are left out.")])

CFG = dict(rom="goonies.rom", org=0x4000, frame=0xB641, pide=0xB590,
           ram=(0xE010, 0xE049), ram0=[(0xE048, 0xB8)],
           excluye=[0xE019, 0xE027, 0xE035], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x9B, 2993, 705), (0xA1, 212, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
