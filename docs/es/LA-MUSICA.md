# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`suena_el_cuadro`, 0xB641, y `pide_pieza`, 0xB590, que le reparte las voces; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la pieza 0x9B, sus primeros 219 cuadros y, tal como el juego la pide, otros 390 de 2.993;
- la puerta abierta (0xA1) entera, 212 cuadros.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`pide_pieza` recibe el número en A. Los números bajos son efectos y del 0x91 en adelante hay música. Cada voz ocupa catorce bytes desde 0xE010 y 0xE048 guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`; se omiten las 0x9A, 0x9C y 0x9D, de minutos de duración.

## Las músicas

**La pieza del 0x41B0** (0x9B)

Lo pide `L_41B0`; dura 49,9 s y vuelve a empezar en el segundo 11,8.

<audio controls preload="none" src="../audio/musica_9B.mp3?v=7953aac3"></audio>

**La puerta abierta** (0xA1)

Lo pide `puerta_abierta`; dura 3,5 s.

<audio controls preload="none" src="../audio/musica_A1.mp3?v=08b92e59"></audio>

**La pieza del nivel** (0x91)

Lo pide `pieza_del_nivel`; dura 2,5 s y vuelve a empezar en el segundo 1,4.

<audio controls preload="none" src="../audio/musica_91.mp3?v=ebf752ef"></audio>

**El título y la ronda pasada** (0xA4)

Lo pide `titulo_borra` y `escena_ronda_pasada`; dura 8,6 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_A4.mp3?v=f440aef4"></audio>

**La pieza del 0x4367** (0xA7)

Lo pide `L_4367`; dura 4,0 s.

<audio controls preload="none" src="../audio/musica_A7.mp3?v=b45079a8"></audio>

**La pieza del 0x82AB** (0x98)

Lo pide `L_82AB`; dura 1,1 s.

<audio controls preload="none" src="../audio/musica_98.mp3?v=80cd8f45"></audio>

**Se acaba el tiempo** (0xAA)

Lo pide `se_acaba_el_tiempo`; dura 0,9 s y vuelve a empezar en el segundo 0,8.

<audio controls preload="none" src="../audio/musica_AA.mp3?v=89b0d19e"></audio>

**Pista 0x92 de la tabla** (0x92)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 25,6 s y vuelve a empezar en el segundo 4,3.

<audio controls preload="none" src="../audio/musica_92.mp3?v=58f9bef1"></audio>

**Pista 0x96 de la tabla** (0x96)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 38,1 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_96.mp3?v=b51a1965"></audio>

**Pista 0x97 de la tabla** (0x97)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 39,1 s y vuelve a empezar en el segundo 1,0.

<audio controls preload="none" src="../audio/musica_97.mp3?v=ce29b8f6"></audio>

**Pista 0x99 de la tabla** (0x99)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 16,8 s y vuelve a empezar en el segundo 16,0.

<audio controls preload="none" src="../audio/musica_99.mp3?v=ca90ad61"></audio>

**Pista 0xA2 de la tabla** (0xA2)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 11,6 s y vuelve a empezar en el segundo 3,0.

<audio controls preload="none" src="../audio/musica_A2.mp3?v=72ea4524"></audio>

**Pista 0xA3 de la tabla** (0xA3)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 11,6 s y vuelve a empezar en el segundo 3,0.

<audio controls preload="none" src="../audio/musica_A3.mp3?v=aad58e98"></audio>

**Pista 0xA5 de la tabla** (0xA5)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 12,4 s y vuelve a empezar en el segundo 3,9.

<audio controls preload="none" src="../audio/musica_A5.mp3?v=75d2575f"></audio>

**Pista 0xA6 de la tabla** (0xA6)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 12,6 s y vuelve a empezar en el segundo 4,0.

<audio controls preload="none" src="../audio/musica_A6.mp3?v=ee136a84"></audio>

**Pista 0xA8 de la tabla** (0xA8)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,0 s.

<audio controls preload="none" src="../audio/musica_A8.mp3?v=e10663ac"></audio>

**Pista 0xA9 de la tabla** (0xA9)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,9 s.

<audio controls preload="none" src="../audio/musica_A9.mp3?v=31d77aa4"></audio>
