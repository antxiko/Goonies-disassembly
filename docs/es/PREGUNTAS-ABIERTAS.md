# Preguntas abiertas

Los 32.768 bytes están explicados y el listado reproduce la ROM byte a byte.
Lo que sigue no son huecos del desensamblado: son cosas que el cartucho hace y
de las que no se ha medido el **porqué**.

## Los dos niveles con dos objetos escondidos

Las veintisiete condiciones de `0x6DBD` se usan las veintisiete, una vez cada
una. Veintitrés niveles llevan un objeto escondido y **dos llevan dos: el 5 y
el 16**. Que sean esos dos y no otros no está medido.

## Los niveles 6 y 15

La tabla de `0x5576` deja sin objeto justo esos dos, y eso está medido. Lo que
no está medido es si es a propósito —dos niveles de descanso, uno por ronda— o
si es que faltan dos objetos de un plan de veinticinco.

## Las tres voces vacías

Las tres últimas entradas de la tabla de voces valen `0xBFEE`, que es donde
empieza el relleno `0xFF`. Son voces vacías, y no se sabe si son sitio reservado
o el rastro de tres piezas que se cayeron.

## Cuánto se juega de verdad

Las cien salas están dibujadas y ninguna se repite, pero **no se ha medido
cuántas de las cien se pisan en una partida**. El enlace entre salas va por dos
tablas de 19x4 y por dónde te sales, así que puede haber salas a las que solo se
llegue por un lado.

## El bicho de patas

Aparece en pocos niveles y siempre uno solo. Está entendido —espera escondido en
una caja de 8x8 hasta que lo pisan, y el objeto `0x13` impide que se despierte—,
pero no se ha medido por qué está en esos niveles y no en otros.

## La segunda cabecera

La del Konami Game Master está, y sus once bytes de punteros también. Este
cartucho no la lee. **De qué es exactamente cada uno de esos once bytes** no se
ha podido cerrar sin tener delante el cartucho de trucos: el reparto de ese
espacio cambia de un juego a otro.

## Los caracteres de la marca oculta

Del código de katakana de la casa están confirmados los índices 0 a 44 —el
*gojūon* corrido— y cinco más: 51, 53, 55, 56 y **58, que lo cierra este
cartucho**. Los demás siguen sin comprobar, y solo se cerrarán con más
cartuchos.
