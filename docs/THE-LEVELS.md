# The map

Twenty-five levels of four rooms each: **one hundred rooms, and not one
repeats**. Compared tile by tile, all hundred come out different, and every one
is drawn from the bytes of the ROM, not a single capture.

Each room is 32x20 tiles that come out of eighty bytes pointing at 8x4 blocks;
they get decompressed, and on top goes - at the exact spot the cartridge puts
it - every item from the level's two lists: the cages, the doors, the hazards,
the creatures and the hidden item. The **64,000 tiles** fit in **2,983 bytes**
of cartridge; how, is worked out in [The code](THE-CODE.html).

The four rooms of a level are placed where the cartridge places them: the
arrangement `0x52DB` gives it, which is not the same for all - there are
columns, rows, 2x2 and fourteen odd shapes. Put together like this, platforms
and ladders carry on from one room into the next, so the rooms are drawn
touching, with no caption in between. The cages are drawn **open, showing what
they hold** - the friend or the potion - but with their padlocks on, which is a
picture the cartridge never paints: once open, a cage has no padlocks left.

Under each level goes only what the picture cannot say: how many keys there
are, what each cage holds, which item is hidden, and which level each skull
door leads to. Rooms are numbered in reading order of the arrangement: on a
2x2, room 1 is top left and room 4 bottom right.

Before each round comes **the minimap of its five levels**, at 1:1 so it can
be zoomed into, with the skull doors joined up. The lines run behind the
levels, so as not to spoil the rooms.

