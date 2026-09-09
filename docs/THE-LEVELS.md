# The 100 rooms

Here are **all one hundred rooms** in the cartridge, one by one. Twenty-five
levels of four rooms each, and **not one repeats**: compared tile by tile, all
hundred come out different. Every one drawn from the bytes of the ROM, not a
single capture.

Each room is 32x20 tiles coming out of eighty bytes that point at 8x4 blocks;
they get decompressed, and then on top goes - at the exact spot the cartridge
puts it - every item from the level's two lists: the cages, the doors, the
hazards, the creatures and the hidden item.

The **64,000 tiles** you see here fit in **2,983 bytes** of cartridge. How, is
worked out in [The code](THE-CODE.html).

Under each room is what it carries, counted by walking the lists with the same
rules the Z80 uses. The captions are written in the cartridge's own font.

And they are not on their own. Before each level comes **the whole plan**, with
the four rooms placed where the cartridge places them: the arrangement `0x52DB`
gives it, which is not the same for all - there are columns, rows, 2x2 and
fourteen odd shapes. Put together like this, platforms and ladders carry on
from one room into the next. Before each round comes **the minimap of its five
levels**, with the skull doors joined up.

## Round 1 — levels 1 to 5

![Round 1](imagenes/ronda-1.png)

*The five levels of round 1 and their skull doors. Each level is laid out with the room arrangement 0x52DB gives it, and every line joins TWO doors that really pair up: door j of level A says (B, k) and door k of level B says (A, j). All 64 in the cartridge pair up like that, and none leaves its round. Two things in this picture do NOT come from the ROM, so they are said out loud: where each level sits on the ring -of the twelve possible orders the one with fewest crossings is picked- and the bow of the curves, which separates the pairs of levels joined by TWO doors.*

### Level 1

![Level 1](imagenes/mapa-nivel-01.png)

*The four rooms of level 1, placed where the cartridge places them: a column of four. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 1 room 1](imagenes/sala-01-1.png)

*Level 1, room 1. It carries: 2 stalactite, 2 drip, 1 blinking pickup, 1 cage, 1 hidden item, 1 skull door, 1 skull.*

![Level 1 room 2](imagenes/sala-01-2.png)

*Level 1, room 2. It carries: 2 skull, 1 stalactite, 1 blinking pickup, 1 water jet, 1 drip.*

![Level 1 room 3](imagenes/sala-01-3.png)

*Level 1, room 3. It carries: 3 stalactite, 3 skull, 2 drip, 1 chaser, 1 blinking pickup, 1 cage, 1 boulder.*

![Level 1 room 4](imagenes/sala-01-4.png)

*Level 1, room 4. It carries: 3 skull, 2 stalactite, 2 door to the next level, 1 blinking pickup, 1 cage, 1 drip.*

### Level 2

![Level 2](imagenes/mapa-nivel-02.png)

*The four rooms of level 2, placed where the cartridge places them: a row of four. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 2 room 1](imagenes/sala-02-1.png)

*Level 2, room 1. It carries: 1 chaser, 1 door to the next level, 1 cage, 1 hidden item.*

![Level 2 room 2](imagenes/sala-02-2.png)

*Level 2, room 2. It carries: 2 stalactite, 2 skull, 1 blinking pickup, 1 cage.*

![Level 2 room 3](imagenes/sala-02-3.png)

*Level 2, room 3. It carries: 3 skull, 1 blinking pickup, 1 cage, 1 drip.*

![Level 2 room 4](imagenes/sala-02-4.png)

*Level 2, room 4. It carries: 2 skull, 1 door to the next level, 1 blinking pickup, 1 drip.*

### Level 3

![Level 3](imagenes/mapa-nivel-03.png)

*The four rooms of level 3, placed where the cartridge places them: 2x2. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 3 room 1](imagenes/sala-03-1.png)

*Level 3, room 1. It carries: 6 pipe leak, 1 stalactite, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 drip.*

![Level 3 room 2](imagenes/sala-03-2.png)

*Level 3, room 2. It carries: 3 pipe leak, 2 stalactite, 1 cage, 1 drip, 1 skull.*

