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

LAS DOS FILAS DEL MARCADOR. Ninguna de esas filas se cuenta desde el techo de
la SALA: se cuentan desde el techo de la PANTALLA, y las dos primeras filas son
el marcador. Lo dice el `ld hl,00002h` de 0x59BC -"h = columna 0, l = fila 2"-,
lo dicen las cuatro bases de 0x45FF (0xE5C0 y no 0xE600: 0x40 bytes, o sea dos
filas, de sesgo) y lo dice 0x5F13, que vuelca la sala a 0x3840 y no a 0x3800.
Asi que la fila que guarda cada ficha es la de la PANTALLA, y la de la sala es
esa menos dos: es la resta que hace FILA_DEL_MARCADOR.

Y LOS SPRITES. Un atributo de sprite del TMS9918 se dibuja UNA linea mas abajo
de lo que dice su byte de fila, asi que la fila del sprite dentro de la sala es
(atributo + 1 - 16): el +1 del VDP y las dos filas del marcador. Cada bicho
calcula su atributo a su manera, y esa cuenta esta al lado de cada uno.

LO QUE SE DIBUJA, y de que instruccion sale su posicion:

  nivel  0  la columna que crece   0x8733 arranca en (ix+002h) y 0x8773 va
                                   BAJANDO: la punta primero y la base al cabo
                                   de (ix+004h) casillas (0x8747, 0x8760 y
                                   0x8763)
  nivel  1  la estalactita         0x8879 y 0x887C
  nivel  2  el perseguidor         0x8E19: el nibble alto del segundo byte por
                                   dieciseis mas 0x0D es la fila, y el bajo por
                                   dieciseis la columna. El sprite lo monta
                                   0x65AF: dieciseis pixeles arriba y ocho a la
                                   izquierda
  nivel  3  la puerta al siguiente 0x5F48 recorre las TRES fichas de 0xE2BD y
                                   0x5F69 pinta en cada una el arco de la
                                   calavera blanca de 0x5F78, 4x3, en
                                   (ix+002h) y (ix+003h). En la ficha van
                                   ademas el nivel al que lleva (ix+004h) y la
                                   entrada por la que se aparece (ix+005h),
                                   que es lo que lee 0x8349
  nivel  4  el trasto que parpadea 0x60EC
  nivel  5  la jaula               0x6038 y 0x603B, y ademas la columnita de
                                   0x605C: (ix+004h) casillas 0x92 en la
                                   columna de al lado, empezando tres filas mas
                                   abajo menos esas mismas casillas
  nivel  6  el objeto escondido    0x6E53, y es una sola casilla: la 0x91
  nivel  7  la puerta              0x5F84: con (ix+004h) a cero se pinta el
                                   arco vacio de 0x5FCF, y si no, el de la
                                   calavera y las tibias de 0x5FC3. La posicion,
                                   en 0x5F6F y 0x5F72
  sala   0  el chorro de agua      0x85EA (la fila de arranque) y 0x86BB
  sala   1  la bola de piedra      0x84F6 y 0x84F9
  sala   2  la llamarada           0x895F y 0x8966
  sala   3  el chorro del tubo     0x8A8B y 0x8A6A; el lado sale del BIT 7 del
                                   segundo byte, que es lo que 0x8EF1 baja a
                                   (ix+003h) con dos `rla` y un `and 001h`
  sala   5  la calavera            0x8F0A: el nibble alto por dieciseis es la
                                   fila y el bajo por dieciseis la columna. Su
                                   sprite no pasa por el montador de fichas:
                                   0x6973 le pone la fila doce pixeles mas
                                   arriba y 0x697A la columna mas lo que pida
                                   la postura (0x6996: -4 con el dibujo derecho
                                   0xA0, -12 con su espejo)
  sala   6  el murcielago          0x6A1A: los dos bytes van ya en pixeles, y
                                   0x6C59 le pone el patron 0x24 y el color 5,
                                   seis pixeles mas arriba y ocho a la
                                   izquierda

  sala   4  el sitio del que gotea 0x8E91 mete la ficha en 0xE3BD y 0x8ACC la
                                   gasta: la fila es el primer byte, la columna
                                   los siete bits bajos del segundo -el 7 dice
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

