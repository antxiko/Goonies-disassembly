# Open questions

All 32,768 bytes are explained and the listing reproduces the ROM byte for byte.
What follows are not gaps in the disassembly: they are things the cartridge does
whose **why** has not been measured.

## The two levels with two hidden items

The twenty-seven conditions at `0x6DBD` are all used, once each. Twenty-three
levels carry one hidden item and **two carry two: 5 and 16**. Why those two and
not others has not been measured.

## Levels 6 and 15

The table at `0x5576` leaves exactly those two without an item, and that much is
measured. What is not measured is whether it is deliberate — one rest level per
round — or whether two items fell out of a plan for twenty-five.

## The three empty voices

The last three entries in the voice table are `0xBFEE`, which is where the
`0xFF` padding starts. They are empty voices, and it is not known whether they
are reserved room or the trace of three pieces that got dropped.

## How much of it is actually played

All hundred rooms are drawn and none repeats, but **how many of the hundred you
actually walk through in a game has not been measured**. The link between rooms
goes through two 19x4 tables and depends on which side you leave by, so there
may be rooms you can only reach from one direction.

## The many-legged creature

It shows up in few levels and always alone. It is understood — it lies hidden in
an 8x8 box until it is stepped on, and item `0x13` stops it waking — but why it
is in those levels and not others has not been measured.

## The second header

The Konami Game Master header is there, and so are its eleven pointer bytes.
This cartridge never reads them. **Exactly what each of those eleven bytes is**
could not be settled without the cheat cartridge to hand: the layout of that
space changes from one game to the next.

## The hidden mark's characters

Of the house's katakana code, indices 0 to 44 are confirmed — the *gojūon* in
order — plus five more: 51, 53, 55, 56 and **58, which this cartridge closes**.
The rest remain unchecked, and will only be settled with more cartridges.
