#!/usr/bin/env python3
"""Escribe la pagina de LAS CIEN SALAS, en los dos idiomas.

Se genera y no se escribe a mano a proposito: debajo de cada sala va la cuenta
de lo que esa sala lleva encima, y esa cuenta sale de recorrer las dos listas
del nivel con las mismas reglas que el Z80 (tools/mapas.py) y quedarse con lo
que cae en esa sala. Escrita a mano seria una cifra sin medir, que es justo lo
que esta serie no publica.

Uso: paginas_niveles.py <rom> <docs>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mapas as M                                          # noqa: E402

# El nombre de cada cosa en las dos lenguas. Las claves son las de mapas.py,
# que salen de la rutina que lee cada tipo.
NOMBRE_EN = {
    "columna que crece": "rising column", "estalactita": "stalactite",
    "perseguidor": "chaser", "puerta al nivel": "door to the next level",
    "trasto": "blinking pickup", "jaula": "cage", "objeto": "hidden item",
    "puerta": "skull door", "agua": "water jet", "bola de piedra": "boulder",
    "llamarada": "flame", "chorro del tubo": "pipe leak", "gotera": "drip",
    "calavera": "skull", "murcielago": "bat",
    "bicho de patas": "many-legged creature",
}

CAB = {
    "es": """# Las 100 salas

Aqui estan **las cien salas** del cartucho, una a una. Veinticinco niveles de
cuatro salas cada uno, y **ninguna se repite**: comparadas casilla a casilla
las cien, salen cien distintas. Todas dibujadas desde los bytes de la ROM, ni
una captura.

Cada sala son 32x20 casillas que salen de ochenta bytes apuntando a bloques de
8x4, se descomprimen, y encima se planta —en el sitio exacto en el que el
cartucho la planta— cada cosa de las dos listas del nivel: las jaulas, las
puertas, los peligros, los bichos y el objeto escondido.

Las **64.000 casillas** que salen de aqui caben en **2.983 bytes** del
cartucho. Como, esta contado en [El codigo](EL-CODIGO.html).

Debajo de cada sala va lo que lleva encima, contado recorriendo las listas con
las mismas reglas que usa el Z80. Los rotulos estan escritos con la fuente del
propio cartucho.

Y no van sueltas. Delante de cada nivel va **el plano entero**, con las cuatro
salas puestas donde el cartucho las pone: el reparto que le da `0x52DB`, que no
es el mismo en todos -hay columnas, filas, 2x2 y catorce formas raras-. Montadas
asi, las plataformas y las escaleras siguen de una sala a la de al lado.
Delante de cada ronda va ademas **el minimapa de sus cinco niveles**, con las
puertas de calavera unidas.

""",
    "en": """# The 100 rooms

Here are **all one hundred rooms** in the cartridge, one by one. Twenty-five
levels of four rooms each, and **not one repeats**: compared tile by tile, all
hundred come out different. Every one drawn from the bytes of the ROM, not a
single capture.

Each room is 32x20 tiles coming out of eighty bytes that point at 8x4 blocks;
they get decompressed, and then on top goes - at the exact spot the cartridge
puts it - every item from the level's two lists: the cages, the doors, the
hazards, the creatures and the hidden item.

The **64,000 tiles** you see here fit in **2,983 bytes** of cartridge. How, is
worked out in [The code](THE-CODE.html).

Under each room is what it carries, counted by walking the lists with the same
rules the Z80 uses. The captions are written in the cartridge's own font.

And they are not on their own. Before each level comes **the whole plan**, with
the four rooms placed where the cartridge places them: the arrangement `0x52DB`
gives it, which is not the same for all - there are columns, rows, 2x2 and
fourteen odd shapes. Put together like this, platforms and ladders carry on
from one room into the next. Before each round comes **the minimap of its five
levels**, with the skull doors joined up.

