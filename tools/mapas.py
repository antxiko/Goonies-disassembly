#!/usr/bin/env python3
"""Los mapas de los 25 niveles, con los bichos y los peligros en su sitio.

Las cuatro salas de un nivel no son solo casillas: encima va una lista de lo
que el nivel trae -la puerta, las jaulas, las estalactitas- y otra lista por
sala -el agua, las llamaradas, las calaveras-. Aqui se leen las dos y se
plantan las figuras donde el cartucho las planta, dibujadas tambien desde la
ROM: no hay ni una captura de pantalla.

DONDE ESTA CADA LISTA, medido sobre el listado:

  el mapa del nivel   0x9D80 + 2*(nivel-1) -> 80 bytes de bloques
  la lista del nivel  justo detras de esos 80 bytes (0x59DA: `ex de,hl` deja de
                      apuntando ahi y 0x59DB la reparte)
  las listas de sala  0xA304 + 2*(nivel-1) -> cuatro punteros, uno por sala
                      (0x5F1C..0x5F2E)

COMO SE LEE UNA LISTA (0x8D64 y 0x8E73): un byte 0xF0+tipo abre un tramo y
detras van sus registros, hasta que aparece otro byte >= 0xF0. El 0xFF cierra.
En la lista del NIVEL el primer byte de cada registro lleva la sala en los bits
7 y 6 y el sitio -la fila- en los seis de abajo (0x8DE9). En las listas de SALA
no hace falta: la sala ya se sabe.

LO QUE SE DIBUJA, y de que instruccion sale su posicion:

  nivel  0  la columna que crece   fila 0x8760, columna 0x8763, alto (ix+004h)
  nivel  1  la estalactita         0x8879 y 0x887C
  nivel  2  el perseguidor         0x8E19: el nibble alto del segundo byte por
                                   dieciseis mas 0x0D es la fila, y el bajo por
                                   dieciseis la columna
  nivel  3  la puerta al siguiente 0x5017 y 0x5023; la misma ficha es la
            puerta que saca del nivel (0x832D) y la entrada por la que se
            aparece en el nuevo
  nivel  4  el trasto que parpadea 0x60EC
  nivel  5  la jaula               0x6038 y 0x603B
  nivel  6  el objeto escondido    0x6E53, y es una sola casilla: la 0x91
  nivel  7  la puerta              0x5F6F y 0x5F72
  sala   0  el chorro de agua      0x85EA (la fila de arranque) y 0x86BB
  sala   1  la bola de piedra      0x84F6 y 0x84F9
  sala   2  la llamarada           0x895F y 0x8966
  sala   3  el chorro del tubo     0x8A8B y 0x8A6A
  sala   5  la calavera            0x8F0A: el nibble alto por dieciseis es la
                                   fila y el bajo por dieciseis la columna
  sala   6  el murcielago          0x6A1A: los dos bytes van ya en pixeles, y
                                   0x6C59 le pone el patron 0x24 y el color 5

  sala   4  el sitio del que gotea 0x8E91 mete la ficha en 0xE3BD y 0x8ACC la
                                   gasta: la fila es el primer byte, la columna
                                   los siete bits bajos del segundo -el 6 dice
                                   hacia donde-, y el tercero cada cuantos
                                   cuadros suelta. El lanzador no tiene dibujo
                                   propio: lo que se ve es la gota, con el
                                   primero de los ocho dibujos de 0x8C15
  sala   7  el bicho de patas      0x8F46 mete la ficha en 0xE453: los dos
                                   bytes van en PIXELES y se copian tambien a
                                   0xE1B2, que es donde el bicho espera
                                   escondido hasta que el jugador lo pisa
                                   (0x8FA1, una caja de 8x8). El sprite, el
                                   patron 0x9C en blanco, se planta ocho
                                   pixeles mas arriba y ocho a la izquierda
                                   (0x91A1)

Se dibuja TODO: los ocho tipos de la lista del nivel y los ocho de la de sala.

Uso: mapas.py <rom> [carpeta]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import figuras as F                                        # noqa: E402
import graficos as G                                       # noqa: E402
import vram as V                                           # noqa: E402

ORG = 0x4000

# Cuantos bytes ocupa cada registro en la lista, contados sobre las rutinas que
# la leen: 0x8DCF (tipos 0, 1, 5 y 6), 0x8DA1 (3 y 7), 0x8DFF (4) y 0x8E19 (2).
LARGO_NIVEL = {0: 3, 1: 3, 2: 2, 3: 3, 4: 2, 5: 3, 6: 3, 7: 3}
# Y sobre 0x8E9F (0), 0x8EC1 (1), 0x8ECA (2), 0x8ED3 (3), 0x8E91 (4), 0x8EFE
# (5), 0x8F28 (6) y 0x8F46 (7).
LARGO_SALA = {0: 4, 1: 5, 2: 2, 3: 3, 4: 3, 5: 2, 6: 2, 7: 2}

NOMBRES_NIVEL = {
    0: "columna que crece", 1: "estalactita", 2: "perseguidor", 3: "puerta al nivel",
    4: "trasto", 5: "jaula", 6: "objeto", 7: "puerta",
}
NOMBRES_SALA = {
    0: "agua", 1: "bola de piedra", 2: "llamarada", 3: "chorro del tubo",
    4: "gotera", 5: "calavera", 6: "murcielago", 7: "bicho de patas",
}


def palabra(rom, a):
    return rom[a - ORG] | (rom[a - ORG + 1] << 8)


# La fuente del cartucho, para rotular con las mismas letras que el juego: el
# guion de 0x4885 se descomprime sobre la casilla 0x10 (0x4850..0x4856), asi que
# 0x10..0x19 son las cifras y 0x21..0x3A la A a la Z.
import formatos as FMT                                     # noqa: E402


def fuente(rom):
    """Los patrones de la fuente, descomprimiendo el guion como hace 0x484D."""
    v = bytearray(0x4000)
    _, tr = FMT.rle(rom, ORG, 0x4885, con_cabecera=False)
    for vram, datos in tr:
        a = (vram if vram is not None else 0x2080) & 0x3FFF
        v[a:a + len(datos)] = datos
    return {c: v[0x2000 + c * 8:0x2000 + c * 8 + 8] for c in range(0x10, 0x40)}


def rotula(px, tipo, texto, fila, col, color=(255, 255, 255)):
    """Escribe con la fuente del cartucho. Solo cifras, letras y el espacio."""
    for i, ch in enumerate(texto):
        if ch == " ":
            continue
        c = 0x10 + int(ch) if ch.isdigit() else 0x21 + ord(ch) - ord("A")
        for y, b in enumerate(tipo.get(c, b"\0" * 8)):
            for x in range(8):
                if b & (0x80 >> x):
                    f, k = fila + y, col + i * 8 + x
                    if 0 <= f < len(px) and 0 <= k < len(px[0]):
                        px[f][k] = color


def tramos(rom, p, largo):
    """Recorre una lista de tramos 0xF0+tipo y devuelve (tipo, registro)."""
    fuera = []
    while True:
        b = rom[p - ORG]
        if b == 0xFF or b < 0xF0:
            return fuera
        t, p = b & 0x0F, p + 1
        while rom[p - ORG] < 0xF0:
            n = largo[t]
            fuera.append((t, bytes(rom[p - ORG:p - ORG + n])))
            p += n


def lista_del_nivel(rom, nivel):
    mapa = palabra(rom, 0x9D80 + 2 * (nivel - 1))
    return tramos(rom, mapa + 80, LARGO_NIVEL)


def listas_de_sala(rom, nivel):
    tabla = palabra(rom, 0xA304 + 2 * (nivel - 1))
    return [tramos(rom, palabra(rom, tabla + 2 * s), LARGO_SALA)
            for s in range(4)]


def bloque(rom, a, filas, cols):
    """Un rectangulo de casillas, tal como lo lee L_83CC."""
    d = rom[a - ORG:a - ORG + filas * cols]
    return [list(d[f * cols:(f + 1) * cols]) for f in range(filas)]


def bloque_con_tamano(rom, a):
    """Los que traen filas y columnas delante, que es lo que lee 0x83C6."""
    filas, cols = rom[a - ORG], rom[a - ORG + 1]
    return bloque(rom, a + 2, filas, cols)


def puntero(rom, tabla, i):
    return palabra(rom, tabla + 2 * i)


def cosas_del_nivel(rom, nivel):
    """Todo lo que hay que pintar encima de las salas, ya colocado."""
    out = []
    for t, r in lista_del_nivel(rom, nivel):
        sala, sitio = r[0] >> 6, r[0] & 0x3F
        if t == 0:                                    # 0x8747: tres dibujos
            alto = r[2]
            for k in range(alto):
                cual = 0 if k == 0 else (2 if k == alto - 1 else 1)
                out.append((sala, sitio - k, r[1], "casillas",
                            bloque_con_tamano(rom, puntero(rom, 0x8787, cual)),
                            NOMBRES_NIVEL[t]))
        elif t == 1:
            out.append((sala, sitio, r[1], "casillas",
                        bloque_con_tamano(rom, puntero(rom, 0x8891, 0)),
                        NOMBRES_NIVEL[t]))
        elif t == 2:
            # 0x8E19: el primer byte lleva la sala y la clase, y el segundo la
            # fila en el nibble alto -por dieciseis, mas 0x0D- y la columna en
            # el bajo. El dibujo y el color salen de 0x78D0 y 0x64B9: las
            # clases 0 a 4 usan la tabla de 0x78F5 y un color por clase, y de
            # la 5 en adelante la de 0x790B, en blanco.
            clase = r[0] & 0x3F
            pat = 0x80 if (clase & 0x0F) < 5 else 0x94
            col = rom[0x6546 - ORG + ((clase & 0x0F) + 1 if
                                      (clase & 0x0F) < 5 else 0)]
            out.append((sala, ((r[1] & 0xF0) | 0x0D) / 8.0,
                        ((r[1] & 0x0F) << 4) / 8.0, "sprite", (pat, col),
                        NOMBRES_NIVEL[t]))
        elif t == 3:
            out.append((sala, sitio, r[1], "jugador", 2, NOMBRES_NIVEL[t]))
        elif t == 4:
            out.append((sala, sitio, r[1], "casillas", [[0x86]],
                        NOMBRES_NIVEL[t]))
        elif t == 5:
            out.append((sala, sitio, r[1], "casillas",
                        bloque(rom, puntero(rom, 0x606C, 0), 4, 3),
                        NOMBRES_NIVEL[t]))
        elif t == 6:
            # 0x6E14: el objeto escondido es UNA casilla, la 0x91, y parpadea
            out.append((sala, sitio, r[1], "casillas", [[0x91]],
                        NOMBRES_NIVEL[t]))
        elif t == 7:
            out.append((sala, sitio, r[1], "casillas",
                        bloque(rom, 0x5FC3, 4, 3), NOMBRES_NIVEL[t]))
    for sala, lista in enumerate(listas_de_sala(rom, nivel)):
        for t, r in lista:
            if t == 0:
                out.append((sala, r[0], r[1], "casillas",
                            bloque_con_tamano(rom, puntero(rom, 0x86D6, 0)),
                            NOMBRES_SALA[t]))
            elif t == 1:
                out.append((sala, r[0], r[1], "casillas",
                            bloque(rom, 0x8508, 5, 2), NOMBRES_SALA[t]))
            elif t == 2:
                alto = rom[puntero(rom, 0x896C, 2) - ORG]
                out.append((sala, r[0] - alto, r[1], "casillas",
                            bloque_con_tamano(rom, puntero(rom, 0x896C, 2)),
                            NOMBRES_SALA[t]))
            elif t == 3:
                # 0x8A6A: la columna es (ix+002h)+1, y con (ix+003h) -el bit 6
                # del segundo byte- puesto se va tres casillas a la izquierda y
                # el dibujo pasa a ser el del chorro hacia el otro lado.
                lado = (r[1] >> 6) & 1
                col = (r[1] & 0x7F) + 1 - (3 if lado else 0)
                out.append((sala, r[0], col, "casillas",
                            bloque(rom, 0x8AA5 + 4 * lado, 2, 2),
                            NOMBRES_SALA[t]))
            elif t == 4:
                # 0x8ACC: el lanzador no tiene dibujo, lo que se ve es la gota
                # que suelta. El bit 6 del segundo byte dice hacia donde va y
                # no mueve el sitio, asi que la columna son los otros siete.
                out.append((sala, r[0], r[1] & 0x7F, "casillas",
                            bloque_con_tamano(rom, puntero(rom, 0x8C15, 0)),
                            NOMBRES_SALA[t]))
            elif t == 5:                              # este va en pixeles
                out.append((sala, ((r[1] & 0xF0) | 0x0D) / 8.0,
                            ((r[1] & 0x0F) << 4) / 8.0, "sprite", (0xA0, 15),
                            NOMBRES_SALA[t]))
            elif t == 6:
                # 0x6A1A: los dos bytes van ya en pixeles, y 0x6C59 le pone el
                # patron 0x24 -las alas abiertas- y el color 5
                out.append((sala, (r[0] - 6) / 8.0, (r[1] - 8) / 8.0,
                            "sprite", (0x24, 5), NOMBRES_SALA[t]))
            elif t == 7:
                # 0x91A1: los dos bytes van en pixeles y el sprite se planta
                # ocho mas arriba y ocho a la izquierda. El patron 0x9C es el
                # bicho de patas mirando a un lado -0xF4 es su espejo- y el
                # color, blanco (0x8FDD)
                out.append((sala, (r[0] - 8) / 8.0, (r[1] - 8) / 8.0,
                            "sprite", (0x9C, 15), NOMBRES_SALA[t]))
    return out


def una_sala(rom, nivel, cual, hueco=12):
    """UNA sala suelta, con su rotulo y todo lo que lleva encima.

    Es el mismo dibujo que hace mapa_del_nivel, recortado a una de las cuatro:
    se monta el mapa entero -las cosas de la lista del NIVEL vienen repartidas
    por las cuatro salas y hay que saber cual es cual- y se devuelve la banda
    que toca.
    """
    px = mapa_del_nivel(rom, nivel, hueco)
    alto = 20 * 8 + hueco
    return px[cual * alto:(cual + 1) * alto]


def mapa_del_nivel(rom, nivel, hueco=12):
    """Las cuatro salas, una debajo de otra, con todo lo que llevan encima."""
    v = V.Vram(rom).monta(nivel).v
    salas, _, _ = V.salas(rom, nivel)
    tipo = fuente(rom)
    alto = 4 * (20 * 8 + hueco)
    px = [[(0, 0, 0)] * (32 * 8) for _ in range(alto)]
    base = [s * (20 * 8 + hueco) + hueco for s in range(4)]
    for s in range(4):
        rotula(px, tipo, "NIVEL %d  SALA %d" % (nivel, s + 1),
               base[s] - hueco + 2, 4)
    for s in range(4):
        dib = G.pinta(v, salas[s], banco_de_fila=lambda f: (f + 2) // 8)
        for y, fila in enumerate(dib):
            px[base[s] + y] = list(fila)
    for sala, fila, col, clase, dato, _ in cosas_del_nivel(rom, nivel):
        y0, x0 = base[sala] + int(fila * 8), int(col * 8)
        # nada de una sala puede pintarse en la banda de la de al lado
        tope, suelo = base[sala], base[sala] + 20 * 8

        def cabe(fy, fx):
            return tope <= fy < suelo and 0 <= fx < 256
        if clase == "casillas":
            for f, linea in enumerate(dato):
                for c, tile in enumerate(linea):
                    if tile == 0:
                        continue
                    banco = (int(fila) + f + 2) // 8
                    if not 0 <= banco <= 2:
                        continue
                    trozo = G.casilla(v, tile, banco)
                    for y in range(8):
                        for x in range(8):
                            fy, fx = y0 + f * 8 + y, x0 + c * 8 + x
                            if cabe(fy, fx):
                                px[fy][fx] = trozo[y][x]
        elif clase == "jugador":
            fig = F.figura_del_jugador(v, rom, dato)
            for y in range(32):
                for x in range(32):
                    if fig[y][x] != (0, 0, 0):
                        fy, fx = y0 - 24 + y, x0 - 12 + x
                        if cabe(fy, fx):
                            px[fy][fx] = fig[y][x]
        elif clase == "sprite":
            recorte = [[(0, 0, 0)] * 16 for _ in range(16)]
            F.pinta_sprite(recorte, v, dato[0], dato[1], 0, 0)
            for y in range(16):
                for x in range(16):
                    if recorte[y][x] != (0, 0, 0):
                        fy, fx = y0 - 12 + y, x0 - 4 + x
                        if cabe(fy, fx):
                            px[fy][fx] = recorte[y][x]
    return px


def los_objetos(rom, nivel=1):
    """Los veintitres iconos del inventario, cada uno con SU nivel debajo.

    Traduce 0x6EAE: de la tabla de 0x6F68 sale UNA casilla por objeto y el
    icono son esa y las tres de detras, puestas en un 2x2 (el `ld bc,00202h`
    de 0x6EC8). Se pintan en la fila 22, o sea en el tercer banco de color.

    Debajo, escrito con la fuente del propio cartucho, el nivel en el que sale
    cada uno: la tabla de 0x5576, que cuenta desde cero. En esa tabla faltan
    justo el 5 y el 14, o sea que los niveles 6 y 15 no llevan objeto.
    """
    v = V.Vram(rom).monta(nivel).v
    base = rom[0x6F68 - ORG:0x6F68 - ORG + 23]
    niveles = rom[0x5576 - ORG:0x5576 - ORG + 23]
    paso, alto = 24, 16 + 10
    px = [[(0, 0, 0)] * (23 * paso) for _ in range(alto)]
    tipo = fuente(rom)
    for i, t in enumerate(base):
        x = i * paso + 4
        for f in range(2):
            for c in range(2):
                for y, fila in enumerate(G.casilla(v, (t + f * 2 + c) & 0xFF,
                                                   2)):
                    px[f * 8 + y][x + c * 8:x + c * 8 + 8] = fila
        rotula(px, tipo, "%02d" % (niveles[i] + 1), 18, x)
    return px


def main():
    rom = open(sys.argv[1], "rb").read()
    carpeta = sys.argv[2] if len(sys.argv) > 2 else "work/gfx"
    os.makedirs(carpeta, exist_ok=True)
    G.png(os.path.join(carpeta, "objetos.png"), los_objetos(rom))
    print("  objetos.png: los 23 iconos del inventario")
    for n in range(1, 26):
        entero = mapa_del_nivel(rom, n)
        G.png(os.path.join(carpeta, "mapa-nivel-%02d.png" % n), entero)
        # y LAS CUATRO SALAS por separado: son cien en todo el cartucho y
        # ninguna se repite, asi que cada una merece su imagen
        alto = 20 * 8 + 12
        for s in range(4):
            G.png(os.path.join(carpeta, "sala-%02d-%d.png" % (n, s + 1)),
                  entero[s * alto:(s + 1) * alto])
        cuenta = {}
        for _, _, _, _, _, nombre in cosas_del_nivel(rom, n):
            cuenta[nombre] = cuenta.get(nombre, 0) + 1
        print("  nivel %2d: %s" % (n, ", ".join(
            "%s x%d" % (k, v) for k, v in sorted(cuenta.items()))))
    print("  100 salas sueltas, ademas de los 25 mapas de nivel")


if __name__ == "__main__":
    main()
