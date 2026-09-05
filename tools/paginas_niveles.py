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

""",
}

RONDA = {
    "es": "## Ronda %d — niveles %d a %d\n\n",
    "en": "## Round %d — levels %d to %d\n\n",
}
NIVEL = {"es": "### Nivel %d\n\n", "en": "### Level %d\n\n"}
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
        for n in range(primero, primero + 5):
            out.append(NIVEL[idioma] % n)
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