""",
}

RONDA = {
    "es": "## Ronda %d — niveles %d a %d\n\n",
    "en": "## Round %d — levels %d to %d\n\n",
}
NIVEL = {"es": "### Nivel %d\n\n", "en": "### Level %d\n\n"}
PIE_RONDA = {
    "es": "*Los cinco niveles de la ronda %d y sus puertas de calavera. Cada "
          "nivel esta puesto con el reparto de salas que le da 0x52DB, y cada "
          "raya une DOS puertas que se emparejan de verdad: la puerta j del "
          "nivel A dice (B, k) y la puerta k del nivel B dice (A, j). Las 64 "
          "del cartucho emparejan asi, y ninguna sale de su ronda. Dos cosas de este dibujo NO salen de la ROM, y por eso se dicen: el sitio de cada nivel en el anillo -de los doce ordenes posibles se elige el que menos cruces deja- y la comba de las curvas, que separa las parejas de niveles unidas por DOS puertas.*\n\n",
    "en": "*The five levels of round %d and their skull doors. Each level is "
          "laid out with the room arrangement 0x52DB gives it, and every line "
          "joins TWO doors that really pair up: door j of level A says (B, k) "
          "and door k of level B says (A, j). All 64 in the cartridge pair up "
          "like that, and none leaves its round. Two things in this picture do NOT come from the ROM, so they are said out loud: where each level sits on the ring -of the twelve possible orders the one with fewest crossings is picked- and the bow of the curves, which separates the pairs of levels joined by TWO doors.*\n\n",
}
PIE_NIVEL = {
    "es": "*Las cuatro salas del nivel %d, puestas donde el cartucho las "
          "pone: %s. El reparto sale del nibble alto de 0x52DB, que es "
          "la fila por cuatro mas la columna.*\n\n",
    "en": "*The four rooms of level %d, placed where the cartridge places "
          "them: %s. The arrangement comes from the high nibble of 0x52DB, "
          "which is the row times four plus the column.*\n\n",
}


def forma(rom, n, idioma):
    """El reparto escrito: 2x2, una fila de cuatro, o el dibujo si es raro."""
    pos = M.reparto_del_nivel(rom, n)
    cols = max(x for x, _ in pos) + 1
    filas = max(y for _, y in pos) + 1
    if cols * filas == 4:
        if filas == 1:
            return "una fila de cuatro" if idioma == "es" else "a row of four"
        if cols == 1:
            return ("una columna de cuatro" if idioma == "es"
                    else "a column of four")
        return "2x2"
    rej = {(x, y): str(s + 1) for s, (x, y) in enumerate(pos)}
    dibujo = " / ".join("".join(rej.get((x, y), "-") for x in range(cols))
                        for y in range(filas))
    return "%dx%d, `%s`" % (cols, filas, dibujo)
PIE = {"es": "*Nivel %d, sala %d. %s*\n\n", "en": "*Level %d, room %d. %s*\n\n"}
NADA = {"es": "No lleva nada encima: solo el decorado.",
        "en": "Nothing on top of it: just the scenery."}
LLEVA = {"es": "Lleva: %s.", "en": "It carries: %s."}


def por_sala(rom, n):
    """Lo que lleva cada una de las cuatro salas del nivel."""
    c = [{} for _ in range(4)]
    for sala, _, _, _, _, nombre in M.cosas_del_nivel(rom, n):
        c[sala][nombre] = c[sala].get(nombre, 0) + 1
    return c


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
            out.append(PIE_NIVEL[idioma] % (n, forma(rom, n, idioma)))
            for s, c in enumerate(por_sala(rom, n)):
                if c:
                    lista = ", ".join(
                        "%d %s" % (v, k if idioma == "es" else NOMBRE_EN[k])
                        for k, v in sorted(c.items(), key=lambda kv: -kv[1]))
                    texto = LLEVA[idioma] % lista
                else:
                    texto = NADA[idioma]
                out.append("![%s %d %s %d](%ssala-%02d-%d.png)\n\n"
                           % ("Nivel" if idioma == "es" else "Level", n,
                              "sala" if idioma == "es" else "room", s + 1,
                              prefijo, n, s + 1))
                out.append(PIE[idioma] % (n, s + 1, texto))
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