TODO ESTO ESTA COTEJADO contra la VRAM del emulador, no deducido a ojo: se deja
correr el cartucho, se vuelca la tabla de nombres y se le resta el mapa de la
sala, y lo que queda son justo estas fichas en estas filas.

Uso: mapas.py <rom> [carpeta]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import figuras as F                                        # noqa: E402
import graficos as G                                       # noqa: E402
import vram as V                                           # noqa: E402

ORG = 0x4000

# Las dos filas de arriba de la pantalla son el marcador y la sala empieza en la
# tercera: el `ld hl,00002h` de 0x59BC. Todas las filas que guardan las fichas
# son de PANTALLA, asi que para dibujarlas sobre la sala hay que restar estas
# dos. En pixeles son dieciseis, que es lo que se le resta a los sprites.
FILA_DEL_MARCADOR = 2

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


def casillas(sala, fila, col, dibujo, nombre):
    """Una ficha de casillas, con la fila pasada de PANTALLA a SALA."""
    return (sala, fila - FILA_DEL_MARCADOR, col, "casillas", dibujo, nombre)


def sprite(sala, y, x, pat, color, nombre):
    """Un sprite, dado su ATRIBUTO: el byte de fila y el de columna.

    El TMS9918 dibuja el sprite una linea por debajo de lo que dice su byte de
    fila, y encima hay que quitar las dos filas del marcador: de ahi el
    (y + 1 - 16). La columna del atributo ya es la de la pantalla.
    """
    return (sala, (y + 1 - 8 * FILA_DEL_MARCADOR) / 8.0, x / 8.0,
            "sprite", (pat, color), nombre)


