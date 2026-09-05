#!/usr/bin/env python3
"""Las figuras de sprite, montadas como las monta el cartucho: EN COLOR.

Un patron de sprite del MSX1 no tiene color: el color va en el atributo, un
byte por sprite. Y las figuras del juego no son un sprite, son varios
superpuestos, cada uno con el suyo. Asi que una hoja de patrones en blanco no
ensena lo que se ve en la pantalla; hay que montar la figura entera.

De donde sale cada cosa, medido sobre el listado:

  el jugador   0x65B7, dieciseis posturas de nueve bytes: tres sprites de
               (fila, columna, patron) cada una. Las posturas van en parejas,
               una por lado, y 0x6550 elige la de al lado cuando (ix+00Bh)
               dice que mira a la izquierda. Los tres colores, en 0x6543.
  los bichos   0x78F5 y 0x790B, un byte por postura: solo el patron, porque
               L_6594 monta un sprite y ya. El color, en 0x6546 + clase - 1.
  la calavera  no pasa por ese montador: 0x6946 le pone el patron a mano desde
               la tabla de 0x6996 y el color 0x0F.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vram as V                                           # noqa: E402

ORG = 0x4000
SPRPAT = 0x1800

# Los quince colores del MSX1 mas el transparente (TMS9918).
PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]

POSTURAS = ["andar A", "quieto", "andar C", "saltar",
            "trepar A", "trepar B", "patada", "patada en el aire"]


def s8(b):
    return b - 256 if b > 127 else b


def pinta_sprite(px, v, patron, color, fila, col, fondo=None):
    """Un patron de 16x16 en (fila, col) del lienzo, con un solo color.

    El VDP se queda con los bits altos del numero de patron: en 16x16 los
    patrones van de cuatro en cuatro.
    """
    base = SPRPAT + (patron & 0xFC) * 8
    for c in range(2):
        for y in range(16):
            b = v[base + c * 16 + y]
            for x in range(8):
                f, k = fila + y, col + c * 8 + x
                if 0 <= f < len(px) and 0 <= k < len(px[0]):
                    if b & (0x80 >> x):
                        px[f][k] = PALETA[color]
                    elif fondo:
                        px[f][k] = fondo
    return px


def figura_del_jugador(v, rom, postura, alto=32, ancho=32, fila=24, col=12):
    """Las tres piezas de una postura, superpuestas, cada una con su color.

    Traduce L_654C: nueve bytes por postura y, dentro, tres ternas de
    (desplazamiento en fila, desplazamiento en columna, patron).
    """
    px = [[(0, 0, 0)] * ancho for _ in range(alto)]
    tabla = 0x65B7 - ORG + postura * 9
    colores = rom[0x6543 - ORG:0x6543 - ORG + 3]
    for i in range(3):
        dy, dx, pat = rom[tabla + i * 3:tabla + i * 3 + 3]
        if dy == 0xC0:        # 0x6576: un 0xC0 en la FILA apaga ese sprite
            continue          # (0xC0 tambien es un patron valido: no confundir)
        pinta_sprite(px, v, pat, colores[i], fila + s8(dy), col + s8(dx))
    return px


def hoja_del_jugador(rom, nivel=1):
    """Las dieciseis posturas, ocho por fila: arriba el derecho, abajo el reves."""
    v = V.Vram(rom).monta(nivel).v
    px = [[(0, 0, 0)] * (8 * 32) for _ in range(2 * 32)]
    for n in range(16):
        f, c = (n % 2) * 32, (n // 2) * 32
        fig = figura_del_jugador(v, rom, n)
        for y in range(32):
            px[f + y][c:c + 32] = fig[y]
    return px


def hoja_de_bichos(rom, nivel=1):
    """Los patrones de un solo sprite de 0x78F5 y 0x790B, con sus seis colores.

    Cada fila de la hoja es una clase de bicho: el color sale de
    0x6546 + clase - 1, que es de donde lo saca 0x64B9.
    """
    v = V.Vram(rom).monta(nivel).v
    tablas = [(0x78F5, 22), (0x790B, 22)]
    patrones = []
    for base, n in tablas:
        for b in rom[base - ORG:base - ORG + n]:
            if b != 0xC0 and b not in patrones:
                patrones.append(b)
    colores = rom[0x6546 - ORG:0x6546 - ORG + 6]
    px = [[(0, 0, 0)] * (len(patrones) * 16) for _ in range(len(colores) * 16)]
    for f, color in enumerate(colores):
        for c, pat in enumerate(patrones):
            pinta_sprite(px, v, pat, color, f * 16, c * 16)
    return px, patrones


def hoja_de_patrones(rom, nivel=1):
    """Los 64 patrones crudos, ocho por fila, en blanco: la referencia tecnica.

    Los 42 primeros vienen dibujados en el cartucho y los 22 ultimos los fabrica
    la maquina al arrancar, espejando el 20 al 41 -y cambiando de sitio las dos
    columnas del patron, que es lo que hace el `sub 020h` de 0x46E7-.
    """
    v = V.Vram(rom).monta(nivel).v
    px = [[(0, 0, 0)] * (8 * 16) for _ in range(8 * 16)]
    for n in range(64):
        pinta_sprite(px, v, n * 4, 15, (n // 8) * 16, (n % 8) * 16)
    return px


if __name__ == "__main__":
    import graficos as G
    rom = open(sys.argv[1], "rb").read()
    carpeta = sys.argv[2] if len(sys.argv) > 2 else "work/gfx"
    os.makedirs(carpeta, exist_ok=True)
    G.png(os.path.join(carpeta, "jugador.png"), hoja_del_jugador(rom), escala=3)
    hoja, pats = hoja_de_bichos(rom)
    G.png(os.path.join(carpeta, "bichos.png"), hoja, escala=3)
    G.png(os.path.join(carpeta, "sprites.png"), hoja_de_patrones(rom), escala=3)
    print("  jugador.png  16 posturas en color")
    print("  bichos.png   %d patrones x 6 colores" % len(pats))
    print("  sprites.png  los 64 patrones crudos")
