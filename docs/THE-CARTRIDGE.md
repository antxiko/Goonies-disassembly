# The cartridge

    file       goonies.rom
    size       32,768 bytes
    sha256     2ba602b1a17e4797da1588afe6e65640331c15746bf5959f4778b404be929dde
    catalogue  RC-734
    machine    MSX1

## Where it lives

A 32 KB cartridge in **pages 1 and 2**, `0x4000..0xBFFF`. No paging, no mapper:
all 32 KB are there at once and the Z80 sees the lot.

## The two headers

The first is the usual one: at `0x4000` sit the `"AB"` signature and the address
of INIT, which here is `0x406A`. STATEMENT, DEVICE and TEXT are zero, and so are
the six reserved bytes.

The second, at `0x4010`, is not an MSX thing: it is the **Konami Game Master**
header, for the house's cheat cartridge that plugs into the other slot. It
starts with `"CD"`, then `07 34` — the `0x07` of the RC-7xx range and the `0x34`
of RC-734 — and then eleven bytes with the variables the Game Master wants to
touch.

This cartridge **never reads it**: `tools/quien_lee.py` gives zero references to
`0x4010..0x401E`. It is there for the cartridge next door to read.

Seven of the Konami ROMs here carry it, five of them disassembled in this
series: Konami's Soccer and Football (RC-732), this one, Konami's Boxing
(RC-736), Yie Ar Kung-Fu II (RC-737), Knightmare (RC-739), Nemesis (RC-742) and
F-1 Spirit (RC-752). The marker in front goes by **year**, not by catalogue
number: `AB` on the 1985 ones and `CD` from 1986 on.

## The hidden mark

At the end of the cartridge, behind the `0xFF` padding, sit the title in
katakana written **backwards** and the catalogue number:

    グーニーズ   34   0xAA

It is read with the house code: index = byte − `0x80`, and indices 0 to 44 are
the *gojūon* in order. The finding is **Manuel Pazos**'s, who uncovered it in
2021; without him nobody would know to look there.

This cartridge also pins down a character that was still unconfirmed: `0xBA`,
index 58, is the long-vowel mark ー. グーニーズ only works out that way.

## The VDP registers

`0x470F` pushes eight bytes into registers 0 to 7, one at a time:

| reg | value | what it says |
|---|---|---|
| R0 | `0x02` | mode 2 (SCREEN 2) |
| R1 | `0xE2` | 16 KB, display on, interrupt enabled, 16x16 sprites |
| R2 | `0x0E` | names at `0x3800` |
| R3 | `0x7F` | colour: base `0x0000`, mask `0x1FFF` |
| R4 | `0x07` | patterns: base `0x2000`, mask `0x1FFF` |
| R5 | `0x76` | sprite attributes at `0x3B00` |
| R6 | `0x03` | sprite patterns at `0x1800` |
| R7 | `0xE4` | dark blue border |

**Careful with R3 and R4**: in mode 2 they are not an address, they are base and
mask. Reading them as an address gives you correct shapes with banded colours,
which is the classic symptom.

The geometry that comes out of it is **upside down from the usual**:

    colour             0x0000..0x17FF   three 0x800 banks
    sprite patterns    0x1800..0x1FFF   64 patterns
    patterns           0x2000..0x37FF   three 0x800 banks
    names              0x3800..0x3AFF   768 tiles
    sprite attributes  0x3B00..0x3B7F   32 sprites

The colour table sits **below** the pattern table. An `ld hl,00008h` in this
cartridge does not point at patterns: it points at colour.

## How the 32,768 bytes break down

| |bytes|%|
|---|---:|---:|
|traced code|17,422|53.17|
|identified data|15,346|46.83|
|**unexplained**|**0**|**0.00**|
|**total**|**32,768**|**100.00**|

Counted by `tools/presupuesto.py`, and checked by `make sanity` on every build.

## Konami's framework

The table dispatcher — `pop hl / add a,a / call ... / ld e,(hl) / inc hl /
ld d,(hl) / ex de,hl / jp (hl)` — is the same in eleven of the house's
cartridges. Searching for its tail (`5e 23 56 eb e9`) across the 47 ROMs to
hand turns it up **exactly once** in each: Sky Jaguar (RC-721), Yie Ar Kung-Fu
(both builds), Hyper Rally (RC-718), Road Fighter (RC-730), Konami's Ping Pong
(RC-731), Konami's Soccer and Football (RC-732), Hyper Sports 3 (RC-733), this
one (RC-734), Nemesis (RC-742) and F-1 Spirit (RC-752).

In this cartridge it is used **twenty-six times**, and all twenty-six tables sit
immediately behind their `call`.