def cosas_del_nivel(rom, nivel):
    """Todo lo que hay que pintar encima de las salas, ya colocado."""
    out = []
    for t, r in lista_del_nivel(rom, nivel):
        sala, sitio = r[0] >> 6, r[0] & 0x3F
        if t == 0:
            # 0x8733 arranca en (ix+002h) y 0x8773 hace `inc (ix+007h)`: la
            # columna crece HACIA ABAJO. 0x8747 elige el dibujo: la punta en la
            # primera casilla, la base en la ultima y el tramo de en medio en
            # las demas.
            alto = r[2]
            for k in range(alto):
                cual = 0 if k == 0 else (2 if k == alto - 1 else 1)
                out.append(casillas(
                    sala, sitio + k, r[1],
                    bloque_con_tamano(rom, puntero(rom, 0x8787, cual)),
                    NOMBRES_NIVEL[t]))
        elif t == 1:
            out.append(casillas(
                sala, sitio, r[1],
                bloque_con_tamano(rom, puntero(rom, 0x8891, 0)),
                NOMBRES_NIVEL[t]))
        elif t == 2:
            # 0x8E19: el primer byte lleva la sala y la clase, y el segundo la
            # fila en el nibble alto -por dieciseis, mas 0x0D- y la columna en
            # el bajo. El dibujo y el color salen de 0x78D0 y 0x64B9: las
            # clases 0 a 4 usan la tabla de 0x78F5 y un color por clase, y de
            # la 5 en adelante la de 0x790B, en blanco. El sprite lo monta
            # 0x65A9: la fila menos dieciseis y la columna menos ocho.
            clase = r[0] & 0x3F
            pat = 0x80 if (clase & 0x0F) < 5 else 0x94
            col = rom[0x6546 - ORG + ((clase & 0x0F) + 1 if
                                      (clase & 0x0F) < 5 else 0)]
            out.append(sprite(sala, ((r[1] & 0xF0) | 0x0D) - 16,
                              ((r[1] & 0x0F) << 4) - 8, pat, col,
                              NOMBRES_NIVEL[t]))
        elif t == 3:
            # 0x5F69: la puerta que lleva al nivel siguiente se pinta con el
            # arco de la calavera blanca de 0x5F78, 4x3.
            out.append(casillas(sala, sitio, r[1], bloque(rom, 0x5F78, 4, 3),
                                NOMBRES_NIVEL[t]))
        elif t == 4:
            out.append(casillas(sala, sitio, r[1], [[0x86]],
                                NOMBRES_NIVEL[t]))
        elif t == 5:
            # 0x6040 pinta la jaula, 4x3, y 0x6048 le anade al lado una
            # columnita: (ix+004h) casillas de la tabla de 0x60A4 -con la jaula
            # todavia cerrada, las 0x92- en la columna de la izquierda,
            # acabando en la tercera fila de la jaula. Nunca son mas de dos, o
            # sea que las dos cosas caben en un mismo 4x4.
            cuantas = r[2] & 0x0F
            jaula = bloque(rom, puntero(rom, 0x606C, 0), 4, 3)
            dibujo = [[0] + fila for fila in jaula]
            for f in range(3 - cuantas, 3):
                dibujo[f][0] = rom[0x60A8 - ORG + f - (3 - cuantas)]
            out.append(casillas(sala, sitio, r[1] - 1, dibujo,
                                NOMBRES_NIVEL[t]))
        elif t == 6:
            # 0x6E14: el objeto escondido es UNA casilla, la 0x91, y parpadea
            out.append(casillas(sala, sitio, r[1], [[0x91]],
                                NOMBRES_NIVEL[t]))
        elif t == 7:
            # 0x5F94: con (ix+004h) a cero -o con siete amigos ya recogidos- la
            # puerta se pinta vacia, y si no, con la calavera y las tibias.
            cual = 0x5FC3 if (r[2] & 0x3F) else 0x5FCF
            out.append(casillas(sala, sitio, r[1], bloque(rom, cual, 4, 3),
                                NOMBRES_NIVEL[t]))
    for sala, lista in enumerate(listas_de_sala(rom, nivel)):
        for t, r in lista:
            if t == 0:
                out.append(casillas(
                    sala, r[0], r[1],
                    bloque_con_tamano(rom, puntero(rom, 0x86D6, 0)),
                    NOMBRES_SALA[t]))
            elif t == 1:
                out.append(casillas(sala, r[0], r[1],
                                    bloque(rom, 0x8508, 5, 2),
                                    NOMBRES_SALA[t]))
            elif t == 2:
                alto = rom[puntero(rom, 0x896C, 2) - ORG]
                out.append(casillas(
                    sala, r[0] - alto, r[1],
                    bloque_con_tamano(rom, puntero(rom, 0x896C, 2)),
                    NOMBRES_SALA[t]))
            elif t == 3:
                # 0x8A6A: la columna es (ix+002h)+1, y con (ix+003h) -el bit 7
                # del segundo byte, que es el que 0x8EF1 se lleva aparte-
                # puesto se va tres casillas a la izquierda y el dibujo pasa a
                # ser el del chorro hacia el otro lado.
                lado = (r[1] >> 7) & 1
                col = (r[1] & 0x7F) + 1 - (3 if lado else 0)
                out.append(casillas(sala, r[0], col,
                                    bloque(rom, 0x8AA5 + 4 * lado, 2, 2),
                                    NOMBRES_SALA[t]))
            elif t == 4:
                # 0x8ACC: el lanzador no tiene dibujo, lo que se ve es la gota
                # que suelta. El bit 7 del segundo byte dice hacia donde va y
                # no mueve el sitio, asi que la columna son los otros siete.
                out.append(casillas(
                    sala, r[0], r[1] & 0x7F,
                    bloque_con_tamano(rom, puntero(rom, 0x8C15, 0)),
                    NOMBRES_SALA[t]))
            elif t == 5:
                # 0x6973 y 0x697A: doce pixeles por encima de la fila y la
                # columna mas lo que pida la postura. La postura la eligen el
                # bit 3 del contador de cuadros y el lado (ix+00Ah), que
                # arranca a cero: la primera pareja de 0x6996, o sea el patron
                # 0xF8 -el espejo del 0xA0- doce pixeles a la izquierda.
                out.append(sprite(sala, ((r[1] & 0xF0) | 0x0D) - 12,
                                  ((r[1] & 0x0F) << 4) - 12, 0xF8, 15,
                                  NOMBRES_SALA[t]))
            elif t == 6:
                # 0x6A1A: los dos bytes van ya en pixeles, y 0x6C59 le pone el
                # patron 0x24 -las alas abiertas- y el color 5, seis pixeles
                # mas arriba y ocho a la izquierda
                out.append(sprite(sala, r[0] - 6, r[1] - 8, 0x24, 5,
                                  NOMBRES_SALA[t]))
            elif t == 7:
                # 0x91A1: los dos bytes van en pixeles y el sprite se planta
                # ocho mas arriba y ocho a la izquierda. El patron 0x9C es el
                # bicho de patas mirando a un lado -0xF4 es su espejo- y el
                # color, blanco (0x8FDD)
                out.append(sprite(sala, r[0] - 8, r[1] - 8, 0x9C, 15,
                                  NOMBRES_SALA[t]))
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
        # fila y col vienen YA en casillas de la sala: cosas_del_nivel les ha
        # quitado las dos filas del marcador, y a los sprites, ademas, la linea
        # que el VDP les suma. Aqui no se corrige nada mas.
        y0, x0 = base[sala] + int(round(fila * 8)), int(round(col * 8))
        # nada de una sala puede pintarse en la banda de la de al lado
        tope, suelo = base[sala], base[sala] + 20 * 8

        def cabe(fy, fx):
            return tope <= fy < suelo and 0 <= fx < 256
        if clase == "casillas":
            for f, linea in enumerate(dato):
                for c, tile in enumerate(linea):
                    if tile == 0:
                        continue
                    # el banco de patrones lo fija el TERCIO de PANTALLA, y la
                    # sala empieza en la fila 2 de la pantalla
                    banco = (int(fila) + f + FILA_DEL_MARCADOR) // 8
                    if not 0 <= banco <= 2:
                        continue
                    trozo = G.casilla(v, tile, banco)
                    for y in range(8):
                        for x in range(8):
                            fy, fx = y0 + f * 8 + y, x0 + c * 8 + x
                            if cabe(fy, fx):
                                px[fy][fx] = trozo[y][x]
        elif clase == "sprite":
            recorte = [[(0, 0, 0)] * 16 for _ in range(16)]
            F.pinta_sprite(recorte, v, dato[0], dato[1], 0, 0)
            for y in range(16):
                for x in range(16):
                    if recorte[y][x] != (0, 0, 0):
                        fy, fx = y0 + y, x0 + x
                        if cabe(fy, fx):
                            px[fy][fx] = recorte[y][x]
    return px