![Level 3 room 3](imagenes/sala-03-3.png)

*Level 3, room 3. It carries: 4 pipe leak, 2 stalactite, 2 blinking pickup, 2 skull, 1 door to the next level, 1 water jet.*

![Level 3 room 4](imagenes/sala-03-4.png)

*Level 3, room 4. It carries: 3 pipe leak, 3 drip, 1 door to the next level, 1 blinking pickup, 1 hidden item, 1 water jet, 1 skull.*

### Level 4

![Level 4](imagenes/mapa-nivel-04.png)

*The four rooms of level 4, placed where the cartridge places them: 3x2, `--3 / 124`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 4 room 1](imagenes/sala-04-1.png)

*Level 4, room 1. It carries: 2 blinking pickup, 2 drip, 2 skull, 1 stalactite, 1 chaser, 1 door to the next level, 1 boulder.*

![Level 4 room 2](imagenes/sala-04-2.png)

*Level 4, room 2. It carries: 2 stalactite, 2 drip, 2 skull, 1 cage, 1 boulder.*

![Level 4 room 3](imagenes/sala-04-3.png)

*Level 4, room 3. It carries: 3 blinking pickup, 3 drip, 2 skull, 1 stalactite, 1 door to the next level.*

![Level 4 room 4](imagenes/sala-04-4.png)

*Level 4, room 4. It carries: 2 cage, 2 skull, 1 stalactite, 1 chaser, 1 hidden item, 1 drip, 1 bat.*

### Level 5

![Level 5](imagenes/mapa-nivel-05.png)

*The four rooms of level 5, placed where the cartridge places them: 2x3, `1- / 2- / 34`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 5 room 1](imagenes/sala-05-1.png)

*Level 5, room 1. It carries: 2 water jet, 1 door to the next level, 1 blinking pickup, 1 hidden item, 1 drip, 1 skull.*

![Level 5 room 2](imagenes/sala-05-2.png)

*Level 5, room 2. It carries: 2 stalactite, 1 blinking pickup, 1 cage, 1 hidden item, 1 water jet, 1 drip, 1 bat.*

![Level 5 room 3](imagenes/sala-05-3.png)

*Level 5, room 3. It carries: 6 stalactite, 2 drip, 1 door to the next level, 1 boulder, 1 skull.*

![Level 5 room 4](imagenes/sala-05-4.png)

*Level 5, room 4. It carries: 4 drip, 2 blinking pickup, 2 skull, 1 chaser, 1 door to the next level, 1 cage, 1 skull door.*

## Round 2 — levels 6 to 10

![Round 2](imagenes/ronda-2.png)

*The five levels of round 2 and their skull doors. Each level is laid out with the room arrangement 0x52DB gives it, and every line joins TWO doors that really pair up: door j of level A says (B, k) and door k of level B says (A, j). All 64 in the cartridge pair up like that, and none leaves its round. Two things in this picture do NOT come from the ROM, so they are said out loud: where each level sits on the ring -of the twelve possible orders the one with fewest crossings is picked- and the bow of the curves, which separates the pairs of levels joined by TWO doors.*

### Level 6

![Level 6](imagenes/mapa-nivel-06.png)

*The four rooms of level 6, placed where the cartridge places them: 3x2, `124 / -3-`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 6 room 1](imagenes/sala-06-1.png)

*Level 6, room 1. It carries: 6 rising column, 3 drip, 2 boulder, 1 chaser, 1 door to the next level, 1 cage, 1 skull door, 1 skull.*

![Level 6 room 2](imagenes/sala-06-2.png)

*Level 6, room 2. It carries: 2 chaser, 2 skull, 1 blinking pickup, 1 cage, 1 bat.*

![Level 6 room 3](imagenes/sala-06-3.png)

*Level 6, room 3. It carries: 2 blinking pickup, 2 drip, 1 chaser, 1 door to the next level, 1 cage, 1 hidden item, 1 skull.*

![Level 6 room 4](imagenes/sala-06-4.png)

