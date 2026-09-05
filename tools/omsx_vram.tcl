# Vuelca la VRAM de The Goonies en los instantes que importan.
#
# No hace falta jugar ni cargar un replay: la presentacion, el titulo y la
# demostracion salen solas desde el encendido y son deterministas -la
# demostracion es una partida GRABADA, tablas de 0x520E y 0x5231-, asi que dos
# arranques dan lo mismo. Los instantes salen de tools/omsx_sonda.tcl:
#
#     t=13  la pantalla del titulo, con el rotulo THE GOONIES
#     t=25  la pantalla de los nueve andando
#     t=45  el nivel 1 jugandose, sala 0
#     t=60  la sala 1
#     t=75  la sala 2
#
# De cada uno salen dos ficheros: vram_NN.bin con los 16 KB tal cual, y
# info_NN.txt con el estado del juego en ese momento, para poder decir CONTRA
# QUE se compara. Ahi va tambien el contador de cuadros (0xE003), porque su
# bit 2 es el que decide en que fase esta el agua, y sin el habria que
# adivinarla.
#
# Trampas ya pagadas en esta serie y respetadas aqui: nada de corchetes dentro
# de un `format`, el fichero binario con -translation binary, y `debug
# read_block` en vez de `debug save_to_file`, que no existe.

set renderer none
set throttle off

set INSTANTES {13 25 45 60 75}
set carpeta "work/omsx"

proc vuelca {num} {
    global carpeta
    set d [debug read_block VRAM 0 16384]
    set f [open [file join $carpeta "vram_$num.bin"] w]
    fconfigure $f -translation binary
    puts -nonewline $f $d
    close $f

    set f [open [file join $carpeta "info_$num.txt"] w]
    puts $f "tiempo [machine_info time]"
    puts $f "escena [debug read memory 0xE000]"
    puts $f "subescena [debug read memory 0xE001]"
    puts $f "nivel [debug read memory 0xE061]"
    puts $f "sala [debug read memory 0xE062]"
    puts $f "demostracion [debug read memory 0xE066]"
    puts $f "ronda [debug read memory 0xE06C]"
    puts $f "cuadro [debug read memory 0xE003]"
    puts $f "agua [debug read memory 0xE345]"
    close $f
}

set n 0
proc siguiente {} {
    global INSTANTES n
    set t [lindex $INSTANTES $n]
    incr n
    if {$n < [llength $INSTANTES]} {
        set espera [expr {[lindex $INSTANTES $n] - $t}]
        after time $espera siguiente
    } else {
        after time 1 exit
    }
    vuelca [format "%02d" $t]
}

after time [lindex $INSTANTES 0] siguiente
