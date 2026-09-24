#!/usr/bin/env python3
"""Escribe la pagina de EL MAPA, en los dos idiomas.

Se genera y no se escribe a mano a proposito: debajo de cada nivel va lo que
ese nivel lleva y el dibujo no dice -las llaves, lo que guarda cada jaula, cual
es el objeto escondido y a que nivel lleva cada puerta de calavera-, y eso sale
de recorrer la lista del nivel con las mismas reglas que el Z80 (tools/mapas.py,
resumen_del_nivel). Escrito a mano seria una cifra sin medir, que es justo lo
que esta serie no publica.

La seccion se rehizo tras el issue #3 de theNestruo: el plano sin rotulos y con
las salas pegadas, las jaulas abiertas, fuera las cien salas sueltas, las listas
reducidas a lo que la imagen no dice y los minimapas a 1:1 con las rayas detras.

Uso: paginas_niveles.py <rom> <docs>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mapas as M                                          # noqa: E402

CAB = {
    "es": """# El mapa

Veinticinco niveles de cuatro salas: **cien salas, y ninguna se repite**.
Comparadas casilla a casilla, las cien salen distintas, y todas estan dibujadas
desde los bytes de la ROM, ni una captura.

Cada sala son 32x20 casillas que salen de ochenta bytes apuntando a bloques de
8x4; se descomprimen, y encima se planta -en el sitio exacto en el que el
cartucho la planta- cada cosa de las dos listas del nivel: las jaulas, las
puertas, los peligros, los bichos y el objeto escondido. Las **64.000
casillas** caben en **2.983 bytes** del cartucho; como, esta contado en [El
codigo](EL-CODIGO.html).

Las cuatro salas de un nivel van puestas donde el cartucho las pone: el reparto
que le da `0x52DB`, que no es el mismo en todos -hay columnas, filas, 2x2 y
catorce formas raras-. Montadas asi, las plataformas y las escaleras siguen de
una sala a la de al lado, y por eso las salas van pegadas, sin rotulo en medio.
Las jaulas van **abiertas, ensenando lo que guardan** -el amigo o el frasco-
pero con sus candados puestos, que es un dibujo que el cartucho no pinta nunca:
abierta, a la jaula no le queda ningun candado.

Debajo de cada nivel va solo lo que el dibujo no dice: cuantas llaves hay, que
guarda cada jaula, cual es el objeto escondido y a que nivel lleva cada puerta
de calavera. Las salas se numeran en el orden de lectura del reparto: en un
2x2, la sala 1 es la de arriba a la izquierda y la 4 la de abajo a la derecha.

Delante de cada ronda va **el minimapa de sus cinco niveles**, a 1:1 para
poder ampliarlo, con las puertas de calavera unidas. Las rayas pasan por
detras de los niveles, para no ensuciar las salas.

