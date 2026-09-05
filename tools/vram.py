#!/usr/bin/env python3
"""Rehace en Python la VRAM que monta el cartucho, paso por paso.

No hay ni una captura de pantalla en este repositorio: las imagenes salen de
ejecutar aqui las mismas operaciones que hace la ROM, en el mismo orden. Cada
funcion lleva al lado la direccion de la rutina que traduce.

La geometria, la que declaran los ocho bytes de 0x4720 (ver el .notes): los
colores van DEBAJO de los patrones, que es lo contrario de lo habitual.

    colores            0x0000..0x17FF   (tres bancos de 0x800)
    patrones de sprite 0x1800..0x1FFF
    patrones           0x2000..0x37FF   (tres bancos de 0x800)
    nombres            0x3800..0x3AFF
    atributos de spr   0x3B00..0x3B7F
"""
import sys

import formatos as F

ORG = 0x4000


class Vram:
    def __init__(self, rom):
        self.rom = rom
        self.v = bytearray(0x4000)

    # -- las primitivas del cartucho -----------------------------------
    def _dir(self, hl):
        return hl & 0x3FFF                      # SETWRT se queda 14 bits

    def ldirvm(self, hl, de, n):                # L_4642 -> BIOS LDIRVM
        a = self._dir(hl)
        self.v[a:a + n] = self.rom[de - ORG:de - ORG + n]

    def filvrm(self, hl, val, n):               # BIOS FILVRM
        a = self._dir(hl)
        self.v[a:a + n] = bytes([val]) * n

    def guion(self, de, hl=None):               # L_469D / L_46A3
        """Vuelca un guion RLE. Sin hl, la direccion la trae el propio guion."""
        n, tramos = F.rle(self.rom, ORG, de, con_cabecera=hl is None)
        for vram, datos in tramos:
            a = self._dir(vram if vram is not None else hl)
            self.v[a:a + len(datos)] = datos
        return n

    def guion_bancos(self, hl, de, cuantos):    # L_466A (3) / L_466E (2)
        for _ in range(cuantos):
            self.guion(de, hl)
            hl += 0x800

    def espeja_sprites(self, hl, de, c):        # L_46C8 / L_46D4
        """Fabrica los sprites que miran al otro lado.

        Cada patron de 16x16 son 32 bytes: dos columnas de 16. Espejarlo es
        invertir los ocho bits de cada byte Y cambiar las dos columnas de
        sitio, que es justo lo que hace el baile de `inc e / sub 020h` de
        0x46E6 con el byte bajo de la direccion: 0x4CDF entra con el destino
        apuntando a la SEGUNDA mitad (0x1D50, no 0x1D40), asi que las
        dieciseis primeras filas del origen caen en la columna derecha y las
        dieciseis siguientes en la izquierda.
        """
        for _ in range(c):
            o = self._dir(hl)
            d = self._dir(de) - 0x10
            for k in range(32):
                self.v[d + k] = int(
                    '{:08b}'.format(self.v[o + ((k + 0x10) & 0x1F)])[::-1], 2)
            hl += 0x20
            de += 0x20

    def espeja_casillas(self, hl, de, n):       # L_4DD3
        o, d = self._dir(hl), self._dir(de)
        for k in range(n):
            self.v[d + k] = int('{:08b}'.format(self.v[o + k])[::-1], 2)

    def repite_patron(self, hl, b, cual):       # L_4DE6
        de = 0x4E03 if cual == 0 else 0x4E0B
        for _ in range(b):
            self.ldirvm(hl, de, 8)
            hl += 8

    def repite_32(self, hl, de, b):             # L_4E13
        """Ojo: el `pop de` de 0x4E21 devuelve el origen, asi que las b copias
        son LA MISMA, repetida en direcciones consecutivas."""
        for _ in range(b):
            self.ldirvm(hl, de, 0x20)
            hl += 0x20
        return hl

    def dos_bytes_0f(self, hl, b):              # L_4E26
        for _ in range(b):
            a = self._dir(hl)
            self.v[a] = 0x0F
            self.v[self._dir(hl + 8)] = 0x0F
            hl += 0x20

    # -- el recoloreado por nivel --------------------------------------
    def _cambia_color(self, c, origen, destino):     # L_4F58
        for i in range(4):
            if c == destino[i]:
                return origen[i] & 0x0F
        return c & 0x0F

    def barre_color(self, hl, n, origen, destino):   # L_4F2E
        for _ in range(n):
            a = self._dir(hl)
            b = self.v[a]
            nuevo = (self._cambia_color(b >> 4, origen, destino) << 4) \
                | self._cambia_color(b & 0x0F, origen, destino)
            if nuevo != b:                            # L_4F74: los tres bancos
                for k in (0, 0x800, 0x1000):
                    self.v[self._dir(hl + k)] = nuevo
            hl += 1

    def salta_cuatro(self, hl, b, origen, destino):  # L_4ECD
        for _ in range(b):
            hl += 4
            self.barre_color(hl, 4, origen, destino)
            hl += 4

    def recolorea(self, nivel):                      # L_4E64
        r = self.rom
        cual = r[0x4E3F - ORG + nivel - 1] & 0x0F     # L_4E58
        if cual == 0:
            return
        b = 0x4EDB - ORG + (cual - 1) * 4
        origen = list(r[b:b + 4])
        destino = list(r[0x4EE7 - ORG:0x4EE7 - ORG + 4])
        self.barre_color(0x0200, 0x100, origen, destino)
        self.barre_color(0x03A0, 0x010, origen, destino)
        self.barre_color(0x05E0, 0x068, origen, destino)
        self.barre_color(0x06F0, 0x068, origen, destino)
        self.salta_cuatro(0x0300, 0x0A, origen, destino)
        self.salta_cuatro(0x05B0, 0x05, origen, destino)
        self.salta_cuatro(0x0648, 0x03, origen, destino)
        self.salta_cuatro(0x0758, 0x03, origen, destino)
        if cual == 1:                                 # 0x4EEB
            origen = list(r[0x4F17 - ORG:0x4F17 - ORG + 4])
            destino = list(r[0x4F1B - ORG:0x4F1B - ORG + 4])
            self.barre_color(0x0350, 0x30, origen, destino)
            self.barre_color(0x0660, 0x20, origen, destino)
            self.barre_color(0x0770, 0x20, origen, destino)
            self.guion_bancos(0x03A2, 0x4F1F, 3)

    # -- las dos rutinas de montaje ------------------------------------
    def monta(self, nivel):
        """L_4CD9 y L_4CEA, las dos seguidas, que es como las llama 0x41EB.

        Con la fuente delante: el juego no la vuelve a cargar -la hereda del
        titulo- y el marcador escribe con ella.
        """
        self.monta_la_fuente()
        self.filvrm(0x3800, 0x00, 0x300)              # L_4627
        # ---- L_4CD9: los sprites
        self.guion(0x927F)                            # 42 patrones de 16x16
        self.espeja_sprites(0x1A80, 0x1D50, 0x16)     # y 22 mas, del reves
        # ---- L_4CEA: las casillas
        self.guion_bancos(0x2200, 0x95DB, 3)
        self.guion(0x9822, 0x24A8)
        self.guion(0x9822, 0x24F0)
        self.guion_bancos(0x2530, 0x9845, 2)
        self.guion_bancos(0x25E0, 0x98D3, 3)
        self.guion_bancos(0x0200, 0x99D2, 3)
        self.repite_patron(0x04A8, 9, 0)
        self.repite_patron(0x04F0, 8, 1)
        self.guion_bancos(0x0530, 0x9B46, 2)
        self.guion_bancos(0x05E0, 0x9B65, 3)
        self.guion_bancos(0x06F0, 0x9B65, 3)
        self.recolorea(nivel)
        self.ldirvm(0x3010, 0x9D01, 0x10)
        hl = self.repite_32(0x3020, 0x9BE5, 2)
        hl = self.repite_32(hl, 0x9C05, 3)
        hl = self.repite_32(hl, 0x9C25, 3)
        hl = self.repite_32(hl, 0x9C45, 7)
        hl = self.repite_32(0x34A8, 0x9C65, 4)
        self.guion(0x9C85, hl)
        self.guion(0x9D11, 0x1010)
        self.guion(0x9D3C, 0x14A8)
        self.dos_bytes_0f(0x1020, 0x0F)
        self.dos_bytes_0f(0x14A8, 0x09)
        self.espeja_casillas(0x25E0, 0x26F0, 0x110)
        self.espeja_casillas(0x2DE0, 0x2EF0, 0x110)
        self.espeja_casillas(0x35E0, 0x36F0, 0x110)
        return self


    def rellena_bancos(self, hl, val, n):       # L_4659
        for k in (0, 0x800, 0x1000):
            self.filvrm(hl + k, val, n)

    def guion_literal(self, de):                # L_4682: el guion sin comprimir
        """Casillas de una en una; 0xFE cambia de sitio y 0xFF cierra."""
        r, p = self.rom, de - ORG
        while True:
            hl = r[p] | (r[p + 1] << 8)
            p += 2
            while True:
                b = r[p]
                p += 1
                if b == 0xFF:
                    return
                if b == 0xFE:
                    break
                self.v[self._dir(hl)] = b
                hl += 1

    def anima_el_agua(self, alterna):           # L_854E
        """El agua corre reescribiendo TRES PATRONES, no el mapa.

        Las casillas 0x6D, 0xCF y 0xF1 se reescriben enteras en los tres
        bancos: cuatro bytes de las filas de arriba y cuatro de las de abajo,
        y el bit 2 del contador de cuadros (0xE003) intercambia las dos
        tandas cada cuatro cuadros. De ahi la sensacion de corriente.

        Cada registro son cuatro bytes de patron y dos de salto a la casilla
        siguiente; el salto de la tercera vuelta se lee y ya no se usa.
        """
        arriba, abajo = (0x859C, 0x858C) if alterna else (0x858C, 0x859C)
        for hl, tabla in ((0x2368, arriba), (0x236C, abajo)):
            p = tabla - ORG
            for _ in range(3):
                for k in (0, 0x800, 0x1000):
                    a = self._dir(hl + k)
                    self.v[a:a + 4] = self.rom[p:p + 4]
                p += 4
                hl = (hl + (self.rom[p] | (self.rom[p + 1] << 8))) & 0xFFFF
                p += 2
        return self

    # -- la pantalla del titulo ----------------------------------------
    def monta_la_fuente(self):
        """Traduce 0x484D: las casillas 0x00 a 0x3F, que son la fuente.

        La monta la pantalla del titulo, pero NO se borra al entrar en el
        juego: el marcador escribe con ella. Por eso hay que montarla antes que
        nada, o al cotejar contra el emulador salen cientos de bytes de
        diferencia que no son un error de lectura sino herencia que falta.
        """
        self.rellena_bancos(0x2000, 0x00, 0x80)       # L_4864
        for k in range(0x10):                         # una rampa de colores
            self.rellena_bancos(k * 8, k, 8)
        self.guion_bancos(0x2080, 0x4885, 3)          # 0x4850
        self.rellena_bancos(0x0080, 0xF0, 0x180)      # blanco sobre negro
        return self

    def monta_el_cartel(self):
        """Traduce 0x49C9: el cartel que baja en la presentacion.

        Lo llama arranca_la_presentacion, o sea la subescena 0 de la escena 0,
        y NADIE lo borra despues: la pantalla del titulo se pinta encima. Sus
        casillas siguen en la VRAM cuando sale el rotulo.
        """
        self.guion_bancos(0x2200, 0x4A0F, 3)          # 0x49C9, el bit 14 del
        self.rellena_bancos(0x0200, 0xF0, 0xD8)       # 0x6200 lo tira SETWRT
        return self

    def monta_la_pantalla_de_los_nueve(self):
        """Traduce L_558D: el decorado sobre el que andan los nueve del titulo.

        Es la subescena 0 de la ESCENA 2, o sea que va DESPUES del rotulo, no
        antes: en el titulo todavia no esta. Y tampoco borra nada, asi que el
        rotulo THE GOONIES se le queda debajo.
        """
        self.guion_bancos(0x2200, 0xB227, 3)
        self.espeja_casillas(0x2A58, 0x2A80, 0x28)
        self.guion_bancos(0x0200, 0xB29D, 3)
        self.guion_bancos(0x0258, 0xB2CA, 3)
        self.guion_bancos(0x0280, 0xB2CA, 3)          # el mismo guion, dos veces
        self.guion(0xB2D7)                            # y el dibujo grande
        self.espeja_sprites(0x1940, 0x1C90, 0x0E)
        return self

    def monta_el_titulo(self):
        """Traduce 0x4AA6 y 0x4ADC: el rotulo THE GOONIES, letra por letra.

        Se monta encima de lo que dejo la presentacion -la fuente y el cartel-,
        que es la herencia que hay que traer para que el cotejo contra el
        emulador salga a cero.
        """
        self.monta_la_fuente()
        self.monta_el_cartel()
        self.monta_la_fuente()                        # 0x4AAE, otra vez
        self.filvrm(0x3800, 0x00, 0x300)              # L_4627
        self.guion_bancos(0x2580, 0x4B16, 3)          # 0x4AB1: el rotulo
        self.guion_bancos(0x0580, 0x4CCC, 3)          # y su color
        hl = 0x0580                                   # 0x4AC3: el retoque
        for _ in range(0x10):
            for k in range(3):
                self.v[self._dir(hl + k)] = 0xB0
            hl += 8
        a, hl = 0xB0, 0x38A8                          # L_4ADC
        for _ in range(3):
            for k in range(0x10):
                self.v[self._dir(hl + k)] = a + k
            a, hl = a + 0x10, hl + 0x20
        for k in range(0x12):
            self.v[self._dir(hl + k)] = a + k
        a += 0x12
        for k in range(2):
            self.v[self._dir(0x388F + k)] = a + k
        self.guion_literal(0x47C0)                    # KONAMI y el ano
        self.guion_literal(0x47E9)                    # y el aviso de marca
        return self


