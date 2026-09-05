# Sonda: que escena corre en cada segundo, arrancando el cartucho en frio.
#
# No hace falta jugar: la presentacion, el titulo y la demostracion salen solas
# y son deterministas -la demostracion es una partida GRABADA, tabla de 0x520E-,
# asi que dos arranques dan lo mismo. Con esto se eligen los instantes en los
# que volcar la VRAM sin adivinar.
#
# Las variables que se miran, todas medidas sobre el listado:
#   0xE000 la escena   0xE001 la subescena   0xE061 el nivel   0xE062 la sala
#   0xE066 si esto es la demostracion
#
# Se lanza desde el Makefile. Ojo con las trampas de Tcl ya pagadas: nada de
# corchetes dentro de un `format`, y reprogramar el temporizador LO PRIMERO.

set renderer none
set throttle off

set salida [open "work/omsx/sonda.txt" w]
fconfigure $salida -translation binary
set n 0

proc mira {} {
    global salida n
    incr n
    if {$n < 90} { after time 1 mira }
    set e [debug read memory 0xE000]
    set s [debug read memory 0xE001]
    set niv [debug read memory 0xE061]
    set sala [debug read memory 0xE062]
    set demo [debug read memory 0xE066]
    set t [machine_info time]
    puts $salida [format "t=%6.2f escena=%3d sub=%3d nivel=%3d sala=%3d demo=%3d" \
                  $t $e $s $niv $sala $demo]
    flush $salida
    if {$n >= 90} { close $salida ; exit }
}

after time 1 mira
