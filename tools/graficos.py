#!/usr/bin/env python3
"""Dibuja las pantallas de The Goonies ejecutando los pasos del propio cartucho.

En este repositorio no hay ni una captura de pantalla. Todo lo que se ve sale
de aqui: se monta la VRAM con tools/vram.py -que es la traduccion a Python de
las rutinas de carga- y luego se pinta lo que esa VRAM dice.

Uso: graficos.py <rom> <org> <carpeta>
"""
import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vram as V                                          # noqa: E402

# Los quince colores del MSX1 mas el transparente, en RGB, tal como los da la
# documentacion del TMS9918 de Texas Instruments.
PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]

COLORES, PATRONES, NOMBRES = 0x0000, 0x2000, 0x3800


def png(ruta, px, escala=2):
    """Escribe un PNG sin depender de ninguna biblioteca."""
    alto, ancho = len(px) * escala, len(px[0]) * escala
    crudo = bytearray()
    for f in px:
        fila = bytearray()
        for p in f:
            fila += bytes(p) * escala
        for _ in range(escala):
            crudo += b"\x00" + fila

    def trozo(tipo, datos):
        return (struct.pack(">I", len(datos)) + tipo + datos
                + struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF))

    with open(ruta, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(trozo(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, 2, 0, 0, 0)))
        f.write(trozo(b"IDAT", zlib.compress(bytes(crudo), 9)))
        f.write(trozo(b"IEND", b""))


def casilla(v, tile, banco, fondo=(0, 0, 0)):
    """Los 8x8 pixeles de una casilla, con el color que le toca en su banco."""
    p = PATRONES + banco * 0x800 + tile * 8
    c = COLORES + banco * 0x800 + tile * 8
    out = []
    for f in range(8):
        forma, col = v[p + f], v[c + f]
        tinta, papel = PALETA[col >> 4], PALETA[col & 0x0F]
        if col >> 4 == 0:
            tinta = fondo
        if col & 0x0F == 0:
            papel = fondo
        out.append([tinta if forma & (0x80 >> b) else papel for b in range(8)])
    return out


def pinta(v, casillas, banco_de_fila=None, fondo=(0, 0, 0)):
    """Pinta una rejilla de casillas. banco_de_fila dice que banco usa cada fila.

    En SCREEN 2 el banco lo fija el TERCIO de pantalla en el que cae la fila:
    filas 0..7 el banco 0, 8..15 el 1 y 16..23 el 2.
    """
    alto, ancho = len(casillas), len(casillas[0])
    px = [[fondo] * (ancho * 8) for _ in range(alto * 8)]
    for f in range(alto):
        b = banco_de_fila(f) if banco_de_fila else (f // 8)
        for c in range(ancho):
            for y, fila in enumerate(casilla(v, casillas[f][c], b, fondo)):
                px[f * 8 + y][c * 8:c * 8 + 8] = fila
    return px


def sala(rom, nivel, cual):
    """Una de las cuatro salas del nivel, tal como la deja el constructor.

    La sala son 32x20 casillas y se dibuja a partir de la fila 2 de la
    pantalla, que es lo que dice el `ld hl,00002h` de 0x59BC: las dos filas de
    arriba son el marcador. Asi que la fila 0 de la sala cae en el tercio de
    arriba, y el banco de patrones que le toca a cada una se cuenta desde ahi.
    """
    v = V.Vram(rom).monta(nivel).v
    cuatro, _, _ = V.salas(rom, nivel)
    return pinta(v, cuatro[cual], banco_de_fila=lambda f: (f + 2) // 8)


def pantalla_del_titulo(rom):
    """El rotulo THE GOONIES, montado como lo monta 0x4AA6 y 0x4ADC.

    No es una captura: se descomprimen los dos guiones del rotulo, se pintan
    sus 68 casillas en la tabla de nombres una a una -que es lo que hace el
    `inc a / inc hl` de 0x4B0E- y se rematan los dos guiones literales con el
    aviso de marca registrada.
    """
    v = V.Vram(rom).monta_el_titulo().v
    casillas = [[v[NOMBRES + f * 32 + c] for c in range(32)] for f in range(24)]
    return pinta(v, casillas)


def hoja_de_casillas(rom, nivel=1):
    """Las 256 casillas del nivel, en sus tres bancos, una debajo de otra."""
    v = V.Vram(rom).monta(nivel).v
    filas = []
    for banco in range(3):
        for f in range(8):
            filas.append([(f * 32 + c, banco) for c in range(32)])
    px = [[(0, 0, 0)] * 256 for _ in range(len(filas) * 8)]
    for i, fila in enumerate(filas):
        for c, (t, b) in enumerate(fila):
            for y, l in enumerate(casilla(v, t, b)):
                px[i * 8 + y][c * 8:c * 8 + 8] = l
    return px


def main():
    rom = open(sys.argv[1], "rb").read()
    carpeta = sys.argv[3] if len(sys.argv) > 3 else "work/gfx"
    os.makedirs(carpeta, exist_ok=True)
    png(os.path.join(carpeta, "titulo.png"), pantalla_del_titulo(rom))
    png(os.path.join(carpeta, "casillas.png"), hoja_de_casillas(rom))
    print("  titulo.png y casillas.png")


if __name__ == "__main__":
    main()
