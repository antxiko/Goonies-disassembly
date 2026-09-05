# En el emulador

Todo lo de esta página se hace **arrancando el cartucho en frío**. No hace falta
jugar, ni grabar una partida, ni poner un punto de ruptura: la presentación, el
título y la demostración salen solos y siempre iguales, porque [la demostración
es una partida grabada](HALLAZGOS.html).

## Dónde está cada pantalla

`tools/omsx_sonda.tcl` mira noventa veces, una por segundo emulado, qué escena
corre. Con eso se eligen los instantes sin adivinar:

| segundo | escena | qué se ve |
|---:|---|---|
| 5–11 | 0 | la presentación, con el cartel que baja |
| 12–15 | 1 | el título con el rótulo THE GOONIES |
| 16–35 | 2.1 | los nueve personajes andando |
| 36– | 2.3 | la demostración jugándose sola |

Para lanzarla:

    openmsx -machine Philips_VG_8020 -cart goonies.rom \
            -script tools/omsx_sonda.tcl

## El cotejo contra la VRAM

    make vram

Arranca openMSX sin renderizador y sin freno, vuelca los 16 KB de VRAM en cinco
instantes —13, 25, 45, 60 y 75 segundos— y luego resta esa VRAM de la que monta
`tools/vram.py`, que es la traducción a Python de las rutinas de carga del
cartucho.

Las tres primeras tablas son estáticas: se montan al entrar en la pantalla y no
se tocan hasta que cambia. **Tienen que salir a cero.**

    pantalla         color        spr patr     patrones
    titulo           0/6144       0/2048       0/6144      (y nombres 0/768)
    los nueve        0/6144       0/2048       0/6144
    nivel 1 sala 1   0/6144       0/2048       0/6144
    nivel 1 sala 2   0/6144       0/2048       0/6144
    nivel 1 sala 3   0/6144       0/2048       0/6144

## La trampa que costó la mitad del trabajo

**El cartucho no borra los patrones ni el color al cambiar de escena. Solo la
tabla de nombres.**

Montar la pantalla del título por su cuenta daba cientos de bytes de diferencia
que no eran un error de lectura: era **herencia que faltaba**. La pantalla del
título se pinta encima de lo que dejó la presentación —la fuente y el cartel
que baja—, y el nivel se pinta encima de lo que dejó la pantalla de los nueve.

Por eso `vram.desde_el_encendido()` encadena las escenas en el orden de la tabla
de `0x40F6`:

    escena 0.0   la fuente y el cartel que baja      (0x412B)
    escena 0.2   el rotulo THE GOONIES               (0x4123)
    escena 1     espera, no toca la VRAM             (0x4139)
    escena 2.0   las dos ultimas filas a cero y el
                 decorado de los nueve               (0x4175)
    escena 2.3   el nivel                            (0x41B9)

Con la cadena entera, las cinco pantallas cierran a cero.

## La fase del agua

Las tres casillas del agua se quedan en la fase que dejó el último repintado, y
esa depende del bit 2 del contador de cuadros **y de si la sala anterior tenía
agua**. El cotejo prueba las dos y dice cuál cuadra; las dos tandas son
distintas, así que acertar por casualidad no es posible.

Se ve en el volcado: en la sala 0 del nivel 1 no hay agua (`(0xE345)` a cero) y
las casillas están como las dejó el guión original; en la sala 1 sí la hay y
están en la otra fase; y la sala 2, que tampoco tiene, **hereda la fase que dejó
la sala 1**.

## Las casillas que bailan

La tabla de nombres no se coteja a cero, y no debe: ahí el juego repinta cada
cuadro los bichos, el agua, las jaulas y el marcador. Lo que se mira es cuántas
casillas bailan y si son las que deben. En el nivel 1 son 19, 47 y 29 de las
640 de cada sala, y caen en las filas donde hay bichos.

En la pantalla del título, en cambio, **sí** cierra a cero: las 768 casillas.
Ahí no se mueve nada.

## Trampas de Tcl ya pagadas en esta serie

- Nada de corchetes dentro de un `format`.
- El fichero binario, con `-translation binary`.
- `debug read_block`, que `debug save_to_file` no existe.
- Reprogramar el temporizador **lo primero**, antes de hacer nada.
