#!/usr/bin/env python3
"""Recorre TODOS los datos del cartucho desde sus raices y dice que queda suelto.

Es el control que hace falta para el presupuesto: en vez de mirar un volcado y
suponer donde acaba cada cosa, se sigue cada puntero desde el codigo que lo usa
y se marca lo que se gasta de verdad. Lo que quede sin marcar es lo que hay que
ir a mirar.

Formatos que sabe recorrer, todos salidos de leer el codigo que los lee:
  guion RLE        L_469D / L_46A3
  mapa de nivel    L_59B2   80 bytes: 4x20 bloques de 8x4 casillas
  objetos          L_8D64   [0xF0+tipo] y registros hasta el siguiente 0xF0+
  datos de sala    L_8E73   igual, con otros tamanos de registro
  bloque 8x4       L_5A05

Uso: cobertura.py <rom> <org>
"""
import sys

import formatos as F

# Cuantos bytes de ROM gasta cada registro, por tipo. Salen de contar los
# `inc hl` de cada rama, no de mirar los datos.
REG_OBJETOS = {0: 3, 1: 3, 2: 2, 3: 3, 4: 2, 5: 3, 6: 3, 7: 3}   # L_8D64
REG_SALA = {0: 4, 1: 5, 2: 2, 3: 3, 4: 3, 5: 2, 6: 2, 7: 2}      # L_8E73


class Mapa:
    def __init__(self, rom, org):
        self.rom, self.org = rom, org
        self.m = [None] * len(rom)

    def W(self, a):
        return self.rom[a - self.org] | (self.rom[a - self.org + 1] << 8)

    def marca(self, a, n, que, comparte=False):
        """comparte: este formato SOLAPA a proposito con sus vecinos.

        Los bloques de 8x4 y las listas de sala comparten cola: cuando dos
        acaban igual, el puntero del segundo entra a mitad del primero y los
        bytes de la cola sirven para los dos. No es un error de medida, es como
        esta escrito el cartucho, y por eso aqui no se avisa.
        """
        for i in range(a - self.org, a - self.org + n):
            if self.m[i] is not None and self.m[i] != que and not comparte:
                print("  OJO: 0x%04X ya era '%s' y ahora '%s'"
                      % (i + self.org, self.m[i], que))
            if self.m[i] is None:
                self.m[i] = que
        return a + n

    def guion(self, a, que, cabecera=True):
        n, _ = F.rle(self.rom, self.org, a, cabecera)
        return self.marca(a, n, que)

    def lista(self, a, que, tam, comparte=False):
        """Un [0xF0+tipo] y sus registros, hasta que un byte no sea 0xF0..0xF7."""
        i = a
        while True:
            t = self.rom[i - self.org]
            if t < 0xF0 or (t & 0x0F) > 7:
                i += 1                                   # el 0xFF que cierra
                break
            i += 1
            n = tam[t & 0x0F]
            while self.rom[i - self.org] < 0xF0:
                i += n
        return self.marca(a, i - a, que, comparte)