*This section was reworked after [issue
#3](https://github.com/antxiko/Goonies-disassembly/issues/3) by
**[theNestruo](https://github.com/theNestruo)**: the plan with no captions, the
cages open, the lists cut down to what the picture cannot say, and the minimaps
at 1:1 with the lines behind. Everything on this page comes from there.*

## Round 1 — levels 1 to 5

![Round 1](imagenes/ronda-1.png)

*The five levels of round 1 and their skull doors, at 1:1. Each level is laid out with the room arrangement 0x52DB gives it, and every line joins TWO doors that really pair up: door j of level A says (B, k) and door k of level B says (A, j). All 64 in the cartridge pair up like that, and none leaves its round. The lines run behind the levels; the yellow mark is the door. Two things in this picture do NOT come from the ROM, so they are said out loud: where each level sits on the ring -of the twelve possible orders the one with fewest crossings is picked- and the bow of the curves, which separates the pairs of levels joined by TWO doors.*

### Level 1

![Level 1](imagenes/mapa-nivel-01.png)

*Level 1, the four rooms in a row. Keys: four, one in room 1, one in room 2, one in room 3 and one in room 4. Cages: a potion behind one padlock in room 1, a friend behind one padlock in room 3 and a friend behind two padlocks in room 4. Hidden item: ![item 16](imagenes/objeto-16.png) in room 1. Skull doors: to level 2 from room 4 and to level 5 from room 4.*

### Level 2

![Level 2](imagenes/mapa-nivel-02.png)

*Level 2, the four rooms in a column. Keys: three, one in room 2, one in room 3 and one in room 4. Cages: a potion behind one padlock in room 1, a friend behind one padlock in room 2 and a friend behind one padlock in room 3. Hidden item: ![item 0](imagenes/objeto-00.png) in room 1. Skull doors: to level 1 from room 1 and to level 3 from room 4.*

### Level 3

![Level 3](imagenes/mapa-nivel-03.png)

*Level 3, the four rooms in a 2x2. Keys: four, one in room 1, two in room 3 and one in room 4. Cages: a friend behind two padlocks in room 1 and a potion behind one padlock in room 2. Hidden item: ![item 10](imagenes/objeto-10.png) in room 4. Skull doors: to level 2 from room 1, to level 5 from room 3, and to level 4 from room 4.*

### Level 4

![Level 4](imagenes/mapa-nivel-04.png)

*Level 4, the rooms laid out `-1 / -2 / 34`. Keys: five, two in room 1 and three in room 3. Cages: a potion behind one padlock in room 2, a friend behind one padlock in room 4 and a potion behind one padlock in room 4. Hidden item: ![item 9](imagenes/objeto-09.png) in room 4. Skull doors: to level 3 from room 1 and to level 5 from room 3.*

### Level 5

![Level 5](imagenes/mapa-nivel-05.png)

*Level 5, the rooms laid out `123 / --4`. Keys: four, one in room 1, one in room 2 and two in room 4. Cages: a friend behind two padlocks in room 2 and a potion behind two padlocks in room 4. Hidden items: ![item 17](imagenes/objeto-17.png) in room 1 and points in room 2. Skull doors: to level 1 from room 1, to level 3 from room 3, and to level 4 from room 4. Exit door: to level 6, the first of round 2, in room 4.*

## Round 2 — levels 6 to 10

![Round 2](imagenes/ronda-2.png)

*The five levels of round 2 and their skull doors, at 1:1. Each level is laid out with the room arrangement 0x52DB gives it, and every line joins TWO doors that really pair up: door j of level A says (B, k) and door k of level B says (A, j). All 64 in the cartridge pair up like that, and none leaves its round. The lines run behind the levels; the yellow mark is the door. Two things in this picture do NOT come from the ROM, so they are said out loud: where each level sits on the ring -of the twelve possible orders the one with fewest crossings is picked- and the bow of the curves, which separates the pairs of levels joined by TWO doors.*

### Level 6

![Level 6](imagenes/mapa-nivel-06.png)

*Level 6, the rooms laid out `1- / 23 / 4-`. Keys: four, one in room 2, two in room 3 and one in room 4. Cages: a potion behind one padlock in room 1, a friend behind two padlocks in room 2 and a potion behind one padlock in room 3. Hidden item: points in room 3. Skull doors: to level 7 from rooms 1 and 3, and to level 10 from room 4.*

### Level 7

![Level 7](imagenes/mapa-nivel-07.png)

*Level 7, the rooms laid out `12- / -34`. Keys: four, one in room 1, one in room 2, one in room 3 and one in room 4. Cages: a friend behind two padlocks in room 1, a potion behind one padlock in room 2 and a friend behind one padlock in room 4. Hidden item: ![item 18](imagenes/objeto-18.png) in room 1. Skull doors: to level 6 from rooms 1 and 3, and to level 8 from room 4.*

### Level 8

![Level 8](imagenes/mapa-nivel-08.png)

*Level 8, the rooms laid out `12 / -3 / -4`. Keys: four, one in room 1, one in room 2 and two in room 4. Cages: a potion behind one padlock in room 1, a potion behind one padlock in room 3 and a friend behind two padlocks in room 4. Hidden item: ![item 5](imagenes/objeto-05.png) in room 2. Skull doors: to level 7 from room 3 and to level 9 from room 4.*

### Level 9

![Level 9](imagenes/mapa-nivel-09.png)

*Level 9, the four rooms in a 2x2. Keys: four, one in room 1, two in room 3 and one in room 4. Cages: a friend behind one padlock in room 1 and a friend behind two padlocks in room 4. Hidden item: ![item 6](imagenes/objeto-06.png) in room 3. Skull doors: to level 8 from room 2 and to level 10 from room 3. Exit door: to level 11, the first of round 3, in room 1.*

### Level 10

![Level 10](imagenes/mapa-nivel-10.png)

*Level 10, the four rooms in a row. Keys: three, one in room 1, one in room 2 and one in room 4. Cages: a friend behind two padlocks in room 3. Hidden item: ![item 7](imagenes/objeto-07.png) in room 4. Skull doors: to level 6 from room 1 and to level 9 from room 4.*

## Round 3 — levels 11 to 15

![Round 3](imagenes/ronda-3.png)

*The five levels of round 3 and their skull doors, at 1:1. Each level is laid out with the room arrangement 0x52DB gives it, and every line joins TWO doors that really pair up: door j of level A says (B, k) and door k of level B says (A, j). All 64 in the cartridge pair up like that, and none leaves its round. The lines run behind the levels; the yellow mark is the door. Two things in this picture do NOT come from the ROM, so they are said out loud: where each level sits on the ring -of the twelve possible orders the one with fewest crossings is picked- and the bow of the curves, which separates the pairs of levels joined by TWO doors.*

### Level 11

![Level 11](imagenes/mapa-nivel-11.png)

*Level 11, the rooms laid out `-1 / 23 / -4`. Keys: three, one in room 2, one in room 3 and one in room 4. Cages: a friend behind two padlocks in room 1. Hidden item: ![item 3](imagenes/objeto-03.png) in room 4. Skull doors: to level 12 from room 1 and to level 15 from room 4.*

### Level 12

![Level 12](imagenes/mapa-nivel-12.png)

*Level 12, the rooms laid out `123 / 4--`. Keys: four, two in room 1, one in room 2 and one in room 3. Cages: a friend behind one padlock in room 3 and a friend behind one padlock in room 4. Hidden item: ![item 11](imagenes/objeto-11.png) in room 3. Skull doors: to level 11 from room 1, to level 13 from room 3, and to level 15 from room 4.*

### Level 13

![Level 13](imagenes/mapa-nivel-13.png)

*Level 13, the four rooms in a 2x2. Keys: four, one in room 1, one in room 2, one in room 3 and one in room 4. Cages: a friend behind one padlock in room 2, a potion behind one padlock in room 3 and a friend behind two padlocks in room 4. Hidden item: ![item 2](imagenes/objeto-02.png) in room 4. Skull doors: to level 12 from room 1 and to level 14 from room 3.*

### Level 14

![Level 14](imagenes/mapa-nivel-14.png)

*Level 14, the rooms laid out `1- / 2- / 34`. Keys: four, one in room 2, two in room 3 and one in room 4. Cages: a friend behind one padlock in room 2, a potion behind one padlock in room 3 and a friend behind one padlock in room 4. Hidden item: ![item 12](imagenes/objeto-12.png) in room 4. Skull doors: to level 15 from room 1 and to level 13 from room 4. Exit door: to level 16, the first of round 4, in room 3.*

### Level 15

![Level 15](imagenes/mapa-nivel-15.png)

*Level 15, the four rooms in a row. Keys: two, one in room 2 and one in room 3. Cages: a potion behind one padlock in room 3 and a potion behind one padlock in room 4. Hidden item: energy in room 1. Skull doors: to level 11 from room 1, to level 12 from room 3, and to level 14 from room 4.*

## Round 4 — levels 16 to 20

![Round 4](imagenes/ronda-4.png)

*The five levels of round 4 and their skull doors, at 1:1. Each level is laid out with the room arrangement 0x52DB gives it, and every line joins TWO doors that really pair up: door j of level A says (B, k) and door k of level B says (A, j). All 64 in the cartridge pair up like that, and none leaves its round. The lines run behind the levels; the yellow mark is the door. Two things in this picture do NOT come from the ROM, so they are said out loud: where each level sits on the ring -of the twelve possible orders the one with fewest crossings is picked- and the bow of the curves, which separates the pairs of levels joined by TWO doors.*

### Level 16

![Level 16](imagenes/mapa-nivel-16.png)

*Level 16, the rooms laid out `123 / -4-`. Keys: three, one in room 1, one in room 2 and one in room 4. Cages: a friend behind one padlock in room 1, a potion behind one padlock in room 3 and a potion behind one padlock in room 3. Hidden items: ![item 8](imagenes/objeto-08.png) in room 4 and the second bar in room 1. Skull doors: to level 20 from room 1, to level 17 from room 3, and to level 19 from room 4.*

### Level 17

![Level 17](imagenes/mapa-nivel-17.png)

*Level 17, the four rooms in a 2x2. Keys: four, one in room 2, two in room 3 and one in room 4. Cages: a friend behind two padlocks in room 2 and a potion behind one padlock in room 3. Hidden item: ![item 14](imagenes/objeto-14.png) in room 3. Skull doors: to level 16 from room 1, to level 19 from room 3, and to level 18 from room 4.*

### Level 18

![Level 18](imagenes/mapa-nivel-18.png)

*Level 18, the rooms laid out `-1- / 234`. Keys: four, two in room 1, one in room 2 and one in room 4. Cages: a friend behind two padlocks in room 4 and a friend behind one padlock in room 4. Hidden item: ![item 21](imagenes/objeto-21.png) in room 3. Skull doors: to level 17 from room 1 and to level 20 from room 2. Exit door: to level 21, the first of round 5, in room 3.*

### Level 19

![Level 19](imagenes/mapa-nivel-19.png)

*Level 19, the four rooms in a column. Keys: four, one in room 1, one in room 3 and two in room 4. Cages: a friend behind two padlocks in room 3 and a potion behind one padlock in room 4. Hidden item: ![item 4](imagenes/objeto-04.png) in room 3. Skull doors: to level 16 from room 1, to level 17 from room 1, and to level 20 from room 4.*

### Level 20

![Level 20](imagenes/mapa-nivel-20.png)

*Level 20, the rooms laid out `1-- / 234`. Keys: four, one in room 1, two in room 2 and one in room 4. Cages: a friend behind one padlock in room 3, a potion behind two padlocks in room 3 and a friend behind one padlock in room 3. Hidden item: ![item 15](imagenes/objeto-15.png) in room 3. Skull doors: to level 16 from room 1, to level 19 from room 3, and to level 18 from room 4.*

## Round 5 — levels 21 to 25

![Round 5](imagenes/ronda-5.png)

*The five levels of round 5 and their skull doors, at 1:1. Each level is laid out with the room arrangement 0x52DB gives it, and every line joins TWO doors that really pair up: door j of level A says (B, k) and door k of level B says (A, j). All 64 in the cartridge pair up like that, and none leaves its round. The lines run behind the levels; the yellow mark is the door. Two things in this picture do NOT come from the ROM, so they are said out loud: where each level sits on the ring -of the twelve possible orders the one with fewest crossings is picked- and the bow of the curves, which separates the pairs of levels joined by TWO doors.*

### Level 21

![Level 21](imagenes/mapa-nivel-21.png)

*Level 21, the rooms laid out `12 / 3- / 4-`. Keys: four, all in room 3. Cages: a potion behind one padlock in room 1, a potion behind one padlock in room 2 and a potion behind one padlock in room 4. Hidden item: ![item 1](imagenes/objeto-01.png) in room 3. Skull doors: to level 22 from room 2 and to level 25 from room 3.*

### Level 22

![Level 22](imagenes/mapa-nivel-22.png)

*Level 22, the rooms laid out `12- / -34`. Keys: three, one in room 1, one in room 2 and one in room 3. Cages: a friend behind two padlocks in room 1 and a friend behind one padlock in room 4. Hidden item: ![item 20](imagenes/objeto-20.png) in room 2. Skull doors: to level 21 from room 1, to level 23 from room 3, and to level 24 from room 4.*

### Level 23

![Level 23](imagenes/mapa-nivel-23.png)

*Level 23, the rooms laid out `-1- / 234`. Keys: four, one in room 2, two in room 3 and one in room 4. Cages: a potion behind one padlock in room 1, a potion behind one padlock in room 2 and a friend behind two padlocks in room 4. Hidden item: ![item 13](imagenes/objeto-13.png) in room 4. Skull doors: to level 24 from room 4, to level 22 from room 1, and to level 25 from room 2. Exit door: to level 1, the first of round 1, in room 3.*

### Level 24

![Level 24](imagenes/mapa-nivel-24.png)

*Level 24, the four rooms in a 2x2. Keys: three, one in room 2 and two in room 3. Cages: a friend behind one padlock in room 1, a potion behind one padlock in room 2 and a friend behind one padlock in room 4. Hidden item: ![item 22](imagenes/objeto-22.png) in room 2. Skull doors: to level 23 from room 2, to level 25 from room 3, and to level 22 from room 4.*

### Level 25

![Level 25](imagenes/mapa-nivel-25.png)

*Level 25, the four rooms in a 2x2. Keys: four, two in room 1, one in room 3 and one in room 4. Cages: a friend behind one padlock in room 2, a potion behind one padlock in room 3 and a friend behind one padlock in room 4. Hidden item: ![item 19](imagenes/objeto-19.png) in room 4. Skull doors: to level 21 from room 2, to level 24 from room 3, and to level 23 from room 4.*