*Level 6, room 4. It carries: 6 rising column, 3 skull, 2 stalactite, 2 drip, 1 door to the next level, 1 blinking pickup, 1 bat.*

### Level 7

![Level 7](imagenes/mapa-nivel-07.png)

*The four rooms of level 7, placed where the cartridge places them: 2x3, `1- / 23 / -4`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 7 room 1](imagenes/sala-07-1.png)

*Level 7, room 1. It carries: 4 stalactite, 4 drip, 2 boulder, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 hidden item.*

![Level 7 room 2](imagenes/sala-07-2.png)

*Level 7, room 2. It carries: 3 stalactite, 3 drip, 2 boulder, 1 chaser, 1 blinking pickup, 1 cage, 1 skull.*

![Level 7 room 3](imagenes/sala-07-3.png)

*Level 7, room 3. It carries: 3 stalactite, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 water jet, 1 boulder, 1 skull.*

![Level 7 room 4](imagenes/sala-07-4.png)

*Level 7, room 4. It carries: 1 stalactite, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 water jet, 1 drip.*

### Level 8

![Level 8](imagenes/mapa-nivel-08.png)

*The four rooms of level 8, placed where the cartridge places them: 3x2, `1-- / 234`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 8 room 1](imagenes/sala-08-1.png)

*Level 8, room 1. It carries: 6 rising column, 3 stalactite, 2 drip, 2 skull, 1 chaser, 1 blinking pickup, 1 cage.*

![Level 8 room 2](imagenes/sala-08-2.png)

*Level 8, room 2. It carries: 6 rising column, 4 drip, 1 stalactite, 1 chaser, 1 blinking pickup, 1 hidden item, 1 skull, 1 bat.*

![Level 8 room 3](imagenes/sala-08-3.png)

*Level 8, room 3. It carries: 2 stalactite, 2 drip, 2 skull, 1 chaser, 1 door to the next level, 1 cage.*

![Level 8 room 4](imagenes/sala-08-4.png)

*Level 8, room 4. It carries: 2 blinking pickup, 2 boulder, 1 chaser, 1 door to the next level, 1 cage.*

### Level 9

![Level 9](imagenes/mapa-nivel-09.png)

*The four rooms of level 9, placed where the cartridge places them: 2x2. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 9 room 1](imagenes/sala-09-1.png)

*Level 9, room 1. It carries: 7 pipe leak, 2 drip, 1 stalactite, 1 chaser, 1 blinking pickup, 1 cage, 1 skull door, 1 skull.*

![Level 9 room 2](imagenes/sala-09-2.png)

*Level 9, room 2. It carries: 7 pipe leak, 1 stalactite, 1 door to the next level, 1 drip, 1 skull.*

![Level 9 room 3](imagenes/sala-09-3.png)

*Level 9, room 3. It carries: 5 pipe leak, 2 blinking pickup, 2 skull, 1 chaser, 1 door to the next level, 1 hidden item.*

![Level 9 room 4](imagenes/sala-09-4.png)

*Level 9, room 4. It carries: 7 pipe leak, 2 chaser, 1 stalactite, 1 blinking pickup, 1 cage, 1 drip, 1 skull.*

### Level 10

![Level 10](imagenes/mapa-nivel-10.png)

*The four rooms of level 10, placed where the cartridge places them: a column of four. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 10 room 1](imagenes/sala-10-1.png)

*Level 10, room 1. It carries: 2 drip, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 boulder.*

![Level 10 room 2](imagenes/sala-10-2.png)

*Level 10, room 2. It carries: 2 water jet, 1 blinking pickup, 1 drip.*

![Level 10 room 3](imagenes/sala-10-3.png)

*Level 10, room 3. It carries: 2 water jet, 1 stalactite, 1 cage, 1 drip, 1 bat.*

![Level 10 room 4](imagenes/sala-10-4.png)

*Level 10, room 4. It carries: 1 stalactite, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 hidden item, 1 boulder, 1 drip, 1 bat.*

## Round 3 — levels 11 to 15

![Round 3](imagenes/ronda-3.png)

