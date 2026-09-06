#!/usr/bin/env python3
"""Comprobaciones sobre el listado de The Goonies, y sobre lo que afirma.

Ninguna necesita el cartucho. Las que miran bytes los sacan de los `defb` del
propio listado, que es lo mismo que hay en la ROM -eso lo garantiza
`make verify`, que reensambla y compara el sha256-.

Lo que se vigila:

  - que el listado no se degrade sin que nadie se entere: densidad, rutinas sin
    explicar, bloques de datos sin descripcion
  - que las afirmaciones que se publican SE COMPRUEBEN sobre los bytes. Las
    cinco palabras clave se leen con la fuente del cartucho y tienen que decir
    MR SLOTH, GOON DOCKS, DOUBLOON, ONE EYED WILLY y GOONIES; la tabla de
    niveles por objeto tiene que dejar sin objeto justo los niveles 6 y 15; la
    curva del salto tiene que subir y bajar; y las listas de los 25 niveles
    tienen que leerse enteras y cerrar por el 0xFF
  - que no se cuele el nombre de otro juego de la serie, que ya ha pasado
"""
import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "goonies.asm")
NOTES = os.path.join(RAIZ, "src", "goonies.notes")
ENTRIES = os.path.join(RAIZ, "src", "goonies.entries")
DOCS = os.path.join(RAIZ, "docs")
ORG, FIN = 0x4000, 0xC000

sys.path.insert(0, os.path.join(RAIZ, "tools"))

# Los demas juegos de la serie. Que el nombre de otro salga en una pagina de
# este es casi siempre un copia y pega: ya paso con cinco ficheros LICENSE, con
# el pie de catorce paginas de otro proyecto y con los tests de Hyper Sports 3,
# que llegaron copiados de Konami's Soccer y apuntaban a src/soccer.asm.
OTROS_JUEGOS = (
    "Tennis", "Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
    "Antarctic", "Athletic Land", "Monkey Academy", "F-1 Spirit", "Pippols",
    "Time Pilot", "Frogger", "Super Cobra", "Billiards", "Mahjong",
    "Hyper Rally", "Nemesis", "Demonia", "Cabbage", "Hole in One",
    "Casio World Open", "3D Golf", "Baseball", "Yie Ar Kung-Fu",
    "King's Valley", "Sky Jaguar", "Mopi Ranger", "Descubrimiento",
    "War in Middle Earth", "Ping Pong", "Soccer", "Football", "Road Fighter",
    "Hyper Sports", "Hyper Olympic",
)