def desde_el_encendido(rom, hasta, nivel=1, agua=True):
    """La VRAM tal y como llega a cada pantalla, encadenando las escenas.

    El cartucho NO borra los patrones ni el color entre escena y escena: solo
    la tabla de nombres. Asi que la VRAM de cualquier momento es la suma de
    todo lo montado antes, y montar una pantalla suelta deja cientos de bytes
    de diferencia que no son un error de lectura sino HERENCIA que falta.

    El orden, el de la tabla de 0x40F6 y de los `djnz` de cada escena:

        escena 0.0  la fuente y el cartel que baja       (0x412B)
        escena 0.2  el rotulo THE GOONIES                (0x4123)
        escena 1    espera, no toca la VRAM              (0x4139)
        escena 2.0  las dos ultimas filas a cero y el
                    decorado de los nueve                (0x4175)
        escena 2.3  el nivel                             (0x41B9)
    """
    v = Vram(rom).monta_el_titulo()
    if hasta == "titulo":
        return v
    v.filvrm(0x39C0, 0x00, 0xA0)                  # 0x4175, las dos ultimas
    v.monta_la_pantalla_de_los_nueve()            # filas de la pantalla
    if hasta == "los nueve":
        return v
    v.monta(nivel)
    if agua:
        v.anima_el_agua(True)
    return v