*The five levels of round 3 and their skull doors. Each level is laid out with the room arrangement 0x52DB gives it, and every line joins TWO doors that really pair up: door j of level A says (B, k) and door k of level B says (A, j). All 64 in the cartridge pair up like that, and none leaves its round. Two things in this picture do NOT come from the ROM, so they are said out loud: where each level sits on the ring -of the twelve possible orders the one with fewest crossings is picked- and the bow of the curves, which separates the pairs of levels joined by TWO doors.*

### Level 11

![Level 11](imagenes/mapa-nivel-11.png)

*The four rooms of level 11, placed where the cartridge places them: 3x2, `-2- / 134`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 11 room 1](imagenes/sala-11-1.png)

*Level 11, room 1. It carries: 2 stalactite, 1 chaser, 1 door to the next level, 1 cage.*

![Level 11 room 2](imagenes/sala-11-2.png)

*Level 11, room 2. It carries: 2 chaser, 2 boulder, 1 blinking pickup, 1 skull door, 1 drip, 1 skull, 1 bat.*

![Level 11 room 3](imagenes/sala-11-3.png)

*Level 11, room 3. It carries: 2 skull, 1 blinking pickup, 1 drip, 1 bat.*

![Level 11 room 4](imagenes/sala-11-4.png)

*Level 11, room 4. It carries: 6 rising column, 3 skull, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 hidden item, 1 boulder, 1 drip, 1 bat.*

### Level 12

![Level 12](imagenes/mapa-nivel-12.png)

*The four rooms of level 12, placed where the cartridge places them: 2x3, `14 / 2- / 3-`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 12 room 1](imagenes/sala-12-1.png)

*Level 12, room 1. It carries: 4 stalactite, 2 blinking pickup, 2 skull, 1 chaser, 1 door to the next level, 1 boulder, 1 drip.*

![Level 12 room 2](imagenes/sala-12-2.png)

*Level 12, room 2. It carries: 1 blinking pickup, 1 drip.*

![Level 12 room 3](imagenes/sala-12-3.png)

*Level 12, room 3. It carries: 6 rising column, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 hidden item, 1 drip, 1 skull.*

![Level 12 room 4](imagenes/sala-12-4.png)

*Level 12, room 4. It carries: 4 skull, 3 stalactite, 1 chaser, 1 door to the next level, 1 cage.*

### Level 13

![Level 13](imagenes/mapa-nivel-13.png)

*The four rooms of level 13, placed where the cartridge places them: 2x2. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 13 room 1](imagenes/sala-13-1.png)

*Level 13, room 1. It carries: 3 stalactite, 2 drip, 2 skull, 1 door to the next level, 1 blinking pickup, 1 many-legged creature.*

![Level 13 room 2](imagenes/sala-13-2.png)

*Level 13, room 2. It carries: 2 skull, 1 stalactite, 1 chaser, 1 blinking pickup, 1 cage, 1 drip, 1 bat.*

![Level 13 room 3](imagenes/sala-13-3.png)

*Level 13, room 3. It carries: 3 stalactite, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 water jet, 1 drip, 1 skull.*

![Level 13 room 4](imagenes/sala-13-4.png)

*Level 13, room 4. It carries: 2 stalactite, 2 drip, 2 skull, 1 blinking pickup, 1 cage, 1 hidden item, 1 water jet.*

### Level 14

![Level 14](imagenes/mapa-nivel-14.png)

*The four rooms of level 14, placed where the cartridge places them: 3x2, `123 / --4`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 14 room 1](imagenes/sala-14-1.png)

*Level 14, room 1. It carries: 2 pipe leak, 1 stalactite, 1 door to the next level, 1 flame.*

![Level 14 room 2](imagenes/sala-14-2.png)

*Level 14, room 2. It carries: 4 pipe leak, 1 stalactite, 1 chaser, 1 blinking pickup, 1 cage, 1 skull, 1 bat.*

![Level 14 room 3](imagenes/sala-14-3.png)

*Level 14, room 3. It carries: 5 pipe leak, 2 stalactite, 2 blinking pickup, 2 flame, 2 skull, 1 chaser, 1 cage, 1 skull door, 1 drip.*

