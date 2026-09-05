#!/usr/bin/env python3
"""Los formatos de datos de The Goonies, sacados del codigo que los lee.

Aqui no se estima ni un limite: cada funcion es la traduccion a Python del
bucle de la ROM que consume ese formato, asi que el byte donde para es el mismo
byte donde para el cartucho.

  guion RLE   L_469D (con cabecera) / L_46A3 (sin ella)
                0x00        fin
                0x80        cambia de direccion de VRAM y sigue
                0x01..0x7F  el byte siguiente, repetido n veces
                0x81..0xFF  n & 0x7F bytes literales

              Ojo al detalle, porque se lee al reves de lo que parece: quien
              separa los dos casos es a que sitio vuelve el `djnz`.
              En 0x46BA vuelve a `ld a,(de) / inc de`, o sea RELEE -> literal;
              en 0x46C4 vuelve solo al `out (c),a` -> repeticion. Y el `cp b`
              de 0x46AD manda al segundo caso cuando el bit 7 esta A CERO.

  bloque 8x4  L_5A05, 32 casillas comprimidas:
                0x0n        n ceros
                0x1n        n veces 0x40
                0x2n <b>    n veces <b>
                0x3n <b>    la fabrica de parejas de L_5A50
                otro        esa casilla, tal cual

  mapa        L_59B2, 80 bytes: 4 columnas x 20 filas de bloques de 8x4
              casillas, o sea 32x80 casillas, que son las CUATRO salas de
              32x20 del nivel, una detras de otra. El bit 7 del byte pide el
              bloque espejado.
"""


def rle(rom, org, dirn, con_cabecera=True):
    """Recorre un guion RLE. Devuelve (bytes que ocupa, [(dirVRAM, datos)])."""
    i = dirn - org
    ini = i
    tramos = []
    vram = None
    primera = True
    while True:
        if primera and con_cabecera or not primera:
            vram = rom[i] | (rom[i + 1] << 8)
            i += 2
        primera = False
        salida = bytearray()
        fin = False
        while True:
            op = rom[i]
            i += 1
            if op == 0x00:
                fin = True
                break
            if op == 0x80:
                break
            n = op & 0x7F
            if op & 0x80:                      # literal
                salida += rom[i:i + n]
                i += n
            else:                              # repeticion
                salida += bytes([rom[i]]) * n
                i += 1
        tramos.append((vram, bytes(salida)))
        if fin:
            return i - ini, tramos


def _parejas(rom, org, k, mascara):
    """Los ocho bytes que L_5A50 fabrica con la tabla de 0x5A79."""
    base = 0x5A79 + (k - 2) * 16 - org
    out = bytearray()
    for j in range(8):
        bit = (mascara >> (7 - j)) & 1
        out.append(rom[base + 2 * j + bit])
    return bytes(out)


def bloque(rom, org, dirn):
    """Descomprime un bloque de 8x4 casillas. Traduce L_5A05.

    Devuelve (bytes consumidos, 32 casillas). Para el bucle en cuanto el
    puntero de escritura llega a 0xE210, que es 0xE1F0 + 32: ese es el `cp 010h
    / cp 0e2h` de 0x5A08.
    """
    i = dirn - org
    ini = i
    out = bytearray()
    while len(out) < 32:
        b = rom[i]
        i += 1
        alto, n = b & 0xF0, b & 0x0F
        if alto == 0x00:
            out += bytes(n)
        elif alto == 0x10:
            out += bytes([0x40]) * n
        elif alto == 0x20:
            out += bytes([rom[i]]) * n
            i += 1
        elif alto == 0x30:
            v = rom[i]
            i += 1                              # el 0x3n siempre gasta 2 bytes
            if n == 0:                          # L_5B29: (v, v+1) cuatro veces
                for _ in range(4):
                    out += bytes([v, (v + 1) & 0xFF])
            elif n == 1:                        # L_5B2E: (v, v-1) cuatro veces
                for _ in range(4):
                    out += bytes([v, (v - 1) & 0xFF])
            else:
                out += _parejas(rom, org, n, v)
        else:
            out.append(b)
    return i - ini, bytes(out[:32])


def espeja_bloque(b):
    """Le da la vuelta a un bloque de 8x4. Traduce L_5B3A.

    No basta con invertir el orden de las ocho casillas de cada fila: las
    casillas 0xBC..0xDD tienen su version espejada dibujada aparte, en
    0xDE..0xFF, y hay que cambiarlas. Eso es lo que hace la aritmetica de
    0x5B49: si la casilla es >= 0xBC se le suman 0x22, y si eso se pasa de
    0xFF se le suman ademas 0xBC.
    """
    def cambia(v):
        if v < 0xBC:
            return v
        w = v + 0x22
        if w > 0xFF:
            w = (w & 0xFF) + 0xBC
        return w & 0xFF
    out = bytearray(32)
    for f in range(4):
        for c in range(8):
            out[f * 8 + c] = cambia(b[f * 8 + (7 - c)])
    return bytes(out)