def lee(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def lineas_del_asm():
    return lee(ASM).splitlines()


def bytes_de_los_defb():
    """Reconstruye los bloques de datos leyendo los `defb` del listado.

    Cada linea de datos acaba en un comentario con su direccion, asi que se
    puede volver a montar el trozo de ROM sin tener el cartucho delante.
    """
    fuera = {}
    for ln in lineas_del_asm():
        m = re.match(r"^\tdef[bw] (.*?)\t*; ?([0-9a-f]{4})", ln)
        if not m:
            continue
        dire = int(m.group(2), 16)
        vals = []
        for tr in m.group(1).split(","):
            tr = tr.strip()
            if not tr:
                continue
            v = int(tr[:-1], 16) if tr.endswith("h") else int(tr, 0)
            if ln.lstrip().startswith("defw"):
                vals += [v & 0xFF, v >> 8]
            else:
                vals.append(v & 0xFF)
        for i, v in enumerate(vals):
            fuera[dire + i] = v
    return fuera


DATOS = bytes_de_los_defb()


def trozo(dire, n):
    """n bytes seguidos desde una direccion, sacados de los `defb`."""
    fuera = []
    for k in range(n):
        if dire + k not in DATOS:
            raise AssertionError("0x%04X no esta en los datos del listado"
                                 % (dire + k))
        fuera.append(DATOS[dire + k])
    return fuera


def texto_con_la_fuente(bs):
    """La fuente del cartucho: 0x00 espacio, 0x21..0x3A la A a la Z."""
    fuera = ""
    for b in bs:
        if b == 0x00:
            fuera += " "
        elif 0x21 <= b <= 0x3A:
            fuera += chr(ord("A") + b - 0x21)
        elif 0x10 <= b <= 0x19:
            fuera += chr(ord("0") + b - 0x10)
        elif b == 0x3B:
            fuera += "?"
        elif b == 0x3C:
            fuera += "!"
        else:
            fuera += "."
    return fuera


class TestListado(unittest.TestCase):
    """Que el listado siga siendo el que se publica."""

    def setUp(self):
        self.lineas = lineas_del_asm()

    def test_reproduce_la_rom_en_el_encabezado(self):
        """El listado dice de que cartucho es, y con que sha256."""
        cabeza = "\n".join(self.lineas[:30])
        self.assertIn("THE GOONIES", cabeza)
        self.assertIn("RC-734", cabeza)

    def test_todas_las_instrucciones_llevan_su_direccion(self):
        """Sin la direccion al lado, ni densidad.py ni los aplicadores valen."""
        malas = [ln for ln in self.lineas
                 if ln.startswith("\t") and ";" not in ln
                 and not ln.strip().startswith(("org", "end", "include"))]
        self.assertEqual(malas, [], "lineas sin direccion: %s" % malas[:3])

    def test_densidad_por_encima_del_liston(self):
        """El liston de la serie: 30 % de instrucciones con comentario."""
        n = c = 0
        for ln in self.lineas:
            m = re.match(r"^\t.*;([0-9a-f]{4})(.*)$", ln)
            if not m:
                continue
            n += 1
            if ";" in m.group(2):
                c += 1
        self.assertGreater(n, 8000)
        self.assertGreaterEqual(100.0 * c / n, 30.0,
                                "densidad %.1f %%, por debajo del liston" %
                                (100.0 * c / n))

    def test_ninguna_rutina_por_debajo_del_diez_por_ciento(self):
        """El otro numero del liston, y el que de verdad cuesta."""
        flojas, nombre, n, c = [], "(cabecera)", 0, 0
        for ln in self.lineas:
            m = re.match(r"^([A-Za-z_][A-Za-z_0-9]*):\s*(;.*)?$", ln)
            if m:
                if n >= 6 and c * 100 // n < 10:
                    flojas.append(nombre)
                nombre, n, c = m.group(1), 0, 0
                continue
            m = re.match(r"^\t.*;([0-9a-f]{4})(.*)$", ln)
            if not m:
                continue
            n += 1
            if ";" in m.group(2):
                c += 1
        self.assertEqual(flojas, [], "rutinas flojas: %s" % flojas[:5])

    def test_no_queda_ninguna_etiqueta_sin_bautizar_en_zona_comentada(self):
        """Las L_xxxx que quedan son las de saltos internos, no rutinas.

        Se acepta que existan, pero no que sean mayoria: si mas de la mitad de
        las etiquetas siguen siendo L_xxxx es que el listado esta a medio
        bautizar.
        """
        etiquetas = [ln[:-1] for ln in self.lineas
                     if re.match(r"^[A-Za-z_][A-Za-z_0-9]*:\s*$", ln)]
        sin_nombre = [e for e in etiquetas if re.match(r"^L_[0-9A-F]{4}$", e)]
        self.assertLess(len(sin_nombre), len(etiquetas) / 2,
                        "%d de %d etiquetas siguen sin bautizar"
                        % (len(sin_nombre), len(etiquetas)))


class TestBloquesDeDatos(unittest.TestCase):
    """Cada bloque de datos tiene que decir QUE es, no solo donde empieza."""

    def test_todos_los_bloques_llevan_nombre_y_explicacion(self):
        cortos = []
        for ln in lee(NOTES).splitlines():
            m = re.match(r"^D (0x[0-9a-f]{4}) (0x[0-9a-f]{4}) (\S+)\s+(.*)$",
                         ln)
            if not m:
                continue
            if len(m.group(4).strip()) < 20:
                cortos.append((m.group(1), m.group(3)))
        self.assertEqual(cortos, [],
                         "bloques con explicacion de menos de veinte letras: %s"
                         % cortos[:5])

    def test_ningun_bloque_se_llama_por_su_direccion(self):
        """Un nombre como DATA_tabla_de_0x1234 es un bloque sin identificar."""
        malos = [ln.split()[3] for ln in lee(NOTES).splitlines()
                 if ln.startswith("D 0x") and "0x" in ln.split()[3]]
        self.assertEqual(malos, [],
                         "bloques bautizados por su direccion: %s" % malos[:5])

    def test_las_entradas_estan_justificadas(self):
        """Cada punto de entrada declarado a mano lleva su por que."""
        sin_razon = []
        for ln in lee(ENTRIES).splitlines():
            ln = ln.strip()
            if not ln or ln.startswith("#"):
                continue
            if "#" not in ln:
                sin_razon.append(ln)
        self.assertEqual(sin_razon, [],
                         "entradas sin justificar: %s" % sin_razon[:5])


class TestPalabrasClave(unittest.TestCase):
    """Las cinco contrasenas, leidas de los bytes con la fuente del cartucho.

    No se comprueba que el texto del listado diga MR SLOTH: se DECODIFICAN los
    diecinueve bytes de cada guion y se mira lo que dicen.
    """

    PALABRAS = ((0x546C, "MR SLOTH"), (0x547F, "GOON DOCKS"),
                (0x5492, "DOUBLOON"), (0x54A5, "ONE EYED WILLY"),
                (0x54B8, "GOONIES"))

    def test_las_cinco_palabras_dicen_lo_que_se_publica(self):
        for dire, texto in self.PALABRAS:
            bs = trozo(dire + 2, 16)
            self.assertEqual(texto_con_la_fuente(bs).rstrip(), texto,
                             "la palabra de 0x%04X no dice %s" % (dire, texto))

    def test_las_cuatro_primeras_cierran_con_ff_y_la_quinta_no(self):
        """GOONIES no se pinta nunca: solo se compara, y no lleva cierre.

        Y por eso su bloque mide DIECIOCHO bytes y no diecinueve: el byte que
        haria de cierre ya es la primera instruccion de 0x54CA.
        """
        for dire, _ in self.PALABRAS[:4]:
            self.assertEqual(trozo(dire + 18, 1), [0xFF],
                             "la palabra de 0x%04X no cierra con 0xFF" % dire)
        self.assertNotIn(0x54B8 + 18, DATOS,
                         "la quinta palabra tiene un byte de mas")
        self.assertIn(0x54B8 + 17, DATOS)

    def test_van_de_diecinueve_en_diecinueve(self):
        """El paso que usa el bucle de 0x5444: 0x13 bytes por palabra."""
        dirs = [d for d, _ in self.PALABRAS]
        for a, b in zip(dirs, dirs[1:]):
            self.assertEqual(b - a, 0x13)

    def test_los_niveles_a_los_que_saltan(self):
        """Las cinco parejas nivel/ronda de 0x543A, en el mismo orden."""
        self.assertEqual(trozo(0x543A, 10),
                         [6, 2, 11, 3, 16, 4, 21, 5, 1, 1])


class TestRotulos(unittest.TestCase):
    """Los guiones literales, decodificados con la fuente."""

    def test_los_tres_rotulos_del_final(self):
        self.assertEqual(texto_con_la_fuente(trozo(0x58C1 + 2, 7)), "THE END")
        self.assertEqual(texto_con_la_fuente(trozo(0x58CB + 2, 12)),
                         "GOOD ENOUGH!")
        self.assertEqual(texto_con_la_fuente(trozo(0x58DA + 2, 8)), "GOONIES!")

    def test_el_rotulo_de_la_contrasena(self):
        self.assertEqual(texto_con_la_fuente(trozo(0x554A + 2, 9)), "KEYWORD ?")

    def test_el_rotulo_de_la_pausa(self):
        """Siete casillas en 0x4450, con la misma fuente."""
        self.assertEqual(texto_con_la_fuente(trozo(0x4450, 7)), " PAUSE ")


class TestObjetos(unittest.TestCase):
    """Las tablas del inventario, contra lo que se publica de ellas."""

    def test_veintitres_niveles_distintos_y_faltan_el_6_y_el_15(self):
        """0x5576: en que nivel esta cada uno de los veintitres objetos."""
        t = trozo(0x5576, 23)
        self.assertEqual(len(set(t)), 23, "hay niveles repetidos")
        faltan = sorted(set(range(25)) - set(t))
        self.assertEqual(faltan, [5, 14],
                         "los niveles sin objeto no son el 6 y el 15")

    def test_veintitres_iconos(self):
        """0x6F68: uno por objeto, y ninguno puede ser la casilla vacia."""
        t = trozo(0x6F68, 23)
        self.assertEqual(len(t), 23)
        self.assertNotIn(0, t)

    def test_el_objeto_que_para_cada_peligro(self):
        """0x7D9B: ocho bytes, y tres peligros no los para nada."""
        t = trozo(0x7D9B, 8)
        self.assertEqual(t.count(0xFF), 3)
        self.assertEqual(t[:4], [0x08, 0x10, 0x0A, 0x0B])

    def test_el_dano_de_cada_peligro(self):
        """0x7D6A: ocho palabras de dieciseis bits, la fraccion delante."""
        t = trozo(0x7D6A, 16)
        palabras = [t[i] | (t[i + 1] << 8) for i in range(0, 16, 2)]
        self.assertEqual(len(palabras), 8)
        self.assertEqual(max(palabras), 0x0A00, "el peor dano ha cambiado")
        self.assertEqual(palabras.count(0), 2)


class TestCurvas(unittest.TestCase):
    """Las tablas de movimiento, contra lo que tienen que hacer."""

    def test_la_curva_del_salto_sube_y_baja_y_cierra(self):
        """0x6420: veinticuatro pasos y el 0xAF de cierre."""
        t = trozo(0x6420, 25)
        self.assertEqual(t[-1], 0xAF)
        pasos = [v - 256 if v > 127 else v for v in t[:-1]]
        self.assertEqual(len(pasos), 24)
        self.assertLess(pasos[0], 0, "el salto no empieza subiendo")
        self.assertGreater(pasos[-1], 0, "el salto no acaba bajando")
        self.assertEqual(pasos, sorted(pasos), "la curva no es monotona")
        self.assertEqual(sum(pasos), 0,
                         "el salto no vuelve a la altura de partida")

    def test_la_curva_de_caida_solo_acelera(self):
        """0x635C: nueve valores, y el ultimo se repite hasta tocar suelo."""
        t = trozo(0x635C, 9)
        self.assertEqual(t[-1], 0xAF)
        self.assertEqual(t[:-1], sorted(t[:-1]))
        self.assertEqual(t[0], 1)

    def test_la_onda_del_murcielago_es_una_onda(self):
        """0x6BC5: sube a 0x0A, baja a -0x0A y vuelve; cierra con 0xAF."""
        t = trozo(0x6BC5, 49)
        self.assertEqual(t[-1], 0xAF)
        v = [x - 256 if x > 127 else x for x in t[:-1]]
        self.assertEqual(len(v), 48)
        self.assertEqual(max(v), 0x0A)
        self.assertEqual(min(v), -0x0A)
        self.assertEqual(v[0], 0)
        self.assertEqual(sum(v), 0, "la onda no vuelve al punto de partida")

    def test_donde_se_para_cada_uno_de_los_siete_del_titulo(self):
        """0x58E5: siete columnas, de 0xBC a 0x2C y de 0x18 en 0x18."""
        t = trozo(0x58E5, 7)
        self.assertEqual(t, [0xBC, 0xA4, 0x8C, 0x74, 0x5C, 0x44, 0x2C])
        for a, b in zip(t, t[1:]):
            self.assertEqual(a - b, 0x18)


class TestTopes(unittest.TestCase):
    """Las parejas de casillas que frenan, que gobiernan toda la fisica."""

    def test_las_tres_parejas_del_suelo(self):
        self.assertEqual(trozo(0x667C, 6), [0x40, 0x48, 0xBC, 0xBE, 0xDE, 0xE0])

    def test_las_tres_parejas_de_las_paredes(self):
        self.assertEqual(trozo(0x66DE, 6), [0x46, 0x4E, 0xBD, 0xC4, 0xDF, 0xE6])

    def test_cada_pareja_va_de_menor_a_mayor(self):
        """El bucle de 0x66CF necesita que el tope bajo venga primero."""
        for dire in (0x667C, 0x66DE, 0x6749, 0x6C3B):
            t = trozo(dire, 6)
            for i in range(0, 6, 2):
                self.assertLess(t[i], t[i + 1],
                                "la pareja %d de 0x%04X esta al reves"
                                % (i // 2, dire))

    def test_las_cinco_casillas_de_escalera(self):
        """0x6789: las que 0x674F acepta para subir o bajar."""
        self.assertEqual(trozo(0x6789, 5), [0x40, 0x41, 0x45, 0xBC, 0xDE])


class TestLasCifrasDeLaPortada(unittest.TestCase):
    """Las cifras que declara make_web.py tienen que ser las del listado.

    Se copian del proyecto anterior, y hasta que no se cambian son las del
    juego anterior. Este test es lo unico que impide publicarlas asi.
    """

    def setUp(self):
        sys.path.insert(0, os.path.join(RAIZ, "tools"))
        import make_web
        self.w = make_web

    def test_la_suma_de_bytes_da_el_cartucho(self):
        self.assertEqual(self.w.CODIGO + self.w.DATOS, 32768)

    def test_las_cifras_de_la_portada_son_las_del_listado(self):
        """Se EJECUTA tools/densidad.py y se le lee la salida.

        Repetir aqui su aritmetica no vigilaria nada: si la cuenta cambiara,
        cambiarian las dos a la vez y el test seguiria en verde.
        """
        import subprocess
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "densidad.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        m = re.search(r"(\d+) instrucciones, (\d+) comentarios", salida)
        self.assertIsNotNone(m, "densidad.py no imprimio el total:\n" + salida)
        self.assertEqual(self.w.INSTRUCCIONES, int(m.group(1)))
        self.assertEqual(self.w.COMENTARIOS, int(m.group(2)))
        m = re.search(r"(\d+) rutinas por debajo del 10 %, de (\d+)", salida)
        self.assertIsNotNone(m)
        self.assertEqual(int(m.group(1)), 0, "hay rutinas flojas")
        self.assertEqual(self.w.RUTINAS, int(m.group(2)))

    def test_las_cifras_de_bytes_son_las_de_este_listado(self):
        """CODIGO y DATOS, atados al listado y no al del juego anterior.

        Los bytes de datos son exactamente los que salen en `defb` y `defw`,
        y el resto del cartucho es codigo. Comprobar solo que suman 32768 no
        vigilaria nada: las cifras del juego anterior tambien sumaban 32768.
        """
        self.assertEqual(self.w.DATOS, len(DATOS))
        self.assertEqual(self.w.CODIGO, 32768 - len(DATOS))

    def test_la_densidad_declarada_cuadra_con_las_dos_cuentas(self):
        pct = 100.0 * self.w.COMENTARIOS / self.w.INSTRUCCIONES
        self.assertAlmostEqual(pct, float(self.w.DENSIDAD.replace(",", ".")),
                               places=1)
        self.assertEqual(self.w.DENSIDAD.replace(",", "."), self.w.DENSIDAD_EN)

    def test_la_ficha_dice_el_sha_de_este_cartucho(self):
        sha = None
        for linea in lee(os.path.join(RAIZ, "Makefile")).splitlines():
            if linea.startswith("SHA"):
                sha = linea.split("=")[1].strip()
        self.assertIsNotNone(sha)
        for idioma in ("es", "en"):
            ficha = " ".join(self.w.TXT[idioma]["ficha"])
            self.assertIn(sha[:8], ficha,
                          "la ficha en %s no lleva el sha de este cartucho"
                          % idioma)
            self.assertIn("RC-734", ficha)


class TestLasCienSalas(unittest.TestCase):
    """Se publica que son CIEN salas y que ninguna se repite. Se comprueba.

    Sin el cartucho, como los demas: los mapas, los bloques y las listas son
    TODO datos, asi que se reconstruyen desde los `defb` del listado y se
    recorren con las mismas rutinas que dibujan las imagenes.
    """

    def setUp(self):
        import vram as V
        self.V = V
        rom = bytearray(0x8000)
        for dire, v in DATOS.items():
            rom[dire - ORG] = v
        self.rom = bytes(rom)

    def _todas(self):
        fuera = []
        for n in range(1, 26):
            cuatro, _, _ = self.V.salas(self.rom, n)
            for s in range(4):
                fuera.append((n, s, tuple(tuple(f) for f in cuatro[s])))
        return fuera

    def test_son_cien_salas_de_32_por_20(self):
        todas = self._todas()
        self.assertEqual(len(todas), 100)
        for n, s, sala in todas:
            self.assertEqual(len(sala), 20, "nivel %d sala %d" % (n, s))
            for fila in sala:
                self.assertEqual(len(fila), 32)

    def test_ninguna_sala_se_repite(self):
        vistas = {}
        for n, s, sala in self._todas():
            if sala in vistas:
                self.fail("el nivel %d sala %d es igual que el %d sala %d"
                          % (n, s + 1, vistas[sala][0], vistas[sala][1] + 1))
            vistas[sala] = (n, s)
        self.assertEqual(len(vistas), 100)

    def test_los_veinticinco_mapas_son_distintos(self):
        ps = [trozo(0x9D80 + 2 * i, 2) for i in range(25)]
        self.assertEqual(len(set(map(tuple, ps))), 25)

    def test_las_27_condiciones_se_usan_las_27(self):
        """Se publica que ninguna sobra: los indices van del 0 al 26.

        Y que dos niveles llevan DOS objetos escondidos, el 5 y el 16.
        """
        import mapas as M
        por_nivel = {}
        for n in range(1, 26):
            for t, r in M.lista_del_nivel(self.rom, n):
                if t == 6:
                    por_nivel.setdefault(n, []).append(r[2])
        indices = sorted(x for v in por_nivel.values() for x in v)
        self.assertEqual(indices, list(range(27)))
        self.assertEqual(sorted(k for k, v in por_nivel.items() if len(v) > 1),
                         [5, 16])


class TestElAgua(unittest.TestCase):
    """El agua corre reescribiendo TRES PATRONES, no el mapa (0x854E).

    Se publica que las casillas 0x6D, 0xCF y 0xF1 se reescriben enteras en los
    tres bancos y que las dos tandas se alternan con el bit 2 del contador de
    cuadros. Aqui se comprueba sobre los bytes: que los saltos llevan de una
    casilla a la siguiente y que las dos tandas son DISTINTAS -si fueran
    iguales no habria corriente, y el cotejo contra el emulador acertaria la
    fase por casualidad-.
    """

    CASILLAS = (0x6D, 0xCF, 0xF1)

    def _recorre(self, tabla, base):
        """Los saltos de dos bytes que hay detras de cada cuatro de patron.

        Solo se leen DOS saltos: el `djnz` de 0x8589 lee el tercero y ya no lo
        usa, y por eso cada tanda ocupa dieciseis bytes y no dieciocho.
        """
        sitios, p, hl = [base], tabla, base
        for _ in range(2):
            p += 4
            salto = trozo(p, 2)
            hl += salto[0] | (salto[1] << 8)
            sitios.append(hl)
            p += 2
        return sitios

    def test_los_saltos_llevan_a_las_tres_casillas(self):
        for tabla, fila in ((0x858C, 0), (0x859C, 4)):
            self.assertEqual(
                self._recorre(tabla, 0x2368 + fila),
                [0x2000 + c * 8 + fila for c in self.CASILLAS],
                "los saltos de 0x%04X no dan con las casillas del agua" % tabla)

    def test_las_dos_tandas_son_distintas(self):
        arriba = [trozo(0x858C + 6 * k, 4) for k in range(3)]
        abajo = [trozo(0x859C + 6 * k, 4) for k in range(3)]
        self.assertNotEqual(arriba, abajo)

    def test_el_ultimo_salto_se_lee_pero_no_se_usa(self):
        """Las dos tandas ocupan 16 bytes, no 18: 0x858C+16 es ya 0x859C."""
        self.assertEqual(0x858C + 16, 0x859C)


# Las paginas donde nombrar otro cartucho de la serie es EL CONTENIDO y no un
# resto del copia y pega: la del cartucho cuenta que el armazon del despachador
# es el mismo en once cartuchos de Konami, y para eso hay que enumerarlos.
#
# La excepcion esta acotada por partida doble: solo vale en esos ficheros, solo
# para esos once juegos, y solo si en el texto aparece la palabra que justifica
# la comparacion. Si un dia se cuela un nombre de otro juego por copia y pega,
# el test sigue cazandolo.
CITAS_LEGITIMAS = {
    "EL-CARTUCHO.md": ("armaz", ("Nemesis", "F-1 Spirit", "Hyper Rally",
                                 "Road Fighter", "Ping Pong", "Soccer",
                                 "Football", "Hyper Sports", "Sky Jaguar",
                                 "Yie Ar Kung-Fu")),
    "THE-CARTRIDGE.md": ("framework", ("Nemesis", "F-1 Spirit", "Hyper Rally",
                                       "Road Fighter", "Ping Pong", "Soccer",
                                       "Football", "Hyper Sports",
                                       "Sky Jaguar", "Yie Ar Kung-Fu")),
}
CITAS_LEGITIMAS["EL-CARTUCHO.html"] = CITAS_LEGITIMAS["EL-CARTUCHO.md"]
CITAS_LEGITIMAS["THE-CARTRIDGE.html"] = CITAS_LEGITIMAS["THE-CARTRIDGE.md"]


class TestSinNombresDeOtroJuego(unittest.TestCase):
    """El copia y pega de otro proyecto de la serie, cazado a tiempo."""

    def _revisa(self, ruta):
        texto = lee(ruta)
        fn = os.path.basename(ruta)
        palabra, permitidos = CITAS_LEGITIMAS.get(fn, (None, ()))
        if permitidos:
            self.assertIn(palabra, texto.lower(),
                          "%s puede nombrar otros cartuchos solo si compara "
                          "el armazon, y la palabra %r no aparece"
                          % (fn, palabra))
        for juego in OTROS_JUEGOS:
            if juego in permitidos:
                continue
            self.assertNotIn(juego, texto,
                             "%s nombra a %s" % (fn, juego))

    def test_el_encabezado_del_listado_es_de_este_juego(self):
        """En el cuerpo del listado, nombrar otro cartucho de la serie vale:
        hay notas que comparan con Nemesis o con F-1 Spirit y son utiles. En el
        encabezado no, que ahi solo cabe este."""
        cabeza = "\n".join(lee(ASM).splitlines()[:30])
        for juego in OTROS_JUEGOS:
            self.assertNotIn(juego, cabeza,
                             "el encabezado del listado nombra a %s" % juego)

    def test_la_licencia_y_los_avisos_son_de_este_juego(self):
        for fn in ("LICENSE", "README.md", "README.es.md", "AVISO-LEGAL.md",
                   "LEGAL-NOTICE.md"):
            ruta = os.path.join(RAIZ, fn)
            if os.path.exists(ruta):
                self._revisa(ruta)

    # Los ficheros de otro proyecto, escritos como RUTA. Es como el copia y
    # pega sobrevive al barrido: el texto se adapta y la ruta se queda. Asi
    # llegaron los tests de Hyper Sports 3 apuntando a src/soccer.asm, y asi
    # se colo un `src/tennis.asm` en los dos avisos legales de este.
    OTROS_FICHEROS = ("soccer", "hypersports", "hypersports3", "roadfighter",
                      "pingpong", "mopiranger", "tennis", "baseball",
                      "nemesis", "pippols", "antarctic", "golf", "frogger",
                      "kingsvalley", "yiearkungfu", "skyjaguar", "hyperrally")

    def _sin_ficheros_de_otro(self, ruta):
        texto = lee(ruta).lower()
        for otro in self.OTROS_FICHEROS:
            for pega in ("src/%s" % otro, "%s.asm" % otro, "%s.rom" % otro,
                         "%s.notes" % otro, "%s.entries" % otro):
                self.assertNotIn(
                    pega, texto,
                    "%s nombra el fichero %s" % (os.path.relpath(ruta, RAIZ),
                                                 pega))

    def test_las_herramientas_no_apuntan_al_fichero_de_otro_juego(self):
        """Nombrar otro juego en un comentario vale; abrir su fichero, no."""
        for fn in os.listdir(os.path.join(RAIZ, "tools")):
            if fn.endswith(".py") or fn.endswith(".tcl"):
                self._sin_ficheros_de_otro(os.path.join(RAIZ, "tools", fn))

    def test_ni_los_textos_publicados_ni_los_tests(self):
        """El mismo barrido sobre todo lo que se publica y sobre los tests."""
        sitios = [RAIZ, os.path.join(RAIZ, "tests"), DOCS,
                  os.path.join(DOCS, "es")]
        for sitio in sitios:
            if not os.path.isdir(sitio):
                continue
            for fn in os.listdir(sitio):
                ruta = os.path.join(sitio, fn)
                if os.path.isfile(ruta) and (
                        fn.endswith((".md", ".py", ".html")) or fn == "LICENSE"):
                    if os.path.basename(ruta) == "test_listado.py":
                        continue          # esta lista vive aqui
                    self._sin_ficheros_de_otro(ruta)

    def test_la_web_no_nombra_otro_juego(self):
        self.assertTrue(os.path.isdir(DOCS), "no hay web que revisar")
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in ficheros:
                if fn.endswith((".md", ".html")):
                    self._revisa(os.path.join(raiz, fn))


if __name__ == "__main__":
    unittest.main()


class TestListasDeLosNiveles(unittest.TestCase):
    """El formato de las dos listas, ejecutado sobre los 25 niveles.

    No se comprueba el ASPECTO de los bytes: se recorren las listas con las
    mismas reglas que 0x8D64 y 0x8E73 -un byte 0xF0+tipo abre tramo y el 0xFF
    cierra- y se exige que TODAS cierren donde tienen que cerrar. Si el largo
    de un registro estuviera mal, la lista se descarrilaria y no cerraria.
    """

    LARGO_NIVEL = {0: 3, 1: 3, 2: 2, 3: 3, 4: 2, 5: 3, 6: 3, 7: 3}
    LARGO_SALA = {0: 4, 1: 5, 2: 2, 3: 3, 4: 3, 5: 2, 6: 2, 7: 2}

    def palabra(self, dire):
        b = trozo(dire, 2)
        return b[0] | (b[1] << 8)

    def recorre(self, p, largo, tope=4000):
        """Devuelve los registros, o revienta si la lista no cierra."""
        fuera = []
        for _ in range(tope):
            b = trozo(p, 1)[0]
            if b == 0xFF:
                return fuera
            self.assertGreaterEqual(b, 0xF0,
                                    "0x%04X no abre tramo: 0x%02X" % (p, b))
            t, p = b & 0x0F, p + 1
            self.assertIn(t, largo, "tipo %d desconocido en 0x%04X" % (t, p))
            while trozo(p, 1)[0] < 0xF0:
                fuera.append((t, trozo(p, largo[t])))
                p += largo[t]
        raise AssertionError("la lista de 0x%04X no cierra" % p)

    def test_los_veinticinco_mapas_y_sus_listas(self):
        vistos = set()
        for nivel in range(1, 26):
            mapa = self.palabra(0x9D80 + 2 * (nivel - 1))
            self.assertTrue(ORG <= mapa < FIN,
                            "el mapa del nivel %d cae fuera" % nivel)
            self.assertEqual(len(trozo(mapa, 80)), 80)
            regs = self.recorre(mapa + 80, self.LARGO_NIVEL)
            self.assertTrue(regs, "el nivel %d no trae nada" % nivel)
            vistos.add(mapa)
        self.assertEqual(len(vistos), 25, "hay dos niveles con el mismo mapa")

    def test_cada_nivel_tiene_de_una_a_tres_jaulas(self):
        for nivel in range(1, 26):
            mapa = self.palabra(0x9D80 + 2 * (nivel - 1))
            regs = self.recorre(mapa + 80, self.LARGO_NIVEL)
            jaulas = [r for t, r in regs if t == 5]
            self.assertIn(len(jaulas), (1, 2, 3),
                          "el nivel %d tiene %d jaulas" % (nivel, len(jaulas)))

    def test_como_mucho_dos_objetos_escondidos_por_nivel(self):
        """Solo hay dos huecos de ficha, 0xE2ED y 0xE2F3."""
        for nivel in range(1, 26):
            mapa = self.palabra(0x9D80 + 2 * (nivel - 1))
            regs = self.recorre(mapa + 80, self.LARGO_NIVEL)
            objetos = [r for t, r in regs if t == 6]
            self.assertLessEqual(len(objetos), 2,
                                 "el nivel %d trae %d objetos"
                                 % (nivel, len(objetos)))

    def test_las_clases_de_objeto_caben_en_la_tabla_de_condiciones(self):
        """La tabla de 0x6DBD tiene veintisiete entradas y ninguna clase
        puede pasarse, o el despachador se saldria de ella."""
        for nivel in range(1, 26):
            mapa = self.palabra(0x9D80 + 2 * (nivel - 1))
            for t, r in self.recorre(mapa + 80, self.LARGO_NIVEL):
                if t == 6:
                    self.assertLess(r[2], 27,
                                    "el nivel %d pide la clase %d"
                                    % (nivel, r[2]))

    def test_las_cien_listas_de_sala(self):
        for nivel in range(1, 26):
            tabla = self.palabra(0xA304 + 2 * (nivel - 1))
            for sala in range(4):
                p = self.palabra(tabla + 2 * sala)
                self.assertTrue(ORG <= p < FIN,
                                "la lista del nivel %d sala %d cae fuera"
                                % (nivel, sala + 1))
                self.recorre(p, self.LARGO_SALA)

    def test_como_mucho_tres_chorros_y_tres_llamaradas_por_sala(self):
        """Los bucles de 0x85AC y 0x88D8 solo recorren tres fichas."""
        for nivel in range(1, 26):
            tabla = self.palabra(0xA304 + 2 * (nivel - 1))
            for sala in range(4):
                regs = self.recorre(self.palabra(tabla + 2 * sala),
                                    self.LARGO_SALA)
                for tipo, tope, que in ((0, 3, "chorros"), (2, 3, "llamaradas"),
                                        (1, 2, "bolas"), (5, 5, "calaveras"),
                                        (6, 1, "murcielagos")):
                    cuantos = len([r for t, r in regs if t == tipo])
                    self.assertLessEqual(cuantos, tope,
                                         "nivel %d sala %d: %d %s"
                                         % (nivel, sala + 1, cuantos, que))


def instrucciones_del_asm():
    """Que instruccion hay en cada direccion, leyendola del propio listado.

    Cada linea de codigo lleva su direccion en el primer comentario, asi que se
    puede preguntar "que hay en 0x5F69" sin tener el cartucho delante. Es la
    forma de anclar en el CODIGO las cuentas que hacen las herramientas de
    dibujo, en vez de repetirlas en el test -que no vigilaria nada-.
    """
    fuera = {}
    for ln in lineas_del_asm():
        m = re.match(r"^\t(.*?)\t*;([0-9a-f]{4})(?:\s|$)", ln)
        if m and not m.group(1).startswith(("defb", "defw")):
            fuera[int(m.group(2), 16)] = m.group(1).strip()
    return fuera


CODIGO = instrucciones_del_asm()


class TestLoQueSeDibujaEncimaDeLaSala(unittest.TestCase):
    """De donde salen las posiciones con las que tools/mapas.py pinta.

    Todo lo que el juego planta encima de una sala -las puertas, las jaulas,
    los trastos, los bichos- se coloca con la fila de la PANTALLA, no con la de
    la sala: las dos primeras filas son el marcador. Y los sprites, ademas,
    salen una linea por debajo de su atributo. Aqui se comprueba, sobre el
    codigo y sobre los datos, cada una de esas cuentas: son las que se
    equivocaron una vez y dejaron todo dos filas mas abajo.
    """

    def instr(self, dire):
        self.assertIn(dire, CODIGO, "0x%04X no sale como codigo" % dire)
        return CODIGO[dire]

    def test_las_bases_de_las_salas_llevan_dos_filas_de_sesgo(self):
        """0x45FF contra 0x5F40: 0x40 bytes, o sea DOS filas de 32 casillas.

        Es la resta que hace que la fila 2 de la pantalla sea la 0 de la sala.
        """
        sesgadas = trozo(0x45FF, 8)
        limpias = trozo(0x5F40, 8)
        for i in range(4):
            a = sesgadas[2 * i] | (sesgadas[2 * i + 1] << 8)
            b = limpias[2 * i] | (limpias[2 * i + 1] << 8)
            self.assertEqual(b - a, 0x40, "la sala %d" % (i + 1))
        # y el constructor del mapa arranca en esa fila 2
        self.assertEqual(self.instr(0x59BC), "ld hl,00002h")
        # mientras que la cuenta contra la pantalla parte de la tabla de nombres
        self.assertEqual(self.instr(0x45E6), "ld de,03800h")

    def test_la_puerta_al_nivel_es_el_arco_de_la_calavera(self):
        """0x5F69 carga 0x5F78 -la calavera blanca- y pinta un 4x3."""
        self.assertEqual(self.instr(0x5F69), "ld de,05f78h")
        self.assertEqual(self.instr(0x5F6C), "ld bc,00403h")
        self.assertEqual(self.instr(0x5F6F), "ld l,(ix+002h)")
        self.assertEqual(self.instr(0x5F72), "ld h,(ix+003h)")
        # doce casillas, que son las cuatro filas de tres
        self.assertEqual(len(trozo(0x5F78, 12)), 12)

    def test_la_puerta_del_nivel_elige_entre_dos_arcos(self):
        """0x5F94: con (ix+004h) a cero el arco vacio, y si no el de la calavera."""
        self.assertEqual(self.instr(0x5F94), "ld a,(ix+004h)")
        self.assertEqual(self.instr(0x5F9A), "ld de,05fc3h")
        self.assertEqual(self.instr(0x5FA4), "ld de,05fcfh")
        # y los dos arcos son distintos: si fueran iguales, elegir no importaria
        self.assertNotEqual(trozo(0x5FC3, 12), trozo(0x5FCF, 12))

    def test_la_columna_crece_hacia_abajo(self):
        """0x8737 arranca en (ix+002h) y 0x8773 INCREMENTA: la punta va arriba."""
        self.assertEqual(self.instr(0x8737), "ld a,(ix+002h)")
        self.assertEqual(self.instr(0x873A), "ld (ix+007h),a")
        self.assertEqual(self.instr(0x8773), "inc (ix+007h)")
        self.assertEqual(self.instr(0x8760), "ld l,(ix+007h)")

    def test_el_lado_del_chorro_y_de_la_gotera_es_el_bit_7(self):
        """0x8EED se queda con siete bits y 0x8EF1 saca el de mas peso."""
        self.assertEqual(self.instr(0x8EED), "and 07fh")
        self.assertEqual(self.instr(0x8EF1), "ld a,(hl)")
        self.assertEqual(self.instr(0x8EF2), "rla")
        self.assertEqual(self.instr(0x8EF3), "rla")
        self.assertEqual(self.instr(0x8EF4), "and 001h")

    def test_los_desplazamientos_de_cada_sprite(self):
        """Cada bicho monta su atributo con un desplazamiento propio."""
        for dire, texto, quien in (
                (0x65A9, "ld a,0f0h", "el bicho de un solo sprite, la fila"),
                (0x65AF, "ld a,0f8h", "el mismo, la columna"),
                (0x6976, "add a,0f4h", "la calavera, la fila"),
                (0x6C5F, "sub 006h", "el murcielago, la fila"),
                (0x6C66, "sub 008h", "el murcielago, la columna"),
                (0x91A2, "add a,0f8h", "el bicho de patas, la fila"),
                (0x91A8, "add a,0f8h", "el bicho de patas, la columna")):
            self.assertEqual(self.instr(dire), texto, quien)
        # y la calavera, ademas, corre la columna segun la postura
        self.assertEqual(trozo(0x6996, 8), [0xF4, 0xF8, 0xFC, 0xA0,
                                            0xF4, 0xFE, 0xFC, 0xA4])


class TestMapasDibujaDondeElCartuchoPinta(unittest.TestCase):
    """Lo que tools/mapas.py coloca, contra lo MEDIDO en el emulador.

    Estas cifras no estan deducidas: salen de dejar correr el cartucho en
    openMSX, volcar la tabla de nombres y la de atributos de sprite y restarle
    el mapa de la sala. Lo que queda son estas fichas en estas filas y con
    estas casillas, y aqui se congelan para que no se vuelvan a torcer.
    """

    ROM = os.path.join(RAIZ, "goonies.rom")

    # (nivel, sala, nombre, fila, columna, las casillas de su primera fila)
    CASILLAS = (
        (1, 0, "puerta", 6, 12, (0xA6, 0xAC, 0xB0)),        # el arco VACIO
        (1, 0, "jaula", 12, 22, (0x00, 0xD5, 0x76, 0xF7)),  # con su columnita
        (1, 0, "estalactita", 5, 15, (0x55, 0x56)),
        (1, 0, "trasto", 14, 11, (0x86,)),
        (1, 3, "puerta al nivel", 2, 13, (0xD2, 0x82, 0xF4)),
        (1, 3, "puerta al nivel", 2, 24, (0xD2, 0x82, 0xF4)),
        (25, 0, "columna que crece", 0, 7, (0xC1, 0xE3)),
        (25, 0, "columna que crece", 7, 7, (0xC2, 0xE4)),
    )
    # (nivel, sala, nombre, fila, columna) en casillas, con decimales
    SPRITES = (
        (1, 3, "calavera", 4.25, 16.50),
        (1, 3, "calavera", 10.25, 18.50),
        (1, 3, "calavera", 14.25, 10.50),
        (4, 0, "calavera", 12.25, 16.50),
        (4, 0, "calavera", 14.25, 0.50),
        (4, 0, "perseguidor", 7.75, 19.00),
        (4, 3, "murcielago", 9.875, 3.50),
    )

    @classmethod
    def setUpClass(cls):
        if not os.path.exists(cls.ROM):
            raise unittest.SkipTest("hace falta goonies.rom")
        import mapas
        cls.M = mapas
        cls.rom = open(cls.ROM, "rb").read()

    def cosas(self, nivel):
        return self.M.cosas_del_nivel(self.rom, nivel)

    def test_las_casillas_caen_donde_las_pinta_el_cartucho(self):
        for nivel, sala, nombre, fila, col, primera in self.CASILLAS:
            cuadra = [x for x in self.cosas(nivel)
                      if x[0] == sala and x[5] == nombre
                      and x[1] == fila and x[2] == col]
            self.assertTrue(cuadra, "%s del nivel %d sala %d: nada en la fila"
                                    " %s columna %s" % (nombre, nivel, sala + 1,
                                                        fila, col))
            self.assertEqual(tuple(cuadra[0][4][0][:len(primera)]), primera,
                             "%s del nivel %d" % (nombre, nivel))

    def test_los_sprites_caen_donde_los_pone_el_vdp(self):
        for nivel, sala, nombre, fila, col in self.SPRITES:
            cuadra = [x for x in self.cosas(nivel)
                      if x[0] == sala and x[5] == nombre
                      and abs(x[1] - fila) < 1e-9 and abs(x[2] - col) < 1e-9]
            self.assertTrue(cuadra, "%s del nivel %d sala %d: nada en la fila"
                                    " %s columna %s" % (nombre, nivel, sala + 1,
                                                        fila, col))


class TestLaCacheNoPuedeServirUnaImagenVieja(unittest.TestCase):
    """Cada imagen de la web va con la marca de su propio contenido.

    Se corrigieron las cien salas, se publicaron, y en el movil seguian saliendo
    las de antes: las 109 imagenes del servidor eran ya las buenas -comprobadas
    una a una por sha256- pero el navegador no volvia a pedirlas, porque el
    nombre del fichero no habia cambiado. Con `?v=<hash del contenido>` la URL
    cambia justo cuando cambia el dibujo, asi que la cache deja de valer sola.

    Sin esto no hay aviso de ninguna clase: la web se genera bien, los enlaces
    comprueban y quien nunca la haya visto la ve correcta. Solo la ve mal el que
    ya estaba mirando.
    """

    def imagenes_del_html(self):
        """(fichero html, src tal cual, ruta del png) de cada <img> local."""
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in sorted(ficheros):
                if not fn.endswith(".html"):
                    continue
                p = os.path.join(raiz, fn)
                texto = open(p, encoding="utf-8").read()
                for m in re.finditer(r'<img src="([^"]+)"', texto):
                    src = m.group(1)
                    if src.startswith(("http", "data:")):
                        continue
                    yield p, src, os.path.normpath(
                        os.path.join(raiz, src.split("?")[0]))

    def test_toda_imagen_lleva_la_marca_de_su_contenido(self):
        import hashlib
        vistas = 0
        for p, src, fich in self.imagenes_del_html():
            vistas += 1
            self.assertIn("?v=", src,
                          "%s saca %s sin marca de version: quien la tenga "
                          "en cache seguira viendo la vieja"
                          % (os.path.basename(p), src))
            self.assertTrue(os.path.isfile(fich), "%s no existe" % fich)
            with open(fich, "rb") as f:
                esperado = hashlib.sha1(f.read()).hexdigest()[:8]
            self.assertEqual(src.split("?v=")[1], esperado,
                             "%s: la marca de %s no es la de su contenido, o "
                             "sea que la web se genero antes de la imagen"
                             % (os.path.basename(p), src))
        # y que de verdad haya mirado algo: si el barrido no encuentra
        # imagenes, las dos comprobaciones de arriba pasan sin vigilar nada
        self.assertGreater(vistas, 100, "solo %d imagenes barridas" % vistas)