# ----------------------------------------------------------------------
# EL REPARTO DE SALAS: DONDE VA CADA UNA DE LAS CUATRO
# ----------------------------------------------------------------------
# Las cuatro salas de un nivel no van en columna: van en un plano, y no el
# mismo en todos los niveles. `empieza_el_nivel` (0x4F82) saca de 0x9D67 un
# byte por nivel y lo deja en (0xE06A); ese byte elige una de las DIECINUEVE
# filas de 0x52DB, cuatro bytes, uno por sala.
#
# De cada byte, el NIBBLE BAJO es la sala a la que se pasa saliendo por la
# izquierda (0xF: no hay), y el ALTO es LA POSICION de esa sala en el plano.
# Que es la posicion lo dice el perseguidor: 0x74C0 compara ese nibble con
# 0xC0 -los dos bits altos- para decidir si tiene que moverse en horizontal,
# y 0x74C4 con 0x30 -los dos bajos- para la vertical. O sea que el nibble es
# columna*4 + fila.
#
# Y encaja con lo demas: 0x5327 da la sala de la derecha, y las de arriba y
# abajo son la de ahora menos y mas uno (el `dec b` de 0x529A y los dos `inc
# b` de 0x52A2).
REPARTO_POR_NIVEL = 0x9D67            # un byte por nivel: cual de los 19
SALAS_POR_LA_IZQUIERDA = 0x52DB       # 19 filas de cuatro
SALAS_POR_LA_DERECHA = 0x5327


def reparto_del_nivel(rom, nivel):
    """La posicion (columna, fila) de cada una de las cuatro salas."""
    r = rom[REPARTO_POR_NIVEL - ORG + nivel - 1]
    return [((rom[SALAS_POR_LA_IZQUIERDA - ORG + 4 * r + s] >> 6),
             (rom[SALAS_POR_LA_IZQUIERDA - ORG + 4 * r + s] >> 4) & 3)
            for s in range(4)]


def puertas_del_nivel(rom, nivel):
    """Las puertas de calavera: (sala, fila, columna, nivel, entrada).

    El tercer byte del registro lo parte 0x8DA8: los seis bits bajos son el
    nivel al que lleva y los dos altos la ENTRADA, que es el numero de puerta
    por la que se aparece alli. Emparejan las 64 sin una sola excepcion.
    """
    out = []
    for t, r in lista_del_nivel(rom, nivel):
        if t == 3:
            out.append((r[0] >> 6, (r[0] & 0x3F) - FILA_DEL_MARCADOR, r[1],
                        r[2] & 0x3F, r[2] >> 6))
    return out


