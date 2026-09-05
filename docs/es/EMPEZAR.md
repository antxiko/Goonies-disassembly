# Empezar

Este repositorio contiene el desensamblado comentado de **The Goonies** de
Konami para MSX (RC-734, 1986). No contiene el cartucho: la imagen de la ROM no
se distribuye.

## Lo que hace falta

- `pasmo` — el ensamblador que reproduce la ROM
- `z80dasm` — el desensamblador con el que se genera el listado
- `python3` — las herramientas de `tools/`
- `make`
- Tu propia copia del cartucho, en la raíz y con el nombre `goonies.rom`

Son **32.768 bytes exactos** y su huella es:

    sha256  2ba602b1a17e4797da1588afe6e65640331c15746bf5959f4778b404be929dde

Para comprobarla:

    make comprueba

## Reproducirlo entero

    make

Eso encadena las cuatro cosas que importan:

| orden | qué hace | qué demuestra |
|---|---|---|
| `make listado` | genera `src/goonies.asm` desde el trazado y las notas | que el listado no está escrito a mano |
| `make verify` | reensambla y compara el sha256 | que el listado **es** el cartucho |
| `make sanity` | comprueba el reparto de bytes | que no queda ni un byte sin explicar |
| `make test` | 40 comprobaciones | que lo que se publica se sostiene sobre los bytes |

La prueba que decide es `make verify`. Si el sha256 del reensamblado no es el
de arriba, el listado miente en alguna parte.

## Las cifras

    make densidad

    0 rutinas por debajo del 10 %, de 1176
    en total: 8774 instrucciones, 3236 comentarios, 36,9 %

## Las imágenes

    make imagenes

Dibuja en `work/gfx/` la pantalla del título, los **veinticinco mapas de nivel**
con sus bichos y sus peligros, las figuras del jugador en color, la hoja de
casillas y los veintitrés iconos del inventario. Ninguna es una captura: se
montan ejecutando en Python los mismos pasos que ejecuta el Z80.

## El cotejo contra el emulador

    make vram

Arranca openMSX con el cartucho, lo deja correr **en frío** y vuelca la VRAM en
cinco instantes; luego resta esa VRAM de la que monta `tools/vram.py`. No hace
falta jugar ni cargar nada: la presentación, el título y la demostración salen
solos y son deterministas, porque [la demostración es una partida
grabada](HALLAZGOS.html).

Última medida, con la última compilación:

    pantalla         color        spr patr     patrones     nombres
    titulo           0/6144       0/2048       0/6144       0/768
    los nueve        0/6144       0/2048       0/6144
    nivel 1 sala 1   0/6144       0/2048       0/6144
    nivel 1 sala 2   0/6144       0/2048       0/6144
    nivel 1 sala 3   0/6144       0/2048       0/6144

## Cómo se comenta

Las tandas de comentarios se escriben en `work/coment/tanda-NN-loquesea.notes`,
con líneas `C 0xADDR texto`, `L 0xADDR nombre` y `B 0xADDR CABECERA`, y luego:

    python3 tools/aplica_comentarios.py src/goonies.asm src/goonies.notes \
            work/coment --escribe && make listado && make verify

Van cuarenta y dos tandas.