![Level 14 room 4](imagenes/sala-14-4.png)

*Level 14, room 4. It carries: 4 pipe leak, 3 stalactite, 2 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 hidden item, 1 skull, 1 bat.*

### Level 15

![Level 15](imagenes/mapa-nivel-15.png)

*The four rooms of level 15, placed where the cartridge places them: a column of four. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 15 room 1](imagenes/sala-15-1.png)

*Level 15, room 1. It carries: 4 stalactite, 1 chaser, 1 door to the next level, 1 hidden item, 1 drip.*

![Level 15 room 2](imagenes/sala-15-2.png)

*Level 15, room 2. It carries: 3 stalactite, 2 drip, 1 chaser, 1 blinking pickup.*

![Level 15 room 3](imagenes/sala-15-3.png)

*Level 15, room 3. It carries: 2 boulder, 1 stalactite, 1 door to the next level, 1 blinking pickup, 1 cage, 1 drip.*

![Level 15 room 4](imagenes/sala-15-4.png)

*Level 15, room 4. It carries: 2 drip, 1 chaser, 1 door to the next level, 1 cage, 1 bat.*

## Round 4 — levels 16 to 20

![Round 4](imagenes/ronda-4.png)

*The five levels of round 4 and their skull doors. Each level is laid out with the room arrangement 0x52DB gives it, and every line joins TWO doors that really pair up: door j of level A says (B, k) and door k of level B says (A, j). All 64 in the cartridge pair up like that, and none leaves its round. Two things in this picture do NOT come from the ROM, so they are said out loud: where each level sits on the ring -of the twelve possible orders the one with fewest crossings is picked- and the bow of the curves, which separates the pairs of levels joined by TWO doors.*

### Level 16

![Level 16](imagenes/mapa-nivel-16.png)

*The four rooms of level 16, placed where the cartridge places them: 2x3, `1- / 24 / 3-`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 16 room 1](imagenes/sala-16-1.png)

*Level 16, room 1. It carries: 1 stalactite, 1 door to the next level, 1 blinking pickup, 1 cage, 1 hidden item, 1 water jet, 1 boulder, 1 skull.*

![Level 16 room 2](imagenes/sala-16-2.png)

*Level 16, room 2. It carries: 2 stalactite, 2 chaser, 2 drip, 1 blinking pickup, 1 skull door, 1 bat.*

![Level 16 room 3](imagenes/sala-16-3.png)

*Level 16, room 3. It carries: 2 cage, 2 drip, 1 chaser, 1 door to the next level, 1 skull.*

![Level 16 room 4](imagenes/sala-16-4.png)

*Level 16, room 4. It carries: 2 water jet, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 hidden item.*

### Level 17

![Level 17](imagenes/mapa-nivel-17.png)

*The four rooms of level 17, placed where the cartridge places them: 2x2. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 17 room 1](imagenes/sala-17-1.png)

*Level 17, room 1. It carries: 8 pipe leak, 1 chaser, 1 door to the next level, 1 skull.*

![Level 17 room 2](imagenes/sala-17-2.png)

*Level 17, room 2. It carries: 1 stalactite, 1 blinking pickup, 1 cage, 1 boulder, 1 flame, 1 drip, 1 skull.*

![Level 17 room 3](imagenes/sala-17-3.png)

*Level 17, room 3. It carries: 6 rising column, 3 skull, 2 blinking pickup, 2 drip, 1 stalactite, 1 chaser, 1 door to the next level, 1 cage, 1 hidden item, 1 pipe leak, 1 bat.*

![Level 17 room 4](imagenes/sala-17-4.png)

*Level 17, room 4. It carries: 2 drip, 2 skull, 1 stalactite, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 flame, 1 pipe leak.*

### Level 18

![Level 18](imagenes/mapa-nivel-18.png)

*The four rooms of level 18, placed where the cartridge places them: 2x3, `-2 / 13 / -4`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 18 room 1](imagenes/sala-18-1.png)

