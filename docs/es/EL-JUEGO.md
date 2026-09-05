# El juego

![La pantalla del título](../imagenes/rotulo.png)

*La pantalla del título, dibujada desde la ROM. El rótulo dice **© KONAMI
1986**, y debajo el aviso de marca de Warner Bros. de 1985.*

Mikey baja a las cuevas de Astoria a rescatar a los otros siete Goonies y a
encontrar el tesoro de Willy el Tuerto. Son **veinticinco niveles repartidos en
cinco rondas de cinco**, y cada nivel son **cuatro salas** de 32x20 casillas.

## Lo que hay que hacer en cada nivel

Sacar a los amigos de sus jaulas. Cada uno que sale sube el contador de
`(0xE130)`, y **con siete se abre la puerta de la calavera**, que es la que deja
pasar al nivel siguiente. La llave está en `(0xE121)`.

Las salas se recorren saliendo por los lados. El enlace entre ellas no es
geométrico: son **dos tablas gemelas de 19 filas por 4 columnas** (`0x52DB` y
`0x5327`), y cuál se mira lo decide por dónde te sales — por la izquierda si la
columna baja de `0x15`, por la derecha si llega a `0xC0`. La fila la elige el
*reparto de salas* del nivel, uno de los 25 bytes de `0x9D67`.

## El jugador

![Las dieciséis posturas](../imagenes/jugador.png)

Seis estados —andar, saltar, escalera, caer, patada y patada en el aire— y
dieciséis posturas. Cada postura son **tres sprites de 16x16 superpuestos**,
montados por `0x586A` desde una entrada de nueve bytes: desplazamiento en y,
desplazamiento en x y número de patrón, tres veces.

La velocidad lleva fracción: `0x0110` normal —un pixel y un dieciseisavo por
cuadro— y `0x0180` con el objeto 0, que es un pixel y medio.

## Las cuerdas verdes

Se sube y se baja por ellas, y no son adorno: **la casilla `0x41` es el pie de
la cuerda** y se sube pulsando arriba; **la `0x53` es la cabeza**, la que cuelga
de la plataforma, y se baja pulsando abajo (`0x66E4`). Los bichos usan
exactamente las mismas.

## Los peligros

![Puertas y jaulas](../imagenes/puertas-y-jaulas.png)

*La puerta de la calavera —cerrada y abierta—, la puerta al nivel siguiente y
las cuatro jaulas: cerrada, abierta, con el amigo dentro y con el objeto
dentro.*

Cada nivel trae dos listas. La **lista del nivel** va pegada detrás de los
ochenta bytes del mapa y reparte lo que hay por las cuatro salas; las **cuatro
listas de sala** cuelgan de una tabla por nivel. Las dos se leen igual
(`0x8D64` y `0x8E73`): un byte `0xF0+tipo` abre un tramo, detrás van sus
registros y el `0xFF` cierra.

| tipo | lista del NIVEL | lista de la SALA |
|---|---|---|
| 0 | columna que crece | chorro de agua |
| 1 | estalactita | bola de piedra |
| 2 | **el perseguidor** | llamarada |
| 3 | la puerta al nivel siguiente | fuga de la tubería |
| 4 | trasto que parpadea | el sitio del que gotea |
| 5 | jaula | calavera |
| 6 | objeto escondido | murciélago |
| 7 | la puerta de la calavera | el bicho de patas |

`0x7A9E` pasa los siete peligros de daño y deja el bit en `(ix+00Ah)`, que es de
donde sale también el color del jugador: chorro de agua `0x01`, estalactita
`0x02`, gota `0x04`, llamarada `0x08`, columna `0x10`, fuga `0x20` y bola de
piedra `0x40`.

![Los bichos](../imagenes/bichos.png)

*Los patrones de sprite de un solo cuadrado, en los seis colores que usa el
juego. El color no está en el dibujo: va en el atributo.*

## El inventario

![Los veintitrés objetos](../imagenes/objetos.png)

*Los veintitrés objetos, con el nivel en el que sale cada uno debajo.*

Veintitrés objetos, y la fila de abajo enseña hasta doce iconos de 2x2. Se
guardan en tres sitios: `0xE176` un bit por objeto, `0xE180` qué sitio ocupa
cada uno en la fila y la tabla de `0x6F68` su icono.

Y no son adornos: **son escudos con carga**. La lista de `0x7D9B` dice qué
objeto para cada peligro; llevándolo, el golpe gasta un uso de
`(0xE150+objeto)` en vez de restar energía, y al acabarse el objeto se pierde.

La tabla de `0x5576` dice en qué nivel está cada uno: veintitrés valores
distintos entre 0 y 24, y **faltan justo el 5 y el 14**. Los niveles 6 y 15 son
los únicos sin objeto.

## La contraseña

Al final de cada ronda, `0x53A7` enseña debajo del rótulo `KEYWORD` el nombre
de la ronda que acabas de pasar. Ese nombre es la contraseña, porque **son los
mismos bytes**: MR SLOTH, GOON DOCKS, DOUBLOON, ONE EYED WILLY y GOONIES. Está
contado entero en [Hallazgos](HALLAZGOS.html).

## Los veinticinco niveles

Están dibujados uno a uno, con sus cien salas, en [Los 25
niveles](LOS-NIVELES.html).
