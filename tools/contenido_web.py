#!/usr/bin/env python3
"""El CONTENIDO de la portada: los hallazgos y los pies de la galeria.

Va aparte de make_web.py a proposito. make_web.py es el generador -la
plantilla, la maquetacion, el HTML- y no cambia de un juego al siguiente; esto
es lo unico que hay que reescribir entero en cada cartucho. Teniendolo separado
no hay que ir buscando los textos del juego anterior dentro del generador, que
es justo como se han colado los nombres equivocados otras veces.

Cada hallazgo es (titulo, html) y cada entrada de galeria
(fichero, pie en castellano, pie en ingles).

Todas las cifras de aqui estan medidas sobre este cartucho, con las
herramientas de tools/, y no copiadas de ningun otro proyecto.
"""

HALLAZGOS = {
    "es": [
        ("Las cuatro salas de un nivel no van en columna: van en un plano",
         "<p><code>empieza_el_nivel</code> (<code>0x4F82</code>) saca de "
         "<code>0x9D67</code> un byte por nivel y lo deja en "
         "<code>(0xE06A)</code>. Ese byte elige una de las <b>diecinueve</b> "
         "filas de <code>0x52DB</code>, cuatro bytes, uno por sala.</p>"
         "<p>De cada byte, el <b>nibble bajo</b> es la sala a la que se pasa "
         "saliendo por la izquierda (<code>0xF</code>: no hay), y el "
         "<b>alto es LA POSICION</b> de esa sala en el plano. Que es la "
         "posicion lo dice el perseguidor: <code>0x74C0</code> compara ese "
         "nibble con <code>0xC0</code> -los dos bits altos- para decidir si "
         "tiene que moverse en horizontal, y <code>0x74C4</code> con "
         "<code>0x30</code> -los dos bajos- para la vertical. O sea que el "
         "nibble es <b>columna por cuatro mas fila</b>.</p>"
         "<p>De ahi salen los repartos: cinco niveles en columna, dos en "
         "fila, seis en 2x2 y <b>catorce con forma rara</b>. Y encaja con lo "
         "demas: <code>0x5327</code> da la sala de la derecha, y las de "
         "arriba y abajo son la de ahora menos y mas uno -el <code>dec b</code> "
         "de <code>0x529A</code> y los dos <code>inc b</code> de "
         "<code>0x52A2</code>-.</p>"
         "<p>La prueba de que el reparto es el bueno esta en el dibujo: "
         "montadas asi, <b>las plataformas y las escaleras siguen de una sala "
         "a la de al lado</b>, y el agua del fondo se continua. Los "
         "veinticinco mapas de <a href=\"LOS-NIVELES.html\">Las 100 salas</a> "
         "estan rehechos con este reparto.</p>"),

        ("Las 64 puertas de calavera emparejan sin una sola excepcion",
         "<p>Cada puerta de calavera son tres bytes, y del tercero "
         "<code>0x8DA8</code> saca <b>dos cosas</b>: los seis bits bajos son "
         "el nivel al que lleva y los <b>dos altos la ENTRADA</b>, que es el "
         "numero de puerta por la que se aparece alli.</p>"
         "<p>Y eso convierte las puertas en parejas comprobables: si la "
         "puerta <i>j</i> del nivel A dice (B, <i>k</i>), la puerta <i>k</i> "
         "del nivel B tiene que decir (A, <i>j</i>). <b>Las 64 del cartucho "
         "lo cumplen</b>, sin una excepcion, y ademas <b>ninguna sale de su "
         "ronda</b>: los 25 niveles son cinco grupos de cinco, cerrados.</p>"),

        ("El nombre de la ronda ES su contrasena",
         "<p>En la pantalla del titulo se puede teclear. Las letras se van "
         "acumulando en <code>0xE4C0</code> y <code>0x5444</code> las compara "
         "contra cinco nombres de dieciseis bytes, colocados de diecinueve en "
         "diecinueve desde <code>0x546E</code>: <b>MR SLOTH</b> lleva a la "
         "ronda 2, <b>GOON DOCKS</b> a la 3, <b>DOUBLOON</b> a la 4, <b>ONE "
         "EYED WILLY</b> a la 5 y <b>GOONIES</b> a la 1.</p>"
         "<p>Y esos mismos bytes son, a la vez, el guion que pinta el nombre "
         "de la ronda cuando empieza. No hay dos tablas: hay una. Al pasar de "
         "ronda, <code>0x53A7</code> te ensena debajo del rotulo "
         "<code>KEYWORD</code> el nombre que acabas de dejar atras, que es "
         "exactamente lo que hay que teclear para volver.</p>"
         "<p>La quinta es la unica sin el <code>0xFF</code> de cierre, y tiene "
         "sentido: <b>ONE EYED WILLY</b> es la ronda a la que se llega, no una "
         "que se anuncie nunca.</p>"),

        ("Sesenta y cuatro mil casillas en menos de tres mil bytes",
         "<p>Los veinticinco niveles son cuatro salas cada uno, y cada sala "
         "32x20 casillas: <b>64.000 casillas</b> en total. Todo eso cabe en "
         "<b>2.983 bytes</b>, o sea a razon de <b>veintiuna casillas por "
         "byte</b>.</p>"
         "<p>El truco son tres capas. Un nivel son ochenta bytes, cuatro "
         "columnas por veinte filas, y cada byte apunta a un <b>bloque de 8x4 "
         "casillas</b> de la tabla de <code>0x5B65</code>, que tiene ciento "
         "ocho. El <b>bit 7 del byte pide el bloque espejado</b>, y asi se usa "
         "615 veces de las 2.000. Y los ciento ocho bloques <b>comparten "
         "cola</b>: contando cada byte una sola vez ocupan 717 y no 841, "
         "porque unos empiezan dentro de otros.</p>"
         "<p>Los ciento ocho se usan. Ni uno sobra.</p>"),

        ("Las veintisiete maneras de sacar un objeto escondido",
         "<p>La tabla mas larga del cartucho es la de <code>0x6DBD</code>: "
         "<b>veintisiete</b> entradas, una por cada condicion que destapa uno "
         "de los objetos escondidos. Dar dos golpes seguidos al mismo sitio; "
         "una patada a cada lado; quedarse quieto <code>0x60</code> cuadros; "
         "tener las dos barras por encima de <code>0x28</code>; darle una "
         "patada a la bola de piedra, o a la llamarada...</p>"
         "<p>Casi todas se apoyan en <code>(0xE126)</code> y "
         "<code>(0xE127)</code>, que son <b>los dos ultimos golpes</b> que ha "
         "dado el jugador y que <code>0x8005</code> va apuntando.</p>"
         "<p>Y no sobra ninguna: recorriendo las listas de los veinticinco "
         "niveles salen <b>veintisiete objetos escondidos con veintisiete "
         "indices distintos, del 0 al 26</b>. Veintitres niveles llevan uno y "
         "dos llevan dos, el 5 y el 16.</p>"
         "<p>Los veintisiete, eso si, se ven exactamente igual: una sola "
         "casilla, la <code>0x91</code>, parpadeando.</p>"),

        ("Los objetos son escudos con carga, no adornos",
         "<p>La lista de <code>0x7D9B</code> tiene ocho bytes, uno por peligro "
         "-chorro de agua, estalactita, gota, llamarada, columna, fuga y bola "
         "de piedra-, y dice <b>que objeto del inventario para cada uno</b>. "
         "Llevandolo, el golpe no resta energia: gasta <b>un uso</b> de "
         "<code>(0xE150+objeto)</code>, y cuando se acaban, el objeto "
         "desaparece del inventario.</p>"
         "<p>La barra de energia es de dieciseis bits -<code>(0xE063)</code> "
         "la fraccion y <code>(0xE064)</code> lo que se ve- y se pinta con "
         "resolucion de <b>un octavo de casilla</b>.</p>"
         "<p>Son veintitres objetos y la tabla de <code>0x5576</code> dice en "
         "que nivel esta cada uno: veintitres valores distintos entre 0 y 24, "
         "y <b>faltan justo el 5 y el 14</b>. Los niveles 6 y 15 son los dos "
         "unicos sin objeto.</p>"),

        ("El perseguidor cuenta casillas para elegir cuerda",
         "<p>Cuando el perseguidor quiere cambiar de altura, "
         "<code>0x756D</code> recorre su fila <b>casilla a casilla hacia los "
         "dos lados</b>, contando cuantas hay hasta la <code>0x41</code> -el "
         "pie de una cuerda- o la <code>0x53</code> -la cabeza-, y se va a por "
         "la mas corta.</p>"
         "<p>Y hay un detalle: el <b>bit 0 de <code>(ix+00Fh)</code></b> "
         "decide cual de los dos lados se prueba primero, y se gasta rotandolo "
         "en cada consulta. Por eso dos perseguidores iguales en la misma fila "
         "<b>no salen los dos hacia la misma cuerda</b>.</p>"
         "<p>Las cuerdas verdes son las mismas para todos: el jugador sube por "
         "la <code>0x41</code> pulsando arriba y baja por la <code>0x53</code> "
         "pulsando abajo (<code>0x66E4</code>), y los bichos usan esas dos.</p>"),

        ("La demostracion es una partida grabada",
         "<p><code>0x5206</code> entra en <code>0x4730</code>, que es el byte "
         "de <b>detras</b> del <code>call</code> que lee los mandos de verdad, "
         "con el acumulador ya puesto desde la tabla. O sea: la rutina de "
         "mandos se ejecuta desde la mitad, y lo que devuelve no lo ha pulsado "
         "nadie.</p>"
         "<p>Son <b>34 estados de mando</b> en <code>0x520E</code> -mas el "
         "<code>0xFF</code> que cierra- y sus <b>34 duraciones</b> en "
         "<code>0x5231</code>. La demostracion hace siempre exactamente lo "
         "mismo, y eso es lo que permite cotejar la VRAM arrancando el "
         "cartucho en frio, sin partidas grabadas ni puntos de ruptura.</p>"),

        ("El agua se lleva un cuaderno de lo que tapa",
         "<p>El chorro de agua baja por la sala pisando casillas. Para poder "
         "recogerse sin dejar agujeros, cuando encuentra una casilla ocupada "
         "<b>apunta en <code>0xE1D0</code> la fila y las tres casillas que "
         "habia</b>, y al retirarse las devuelve a su sitio. El mapa no se "
         "toca: el mapa es de solo lectura y lo unico que cambia es la "
         "pantalla.</p>"
         "<p>La corriente, en cambio, no mueve nada: <code>0x854E</code> "
         "reescribe <b>tres patrones</b> -las casillas <code>0x6D</code>, "
         "<code>0xCF</code> y <code>0xF1</code>- en los tres bancos, "
         "alternando dos tandas de dieciseis bytes con <b>el bit 2 del "
         "contador de cuadros</b>. El agua parece correr y ni una casilla de "
         "la pantalla ha cambiado.</p>"),

        ("La mitad de los dibujos se fabrican al arrancar",
         "<p>De los 42 patrones de sprite de 16x16 que trae el cartucho, "
         "<b>22 no estan dibujados</b>: se fabrican espejando a los otros. Y "
         "con las casillas, lo mismo: 34 se hacen dandole la vuelta a los ocho "
         "bits de otras 34.</p>"
         "<p>Espejar un sprite de 16x16 no es solo invertir los bits: hay que "
         "<b>cambiar de sitio sus dos columnas</b>. El cartucho lo hace con un "
         "<code>inc e</code> y un <code>sub 020h</code> sobre el byte bajo de "
         "la direccion (<code>0x46E6</code>), y entra con el destino apuntando "
         "a la segunda mitad. Hacerlo sin ese detalle da dibujos partidos por "
         "la mitad, y el cotejo contra la VRAM lo canta: con el arreglo, "
         "<b>0 bytes distintos de los 2.048</b> de patrones de sprite.</p>"),

        ("La geometria de la VRAM va al reves, y el RLE tambien",
         "<p>Los ocho bytes de <code>0x4720</code> son los registros del VDP, "
         "y colocan las tablas al reves de lo habitual: <b>el color abajo y "
         "los patrones arriba</b>. Color en <code>0x0000..0x17FF</code>, "
         "patrones de sprite en <code>0x1800</code>, patrones en "
         "<code>0x2000..0x37FF</code> y nombres en <code>0x3800</code>. Un "
         "<code>ld hl,00008h</code> en este cartucho no apunta a patrones: "
         "apunta al color.</p>"
         "<p>Y el descompresor tambien va al contrario de lo que parece. En "
         "<code>0x46A6</code>, <b>el bit 7 PUESTO es literal</b> y a cero es "
         "repeticion: lo decide a donde vuelve el <code>djnz</code>, si al "
         "<code>ld a,(de)</code> -y entonces relee- o al <code>out</code> -y "
         "entonces repite-.</p>"),

        ("La marca oculta de la casa, y el ano que dice el rotulo",
         "<p>Al final del cartucho, detras del relleno, esta el titulo en "
         "katakana escrito del reves y el numero de catalogo: "
         "<b>グーニーズ</b> y el <b>34</b> del <b>RC-734</b>. El hallazgo no "
         "es nuestro: lo destapo <b>Manuel Pazos</b> en 2021, y gracias a el "
         "se sabe que hay que mirar ahi. Este cartucho, ademas, deja atado un "
         "caracter que estaba sin confirmar: el <code>0xBA</code> solo cuadra "
         "si es el alargador.</p>"
         "<p>Y una cosa que dice el propio cartucho y no una ficha de fuera: "
         "el rotulo de la pantalla del titulo, dibujado desde la ROM, pone "
         "<b>© KONAMI 1986</b>, y debajo el aviso de marca de Warner Bros. de "
         "1985. El juego es de <b>1986</b>.</p>"),
    ],
    "en": [
        ("The four rooms of a level are not a column: they are a plan",
         "<p><code>empieza_el_nivel</code> (<code>0x4F82</code>) takes one "
         "byte per level from <code>0x9D67</code> and leaves it in "
         "<code>(0xE06A)</code>. That byte picks one of <b>nineteen</b> rows "
         "at <code>0x52DB</code>, four bytes, one per room.</p>"
         "<p>In each byte the <b>low nibble</b> is the room you pass into "
         "leaving through the left (<code>0xF</code>: none), and the "
         "<b>high one is THE POSITION</b> of that room in the plan. That it "
         "is the position is settled by the chaser: <code>0x74C0</code> "
         "compares that nibble with <code>0xC0</code> -the top two bits- to "
         "decide whether to move horizontally, and <code>0x74C4</code> with "
         "<code>0x30</code> -the bottom two- for the vertical. So the nibble "
         "is <b>column times four plus row</b>.</p>"
         "<p>Out come the arrangements: five levels in a column, two in a "
         "row, six as 2x2 and <b>fourteen odd-shaped</b>. And it fits "
         "everything else: <code>0x5327</code> gives the room to the right, "
         "and the ones above and below are the current one minus and plus "
         "one -the <code>dec b</code> at <code>0x529A</code> and the two "
         "<code>inc b</code> at <code>0x52A2</code>-.</p>"
         "<p>The proof that the arrangement is right is in the picture: put "
         "together like this, <b>platforms and ladders carry on from one "
         "room into the next</b>, and the water at the bottom runs through. "
         "All twenty-five maps in <a href=\"THE-LEVELS.html\">The 100 "
         "rooms</a> are redrawn with it.</p>"),

        ("All 64 skull doors pair up without a single exception",
         "<p>Each skull door is three bytes, and out of the third "
         "<code>0x8DA8</code> takes <b>two things</b>: the low six bits are "
         "the level it leads to and the <b>top two the ENTRANCE</b>, which is "
         "the number of the door you come out of over there.</p>"
         "<p>That turns the doors into checkable pairs: if door <i>j</i> of "
         "level A says (B, <i>k</i>), then door <i>k</i> of level B has to "
         "say (A, <i>j</i>). <b>All 64 in the cartridge do</b>, without one "
         "exception, and on top of that <b>none leaves its round</b>: the 25 "
         "levels are five closed groups of five.</p>"),

        ("The name of the round IS its password",
         "<p>You can type on the title screen. Letters pile up at "
         "<code>0xE4C0</code> and <code>0x5444</code> matches them against "
         "five sixteen-byte names, laid out nineteen bytes apart from "
         "<code>0x546E</code>: <b>MR SLOTH</b> takes you to round 2, <b>GOON "
         "DOCKS</b> to 3, <b>DOUBLOON</b> to 4, <b>ONE EYED WILLY</b> to 5 and "
         "<b>GOONIES</b> to 1.</p>"
         "<p>And those very same bytes are also the script that paints the "
         "round's name when it starts. There are not two tables: there is one. "
         "On finishing a round, <code>0x53A7</code> shows you, under the "
         "<code>KEYWORD</code> caption, the name you have just left behind - "
         "which is exactly what you type to come back.</p>"
         "<p>The fifth is the only one without a closing <code>0xFF</code>, "
         "and that fits: <b>ONE EYED WILLY</b> is the round you reach, never "
         "one that gets announced.</p>"),

        ("Sixty-four thousand tiles in under three thousand bytes",
         "<p>The twenty-five levels are four rooms each, and every room is "
         "32x20 tiles: <b>64,000 tiles</b> altogether. All of it fits in "
         "<b>2,983 bytes</b> - about <b>twenty-one tiles per byte</b>.</p>"
         "<p>Three layers do it. A level is eighty bytes, four columns by "
         "twenty rows, and each byte points at an <b>8x4 tile block</b> in the "
         "table at <code>0x5B65</code>, which holds a hundred and eight. "
         "<b>Bit 7 of the byte asks for the block mirrored</b>, and that is "
         "used 615 times out of 2,000. And the hundred and eight blocks "
         "<b>share tails</b>: counting every byte once they take 717 rather "
         "than 841, because some start inside others.</p>"
         "<p>All hundred and eight are used. Not one is spare.</p>"),

        ("The twenty-seven ways to uncover a hidden item",
         "<p>The longest table in the cartridge is the one at "
         "<code>0x6DBD</code>: <b>twenty-seven</b> entries, one per condition "
         "that uncovers one of the hidden items. Hit the same spot twice in a "
         "row; kick once to each side; stand still for <code>0x60</code> "
         "frames; keep both bars above <code>0x28</code>; kick the rolling "
         "boulder, or the flame...</p>"
         "<p>Nearly all of them lean on <code>(0xE126)</code> and "
         "<code>(0xE127)</code>, which hold <b>the player's last two hits</b>, "
         "kept up to date by <code>0x8005</code>.</p>"
         "<p>And none is spare: walking the lists of all twenty-five levels "
         "turns up <b>twenty-seven hidden items with twenty-seven distinct "
         "indices, 0 to 26</b>. Twenty-three levels carry one and two carry "
         "two, levels 5 and 16.</p>"
         "<p>All twenty-seven, mind you, look exactly alike: a single tile, "
         "<code>0x91</code>, blinking.</p>"),

        ("Items are shields with charges, not trophies",
         "<p>The list at <code>0x7D9B</code> is eight bytes, one per hazard - "
         "water jet, stalactite, drip, flame, rising column, pipe leak and "
         "boulder - and it says <b>which inventory item stops each one</b>. "
         "Carrying it, the hit does not take energy: it spends <b>one "
         "charge</b> of <code>(0xE150+item)</code>, and when they run out the "
         "item vanishes from the inventory.</p>"
         "<p>The energy bar is sixteen bits - <code>(0xE063)</code> the "
         "fraction, <code>(0xE064)</code> what you see - and it is drawn to "
         "<b>one eighth of a tile</b>.</p>"
         "<p>There are twenty-three items, and the table at <code>0x5576</code> "
         "says which level each is in: twenty-three distinct values between 0 "
         "and 24, and <b>5 and 14 are exactly the ones missing</b>. Levels 6 "
         "and 15 are the only two with no item.</p>"),

        ("The chaser counts tiles to pick a rope",
         "<p>When the chaser wants to change height, <code>0x756D</code> walks "
         "its row <b>tile by tile in both directions</b>, counting how many "
         "there are until it hits <code>0x41</code> - the foot of a rope - or "
         "<code>0x53</code> - the head - and it heads for the shorter "
         "count.</p>"
         "<p>There is a nice detail: <b>bit 0 of <code>(ix+00Fh)</code></b> "
         "decides which side is tried first, and it is consumed by rotating it "
         "on each query. That is why two identical chasers on the same row "
         "<b>do not both make for the same rope</b>.</p>"
         "<p>The green ropes are the same for everyone: the player climbs "
         "<code>0x41</code> pressing up and goes down <code>0x53</code> "
         "pressing down (<code>0x66E4</code>), and the creatures use those "
         "two.</p>"),

        ("The demo is a recorded game",
         "<p><code>0x5206</code> jumps into <code>0x4730</code>, the byte "
         "<b>after</b> the <code>call</code> that really reads the joystick, "
         "with the accumulator already loaded from a table. So the input "
         "routine runs from halfway through, and what it hands back nobody "
         "pressed.</p>"
         "<p>It is <b>34 joystick states</b> at <code>0x520E</code> - plus the "
         "closing <code>0xFF</code> - and their <b>34 durations</b> at "
         "<code>0x5231</code>. The demo always does exactly the same thing, "
         "and that is what makes it possible to check VRAM from a cold boot, "
         "with no savestates and no breakpoints.</p>"),

        ("The water keeps a notebook of what it covers",
         "<p>The water jet runs down the room standing on tiles. So it can "
         "retract without leaving holes, whenever it meets an occupied tile it "
         "<b>writes down at <code>0xE1D0</code> the row and the three tiles "
         "that were there</b>, and puts them back on the way out. The map is "
         "never touched: the map is read-only and only the screen changes.</p>"
         "<p>The current, on the other hand, moves nothing at all: "
         "<code>0x854E</code> rewrites <b>three patterns</b> - tiles "
         "<code>0x6D</code>, <code>0xCF</code> and <code>0xF1</code> - across "
         "all three banks, swapping two sixteen-byte batches with <b>bit 2 of "
         "the frame counter</b>. The water appears to flow and not one tile on "
         "screen has changed.</p>"),

        ("Half the artwork is manufactured at boot",
         "<p>Of the 42 16x16 sprite patterns the cartridge carries, <b>22 are "
         "not drawn</b>: they are made by mirroring the others. Same with "
         "tiles: 34 are made by reversing the eight bits of another 34.</p>"
         "<p>Mirroring a 16x16 sprite is not just flipping bits - you must "
         "<b>swap its two columns</b>. The cartridge does it with an "
         "<code>inc e</code> and a <code>sub 020h</code> on the low byte of "
         "the address (<code>0x46E6</code>), entering with the destination "
         "already pointing at the second half. Getting that wrong gives you "
         "figures split down the middle, and the VRAM check says so plainly: "
         "with the fix, <b>0 bytes different out of the 2,048</b> of sprite "
         "patterns.</p>"),

        ("VRAM geometry is upside down, and so is the RLE",
         "<p>The eight bytes at <code>0x4720</code> are the VDP registers, and "
         "they lay the tables out the wrong way round: <b>colour low and "
         "patterns high</b>. Colour at <code>0x0000..0x17FF</code>, sprite "
         "patterns at <code>0x1800</code>, patterns at "
         "<code>0x2000..0x37FF</code> and names at <code>0x3800</code>. An "
         "<code>ld hl,00008h</code> in this cartridge does not point at "
         "patterns: it points at colour.</p>"
         "<p>And the decompressor runs backwards from what it looks like too. "
         "At <code>0x46A6</code>, <b>bit 7 SET means literal</b> and clear "
         "means run: it is decided by where the <code>djnz</code> jumps back "
         "to, the <code>ld a,(de)</code> - so it re-reads - or the "
         "<code>out</code> - so it repeats.</p>"),

        ("The house's hidden mark, and the year the caption gives",
         "<p>At the end of the cartridge, behind the padding, sits the title "
         "in katakana written backwards along with the catalogue number: "
         "<b>グーニーズ</b> and the <b>34</b> of <b>RC-734</b>. The finding is "
         "not ours: <b>Manuel Pazos</b> uncovered it in 2021, and it is thanks "
         "to him that anyone knows to look there. This cartridge also pins "
         "down a character that was still unconfirmed: <code>0xBA</code> only "
         "works out as the long-vowel mark.</p>"
         "<p>And something the cartridge itself says, rather than an outside "
         "catalogue entry: the title-screen caption, drawn from the ROM, reads "
         "<b>© KONAMI 1986</b>, with the 1985 Warner Bros. trademark notice "
         "below it. The game is from <b>1986</b>.</p>"),
    ],
}