def salas(rom, nivel):
    """Las cuatro salas del nivel, de 32x20 casillas. Traduce L_59B2.

    El mapa son 80 bytes: cuatro columnas de bloques por veinte filas. Cada
    bloque son 8x4 casillas, asi que salen 32 columnas por 80 filas, que es lo
    mismo que decir cuatro salas de 32x20 seguidas.
    """
    puntero = 0x9D80 + 2 * (nivel - 1)
    mapa = rom[puntero - ORG] | (rom[puntero - ORG + 1] << 8)
    lienzo = [[0] * 32 for _ in range(80)]
    p = mapa
    for fila in range(20):
        for col in range(4):
            b = rom[p - ORG]
            p += 1
            i = b & 0x7F
            t = 0x5B65 + 2 * i
            dirn = rom[t - ORG] | (rom[t - ORG + 1] << 8)
            _, casillas = F.bloque(rom, ORG, dirn)
            if b & 0x80:
                casillas = F.espeja_bloque(casillas)
            for f in range(4):
                for c in range(8):
                    lienzo[fila * 4 + f][col * 8 + c] = casillas[f * 8 + c]
    return [lienzo[s * 20:(s + 1) * 20] for s in range(4)], mapa, p - mapa


if __name__ == "__main__":
    rom = open(sys.argv[1], "rb").read()
    nivel = int(sys.argv[2], 0) if len(sys.argv) > 2 else 1
    v = Vram(rom).monta(nivel)
    print("VRAM montada para el nivel %d" % nivel)
    sal, mapa, n = salas(rom, nivel)
    print("mapa en 0x%04X, %d bytes leidos" % (mapa, n))
