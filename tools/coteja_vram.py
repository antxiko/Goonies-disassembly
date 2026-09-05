#!/usr/bin/env python3
"""Compara la VRAM que monta tools/vram.py con la del emulador, byte a byte.

Mirar el dibujo no basta. Las imagenes de este repositorio se montan ejecutando
en Python los pasos del cartucho, y la unica forma de saber si el formato esta
bien leido es coger la VRAM que el VDP tiene DE VERDAD -volcada con
tools/omsx_vram.tcl mientras la demostracion se juega sola- y restarle la de
Python.

La geometria de este cartucho va al reves de lo normal, y por eso las tablas no
estan donde uno espera (lo dicen los ocho bytes de 0x4720):

    color      0x0000..0x17FF   tres bancos de 0x800
    spr patr   0x1800..0x1FFF   los 64 patrones de sprite
    patrones   0x2000..0x37FF   tres bancos de 0x800
    nombres    0x3800..0x3AFF   que casilla va en cada sitio

Las tres primeras son ESTATICAS: se montan al entrar en el nivel y no se tocan
hasta que cambia la pantalla, asi que tienen que salir a CERO. La tabla de
nombres no: ahi el juego repinta cada cuadro los bichos, el agua, las jaulas y
el marcador, asi que lo que se mira es cuantas casillas bailan y si son las que
deben.

Y hay una trampa que costo la mitad del trabajo: el cartucho **no borra los
patrones ni el color al cambiar de escena**, solo la tabla de nombres. Montar
la pantalla suelta deja cientos de bytes de diferencia que no son un error de
lectura sino herencia que falta, asi que aqui se encadena todo desde el
encendido con vram.desde_el_encendido().

Uso: coteja_vram.py <rom> <org> <carpeta de volcados>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vram as V                                            # noqa: E402

TABLAS = (
    ("color", 0x0000, 0x1800),
    ("spr patr", 0x1800, 0x0800),
    ("patrones", 0x2000, 0x1800),
)

# Que volcado se compara con que montaje. Los instantes salen de la sonda:
# el cartucho llega solo a todos ellos desde el encendido.
PARES = (
    ("13", "titulo", "titulo", None),
    ("25", "los nueve", "los nueve", None),
    ("45", "nivel 1, sala 1", "juego", 0),
    ("60", "nivel 1, sala 2", "juego", 1),
    ("75", "nivel 1, sala 3", "juego", 2),
)


def lee_info(ruta):
    d = {}
    if not os.path.exists(ruta):
        return d
    for linea in open(ruta, encoding="utf-8"):
        k, _, v = linea.strip().partition(" ")
        d[k] = v
    return d


def compara(nuestra, suya):
    return [(nombre, sum(1 for i in range(n)
                         if nuestra[ini + i] != suya[ini + i]), n)
            for nombre, ini, n in TABLAS]


def compara_la_sala(rom, suya, nivel, cual):
    """La sala se vuelca a 0x3840, o sea a partir de la fila 2 de la pantalla.

    Las dos primeras filas son el marcador y no se comparan: las pinta otra
    rutina y llevan las cifras, que cambian en cada cuadro.
    """
    salas, _, _ = V.salas(rom, nivel)
    plano = [c for fila in salas[cual] for c in fila]
    distintas = [i for i, c in enumerate(plano) if suya[0x3840 + i] != c]
    return len(distintas), len(plano), distintas


def main(argv):
    if len(argv) < 4:
        return print(__doc__) or 2
    rom = open(argv[1], "rb").read()
    carpeta = argv[3]

    print("%-16s %-8s  %s" % ("pantalla", "volcado", "bytes distintos"))
    print("=" * 72)
    total = 0
    for num, nombre, hasta, sala in PARES:
        ruta = os.path.join(carpeta, "vram_%s.bin" % num)
        if not os.path.exists(ruta):
            print("  %-16s %-8s  (no hay volcado)" % (nombre, num))
            continue
        suya = open(ruta, "rb").read()
        info = lee_info(os.path.join(carpeta, "info_%s.txt" % num))
        # Las tres casillas del agua se quedan en la fase que dejo el ultimo
        # repintado, y esa depende del bit 2 del contador de cuadros Y de si
        # la sala anterior tenia agua, asi que aqui se prueban las dos y se
        # dice cual cuadra: las dos tablas son distintas, o sea que acertar
        # por casualidad no es posible.
        opciones = [(V.desde_el_encendido(rom, hasta, 1, agua=f).v, f)
                    for f in ((False, True) if hasta == "juego" else (False,))]
        nuestra, fase = min(
            opciones, key=lambda o: sum(d for _, d, _ in compara(o[0], suya)))
        res = compara(nuestra, suya)
        print("  %-16s %-8s  %s" % (nombre, num, "  ".join(
            "%s %d/%d" % (n, d, t) for n, d, t in res)))
        total += sum(d for _, d, _ in res)
        if hasta == "juego":
            print("  %-16s %-8s  el agua, en la fase %d (cuadro %s, hay agua"
                  " en la sala: %s)"
                  % ("", "", 1 if fase else 0, info.get("cuadro"),
                     "si" if info.get("agua", "0") != "0" else "no"))
        if hasta == "titulo":
            # el titulo se pinta entero en la tabla de nombres, y ahi si
            # se puede comparar casilla a casilla
            d = sum(1 for i in range(0x300)
                    if nuestra[0x3800 + i] != suya[0x3800 + i])
            print("  %-16s %-8s  nombres %d/768" % ("", "", d))
            total += d
        elif sala is not None:
            d, n, cuales = compara_la_sala(rom, suya, 1, sala)
            print("  %-16s %-8s  la sala %d/%d casillas%s"
                  % ("", "", d, n,
                     "" if not cuales else "  (filas %s)"
                     % sorted(set(c // 32 for c in cuales))))
        print("  %-16s %-8s  (escena %s.%s, nivel %s, sala %s, t=%s)"
              % ("", "", info.get("escena"), info.get("subescena"),
                 info.get("nivel"), info.get("sala"),
                 info.get("tiempo", "?")[:5]))
    print("-" * 72)
    print("  bytes distintos en las tablas estaticas: %d" % total)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
