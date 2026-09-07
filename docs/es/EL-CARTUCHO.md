# El cartucho

    fichero    goonies.rom
    tamano     32.768 bytes
    sha256     2ba602b1a17e4797da1588afe6e65640331c15746bf5959f4778b404be929dde
    catalogo   RC-734
    maquina    MSX1

## Dónde vive

Es un cartucho de 32 KB en las **páginas 1 y 2**, `0x4000..0xBFFF`. No hay
paginación ni mapeador: los 32 KB están a la vez y el Z80 los ve enteros.

## Las dos cabeceras

La primera es la de siempre: en `0x4000` van la firma `"AB"` y la dirección de
INIT, que aquí es `0x406A`. STATEMENT, DEVICE y TEXT están a cero, y los seis
bytes reservados también.

La segunda, en `0x4010`, no es del MSX: es la del **Konami Game Master**, el
cartucho de trucos de la casa que se enchufa en la otra ranura. Empieza por
`"CD"`, y detrás van `07 34` — el `0x07` de los RC-7xx y el `0x34` de RC-734—,
y luego once bytes con las variables que el Game Master quiere tocar.

Este cartucho **no la lee nunca**: `tools/quien_lee.py` da cero referencias a
`0x4010..0x401E`. Está ahí para que la lea el cartucho de al lado.

Siete de las ROM de Konami que hay aquí la llevan, cinco de ellas
desensambladas en esta serie: Konami's Soccer y Football (RC-732), éste,
Konami's Boxing (RC-736), Yie Ar Kung-Fu II (RC-737), Knightmare (RC-739),
Nemesis (RC-742) y F-1 Spirit (RC-752). El marcador de delante va por **año** y
no por número de catálogo: `AB` en los de 1985 y `CD` de 1986 en adelante.

## La marca oculta

Al final del cartucho, detrás del relleno `0xFF`, están el título en katakana
escrito **del revés** y el número de catálogo:

    グーニーズ   34   0xAA

Se lee con el código de la casa: índice = byte − `0x80`, y los índices 0 a 44
son el *gojūon* corrido. El hallazgo es de **Manuel Pazos**, que lo destapó en
2021; sin él nadie sabría que hay que mirar ahí.

Este cartucho, además, deja atado un carácter que estaba sin confirmar: el
`0xBA`, índice 58, es el alargador ー. グーニーズ solo cuadra así.

## Los registros del VDP

`0x470F` vuelca ocho bytes en los registros 0 a 7, uno por uno:

| reg | valor | qué dice |
|---|---|---|
| R0 | `0x02` | modo 2 (SCREEN 2) |
| R1 | `0xE2` | 16 KB, pantalla encendida, interrupción activa, sprites de 16x16 |
| R2 | `0x0E` | nombres en `0x3800` |
| R3 | `0x7F` | colores: base `0x0000`, máscara `0x1FFF` |
| R4 | `0x07` | patrones: base `0x2000`, máscara `0x1FFF` |
| R5 | `0x76` | atributos de sprite en `0x3B00` |
| R6 | `0x03` | patrones de sprite en `0x1800` |
| R7 | `0xE4` | borde azul oscuro |

**Cuidado con R3 y R4**: en el modo 2 no son una dirección, son base y máscara.
Leerlos como dirección da colores a franjas con las formas bien, que es el
síntoma clásico.

La geometría que sale de ahí va **al revés de lo habitual**:

    color              0x0000..0x17FF   tres bancos de 0x800
    patrones de sprite 0x1800..0x1FFF   64 patrones
    patrones           0x2000..0x37FF   tres bancos de 0x800
    nombres            0x3800..0x3AFF   768 casillas
    atributos de spr   0x3B00..0x3B7F   32 sprites

La tabla de colores va **debajo** de la de patrones. Un `ld hl,00008h` en este
cartucho no apunta a patrones: apunta al color.

## El reparto de los 32.768 bytes

| |bytes|%|
|---|---:|---:|
|código trazado|17.422|53,17|
|datos identificados|15.346|46,83|
|**sin explicar**|**0**|**0,00**|
|**total**|**32.768**|**100,00**|

Lo cuenta `tools/presupuesto.py`, y `make sanity` lo comprueba en cada
compilación.

## El armazón de Konami

El despachador que reparte por tablas —`pop hl / add a,a / call ... / ld e,(hl)
/ inc hl / ld d,(hl) / ex de,hl / jp (hl)`— es el mismo en once cartuchos de la
casa. Buscando su cola (`5e 23 56 eb e9`) por las 47 ROM que hay a mano aparece
**una sola vez** en cada uno: Sky Jaguar (RC-721), Yie Ar Kung-Fu (las dos
compilaciones), Hyper Rally (RC-718), Road Fighter (RC-730), Konami's Ping Pong
(RC-731), Konami's Soccer y Football (RC-732), Hyper Sports 3 (RC-733), éste
(RC-734), Nemesis (RC-742) y F-1 Spirit (RC-752).

En este cartucho se usa **veintiséis veces**, y las veintiséis tablas van
pegadas justo detrás de su `call`.
