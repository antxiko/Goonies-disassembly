# The Goonies (Konami, MSX1) — desensamblado comentado

*(Also [in English](README.md).)* ·
**[Leerlo en la web](https://antxiko.github.io/Goonies-disassembly/es/)**

Desensamblado completo y comentado de **The Goonies** de Konami para MSX
(RC-734, 32 KB, 1986). Los 32.768 bytes están explicados, y el listado
reensambla en la ROM **byte a byte**.

    explicado          32.768 de 32.768   100 %
    densidad           3.236 de 8.774     36,9 %
    rutinas bajo el 10 %     0 de 1.176
    tests                   50, en verde
    reensamblado       el mismo sha256 que el cartucho

## Qué hay aquí

    src/goonies.asm       el listado comentado, generado
    src/goonies.notes     los comentarios y los bloques de datos, con su medida
    src/goonies.entries   los puntos de entrada que no se deducen solos
    tools/                las herramientas: trazado, listado, dibujos, cotejo
    tests/                50 comprobaciones que no necesitan el cartucho
    docs/                 la web bilingüe

## El cartucho no está aquí

`goonies.rom` no se distribuye. Pon tu propia copia en la raíz; son 32.768
bytes exactos y

    sha256  2ba602b1a17e4797da1588afe6e65640331c15746bf5959f4778b404be929dde

## Reproducirlo

    make comprueba     # comprueba que tu ROM es la misma
    make               # listado, reensamblado, comprobaciones y tests
    make imagenes      # dibuja las cien salas, y lo demás, desde la ROM
    make vram          # coteja esos dibujos contra la VRAM de openMSX

## Ni una captura de pantalla

Todas las imágenes de este repositorio están **dibujadas desde los bytes de la
ROM**, ejecutando en Python el mismo descompresor, motor de figuras e
intérprete de rótulos que corre el Z80. Y están cotejadas byte a byte contra la
VRAM del emulador: las cinco pantallas salen a **cero diferencias** en color,
patrones y patrones de sprite.

Están dibujadas **las cien salas**: veinticinco niveles de cuatro, y ninguna se
repite. Y los **veinticinco planos**, con las cuatro salas puestas donde el
cartucho las pone, más un **minimapa por ronda** con las puertas unidas.

## Lo que apareció

- **Las cuatro salas de un nivel van en un plano, no en columna.** El nibble
  alto de `0x52DB` es la posición de cada sala: columna por cuatro más fila.
  Hay columnas, filas, 2x2 y catorce formas raras.
- **Las 64 puertas de calavera emparejan sin una sola excepción**, y ninguna
  sale de su ronda: los 25 niveles son cinco grupos de cinco, cerrados.
- **El nombre de la ronda es su contraseña.** Los mismos bytes que pintan el
  rótulo son los que se teclean. MR SLOTH, GOON DOCKS, DOUBLOON, ONE EYED
  WILLY, GOONIES.
- **64.000 casillas en 2.983 bytes**: bloques de 8x4, un bit de espejo y
  bloques que comparten cola.
- **Veintisiete maneras de sacar un objeto escondido**, y las veintisiete se
  usan.
- **Los objetos son escudos con carga**, no adornos.
- **La demostración es una partida grabada**: 34 estados de mando y sus
  duraciones.
- **La mitad de los dibujos se fabrican al arrancar**, espejando.

Todo, con su medida, en
[Hallazgos](https://antxiko.github.io/Goonies-disassembly/es/HALLAZGOS.html).

## Licencia y crédito

Las herramientas, los comentarios, el análisis y la documentación son MIT —ver
`LICENSE`—. El juego no es nuestro: lee [AVISO-LEGAL.md](AVISO-LEGAL.md).

La marca oculta de Konami la descubrió **Manuel Pazos**.
