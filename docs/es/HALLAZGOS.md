# Hallazgos

## Las cuatro salas de un nivel no van en columna: van en un plano

*Esto lo encontro **[theNestruo](https://github.com/theNestruo)**, en el
[issue #1](https://github.com/antxiko/Goonies-disassembly/issues/1). Aqui las
cien salas se publicaban una a una, sin plano, y el fue quien dijo que en el
juego van agrupadas por nivel y con formas distintas -y puso de ejemplo los
niveles 1, 2, 3, 8 y 11-. Todos y cada uno le dan la razon. Lo de abajo es solo
buscar en los bytes lo que el ya sabia.*

`empieza_el_nivel` (`0x4F82`) saca de `0x9D67` un byte por nivel y lo deja en
`(0xE06A)`. Ese byte elige una de las **diecinueve** filas de `0x52DB`, cuatro
bytes, uno por sala.

De cada byte, el **nibble bajo** es la sala a la que se pasa saliendo por la
izquierda (`0xF`: no hay), y el **alto es LA POSICION** de esa sala en el
plano. Que es la posicion no es una suposicion: lo dice el perseguidor.
`0x74C0` compara ese nibble con `0xC0` -los dos bits altos- para decidir si
tiene que moverse en horizontal, y `0x74C4` con `0x30` -los dos bajos- para la
vertical. O sea que el nibble es **columna por cuatro mas fila**.

Y encaja con todo lo demas: `0x5327` da la sala de la derecha, y las de arriba
y abajo son la de ahora menos y mas uno -el `dec b` de `0x529A` y los dos
`inc b` de `0x52A2`-.

Los veinticinco repartos, contados sobre esos bytes:

| forma | niveles |
| --- | --- |
| una columna de cuatro | 1, 10, 15 |
| una fila de cuatro | 2, 19 |
| 2x2 | 3, 9, 13, 17, 24, 25 |
| tres columnas por dos filas | 4, 6, 8, 11, 14, 21 |
| dos columnas por tres filas | 5, 7, 12, 16, 18, 20, 22, 23 |

La prueba de que el reparto es el bueno esta en el dibujo: montadas asi, **las
plataformas y las escaleras siguen de una sala a la de al lado**, y el agua del
fondo se continua.

![El nivel 8](../imagenes/mapa-nivel-08.png)

Los veinticinco mapas de [Las 100 salas](LOS-NIVELES.html) estan rehechos con
este reparto.

## Las 64 puertas de calavera emparejan sin una sola excepcion

*Tambien de **[theNestruo](https://github.com/theNestruo)**, en el mismo issue:
pidio un minimapa por ronda con las puertas unidas. No habia forma de dibujarlo
sin saber que puerta va con cual, y buscarlo es lo que destapo esto.*

Cada puerta de calavera son tres bytes, y del tercero `0x8DA8` saca **dos
cosas**: los seis bits bajos son el nivel al que lleva y los **dos altos la
ENTRADA**, que es el numero de puerta por la que se aparece alli.

Eso convierte las puertas en parejas comprobables: si la puerta *j* del nivel A
dice (B, *k*), la puerta *k* del nivel B tiene que decir (A, *j*). **Las 64 del
cartucho lo cumplen**, sin una excepcion, y ademas **ninguna sale de su ronda**:
los 25 niveles son cinco grupos de cinco, cerrados.

![La ronda 1](../imagenes/ronda-1.png)

Cada raya de ese minimapa une dos puertas que se emparejan de verdad. Hay uno
por ronda en [Las 100 salas](LOS-NIVELES.html).

## El nombre de la ronda es su contraseña

En la pantalla del título se puede teclear. `0x53C8` lee el teclado con SNSMAT
y va metiendo lo tecleado en `0xE4C0` —hasta dieciséis letras, con el índice en
`(0xE074)`—, y al soltar llama a `0x5444`, que compara esos dieciséis bytes
contra **cinco nombres**, de `0x546E` en adelante y **de diecinueve en
diecinueve** bytes.

Si alguno cuadra, `0x5421` usa cuál era como índice en la tabla de `0x543A`:

| contraseña | nivel | ronda |
|---|---:|---:|
| MR SLOTH | 6 | 2 |
| GOON DOCKS | 11 | 3 |
| DOUBLOON | 16 | 4 |
| ONE EYED WILLY | 21 | 5 |
| GOONIES | 1 | 1 |

Y el detalle: **esos mismos bytes son también el rótulo que se pinta en
pantalla**. Cada uno de los cinco es un guión literal completo —dirección de
VRAM, dieciséis casillas y el `0xFF` que cierra— y la comparación entra dos
bytes más adelante, saltándose la dirección. No hay dos tablas: hay una.

Por eso `0x53A7` te enseña la contraseña al pasar de ronda, debajo del rótulo
`KEYWORD`: te está enseñando el nombre de la ronda que acabas de dejar.

Los nombres de ronda 2 a 5 tienen sus punteros en `0x53C0`, con `(0xE06C)-2` de
índice. La quinta, ONE EYED WILLY, es **la única sin `0xFF` de cierre**, y eso
cuadra: es la ronda a la que se llega, no una que se anuncie.

## Sesenta y cuatro mil casillas en 2.983 bytes

Cien salas de 32x20, todas distintas, en menos de tres mil bytes: veintiuna
casillas por byte. Está desmenuzado en [El código](EL-CODIGO.html) —bloques de
8x4, el bit de espejar y las colas compartidas—, y el resultado se ve en [Las
100 salas](LOS-NIVELES.html).

## Las veintisiete condiciones de los objetos escondidos

La tabla más larga del cartucho es la de `0x6DBD`: **veintisiete** entradas.
Cada una es una condición que destapa uno de los objetos escondidos.

Dar dos golpes seguidos al mismo sitio. Una patada a cada lado. Quedarse quieto
`0x60` cuadros. Tener las dos barras por encima de `0x28`. Darle una patada a
la bola de piedra, o a la llamarada.

Casi todas se apoyan en `(0xE126)` y `(0xE127)`, que son **los dos últimos
golpes** que ha dado el jugador y que `0x8005` va apuntando cuadro a cuadro.

Y no sobra ninguna. Recorriendo las listas de los veinticinco niveles salen
**veintisiete objetos escondidos con veintisiete índices distintos, del 0 al
26**: cada condición se usa exactamente una vez. Veintitrés niveles llevan uno
y **dos llevan dos, el 5 y el 16**.

Los veintisiete, eso sí, se ven exactamente igual: una sola casilla, la `0x91`,
parpadeando. Lo dice `0x6E14`.

## Los objetos son escudos con carga

La lista de `0x7D9B` son ocho bytes, uno por peligro, y dice **qué objeto del
inventario para cada uno** —o `0xFF` si no lo para ninguno—. Llevándolo, el
golpe no resta energía: gasta **un uso** de `(0xE150+objeto)`, y cuando se
acaban, `0x8B37` saca el objeto del inventario.

Los siete peligros y su bit, que `0x7A9E` deja en `(ix+00Ah)` —de donde sale
también el color del jugador—:

| peligro | bit |
|---|---|
| chorro de agua | `0x01` |
| estalactita | `0x02` |
| gota | `0x04` |
| llamarada | `0x08` |
| columna que crece | `0x10` |
| fuga de la tubería | `0x20` |
| bola de piedra | `0x40` |

La barra de energía es de dieciséis bits —`(0xE063)` la fracción y `(0xE064)`
lo que se ve— y se pinta con resolución de **un octavo de casilla**.

Son veintitrés objetos, y la tabla de `0x5576` dice en qué nivel está cada uno:
veintitrés valores distintos entre 0 y 24, y **faltan justo el 5 y el 14**. Los
niveles 6 y 15 son los dos únicos sin objeto.

## La demostración es una partida grabada

`0x51D5` no simula a nadie: **lee una cinta**. `0x472D` empieza leyendo los
mandos y el teclado con `0x4742`, pero `0x5206` entra por `0x4730`, que es
justo el byte de después, con `a` ya puesto desde una tabla. O sea que la rutina
de mandos se ejecuta desde la mitad y devuelve lo que le han metido.

Son dos tablas en paralelo, las dos indexadas por `(0xE00B)`: en `0x520E`, **34
estados de mando** y el `0xFF` que cierra; en `0x5231`, **cuántos cuadros dura
cada uno**. Cuando `(0xE00C)` llega a la duración, se pasa al siguiente. El
`0xFF` cierra la grabación y apaga `(0xE066)`.

Esto es lo que hace posible cotejar la VRAM arrancando el cartucho **en frío**:
la presentación, el título y la demostración salen solos, siempre iguales, sin
partidas grabadas ni puntos de ruptura.

## El perseguidor cuenta casillas para elegir cuerda

Cuando el perseguidor quiere cambiar de altura, `0x756D` y `0x7577` recorren su
fila **casilla a casilla hacia los dos lados**, contando cuántas hay hasta la
`0x41` —el pie de una cuerda— o la `0x53` —la cabeza—, y se va a por la más
corta.

Y el **bit 0 de `(ix+00Fh)`** decide cuál de los dos lados se prueba primero, y
se gasta rotándolo en cada consulta. Por eso dos perseguidores iguales en la
misma fila no salen los dos hacia la misma cuerda.

Las cuerdas verdes son las mismas para todos. Lo dice `0x66E4`: el jugador sube
por la `0x41` pulsando arriba y baja por la `0x53` pulsando abajo.

## El agua se lleva un cuaderno de lo que tapa

El chorro de agua baja por la sala pisando casillas. Para poder recogerse sin
dejar agujeros, cuando encuentra una casilla ocupada **apunta en `0xE1D0` la
fila y las tres casillas que había**, y al retirarse las devuelve. El mapa no se
toca: el mapa es de solo lectura.

La corriente, en cambio, no mueve nada. `0x854E` reescribe **tres patrones**
—las casillas `0x6D`, `0xCF` y `0xF1`— en los tres bancos, alternando dos
tandas de dieciséis bytes con **el bit 2 del contador de cuadros**. El agua
parece correr y ni una casilla de la pantalla ha cambiado.

Cada registro de esas tandas son cuatro bytes de patrón y dos de salto a la
casilla siguiente. El salto de la tercera vuelta **se lee y ya no se usa**: por
eso cada tanda ocupa dieciséis bytes y no dieciocho.

## La mitad de los dibujos se fabrican al arrancar

De los 42 patrones de sprite de 16x16 que trae el cartucho (`0x927F`), **22 no
están dibujados**: `0x4CDF` los fabrica espejando a los otros. Y con las
casillas lo mismo: 34 se hacen dándole la vuelta a los ocho bits de otras 34.

Espejar un sprite de 16x16 **no es solo invertir los bits**: hay que cambiar de
sitio sus dos columnas, porque un patrón de 16x16 son dos columnas de dieciséis
bytes puestas una detrás de otra. El cartucho lo hace entrando con el destino
apuntando a la segunda mitad (`0x1D50`, no `0x1D40`) y con el baile de `inc e /
sub 020h` sobre el byte bajo de la dirección, en `0x46E6`.

Hacerlo sin ese detalle da dibujos partidos por la mitad, y el cotejo contra la
VRAM lo canta: con el arreglo, **0 bytes distintos de los 2.048** de patrones de
sprite.

Lo confirma también la tabla de `0x6996`: el dibujo espejado se pinta doce
píxeles a la izquierda y el normal cuatro.

## La geometría va al revés, y el RLE también

Los ocho bytes de `0x4720` ponen **el color debajo y los patrones encima**, que
es lo contrario de lo que hacen casi todos. Está en [El
cartucho](EL-CARTUCHO.html).

Y el descompresor de `0x46A6` también va al contrario de lo que parece: **el bit
7 puesto es literal** y a cero es repetición. Lo decide a dónde vuelve el
`djnz`.

## La pantalla del título y la del final son la misma

`0x558D` monta una sola escena, con nueve personajes andando, y de ella salen
las dos: solo cambia por `(0xE06C)==6`, o sea después de pasarse el juego. El
rótulo THE GOONIES se pinta **encima** de ese decorado y no se borra al entrar
en él, porque entre escena y escena el cartucho solo limpia la tabla de nombres.

## Un sprite se apaga con un 0xC0 en la fila

En `0x6576`, un sprite se quita poniéndole `0xC0` en el byte de la **fila**, que
es el convenio del VDP. No en el del patrón — y `0xC0` también es un número de
patrón perfectamente válido. Comprobar el byte equivocado se come sprites
buenos: la postura 7 del jugador salía sin cuerpo.

## El rótulo dice 1986

No hace falta una ficha de fuera: el rótulo de la pantalla del título, dibujado
desde la ROM, pone **© KONAMI 1986**, y debajo el aviso de marca de Warner Bros.
de 1985. La película es de 1985; el cartucho, de 1986.

## La marca oculta de la casa

Está contada en [El cartucho](EL-CARTUCHO.html). El hallazgo es de **Manuel
Pazos**, y este cartucho cierra un carácter que estaba sin confirmar.