def plano_del_nivel(rom, nivel, hueco=12):
    """Las cuatro salas puestas donde el cartucho las pone, no en columna."""
    tira = mapa_del_nivel(rom, nivel, hueco)
    pos = reparto_del_nivel(rom, nivel)
    alto, ancho = 20 * 8 + hueco, 32 * 8
    cols = max(x for x, _ in pos) + 1
    filas = max(y for _, y in pos) + 1
    px = [[(0, 0, 0)] * (cols * ancho) for _ in range(filas * alto)]
    for s, (x, y) in enumerate(pos):
        for f, fila in enumerate(tira[s * alto:(s + 1) * alto]):
            px[y * alto + f][x * ancho:(x + 1) * ancho] = list(fila)
    return px


def encoge(px, n=4):
    """Reduce a la enesima parte promediando bloques de nxn."""
    alto, ancho = len(px) // n, len(px[0]) // n
    fuera = [[(0, 0, 0)] * ancho for _ in range(alto)]
    for f in range(alto):
        for c in range(ancho):
            r = g = b = 0
            for y in range(n):
                for x in range(n):
                    p = px[f * n + y][c * n + x]
                    r, g, b = r + p[0], g + p[1], b + p[2]
            k = n * n
            fuera[f][c] = (r // k, g // k, b // k)
    return fuera


def raya(px, a, b, color, grosor=1):
    """Una recta de a a b, con el algoritmo de Bresenham."""
    (y0, x0), (y1, x1) = a, b
    dy, dx = abs(y1 - y0), abs(x1 - x0)
    sy, sx = (1 if y1 > y0 else -1), (1 if x1 > x0 else -1)
    err = dx - dy
    while True:
        for f in range(-grosor, grosor + 1):
            for c in range(-grosor, grosor + 1):
                if 0 <= y0 + f < len(px) and 0 <= x0 + c < len(px[0]):
                    px[y0 + f][x0 + c] = color
        if y0 == y1 and x0 == x1:
            return
        e = 2 * err
        if e > -dy:
            err -= dy
            x0 += sx
        if e < dx:
            err += dx
            y0 += sy


# El minimapa de la ronda: colores propios, que no son los del cartucho porque
# esto no es una pantalla del juego sino un diagrama.
MM_FONDO = (14, 14, 22)
MM_MARCO = (86, 86, 112)
MM_CABECERA = (38, 38, 56)
MM_RAYA = (255, 146, 24)
MM_PUERTA = (255, 214, 0)
MM_ROTULO = (232, 232, 240)


def recuadro(px, y0, x0, alto, ancho, color, grosor=1):
    """Un marco alrededor de un nivel, con su franja de cabecera."""
    for g in range(grosor):
        for c in range(x0 - 1 - g, x0 + ancho + 1 + g):
            for f in (y0 - 1 - g, y0 + alto + g):
                if 0 <= f < len(px) and 0 <= c < len(px[0]):
                    px[f][c] = color
        for f in range(y0 - 1 - g, y0 + alto + 1 + g):
            for c in (x0 - 1 - g, x0 + ancho + g):
                if 0 <= f < len(px) and 0 <= c < len(px[0]):
                    px[f][c] = color


def banda(px, y0, x0, alto, ancho, color):
    """Rellena un rectangulo: la franja donde va el numero del nivel."""
    for f in range(y0, y0 + alto):
        if 0 <= f < len(px):
            for c in range(x0, x0 + ancho):
                if 0 <= c < len(px[0]):
                    px[f][c] = color


def punto_gordo(px, y, x, color, r=2, borde=(20, 20, 28)):
    """Una marca de puerta, con reborde para que se vea sobre cualquier sala."""
    for f in range(-r - 1, r + 2):
        for c in range(-r - 1, r + 2):
            if abs(f) > r or abs(c) > r:
                if 0 <= y + f < len(px) and 0 <= x + c < len(px[0]):
                    px[y + f][x + c] = borde
    for f in range(-r, r + 1):
        for c in range(-r, r + 1):
            if 0 <= y + f < len(px) and 0 <= x + c < len(px[0]):
                px[y + f][x + c] = color


def curva(px, a, b, comba, color, centro=None):
    """Una Bezier cuadratica de a a b, combada `comba` pixeles hacia un lado.

    Las rayas rectas tenian dos problemas: cortaban por el medio del dibujo, y
    dos niveles unidos por DOS puertas -el 6 y el 7 de la ronda 2- daban dos
    rayas casi encima una de otra, o sea que se veia una. Combadas, y con una
    comba distinta por cada pareja repetida, se ven las dos.
    """
    (ay, ax), (by, bx) = a, b
    my, mx = (ay + by) / 2.0, (ax + bx) / 2.0
    dy, dx = by - ay, bx - ax
    largo = max(1.0, (dy * dy + dx * dx) ** 0.5)
    ny, nx = -dx / largo, dy / largo
    # la comba va SIEMPRE hacia fuera del centro del dibujo: asi las curvas
    # rodean los paneles en vez de cruzarlos por encima
    if centro is not None and ((my - centro[0]) * ny + (mx - centro[1]) * nx) < 0:
        ny, nx = -ny, -nx
    cy, cx = my + ny * comba, mx + nx * comba
    pasos = int(largo * 1.5) + 2
    for k in range(pasos + 1):
        s = k / float(pasos)
        u = 1.0 - s
        y = int(round(u * u * ay + 2 * u * s * cy + s * s * by))
        x = int(round(u * u * ax + 2 * u * s * cx + s * s * bx))
        for f in (0, 1):
            for c in (0, 1):
                if 0 <= y + f < len(px) and 0 <= x + c < len(px[0]):
                    px[y + f][x + c] = color


def se_cruzan(p1, p2, p3, p4):
    """Si los segmentos p1p2 y p3p4 se cortan. Solo para ordenar el anillo."""
    def lado(a, b, c):
        v = ((b[1] - a[1]) * (c[0] - a[0]) - (b[0] - a[0]) * (c[1] - a[1]))
        return (v > 0) - (v < 0)
    return (lado(p1, p2, p3) * lado(p1, p2, p4) < 0
            and lado(p3, p4, p1) * lado(p3, p4, p2) < 0)


def minimapa_de_la_ronda(rom, ronda, escala=4, margen=20):
    """Los cinco niveles de una ronda, con sus puertas de calavera unidas.

    Cada nivel va en su propio recuadro, con su plano montado como lo monta el
    cartucho, y cada curva une DOS puertas que se emparejan de verdad: la
    puerta j del nivel A dice (B, k) y la puerta k del nivel B dice (A, j).

    Dos cosas que este dibujo NO deduce de la ROM, y por eso se dicen aqui: el
    sitio de cada nivel en el anillo y la comba de las curvas. El cartucho no
    guarda ninguna posicion para un nivel dentro de su ronda -una ronda es un
    grafo, no una rejilla-, asi que de los doce ordenes distintos del anillo se
    elige el que menos cruces de rayas produce, y nada mas.
    """
    import math
    import itertools
    tipo = fuente(rom)
    primero = 5 * ronda - 4
    niveles = list(range(primero, primero + 5))
    planos = {n: encoge(plano_del_nivel(rom, n, hueco=0), escala)
              for n in niveles}
    puertas = {n: puertas_del_nivel(rom, n) for n in niveles}
    parejas = [(n, j, p[3], p[4]) for n in niveles
               for j, p in enumerate(puertas[n]) if p[3] > n]

    # el anillo: una elipse a la medida de los planos, para no dejar un
    # agujero enorme en el centro
    ancho_max = max(len(pl[0]) for pl in planos.values())
    alto_max = max(len(pl) for pl in planos.values())
    rx, ry = ancho_max * 0.85 + 60, alto_max * 0.85 + 60

    def sitios(orden):
        d = {}
        for i, n in enumerate(orden):
            ang = -math.pi / 2 + 2 * math.pi * i / 5
            d[n] = (ry * math.sin(ang), rx * math.cos(ang))
        return d

    def cruces(orden):
        c = sitios(orden)
        seg = [(c[a], c[b]) for a, _, b, _ in parejas]
        return sum(1 for i in range(len(seg)) for k in range(i + 1, len(seg))
                   if se_cruzan(seg[i][0], seg[i][1], seg[k][0], seg[k][1]))

    # los doce ordenes distintos del anillo: el primero se fija y no se cuenta
    # el mismo anillo del reves
    mejor, mejores = None, None
    for resto in itertools.permutations(niveles[1:]):
        if resto[0] > resto[-1]:
            continue
        orden = [niveles[0]] + list(resto)
        c = cruces(orden)
        if mejor is None or c < mejor:
            mejor, mejores = c, orden

    centros = sitios(mejores)
    esquina = {n: (int(centros[n][0] - len(planos[n]) / 2),
                   int(centros[n][1] - len(planos[n][0]) / 2))
               for n in niveles}
    CAB = 11
    y0 = min(e[0] for e in esquina.values()) - CAB - margen
    x0 = min(e[1] for e in esquina.values()) - margen
    H = max(esquina[n][0] + len(planos[n]) for n in niveles) - y0 + margen
    W = max(esquina[n][1] + max(len(planos[n][0]), 8 * len("NIVEL %d" % n) + 6)
            for n in niveles) - x0 + margen
    esquina = {n: (e[0] - y0, e[1] - x0) for n, e in esquina.items()}
    px = [[MM_FONDO] * W for _ in range(H)]

    def sitio(n, puerta):
        """El pixel de una puerta: su sala en el plano, y su sitio en la sala."""
        sala, fila, col, _, _ = puerta
        x, y = reparto_del_nivel(rom, n)[sala]
        ey, ex = esquina[n]
        return (ey + (y * 20 * 8 + fila * 8 + 16) // escala,
                ex + (x * 32 * 8 + col * 8 + 12) // escala)

    # los recuadros y los planos
    for n in niveles:
        ey, ex = esquina[n]
        alto, ancho = len(planos[n]), len(planos[n][0])
        # la cabecera nunca mas estrecha que su rotulo: "NIVEL 10" son 64
        # pixeles y un nivel en columna mide justo eso
        cab_ancho = max(ancho + 2, 8 * len("NIVEL %d" % n) + 6)
        banda(px, ey - CAB, ex - 1, CAB, cab_ancho, MM_CABECERA)
        for f, fila in enumerate(planos[n]):
            px[ey + f][ex:ex + ancho] = list(fila)
        recuadro(px, ey - CAB, ex, alto + CAB, max(ancho, cab_ancho - 2),
                 MM_MARCO)
        rotula(px, tipo, "NIVEL %d" % n, ey - CAB + 2, ex + 2, MM_ROTULO)

    # y las curvas encima, con una comba distinta por cada pareja repetida
    veces = {}
    for a, j, b, k in parejas:
        veces[(a, b)] = veces.get((a, b), 0) + 1
        comba = 16 + 22 * (veces[(a, b)] - 1)
        curva(px, sitio(a, puertas[a][j]), sitio(b, puertas[b][k]),
              comba, MM_RAYA, (H / 2.0, W / 2.0))
    for n in niveles:
        for p in puertas[n]:
            fy, fx = sitio(n, p)
            punto_gordo(px, fy, fx, MM_PUERTA)
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
        # el mapa del nivel va con las salas DONDE EL CARTUCHO LAS PONE, que
        # es el reparto de 0x52DB, no una encima de otra
        G.png(os.path.join(carpeta, "mapa-nivel-%02d.png" % n),
              plano_del_nivel(rom, n))
        # y LAS CUATRO SALAS por separado: son cien en todo el cartucho y
        # ninguna se repite, asi que cada una merece su imagen
        alto = 20 * 8 + 12
        for s in range(4):
            G.png(os.path.join(carpeta, "sala-%02d-%d.png" % (n, s + 1)),
                  entero[s * alto:(s + 1) * alto])
        cuenta = {}
        for _, _, _, _, _, nombre in cosas_del_nivel(rom, n):
            cuenta[nombre] = cuenta.get(nombre, 0) + 1
        print("  nivel %2d: %s  reparto %s" % (n, ", ".join(
            "%s x%d" % (k, v) for k, v in sorted(cuenta.items())),
            reparto_del_nivel(rom, n)))
    for r in range(1, 6):
        # a escala 1: el minimapa ya trae sus propios tamanos, y doblarlo solo
        # lo hace pesado
        G.png(os.path.join(carpeta, "ronda-%d.png" % r),
              minimapa_de_la_ronda(rom, r), escala=1)
    print("  100 salas sueltas, 25 mapas de nivel y 5 minimapas de ronda")


if __name__ == "__main__":
    main()