*Level 18, room 1. It carries: 2 blinking pickup, 2 flame, 2 drip, 1 stalactite, 1 chaser, 1 door to the next level, 1 skull.*

![Level 18 room 2](imagenes/sala-18-2.png)

*Level 18, room 2. It carries: 2 flame, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 boulder, 1 drip, 1 bat.*

![Level 18 room 3](imagenes/sala-18-3.png)

*Level 18, room 3. It carries: 1 chaser, 1 hidden item, 1 skull door, 1 flame, 1 drip, 1 skull.*

![Level 18 room 4](imagenes/sala-18-4.png)

*Level 18, room 4. It carries: 3 flame, 2 cage, 1 chaser, 1 blinking pickup, 1 drip, 1 skull, 1 many-legged creature.*

### Level 19

![Level 19](imagenes/mapa-nivel-19.png)

*The four rooms of level 19, placed where the cartridge places them: a row of four. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 19 room 1](imagenes/sala-19-1.png)

*Level 19, room 1. It carries: 2 door to the next level, 1 stalactite, 1 chaser, 1 blinking pickup.*

![Level 19 room 2](imagenes/sala-19-2.png)

*Level 19, room 2. It carries: 1 chaser.*

![Level 19 room 3](imagenes/sala-19-3.png)

*Level 19, room 3. It carries: 2 chaser, 1 stalactite, 1 blinking pickup, 1 cage, 1 hidden item, 1 bat.*

![Level 19 room 4](imagenes/sala-19-4.png)

*Level 19, room 4. It carries: 2 blinking pickup, 2 water jet, 1 stalactite, 1 door to the next level, 1 cage, 1 drip, 1 bat.*

### Level 20

![Level 20](imagenes/mapa-nivel-20.png)

*The four rooms of level 20, placed where the cartridge places them: 2x3, `12 / -3 / -4`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 20 room 1](imagenes/sala-20-1.png)

*Level 20, room 1. It carries: 2 skull, 1 stalactite, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 flame, 1 drip.*

![Level 20 room 2](imagenes/sala-20-2.png)

*Level 20, room 2. It carries: 2 chaser, 2 blinking pickup, 1 water jet, 1 skull.*

![Level 20 room 3](imagenes/sala-20-3.png)

*Level 20, room 3. It carries: 3 cage, 1 stalactite, 1 door to the next level, 1 hidden item, 1 flame, 1 bat, 1 many-legged creature.*

![Level 20 room 4](imagenes/sala-20-4.png)

*Level 20, room 4. It carries: 1 stalactite, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 boulder.*

## Round 5 — levels 21 to 25

![Round 5](imagenes/ronda-5.png)

*The five levels of round 5 and their skull doors. Each level is laid out with the room arrangement 0x52DB gives it, and every line joins TWO doors that really pair up: door j of level A says (B, k) and door k of level B says (A, j). All 64 in the cartridge pair up like that, and none leaves its round. Two things in this picture do NOT come from the ROM, so they are said out loud: where each level sits on the ring -of the twelve possible orders the one with fewest crossings is picked- and the bow of the curves, which separates the pairs of levels joined by TWO doors.*

### Level 21

![Level 21](imagenes/mapa-nivel-21.png)

*The four rooms of level 21, placed where the cartridge places them: 3x2, `134 / 2--`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 21 room 1](imagenes/sala-21-1.png)

*Level 21, room 1. It carries: 2 drip, 1 stalactite, 1 chaser, 1 cage, 1 skull door, 1 skull.*

![Level 21 room 2](imagenes/sala-21-2.png)

*Level 21, room 2. It carries: 1 stalactite, 1 door to the next level, 1 cage, 1 water jet, 1 skull.*

![Level 21 room 3](imagenes/sala-21-3.png)

*Level 21, room 3. It carries: 4 blinking pickup, 2 chaser, 1 door to the next level, 1 hidden item.*

![Level 21 room 4](imagenes/sala-21-4.png)

*Level 21, room 4. It carries: 3 drip, 2 stalactite, 1 chaser, 1 cage, 1 skull.*

### Level 22

![Level 22](imagenes/mapa-nivel-22.png)