*Esta seccion se rehizo tras el [issue
#3](https://github.com/antxiko/Goonies-disassembly/issues/3) de
**[theNestruo](https://github.com/theNestruo)**: el plano sin rotulos, las
jaulas abiertas, las listas reducidas a lo que la imagen no dice y los minimapas
a 1:1 con las rayas detras. Todo lo de esta pagina sale de ahi.*

""",
    "en": """# The map

Twenty-five levels of four rooms each: **one hundred rooms, and not one
repeats**. Compared tile by tile, all hundred come out different, and every one
is drawn from the bytes of the ROM, not a single capture.

Each room is 32x20 tiles that come out of eighty bytes pointing at 8x4 blocks;
they get decompressed, and on top goes - at the exact spot the cartridge puts
it - every item from the level's two lists: the cages, the doors, the hazards,
the creatures and the hidden item. The **64,000 tiles** fit in **2,983 bytes**
of cartridge; how, is worked out in [The code](THE-CODE.html).

The four rooms of a level are placed where the cartridge places them: the
arrangement `0x52DB` gives it, which is not the same for all - there are
columns, rows, 2x2 and fourteen odd shapes. Put together like this, platforms
and ladders carry on from one room into the next, so the rooms are drawn
touching, with no caption in between. The cages are drawn **open, showing what
they hold** - the friend or the potion - but with their padlocks on, which is a
picture the cartridge never paints: once open, a cage has no padlocks left.

Under each level goes only what the picture cannot say: how many keys there
are, what each cage holds, which item is hidden, and which level each skull
door leads to. Rooms are numbered in reading order of the arrangement: on a
2x2, room 1 is top left and room 4 bottom right.

Before each round comes **the minimap of its five levels**, at 1:1 so it can
be zoomed into, with the skull doors joined up. The lines run behind the
levels, so as not to spoil the rooms.

*This section was reworked after [issue
#3](https://github.com/antxiko/Goonies-disassembly/issues/3) by
**[theNestruo](https://github.com/theNestruo)**: the plan with no captions, the
cages open, the lists cut down to what the picture cannot say, and the minimaps
at 1:1 with the lines behind. Everything on this page comes from there.*

""",
}

RONDA = {
    "es": "## Ronda %d — niveles %d a %d\n\n",
    "en": "## Round %d — levels %d to %d\n\n",
}
NIVEL = {"es": "### Nivel %d\n\n", "en": "### Level %d\n\n"}
PIE_RONDA = {
    "es": "*Los cinco niveles de la ronda %d y sus puertas de calavera, a "
          "1:1. Cada nivel esta puesto con el reparto de salas que le da "
          "0x52DB, y cada raya une DOS puertas que se emparejan de verdad: la "
          "puerta j del nivel A dice (B, k) y la puerta k del nivel B dice "
          "(A, j). Las 64 del cartucho emparejan asi, y ninguna sale de su "
          "ronda. Las rayas van por detras de los niveles; la marca amarilla "
          "es la puerta. Dos cosas de este dibujo NO salen de la ROM, y por "
          "eso se dicen: el sitio de cada nivel en el anillo -de los doce "
          "ordenes posibles se elige el que menos cruces deja- y la comba de "
          "las curvas, que separa las parejas de niveles unidas por DOS "
          "puertas.*\n\n",
    "en": "*The five levels of round %d and their skull doors, at 1:1. Each "
          "level is laid out with the room arrangement 0x52DB gives it, and "
          "every line joins TWO doors that really pair up: door j of level A "
          "says (B, k) and door k of level B says (A, j). All 64 in the "
          "cartridge pair up like that, and none leaves its round. The lines "
          "run behind the levels; the yellow mark is the door. Two things in "
          "this picture do NOT come from the ROM, so they are said out loud: "
          "where each level sits on the ring -of the twelve possible orders "
          "the one with fewest crossings is picked- and the bow of the "
          "curves, which separates the pairs of levels joined by TWO "
          "doors.*\n\n",
}

# Los cuatro objetos escondidos que no van al inventario: 0x6E21 reparte del
# 0x16 en adelante por la tabla de 0x6E2C, y el 0x16 -que si es de los
# veintitres- abre ademas una escena. Los otros cuatro solo hacen esto.
EXTRA = {
    "es": {23: "energia", 24: "la segunda barra", 25: "puntos", 26: "puntos"},
    "en": {23: "energy", 24: "the second bar", 25: "points", 26: "points"},
}
CIFRA = {
    "es": ["ninguna", "una", "dos", "tres", "cuatro", "cinco", "seis",
           "siete", "ocho", "nueve"],
    "en": ["none", "one", "two", "three", "four", "five", "six", "seven",
           "eight", "nine"],
}


def cifra(n, idioma):
    return CIFRA[idioma][n] if n < 10 else str(n)


def lista(partes, idioma, coma=False):
    """a, b y c / a, b and c. Con coma, la de antes del ultimo: para las
    partes que ya llevan un "y" dentro, como "las salas 1 y 3"."""
    if len(partes) <= 1:
        return "".join(partes)
    y = " y " if idioma == "es" else " and "
    if coma and (len(partes) > 2 or any(y in p for p in partes)):
        y = "," + y
    return ", ".join(partes[:-1]) + y + partes[-1]


def forma(rom, n, idioma):
    """El reparto escrito: 2x2, una fila de cuatro, o el dibujo si es raro."""
    pos = M.reparto_del_nivel(rom, n)
    cols = max(x for x, _ in pos) + 1
    filas = max(y for _, y in pos) + 1
    if cols * filas == 4:
        if filas == 1:
            return ("las cuatro salas en fila" if idioma == "es"
                    else "the four rooms in a row")
        if cols == 1:
            return ("las cuatro salas en columna" if idioma == "es"
                    else "the four rooms in a column")
        return ("las cuatro salas en 2x2" if idioma == "es"
                else "the four rooms in a 2x2")
    rej = {(x, y): str(s + 1) for s, (x, y) in enumerate(pos)}
    dibujo = " / ".join("".join(rej.get((x, y), "-") for x in range(cols))
                        for y in range(filas))
    return ("las salas repartidas `%s`" if idioma == "es"
            else "the rooms laid out `%s`") % dibujo


def llaves(cuenta, idioma):
    total = sum(cuenta)
    if idioma == "es":
        if total == 0:
            return "Llaves: ninguna."
        donde = [i for i, c in enumerate(cuenta) if c]
        if len(donde) == 1:
            s = donde[0] + 1
            if total == 1:
                return "Llaves: una, en la sala %d." % s
            return "Llaves: %s, todas en la sala %d." % (cifra(total, "es"), s)
        partes = ["%s en la %s%d" % (cifra(c, "es"), "sala " if k == 0 else "",
                                     i + 1)
                  for k, (i, c) in enumerate((i, cuenta[i]) for i in donde)]
        return "Llaves: %s, %s." % (cifra(total, "es"), lista(partes, "es"))
    if total == 0:
        return "Keys: none."
    donde = [i for i, c in enumerate(cuenta) if c]
    if len(donde) == 1:
        if total == 1:
            return "Keys: one, in room %d." % (donde[0] + 1)
        return "Keys: %s, all in room %d." % (cifra(total, "en"), donde[0] + 1)
    partes = ["%s in room %d" % (cifra(c, "en"), i + 1)
              for i, c in ((i, cuenta[i]) for i in donde)]
    return "Keys: %s, %s." % (cifra(total, "en"), lista(partes, "en"))


def jaulas(js, idioma):
    if not js:
        return "Jaulas: ninguna." if idioma == "es" else "Cages: none."
    partes = []
    for sala, que, candados in js:
        if idioma == "es":
            cosa = "un amigo" if que == "amigo" else "un frasco"
            if candados == 0:
                cerrojo = "sin candado"
            elif candados == 1:
                cerrojo = "con un candado"
            else:
                cerrojo = "con %s candados" % cifra(candados, "es")
            partes.append("%s %s en la sala %d" % (cosa, cerrojo, sala + 1))
        else:
            cosa = "a friend" if que == "amigo" else "a potion"
            if candados == 0:
                cerrojo = "behind no padlock"
            elif candados == 1:
                cerrojo = "behind one padlock"
            else:
                cerrojo = "behind %s padlocks" % cifra(candados, "en")
            partes.append("%s %s in room %d" % (cosa, cerrojo, sala + 1))
    return ("Jaulas: %s." if idioma == "es" else "Cages: %s.") % lista(
        partes, idioma)


def objetos(objs, idioma, prefijo):
    if not objs:
        return ("Objeto escondido: ninguno." if idioma == "es"
                else "Hidden item: none.")
    partes = []
    for sala, i in objs:
        if i < 23:
            que = "![%s %d](%sobjeto-%02d.png)" % (
                "objeto" if idioma == "es" else "item", i, prefijo, i)
        else:
            que = EXTRA[idioma][i]
        partes.append(("%s en la sala %d" if idioma == "es"
                       else "%s in room %d") % (que, sala + 1))
    if idioma == "es":
        return "%s: %s." % ("Objeto escondido" if len(objs) == 1
                            else "Objetos escondidos", lista(partes, "es"))
    return "%s: %s." % ("Hidden item" if len(objs) == 1 else "Hidden items",
                        lista(partes, "en"))


def puertas(ps, idioma):
    """Agrupadas por nivel de destino, en el orden en que salen en la lista."""
    if not ps:
        return ("Puertas de calavera: ninguna." if idioma == "es"
                else "Skull doors: none.")
    destinos = []
    for sala, nivel, _ in ps:
        if nivel not in destinos:
            destinos.append(nivel)
    partes = []
    for nivel in destinos:
        salas = [str(s + 1) for s, n, _ in ps if n == nivel]
        if idioma == "es":
            desde = ("desde la sala %s" % salas[0] if len(salas) == 1
                     else "desde las salas %s" % lista(salas, "es"))
            partes.append("al nivel %d %s" % (nivel, desde))
        else:
            desde = ("from room %s" % salas[0] if len(salas) == 1
                     else "from rooms %s" % lista(salas, "en"))
            partes.append("to level %d %s" % (nivel, desde))
    return ("Puertas de calavera: %s." if idioma == "es"
            else "Skull doors: %s.") % lista(partes, idioma, coma=True)


def salida(ss, idioma):
    if not ss:
        return ""
    sala, nivel = ss[0]
    ronda = (nivel - 1) // 5 + 1
    if idioma == "es":
        return (" Puerta de salida: al nivel %d, el primero de la ronda %d, "
                "en la sala %d." % (nivel, ronda, sala + 1))
    return (" Exit door: to level %d, the first of round %d, in room %d."
            % (nivel, ronda, sala + 1))


def pie_del_nivel(rom, n, idioma, prefijo):
    r = M.resumen_del_nivel(rom, n)
    cab = ("Nivel %d, %s." if idioma == "es" else "Level %d, %s.") % (
        n, forma(rom, n, idioma))
    return "*%s %s %s %s %s%s*\n\n" % (
        cab, llaves(r["llaves"], idioma), jaulas(r["jaulas"], idioma),
        objetos(r["objetos"], idioma, prefijo), puertas(r["puertas"], idioma),
        salida(r["salida"], idioma))


def pagina(rom, idioma, prefijo):
    out = [CAB[idioma]]
    for ronda in range(1, 6):
        primero = 5 * ronda - 4
        out.append(RONDA[idioma] % (ronda, primero, primero + 4))
        out.append("![%s %d](%sronda-%d.png)\n\n"
                   % ("Ronda" if idioma == "es" else "Round", ronda,
                      prefijo, ronda))
        out.append(PIE_RONDA[idioma] % ronda)
        for n in range(primero, primero + 5):
            out.append(NIVEL[idioma] % n)
            out.append("![%s %d](%smapa-nivel-%02d.png)\n\n"
                       % ("Nivel" if idioma == "es" else "Level", n,
                          prefijo, n))
            out.append(pie_del_nivel(rom, n, idioma, prefijo))
    return "".join(out)


def main(argv):
    if len(argv) < 3:
        return print(__doc__) or 2
    with open(argv[1], "rb") as f:
        rom = f.read()
    docs = argv[2]
    for idioma, carpeta, fich, prefijo in (
            ("en", docs, "THE-LEVELS.md", "imagenes/"),
            ("es", os.path.join(docs, "es"), "LOS-NIVELES.md",
             "../imagenes/")):
        ruta = os.path.join(carpeta, fich)
        with open(ruta, "w", encoding="utf-8") as f:
            f.write(pagina(rom, idioma, prefijo))
        print("  %s" % ruta)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