def main():
    rom = open(sys.argv[1], "rb").read()
    org = int(sys.argv[2], 0) if len(sys.argv) > 2 else 0x4000
    g = Mapa(rom, org)
    W = g.W

    g.marca(0x4000, 0x10, "cabecera")
    g.marca(0x4010, 0x0F, "cabecera del game master")
    g.marca(0x4720, 8, "registros del vdp")
    g.marca(0xBFEE, 8, "relleno")
    g.marca(0xBFF6, 10, "marca de konami")

    # -- la cadena de graficos de L_4CD9 y L_4CEA ----------------------
    g.guion(0x927F, "sprites")
    for a, q in ((0x95DB, "casillas 0x40..0x94"), (0x9822, "casillas 0x95.."),
                 (0x9845, "casillas 0xA6.."), (0x98D3, "casillas 0xBC.. (espejables)"),
                 (0x99D2, "color 0x40..0x94"), (0x9B46, "color 0xA6.."),
                 (0x9B65, "color 0xBC.. y 0xDE..")):
        g.guion(a, q, cabecera=False)
    for a in (0x9BE5, 0x9C05, 0x9C25, 0x9C45, 0x9C65):
        g.marca(a, 0x20, "cuatro casillas crudas")
    g.guion(0x9C85, "casillas del marcador", cabecera=False)
    g.marca(0x9D01, 0x10, "dos casillas crudas")
    g.guion(0x9D11, "color del marcador", cabecera=False)
    g.guion(0x9D3C, "color del marcador", cabecera=False)
    g.marca(0x9D67, 25, "un byte por nivel para (0xE06A)")
    g.marca(0x4E03, 16, "dos patrones de relleno")
    g.marca(0x4E3F, 25, "el recoloreado que le toca a cada nivel")
    g.marca(0x4EDB, 16, "las cuatro parejas de colores")
    g.marca(0x4F17, 8, "el segundo cambio de color")
    g.guion(0x4F1F, "parche de color", cabecera=False)
    g.marca(0x45FF, 8, "las cuatro salas, con dos filas de sesgo")
    g.marca(0x5F40, 8, "las cuatro salas")

    # -- los mapas y sus objetos ---------------------------------------
    notas = "--notas" in sys.argv
    g.marca(0x9D80, 50, "tabla de mapas")
    for n in range(25):
        a = W(0x9D80 + 2 * n)
        g.marca(a, 80, "mapa del nivel %d" % (n + 1))
        b = g.lista(a + 80, "objetos del nivel %d" % (n + 1), REG_OBJETOS)
        if notas:
            print("D 0x%04x 0x%04x mapa_del_nivel_%02d  80 bytes: 4x20 bloques "
                  "de 8x4 casillas, o sea las cuatro salas de 32x20 seguidas"
                  % (a, a + 80, n + 1))
            print("F 0x%04x 20" % a)
            print("D 0x%04x 0x%04x objetos_del_nivel_%02d  lo que hay repartido "
                  "por las cuatro salas; L_8D64 lo lee por tipos, del 0xF0 al "
                  "0xF7, y lo cierra el 0xFF" % (a + 80, b, n + 1))
            print("F 0x%04x 16" % (a + 80))

    # -- los datos de cada sala ----------------------------------------
    g.marca(0xA304, 50, "tabla de datos de sala")
    for n in range(25):
        a = W(0xA304 + 2 * n)
        g.marca(a, 8, "las cuatro salas del nivel %d" % (n + 1))
        if notas:
            print("D 0x%04x 0x%04x salas_del_nivel_%02d  cuatro punteros, uno "
                  "por sala" % (a, a + 8, n + 1))
            print("F 0x%04x w" % a)
        vistos = set()
        for s in range(4):
            p = W(a + 2 * s)
            b = g.lista(p, "sala %d del nivel %d" % (s + 1, n + 1),
                        REG_SALA, comparte=True)
            if notas and p not in vistos:
                vistos.add(p)
                print("D 0x%04x 0x%04x sala_%d_del_nivel_%02d  lo que lleva "
                      "montado la sala; L_8E73 lo lee por tipos, del 0xF0 al "
                      "0xF7" % (p, b, s + 1, n + 1))
                print("F 0x%04x 16" % p)

    # -- los bloques del mapa ------------------------------------------
    n = (W(0x5B65) - 0x5B65) // 2
    g.marca(0x5B65, 2 * n, "tabla de bloques de 8x4")
    for i in range(n):
        a = W(0x5B65 + 2 * i)
        k, _ = F.bloque(rom, org, a)
        g.marca(a, k, "bloque %d" % i, comparte=True)
    g.marca(0x5A79, 176, "las once parejas de casillas")

    # -- el resultado ---------------------------------------------------
    libre, tramos, ini = 0, [], None
    for i, v in enumerate(g.m):
        if v is None:
            libre += 1
            if ini is None:
                ini = i
        elif ini is not None:
            tramos.append((ini + org, i + org))
            ini = None
    if ini is not None:
        tramos.append((ini + org, len(g.m) + org))
    print("marcados %d bytes de %d; quedan %d sueltos en %d tramos"
          % (len(rom) - libre, len(rom), libre, len(tramos)))
    for a, b in sorted(tramos, key=lambda t: -(t[1] - t[0]))[:40]:
        print("   0x%04X..0x%04X  %6d" % (a, b, b - a))


main()