GALERIA = [
    ("rotulo.png",
     "La pantalla del titulo, montada paso a paso como la monta el cartucho: "
     "la fuente, el cartel de la presentacion debajo, el rotulo descomprimido "
     "en los tres bancos de patrones y sus casillas escritas una a una. "
     "Cotejada contra la VRAM de openMSX: <b>cero</b> bytes distintos en "
     "color, patrones, patrones de sprite <b>y en las 768 casillas de la "
     "tabla de nombres</b>.",
     "The title screen, built step by step the way the cartridge builds it: "
     "the font, the intro sign underneath, the lettering decompressed into all "
     "three pattern banks and its tiles written one by one. Checked against "
     "openMSX's VRAM: <b>zero</b> bytes different in colour, patterns, sprite "
     "patterns <b>and across all 768 tiles of the name table</b>."),

    ("mapa-nivel-01.png",
     "El nivel 1 entero: sus cuatro salas de 32x20 casillas, descomprimidas "
     "desde los ochenta bytes del mapa, con todo lo que el cartucho planta "
     "encima puesto donde lo planta -las jaulas, la puerta de la calavera, la "
     "puerta al nivel siguiente, las estalactitas, las calaveras, las goteras "
     "y el objeto escondido-. Los rotulos van escritos con la fuente del "
     "propio cartucho.",
     "The whole of level 1: its four 32x20 tile rooms, decompressed from the "
     "eighty bytes of the map, with everything the cartridge puts on top "
     "placed exactly where it puts it - the cages, the skull door, the door to "
     "the next level, the stalactites, the skulls, the drips and the hidden "
     "item. The captions are written in the cartridge's own font."),

    ("objetos.png",
     "Los veintitres objetos del inventario, cada uno con el nivel en el que "
     "aparece debajo. El icono no se guarda como imagen: la tabla de "
     "<code>0x6F68</code> da UNA casilla por objeto y el juego coge esa y las "
     "tres de detras para montar un 2x2 en la fila de abajo. Los niveles 6 y "
     "15 no salen en la lista: son los dos sin objeto.",
     "The twenty-three inventory items, each with the level it appears in "
     "underneath. The icon is not stored as a picture: the table at "
     "<code>0x6F68</code> gives ONE tile per item and the game takes that one "
     "and the next three to build a 2x2 on the bottom row. Levels 6 and 15 do "
     "not show up in the list: they are the two with no item."),

    ("jugador.png",
     "Las dieciseis posturas del jugador, compuestas y en color. Un sprite del "
     "MSX1 no lleva color dentro -va en su atributo-, asi que cada postura son "
     "varios sprites de 16x16 superpuestos, cada uno con el suyo. La fila de "
     "abajo son los mismos espejados, y esos veintidos patrones no estan en la "
     "ROM: los fabrica el cartucho al arrancar.",
     "The player's sixteen poses, composed and in colour. An MSX1 sprite "
     "carries no colour of its own - that lives in its attribute - so each "
     "pose is several overlapping 16x16 sprites, each with its own. The bottom "
     "row is the same mirrored, and those twenty-two patterns are not in the "
     "ROM at all: the cartridge manufactures them at boot."),

    ("bichos.png",
     "Los patrones de sprite de un solo cuadrado, en los seis colores que usa "
     "el juego. El color no esta en el dibujo: sale del atributo, y por eso el "
     "mismo patron aparece seis veces. Los murcielagos, las calaveras y el "
     "bicho de patas salen de aqui.",
     "The single-square sprite patterns, in the six colours the game uses. The "
     "colour is not in the drawing: it comes from the attribute, which is why "
     "the same pattern shows up six times over. The bats, the skulls and the "
     "many-legged creature all come from here."),

    ("puertas-y-jaulas.png",
     "La puerta de la calavera -que solo se abre con los siete amigos "
     "sueltos-, la puerta al nivel siguiente y las cuatro jaulas: cerrada, "
     "abierta, con el amigo dentro y con el objeto dentro. Cada una es un "
     "bloque de casillas del cartucho, sin retocar.",
     "The skull door - which opens only once all seven friends are freed - the "
     "door to the next level, and the four cages: shut, open, with the friend "
     "inside and with the item inside. Each is a tile block straight out of "
     "the cartridge, untouched."),

    ("ronda-1.png",
     "Los cinco niveles de la ronda 1 y sus puertas de calavera. Cada nivel "
     "va con el reparto de salas que le da 0x52DB, y cada raya une DOS "
     "puertas que se emparejan de verdad: la puerta j del nivel A dice "
     "(B, k) y la puerta k del nivel B dice (A, j). Las 64 del cartucho "
     "emparejan asi, y ninguna sale de su ronda.",
     "The five levels of round 1 and their skull doors. Each level is laid "
     "out with the room arrangement 0x52DB gives it, and every line joins "
     "TWO doors that really pair up: door j of level A says (B, k) and door "
     "k of level B says (A, j). All 64 in the cartridge pair up like that, "
     "and none leaves its round."),

    ("mapa-nivel-08.png",
     "El nivel 8, uno de los que no son ni una fila ni un 2x2: la sala 1 "
     "arriba a la izquierda y las otras tres en fila debajo. Las escaleras y "
     "las plataformas siguen de una sala a la de al lado, que es la prueba de "
     "que el reparto de 0x52DB es el bueno.",
     "Level 8, one of those that are neither a row nor a 2x2: room 1 at the "
     "top left and the other three in a row below. Ladders and platforms "
     "carry on from one room into the next, which is the proof that the "
     "arrangement at 0x52DB is the right one."),

    ("mapa-nivel-13.png",
     "El nivel 13, uno de los tres que llevan el bicho de patas: el que espera "
     "escondido en una casilla de 8x8 hasta que el jugador la pisa. Se ve "
     "tambien el agua, que tapa lo que hay debajo y se lo apunta para "
     "devolverlo al recogerse.",
     "Level 13, one of the three that carry the many-legged creature: the one "
     "that lies hidden in an 8x8 box until the player steps on it. You can "
     "also see the water, which covers what is beneath it and writes it down "
     "so it can put it back when it retracts."),

    ("mapa-nivel-25.png",
     "El nivel 25, el ultimo: treinta y dos columnas que crecen, ocho "
     "estalactitas, tres bolas de piedra y tres perseguidores repartidos por "
     "las cuatro salas. Es el nivel con mas columnas del cartucho, con "
     "diferencia.",
     "Level 25, the last one: thirty-two rising columns, eight stalactites, "
     "three boulders and three chasers spread across the four rooms. It is by "
     "some distance the level with the most columns in the cartridge."),

    ("casillas.png",
     "Las 256 casillas del nivel 1 en sus tres bancos, una debajo de otra. "
     "SCREEN 2 tiene tres juegos de colores independientes, uno por tercio de "
     "pantalla, y por eso el mismo dibujo sale de tres colores segun donde "
     "caiga. Aqui estan las tres versiones, tal como quedan en la VRAM.",
     "The 256 tiles of level 1 in their three banks, one under the other. "
     "SCREEN 2 has three independent colour sets, one per third of the screen, "
     "which is why the same drawing comes out in three colours depending on "
     "where it lands. Here are all three versions, exactly as they sit in "
     "VRAM."),
]