*The four rooms of level 22, placed where the cartridge places them: 2x3, `1- / 23 / -4`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 22 room 1](imagenes/sala-22-1.png)

*Level 22, room 1. It carries: 2 stalactite, 2 skull, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 flame, 1 drip.*

![Level 22 room 2](imagenes/sala-22-2.png)

*Level 22, room 2. It carries: 2 stalactite, 2 flame, 2 skull, 1 chaser, 1 blinking pickup, 1 hidden item, 1 boulder, 1 drip, 1 bat.*

![Level 22 room 3](imagenes/sala-22-3.png)

*Level 22, room 3. It carries: 2 stalactite, 2 flame, 2 drip, 2 skull, 1 door to the next level, 1 blinking pickup, 1 bat.*

![Level 22 room 4](imagenes/sala-22-4.png)

*Level 22, room 4. It carries: 3 stalactite, 2 chaser, 1 door to the next level, 1 cage, 1 boulder, 1 flame, 1 drip, 1 skull, 1 bat.*

### Level 23

![Level 23](imagenes/mapa-nivel-23.png)

*The four rooms of level 23, placed where the cartridge places them: 2x3, `-2 / 13 / -4`. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 23 room 1](imagenes/sala-23-1.png)

*Level 23, room 1. It carries: 2 stalactite, 2 drip, 1 chaser, 1 door to the next level, 1 cage.*

![Level 23 room 2](imagenes/sala-23-2.png)

*Level 23, room 2. It carries: 3 skull, 2 drip, 1 stalactite, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 bat.*

![Level 23 room 3](imagenes/sala-23-3.png)

*Level 23, room 3. It carries: 2 blinking pickup, 2 boulder, 1 chaser, 1 skull door, 1 drip, 1 skull, 1 bat.*

![Level 23 room 4](imagenes/sala-23-4.png)

*Level 23, room 4. It carries: 1 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 hidden item, 1 water jet, 1 many-legged creature.*

### Level 24

![Level 24](imagenes/mapa-nivel-24.png)

*The four rooms of level 24, placed where the cartridge places them: 2x2. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 24 room 1](imagenes/sala-24-1.png)

*Level 24, room 1. It carries: 4 pipe leak, 2 stalactite, 1 cage, 1 drip, 1 skull.*

![Level 24 room 2](imagenes/sala-24-2.png)

*Level 24, room 2. It carries: 3 pipe leak, 2 stalactite, 2 drip, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 hidden item, 1 skull.*

![Level 24 room 3](imagenes/sala-24-3.png)

*Level 24, room 3. It carries: 6 rising column, 6 pipe leak, 2 blinking pickup, 2 skull, 1 stalactite, 1 chaser, 1 door to the next level, 1 drip.*

![Level 24 room 4](imagenes/sala-24-4.png)

*Level 24, room 4. It carries: 2 pipe leak, 2 drip, 2 skull, 1 door to the next level, 1 cage.*

### Level 25

![Level 25](imagenes/mapa-nivel-25.png)

*The four rooms of level 25, placed where the cartridge places them: 2x2. The arrangement comes from the high nibble of 0x52DB, which is column times four plus row.*

![Level 25 room 1](imagenes/sala-25-1.png)

*Level 25, room 1. It carries: 8 rising column, 3 stalactite, 2 blinking pickup, 2 boulder, 1 chaser, 1 skull, 1 bat.*

![Level 25 room 2](imagenes/sala-25-2.png)

*Level 25, room 2. It carries: 2 drip, 1 stalactite, 1 door to the next level, 1 cage, 1 boulder, 1 skull, 1 many-legged creature.*

![Level 25 room 3](imagenes/sala-25-3.png)

*Level 25, room 3. It carries: 12 rising column, 3 stalactite, 2 drip, 2 skull, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 many-legged creature.*

![Level 25 room 4](imagenes/sala-25-4.png)

*Level 25, room 4. It carries: 12 rising column, 2 drip, 2 skull, 1 stalactite, 1 chaser, 1 door to the next level, 1 blinking pickup, 1 cage, 1 hidden item.*

