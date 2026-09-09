; ==========================================================================
; THE GOONIES - Konami - MSX1 - cartucho RC-734 de 32 KB en las paginas 1 y 2
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: "AB" y la direccion de INIT (0x406A);
;   STATEMENT, DEVICE y TEXT a cero, y los seis bytes reservados tambien
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defw 04241h,0406ah,00000h,00000h,00000h,00000h,00000h,00000h	; 4000

; ----------------------------------------------------------------------
; DATOS cabecera_del_game_master: "CD" 07 34: el 0x07 de los RC-7xx y el 0x34
;   de RC-734
;   0x4010..0x4014  (4 bytes)
DATA_cabecera_del_game_master:
	defb 043h,044h,007h,034h	; 4010

; ----------------------------------------------------------------------
; DATOS punteros_del_game_master: once bytes con las variables que el Game
;   Master toca; el reparto de este espacio cambia de un cartucho a otro, y
;   aqui acaba en 0x401E porque en 0x401F ya vuelve a haber codigo
;   0x4014..0x401f  (11 bytes)
DATA_punteros_del_game_master:
	defb 0e4h,000h,0e0h,004h,06ch,0e0h,005h,053h,0e0h,056h,0e0h	; 4014  ....l..S.V.

; ======================================================================
; CODIGO 0x401f..0x40f6  (215 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL ARRANQUE DEL TITULO, con un escribe-en-la-ROM que no hace nada
; ----------------------------------------------------------------------
prepara_el_titulo:
	ld hl,0c9e1h		;401f   ; 0xC9E1 son, puestos en memoria, los bytes E1 C9: `pop hl / ret`
	ld (0411ch),hl		;4022   ; pero 0x411C es la ROM del propio cartucho, asi que este escribe SE PIERDE. Si tuviera efecto, convertiria el `djnz` de 0x411C en un `pop hl / ret`
	jp monta_el_cartel		;4025   ; y sigue montando la pantalla del titulo

; ----------------------------------------------------------------------
; EL GANCHO DE LA INTERRUPCION: aqui cuelga el cuadro entero
; ----------------------------------------------------------------------
cada_cuadro:
	call 0013eh		;4028   ; BIOS RDVDP - Reads VDP status register | RDVDP borra la peticion de interrupcion del VDP; si no se lee, el VDP la mantiene
	di			;402b
	call suena_el_cuadro		;402c   ; el sonido va PRIMERO, antes que nada, para que no se le note el retraso si el cuadro se alarga
	ld hl,0e005h		;402f   ; el cerrojo de reentrada: si el cuadro anterior todavia no ha acabado
	bit 0,(hl)		;4032
	jr nz,L_4043		;4034   ; se salta el trabajo entero y se va a limpiar y salir
	inc (hl)			;4036   ; echa el cerrojo
	ei			;4037   ; y abre las interrupciones ESTANDO dentro, que es lo que permite que el sonido siga sonando aunque el cuadro se pase de largo
	call lee_los_mandos		;4038   ; lee mandos y teclado
	call haz_el_cuadro		;403b   ; y hace el cuadro: la escena que toque
	ld a,000h		;403e   ; quita el cerrojo
	ld (0e005h),a		;4040
L_4043:
	call 0013eh		;4043   ; BIOS RDVDP - Reads VDP status register | segunda lectura del VDP, ya de salida
	or a			;4046
	di			;4047
	call m,suena_el_cuadro		;4048   ; y si el bit 7 dice que hubo colision o quinto sprite, otra pasada de sonido
	ei			;404b
	ret			;404c

; ----------------------------------------------------------------------
; PONER UN REGISTRO DEL VDP, con otro escribe-en-la-ROM
; ----------------------------------------------------------------------
pon_registro_del_vdp:
	ld hl,00000h		;404d   ; otra vez lo mismo: 0x4129 cae dentro del `jp L_41C8` de 0x4128, y es ROM
	ld (04129h),hl		;4050   ; asi que el escribe se pierde. De tener efecto, dejaria ahi un `jp 00000h`, o sea un reinicio
	jp 00047h		;4053   ; BIOS WRTVDP - Writes data in the VDP-register | lo que si hace es escribir el registro: b el valor, c el numero

; ----------------------------------------------------------------------
; LAS DOS SUMAS DE 16 BITS QUE USA TODO EL CARTUCHO
; ----------------------------------------------------------------------
suma_a_a_hl:
	add a,l			;4056   ; hl += a, sin signo
	ld l,a			;4057
	ret nc			;4058   ; el `ret nc` se ahorra el incremento cuando no hay acarreo
	inc h			;4059
	ret			;405a
suma_a_a_de:
	add a,e			;405b   ; de += a, la misma receta
	ld e,a			;405c
	ret nc			;405d
	inc d			;405e
	ret			;405f

; ----------------------------------------------------------------------
; EL DESPACHADOR DE KONAMI: la tabla va PEGADA detras del `call`
; ----------------------------------------------------------------------
reparte_por_tabla:
	pop hl			;4060   ; recoge su propia direccion de retorno, que es donde empieza la tabla
	add a,a			;4061   ; dos bytes por entrada
	call suma_a_a_hl		;4062   ; hl = tabla + a*2
	ld e,(hl)			;4065   ; saca el destino
	inc hl			;4066
	ld d,(hl)			;4067
	ex de,hl			;4068
	jp (hl)			;4069   ; y salta. Al no volver, el `ret` de la escena vuelve a quien llamara ANTES, o a la direccion que se hubiera empujado a mano

; ----------------------------------------------------------------------
; INIT: lo que la cabecera del cartucho manda ejecutar
; ----------------------------------------------------------------------
INIT:
	di			;406a   ; nada de interrupciones mientras se cambian las ranuras
	im 1		;406b
	call 00138h		;406d   ; BIOS RSLREG - Reads the primary slot register | RSLREG da el registro de ranuras primarias
	rrca			;4070   ; los dos bits de la pagina 1, que es donde esta este cartucho
	rrca			;4071
	and 003h		;4072
	ld c,a			;4074
	ld b,000h		;4075
	ld hl,0fcc1h		;4077   ; 0xFCC1 es SLTTBL, la tabla de ranuras expandidas
	add hl,bc			;407a
	or (hl)			;407b   ; si la ranura es expandida, se le pega el bit 7
	ld c,a			;407c
	inc hl			;407d   ; cuatro adelante esta el byte de la subranura
	inc hl			;407e
	inc hl			;407f
	inc hl			;4080
	ld a,(hl)			;4081
	and 00ch		;4082   ; y de el solo interesan los dos bits de la pagina 1
	or c			;4084
	ld h,080h		;4085   ; h = 0x80: la pagina 2, que es donde hay que meter la segunda mitad del cartucho
	call 00024h		;4087   ; BIOS ENASLT - Switches to specified slot and page definitively | ENASLT deja el cartucho entero visible, 0x4000..0xBFFF
	ld a,0c3h		;408a   ; 0xC3 es el opcode de `jp`
	ld (0fd9ah),a		;408c   ; H.KEYI, el gancho de la interrupcion del teclado, que salta antes que el reloj
	ld hl,cada_cuadro		;408f   ; y ahi va la direccion del cuadro
	ld (0fd9bh),hl		;4092
	ld sp,0e600h		;4095   ; la pila, justo debajo de las cuatro salas
	ld hl,0e000h		;4098   ; borra las variables: 0xE000..0xE5FF
	ld de,0e001h		;409b
	ld bc,005ffh		;409e
	ld (hl),000h		;40a1
	ldir		;40a3
	ld a,001h		;40a5   ; el cerrojo de reentrada, echado a mano
	ld (0e005h),a		;40a7
	call arranca_la_pantalla		;40aa   ; monta el VDP y la pantalla de arranque
	xor a			;40ad
	ld (0e005h),a		;40ae   ; y lo suelta
	call 0013eh		;40b1   ; BIOS RDVDP - Reads VDP status register
	ei			;40b4   ; a partir de aqui manda la interrupcion
L_40B5:
	jr L_40B5		;40b5   ; y este bucle vacio es todo el programa principal: el juego entero ocurre dentro del gancho

; ----------------------------------------------------------------------
; PEDIR UNA PIEZA CON EL VDP A OSCURAS
; ----------------------------------------------------------------------
suena_con_pantalla_apagada:
	ld hl,04721h		;40b7   ; 0x4721 es el byte de R1 dentro de la tabla de registros del VDP
	res 6,(hl)		;40ba   ; le quita el bit 6, que es el que enciende la pantalla, pero SOLO en la copia de la ROM... que es ROM: no cambia nada
	jp pide_pieza		;40bc   ; y pide la pieza

; ----------------------------------------------------------------------
; EL CUADRO: cuenta, mira el pausa y reparte la escena
; ----------------------------------------------------------------------
haz_el_cuadro:
	ld hl,0e003h		;40bf   ; el contador de cuadros, que muchas animaciones usan de reloj
	inc (hl)			;40c2
	ld a,(0e07dh)		;40c3   ; si (0xE07D) no es cero estamos tecleando la palabra clave
	and a			;40c6
	jp nz,lee_la_palabra_clave		;40c7
	ld a,(0e000h)		;40ca   ; solo se puede pausar mientras se juega
	cp 003h		;40cd
	jr nc,L_40E3		;40cf
	ld a,006h		;40d1   ; fila 6 del teclado
	call 00141h		;40d3   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	and 002h		;40d6   ; la tecla de parada
	jr nz,L_40E3		;40d8
	ld a,004h		;40da   ; fila 4
	call 00141h		;40dc   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	rra			;40df
	jp nc,pide_la_contrasena		;40e0   ; y si esta pulsada, a la pausa
L_40E3:
	ld a,(0e000h)		;40e3   ; en las escenas de juego
	cp 003h		;40e6
	jr nc,L_40EE		;40e8
	ld hl,043e7h		;40ea   ; se empuja 0x43E7 a mano, para que la escena remate por ahi al volver
	push hl			;40ed
L_40EE:
	ld bc,(0e000h)		;40ee   ; c = (0xE000) la escena, b = (0xE001) la subescena
	ld a,c			;40f2
	call reparte_por_tabla		;40f3   ; y a la tabla de nueve

; ----------------------------------------------------------------------
; DATOS tabla_de_escenas: 9 entradas; reparte segun (0xE000) el arranque, el
;   titulo, el juego y el final
;   0x40f6..0x4108  (18 bytes)
DATA_tabla_de_escenas:
	defw 04108h,04139h,04141h,04196h,041b9h,04212h,0435ch,0436fh	; 40f6
	defw 04395h	; 4106  -> escena_ronda_pasada

; ======================================================================
; CODIGO 0x4108..0x4450  (840 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ESCENA 0: la presentacion
; ----------------------------------------------------------------------
escena_presentacion:
	djnz presentacion_espera		;4108   ; el `djnz` reparte por (0xE001): cada escena lleva sus subescenas asi
	ld a,(0e003h)		;410a   ; el contador de cuadros
	rra			;410d   ; uno de cada dos
	ret nc			;410e
	call baja_un_paso		;410f   ; si se ha pulsado algo, se corta
	ret nz			;4112
	ld de,0477bh		;4113   ; el guion del marcador
	call guion_rle		;4116
	xor a			;4119   ; y a la subescena 0 de la siguiente
	jr pon_los_cuadros		;411a
presentacion_espera:
	djnz presentacion_anima		;411c
	ld hl,0e004h		;411e   ; cuenta atras
	dec (hl)			;4121
	ret nz			;4122
	call monta_el_titulo_y_el_rotulo		;4123   ; monta lo que sea
	ld a,0c0h		;4126   ; y 0xC0 cuadros mas
	jp L_41C8		;4128
presentacion_anima:
	call pon_los_registros_del_vdp		;412b   ; lee los mandos
	call limpia_la_pantalla		;412e
	call monta_la_fuente		;4131
	call arranca_la_presentacion		;4134
	jr sube_de_subescena		;4137   ; y a la subescena siguiente
escena_espera:
	ld hl,0e004h		;4139
	dec (hl)			;413c   ; cuenta atras y ya
	ret nz			;413d
	jp escena_siguiente		;413e
escena_titulo:
	djnz titulo_espera_tecla		;4141
	call mueve_a_los_nueve		;4143   ; monta el titulo
	ld a,(0e251h)		;4146   ; si hay algo en marcha, no se toca
	and a			;4149
	ret nz			;414a
	ld a,0adh		;414b   ; la pieza del titulo
	call pide_pieza		;414d
	jr treinta_y_dos_cuadros		;4150   ; y 0x20 cuadros
titulo_espera_tecla:
	djnz titulo_arranca		;4152
	call cortina		;4154   ; mira si se ha pulsado
	ret p			;4157   ; y si no, vuelve
	call empieza_la_partida		;4158
	jr sube_de_subescena		;415b
titulo_arranca:
	djnz titulo_borra		;415d
	call mueve_la_demostracion		;415f
	call vuelca_y_reparte		;4162
	ld a,(0e066h)		;4165   ; (0xE066) dice si esto es la demostracion
	or a			;4168
	ret nz			;4169
L_416A:
	xor a			;416a   ; escena 0
pon_escena:
	ld (0e000h),a		;416b
	ld a,020h		;416e
	ld (0e004h),a		;4170   ; y 0x20 cuadros
	jr L_41CF		;4173
titulo_borra:
	ld hl,039c0h		;4175   ; 0x39C0 son las dos ultimas filas de la pantalla
	xor a			;4178
	ld bc,000a0h		;4179   ; 160 casillas
	call 00056h		;417c   ; BIOS FILVRM - Fills VRAM with value | a cero
	call monta_la_pantalla_del_titulo		;417f
	ld a,0a4h		;4182   ; la pieza 0xA4
	call pide_pieza		;4184
	ld a,001h		;4187   ; ronda 1
	ld (0e06ch),a		;4189
treinta_y_dos_cuadros:
	ld a,020h		;418c
pon_los_cuadros:
	ld (0e004h),a		;418e
sube_de_subescena:
	ld hl,0e001h		;4191   ; (0xE001) es la subescena
	inc (hl)			;4194
	ret			;4195
escena_cuenta_atras:
	djnz cuenta_atras_2		;4196
	ld hl,0e004h		;4198
	dec (hl)			;419b
	jr z,sube_de_subescena		;419c
	bit 2,(hl)		;419e   ; el bit 2 del contador hace el parpadeo
	ld de,047cfh		;41a0   ; y por eso el mismo guion se pinta
	jp z,pinta_guion		;41a3
	jp borra_guion		;41a6   ; y se borra
cuenta_atras_2:
	djnz L_41B0		;41a9
	call partida_nueva		;41ab
	jr escena_siguiente		;41ae
L_41B0:
	ld a,09bh		;41b0   ; la pieza 0x9B
	call pide_pieza		;41b2
	ld a,050h		;41b5   ; y 0x50 cuadros
	jr pon_los_cuadros		;41b7
escena_empieza_el_nivel:
	djnz arranca_el_nivel		;41b9
	ld hl,0e004h		;41bb
	dec (hl)			;41be
	ret nz			;41bf
	ld de,047b5h		;41c0   ; borra el rotulo
	call borra_guion		;41c3
escena_siguiente:
	ld a,020h		;41c6   ; 0x20 cuadros
L_41C8:
	ld (0e004h),a		;41c8
	ld hl,0e000h		;41cb   ; sube de escena
	inc (hl)			;41ce
L_41CF:
	xor a			;41cf   ; y empieza por su subescena 0
L_41D0:
	ld (0e001h),a		;41d0
	ret			;41d3
arranca_el_nivel:
	call cortina		;41d4
	ret p			;41d7
	ld a,(0e122h)		;41d8   ; (0xE122) a 3 quiere decir que es el principio de una ronda
	cp 003h		;41db
	jr nz,L_41EB		;41dd
	ld a,(0e06ch)		;41df   ; la ronda
	ld c,a			;41e2
	add a,a			;41e3   ; por cinco
	add a,a			;41e4
	add a,c			;41e5
	sub 004h		;41e6   ; menos cuatro: la ronda 1 empieza en el nivel 1, la 2 en el 6, y asi hasta el 21
	ld (0e061h),a		;41e8
L_41EB:
	call monta_los_sprites		;41eb   ; los sprites
	ld hl,0e060h		;41ee
	ld a,(hl)			;41f1   ; y aqui se gasta una vida
	sub 001h		;41f2   ; restar en BCD, que es como se lleva la cuenta para poder pintarla sin dividir
	daa			;41f4
	ld (hl),a			;41f5
	call monta_las_casillas		;41f6   ; las casillas
	call nivel_en_decimal		;41f9   ; el nivel, pasado a decimal
	call pinta_el_marcador		;41fc
	ld de,047b5h		;41ff   ; el rotulo
	call pinta_guion		;4202
	dec l			;4205
	dec l			;4206
	call pinta_la_ronda		;4207
	ld a,078h		;420a   ; y 0x78 cuadros de espera
	ld (0e004h),a		;420c
	jp sube_de_subescena		;420f
escena_de_juego:
	push bc			;4212
	call vuelca_los_sprites		;4213   ; un cuadro de la partida
	pop bc			;4216
	djnz escena_muere		;4217
	ld a,006h		;4219   ; fila 6 del teclado
	call 00141h		;421b   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;421e
	and 020h		;421f   ; la tecla de parada
	ld hl,0e07eh		;4221   ; lo de antes
	ld b,(hl)			;4224
	ld (hl),a			;4225
	inc hl			;4226
	and a			;4227
	jr z,L_424C		;4228   ; si no esta pulsada, nada
	xor b			;422a
	jr z,L_424C		;422b   ; ni si ya lo estaba: solo cuenta el momento de pulsar
	ld a,(hl)			;422d
	xor 010h		;422e   ; y cambia el estado de la pausa
	ld (hl),a			;4230
	push af			;4231
	call nz,guarda_de_la_pantalla		;4232   ; al entrar en pausa
	pop af			;4235
	call z,devuelve_lo_que_habia		;4236   ; y al salir
	ld hl,0e07fh		;4239
	ld a,(hl)			;423c
	and a			;423d
	ld a,001h		;423e
	jr z,L_4244		;4240
	ld a,000h		;4242
L_4244:
	ld (0e049h),a		;4244
	ld a,08eh		;4247   ; la pieza 0x8E
	call nz,pide_pieza_si_toca		;4249
L_424C:
	ld a,(hl)			;424c
	and a			;424d
	jp nz,parpadea_la_pausa		;424e   ; si estamos en pausa, ahi se queda
	call reparte_la_partida		;4251   ; y si no, el cuadro entero
	ld a,(0e00dh)		;4254
	and a			;4257
	ld a,003h		;4258
	jp nz,L_41D0		;425a
se_acaba_el_tiempo:
	ld a,(0e064h)		;425d   ; lo que queda de tiempo
	and a			;4260
	ret nz			;4261
	ld a,0aah		;4262   ; la pieza 0xAA
	call pide_pieza		;4264
	ld a,080h		;4267   ; y 0x80 cuadros
	jp pon_los_cuadros		;4269
escena_muere:
	djnz muere_2		;426c
	ld ix,0e110h		;426e   ; la ficha del jugador
	call pinta_al_jugador		;4272   ; dibujado
	ld hl,0e004h		;4275
	dec (hl)			;4278   ; cuenta atras
	ld hl,0e12dh		;4279
	ld (hl),001h		;427c   ; mientras dura, (0xE12D) queda a uno
	ret nz			;427e
	ld (hl),000h		;427f   ; y al acabarse, a cero
	jp escena_siguiente		;4281
muere_2:
	djnz muere_3_los_dos_sprites		;4284
	call devuelve_la_fila_de_abajo		;4286   ; la fila de abajo
	call aparca_los_sprites		;4289   ; y todos los sprites fuera
	ld a,(0e123h)		;428c   ; que ficha era
	call L_5006		;428f
	ld ix,0e110h		;4292   ; se le vuelve a colocar
	call pinta_al_jugador		;4296
	ld a,010h		;4299   ; 0x10 cuadros
	jp pon_los_cuadros		;429b
muere_3_los_dos_sprites:
	djnz muere_4_da_vueltas		;429e
	ld hl,0e004h		;42a0   ; cuenta atras
	dec (hl)			;42a3
	ret nz			;42a4
	ld hl,0e080h		;42a5   ; el primer sprite
	ld de,0e084h		;42a8   ; y el segundo
	ld a,(0e113h)		;42ab   ; la fila del jugador
	add a,0f0h		;42ae   ; dieciseis pixeles mas arriba
	ld (hl),a			;42b0
	ld (de),a			;42b1
	inc hl			;42b2
	inc de			;42b3
	ld a,(0e115h)		;42b4   ; y su columna
	add a,004h		;42b7   ; cuatro a la derecha
	ld (hl),a			;42b9
	add a,004h		;42ba   ; y el otro, cuatro mas
	ld (de),a			;42bc
	inc hl			;42bd
	inc de			;42be
	ld b,040h		;42bf   ; el patron 0x40
	ld c,00fh		;42c1   ; en blanco
	ld a,(0e123h)		;42c3   ; salvo la ficha 3
	cp 003h		;42c6
	jr nz,L_42CE		;42c8
	ld b,044h		;42ca   ; que usa el 0x44
	ld c,007h		;42cc   ; y otro color
L_42CE:
	ld (hl),b			;42ce
	xor a			;42cf
	ld (de),a			;42d0
	inc hl			;42d1
	inc de			;42d2
	ld (hl),c			;42d3
	inc a			;42d4
	ld (de),a			;42d5
	ld a,028h		;42d6   ; y 0x28 cuadros
	jp pon_los_cuadros		;42d8
muere_4_da_vueltas:
	djnz escena_vuelve_a_empezar		;42db
	ld hl,0e004h		;42dd   ; cuenta atras
	dec (hl)			;42e0
	jr z,acaba_de_morir		;42e1
	ld a,(hl)			;42e3   ; los ocho ultimos cuadros no giran
	cp 008h		;42e4
	ret c			;42e6
	rra			;42e7   ; dos rotaciones: cambia de postura cada cuatro cuadros
	rra			;42e8
	ret nc			;42e9
	ld b,002h		;42ea   ; mirando a un lado
	rra			;42ec
	jr nc,L_42F6		;42ed
	ld b,000h		;42ef   ; al frente
	rra			;42f1
	jr nc,L_42F6		;42f2
	ld b,004h		;42f4   ; o al otro lado
L_42F6:
	ld hl,0e115h		;42f6   ; y sube un pixel
	inc (hl)			;42f9
	ld a,b			;42fa
	ld (0e11ch),a		;42fb
	ld ix,0e110h		;42fe
	jp pinta_al_jugador		;4302
acaba_de_morir:
	ld hl,0e080h		;4305   ; el primer sprite, fuera de la pantalla
	ld (hl),0e0h		;4308
	ld hl,0e00dh		;430a   ; por que se ha acabado
	ld a,(hl)			;430d
	ld (hl),000h		;430e   ; y se olvida
	dec a			;4310   ; si valia 1 fue por tiempo o por un bicho: otra vida
	jp z,treinta_y_dos_cuadros		;4311
	ld a,008h		;4314   ; y si no, a la escena 8, que es la del final de ronda
	jp pon_escena		;4316
escena_vuelve_a_empezar:
	djnz rehace_el_nivel		;4319
	call aparca_los_sprites		;431b   ; todos los sprites fuera
	call limpia_la_sala		;431e
	ld a,0adh		;4321   ; la pieza 0xAD, que es la del silencio
	call pide_pieza		;4323
	jp L_41CF		;4326
rehace_el_nivel:
	call monta_las_casillas		;4329   ; las casillas
	call nivel_en_decimal		;432c   ; el nivel en decimal
	call pinta_el_marcador		;432f
	call pieza_del_nivel		;4332   ; la pieza del nivel
	call empieza_el_nivel		;4335   ; el estado
	call monta_el_nivel		;4338   ; y las cuatro salas otra vez
	ld hl,0e066h		;433b
	ld (hl),001h		;433e   ; se enciende la demostracion
	call entra_de_nuevo_en_la_sala		;4340
	jp sube_de_subescena		;4343
entra_de_nuevo_en_la_sala:
	call borra_los_trastos		;4346   ; se borran los trastos de la sala anterior
	call entra_en_la_sala		;4349   ; y se monta la nueva
	jp pinta_el_marcador		;434c

; ----------------------------------------------------------------------
; LA PIEZA QUE LE TOCA AL NIVEL
; ----------------------------------------------------------------------
pieza_del_nivel:
	call recoloreado_del_nivel		;434f   ; el byte de recoloreado del nivel
	rla			;4352   ; su bit 7
	ld a,096h		;4353   ; con el a cero, la pieza 0x96
	jr nc,L_4359		;4355
	ld a,091h		;4357   ; y con el puesto, la 0x91: los niveles llevan una de dos musicas
L_4359:
	jp pide_pieza_si_toca		;4359
escena_se_acabo_una_vida:
	ld a,(0e060h)		;435c   ; las vidas que quedan
	or a			;435f
	jr z,L_4367		;4360   ; si no queda ninguna, se acabo
L_4362:
	ld a,004h		;4362   ; y si quedan, a la escena 4, que vuelve a montar el nivel
	jp pon_escena		;4364
L_4367:
	ld a,0a7h		;4367   ; la pieza 0xA7 es la del final de la partida
	call pide_pieza		;4369
	jp escena_siguiente		;436c
escena_fin_de_partida:
	djnz fin_de_partida_2		;436f
	ld a,(0e012h)		;4371   ; mientras la musica siga sonando, no se toca nada
	or a			;4374
	ret nz			;4375
L_4376:
	ld hl,0e002h		;4376
	ld a,(hl)			;4379
	and 0bfh		;437a   ; se apaga el sonido
	ld (hl),a			;437c
	ld a,0adh		;437d   ; con la pieza del silencio
	call pide_pieza		;437f
	jp L_416A		;4382   ; y de vuelta al titulo
fin_de_partida_2:
	call cortina		;4385   ; espera a que suelte
	ret p			;4388
	ld de,047dch		;4389   ; pinta el rotulo de la fila de arriba
	call pinta_guion		;438c
	call pinta_el_marcador		;438f
	jp sube_de_subescena		;4392
escena_ronda_pasada:
	djnz ronda_pasada_2		;4395
	ld a,(0e012h)		;4397   ; se espera a que la musica acabe
	and a			;439a
	ret nz			;439b
	call monta_la_pantalla_del_titulo		;439c   ; monta la pantalla de la ronda
	call pinta_el_suelo		;439f
	ld a,0a4h		;43a2   ; y la pieza 0xA4
	call pide_pieza		;43a4
	jp sube_de_subescena		;43a7
ronda_pasada_2:
	djnz ronda_pasada_espera		;43aa
	call mueve_a_los_nueve		;43ac
	ld a,(0e251h)		;43af   ; si queda algo en marcha, se espera
	and a			;43b2
	ret nz			;43b3
	ld a,(0e06ch)		;43b4   ; despues de la ronda 5
	cp 006h		;43b7
	jr nc,L_4376		;43b9   ; se vuelve al titulo: el juego da la vuelta
	call da_la_contrasena		;43bb   ; y si no, se pinta el nombre de la ronda
	jp sube_de_subescena		;43be
ronda_pasada_espera:
	djnz ronda_pasada_suma_vida		;43c1
	ld a,(0e008h)		;43c3   ; el disparo
	and 010h		;43c6
	ret z			;43c8
	ld a,0adh		;43c9   ; la pieza del silencio
	call pide_pieza		;43cb
	jp L_4362		;43ce
ronda_pasada_suma_vida:
	call cortina		;43d1   ; espera a que suelte
	ret p			;43d4
	call limpia_el_marcador		;43d5   ; pone el marcador a cero
	ld hl,0e060h		;43d8
	ld a,(hl)			;43db
	add a,001h		;43dc   ; y regala una vida
	daa			;43de   ; otra vez en BCD
	ld (hl),a			;43df
	ld hl,0e06ch		;43e0
	inc (hl)			;43e3   ; y sube de ronda
	jp sube_de_subescena		;43e4

; ----------------------------------------------------------------------
; EL REMATE DEL CUADRO: lo que 0x40EA empuja a mano
; ----------------------------------------------------------------------
remata_el_cuadro:
	call lee_mando_y_teclado		;43e7   ; se relee el mando
	ld hl,0e052h		;43ea   ; contra el estado guardado en 0xE052
	call L_4733		;43ed
	or a			;43f0   ; si no se ha pulsado nada nuevo, se acabo
	ret z			;43f1
	ld hl,0e004h		;43f2   ; y si si, 0xC0 cuadros
	ld (hl),0c0h		;43f5
	ld hl,0e000h		;43f7
	ld b,(hl)			;43fa   ; la escena de ahora
	djnz vuelve_al_titulo		;43fb   ; con la escena 1 se sigue por aqui; con cualquier otra, se salta
	and 030h		;43fd   ; y solo con los botones de disparo
	ret z			;43ff
	ld a,040h		;4400   ; el bit 6 de (0xE002) enciende el sonido
	ld (0e002h),a		;4402
	ld (hl),003h		;4405   ; escena 3
	inc hl			;4407
	ld (hl),000h		;4408   ; subescena 0: a jugar
	ret			;440a
vuelve_al_titulo:
	ld (hl),001h		;440b   ; escena 1
	ld a,0adh		;440d   ; con el silencio
	call pide_pieza		;440f
	jp monta_el_titulo_y_el_rotulo		;4412   ; y montando el titulo

; ----------------------------------------------------------------------
; GUARDAR Y DEVOLVER UN TROZO DE PANTALLA
; ----------------------------------------------------------------------
guarda_de_la_pantalla:
	call sitio_del_rotulo_de_pausa		;4415   ; saca el sitio y la cuenta
L_4418:
	call 0004ah		;4418   ; BIOS RDVRM - Reads the content of VRAM | lee de la VRAM
	ld (de),a			;441b   ; y lo va dejando en RAM
	inc hl			;441c
	inc de			;441d
	djnz L_4418		;441e
	exx			;4420
	ret			;4421

; ----------------------------------------------------------------------
; EL ROTULO DE LA PAUSA
; ----------------------------------------------------------------------
sitio_del_rotulo_de_pausa:
	exx			;4422
	ld hl,0396ch		;4423   ; 0x396C es donde va, en la fila de en medio
	ld de,0e1c0h		;4426   ; y ahi se guarda lo que habia
	ld b,007h		;4429   ; siete casillas
	ret			;442b
devuelve_lo_que_habia:
	call sitio_del_rotulo_de_pausa		;442c
L_442F:
	ld a,(de)			;442f   ; casilla a casilla
	call 0004dh		;4430   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4433
	inc de			;4434
	djnz L_442F		;4435
	exx			;4437
	ret			;4438
parpadea_la_pausa:
	ld hl,0396ch		;4439
	ld bc,00007h		;443c
	ld a,(0e003h)		;443f   ; el contador de cuadros
	bit 2,a		;4442   ; su bit 2 hace el parpadeo, cuatro cuadros puesto y cuatro quitado
	jr z,L_444A		;4444
	xor a			;4446   ; se borra
	jp 00056h		;4447   ; BIOS FILVRM - Fills VRAM with value
L_444A:
	ld de,04450h		;444a   ; o se pinta " PAUSE "
	jp vuelca_bc_bytes		;444d

; ----------------------------------------------------------------------
; DATOS rotulo_de_pausa: siete casillas: espacio, PAUSE y espacio; lo vuelca
;   0x444A
;   0x4450..0x4457  (7 bytes)
DATA_rotulo_de_pausa:
	defb 000h,030h,021h,035h,033h,025h,000h	; 4450

; ======================================================================
; CODIGO 0x4457..0x4487  (48 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EMPEZAR UNA PARTIDA DE CERO
; ----------------------------------------------------------------------
partida_nueva:
	ld hl,0e056h		;4457   ; borra de 0xE056 a 0xE58C: el marcador y todo lo demas
	ld bc,00536h		;445a
	ld d,h			;445d
	ld e,l			;445e
	inc e			;445f
	ld (hl),000h		;4460
	ldir		;4462
	ld a,001h		;4464
	ld (0e06ch),a		;4466   ; ronda 1
estado_de_arranque:
	ld hl,0449dh		;4469   ; los seis bytes de arranque
	ld de,0e060h		;446c
	ld bc,00006h		;446f
	ldir		;4472
	ld a,003h		;4474
	ld (0e122h),a		;4476   ; (0xE122) a 3 dice que hay que recalcular el nivel a partir de la ronda
	ld hl,04487h		;4479   ; y los veintidos de 0xE150
	ld de,0e150h		;447c
	ld bc,00016h		;447f
	ldir		;4482
	jp limpia_el_marcador		;4484

; ----------------------------------------------------------------------
; DATOS estado_inicial_de_e150: 22 bytes que 0x4479 copia tal cual a 0xE150
;   0x4487..0x449d  (22 bytes)
DATA_estado_inicial_de_e150:
	defb 0ffh,005h,005h,005h,002h,005h,004h,005h,080h,060h,005h,040h,005h,005h,005h,005h,005h,010h,002h,002h,002h,002h	; 4487  .........`.@..........

; ----------------------------------------------------------------------
; DATOS estado_inicial_de_la_partida: seis bytes a 0xE060: entre ellos el
;   nivel (1) y la sala (0)
;   0x449d..0x44a3  (6 bytes)
DATA_estado_inicial_de_la_partida:
	defb 001h,001h,000h,000h,050h,000h	; 449d

; ======================================================================
; CODIGO 0x44a3..0x45bf  (284 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL BORRADO EN CORTINA
; ----------------------------------------------------------------------
cortina:
	ld hl,0e004h		;44a3   ; la cuenta atras de la escena
	dec (hl)			;44a6
	ret m			;44a7   ; con signo: al pasar de cero se acaba
	ld a,(hl)			;44a8
	ld h,038h		;44a9   ; la tabla de nombres
	xor 01fh		;44ab   ; del reves, para que la cortina vaya de un lado al otro
	add a,040h		;44ad   ; dos filas mas abajo
	ld l,a			;44af
	ld b,014h		;44b0   ; veinte filas
	xor a			;44b2
	ld de,00020h		;44b3   ; 32 casillas por fila, o sea la misma columna en todas
L_44B6:
	call 0004dh		;44b6   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;44b9
	djnz L_44B6		;44ba
aparca_los_sprites_en_vram:
	ld hl,03b00h		;44bc   ; la tabla de atributos
	ld bc,00080h		;44bf   ; 128 bytes
	ld a,0c3h		;44c2   ; 0xC3 de coordenada deja los sprites fuera
	call 00056h		;44c4   ; BIOS FILVRM - Fills VRAM with value
	xor a			;44c7
	ret			;44c8
limpia_la_sala:
	call aparca_los_sprites_en_vram		;44c9
	ld hl,03840h		;44cc   ; dos filas mas abajo de la tabla de nombres
	ld bc,00280h		;44cf   ; las 640 casillas de la sala
	xor a			;44d2
	jp 00056h		;44d3   ; BIOS FILVRM - Fills VRAM with value
suma_c_cero:
	ld c,000h		;44d6

; ----------------------------------------------------------------------
; SUMAR PUNTOS, EN BCD
; ----------------------------------------------------------------------
suma_puntos:
	ld a,(0e002h)		;44d8   ; el bit 6 de (0xE002)
	add a,a			;44db   ; subido al 7 para poder mirarlo con `ret p`
	ret p			;44dc
	ld hl,0e056h		;44dd   ; el marcador, tres bytes en BCD
	ld a,(hl)			;44e0
	add a,e			;44e1   ; se suma el byte bajo
	daa			;44e2   ; y `daa` arregla el resultado a decimal: por eso el marcador se puede pintar sin dividir por diez
	ld (hl),a			;44e3
	inc hl			;44e4
	ld a,(hl)			;44e5   ; el de en medio, con acarreo
	adc a,d			;44e6
	daa			;44e7
	ld (hl),a			;44e8
	inc hl			;44e9
	ld a,(hl)			;44ea   ; y el alto
	adc a,c			;44eb
	daa			;44ec
	ld (hl),a			;44ed
	jr nc,L_44FD		;44ee   ; si se ha pasado de 999999
	ld bc,09999h		;44f0   ; se clava en 999999
	ld (0e053h),bc		;44f3   ; y tambien el record
	ld (0e054h),bc		;44f7
	jr pinta_los_puntos		;44fb
L_44FD:
	ld b,003h		;44fd   ; tres bytes
	ld de,0e055h		;44ff   ; el record
L_4502:
	ld a,(de)			;4502   ; se comparan de arriba abajo
	sub (hl)			;4503
	jr c,L_450C		;4504   ; si el record es mayor, no hay nada que hacer
	jr nz,pinta_los_puntos		;4506   ; y si es menor, hay record nuevo
	dec l			;4508
	dec e			;4509
	djnz L_4502		;450a
L_450C:
	ld bc,00003h		;450c   ; tres bytes
	ld e,055h		;450f
	ld l,058h		;4511
	lddr		;4513   ; copiados de atras adelante
	jr pinta_los_puntos		;4515

; ----------------------------------------------------------------------
; PINTAR EL MARCADOR ENTERO
; ----------------------------------------------------------------------
pinta_el_marcador:
	ld de,0478ch		;4517   ; el guion de la pantalla de juego
	call pinta_guion		;451a
	call pinta_el_nivel		;451d   ; la ronda y el nivel
	call pinta_las_dos_barras		;4520
	call pinta_el_inventario		;4523
	call borra_la_fila_de_abajo		;4526   ; la fila de arriba
	call parpadea_la_fila_de_abajo		;4529   ; y la de abajo
pinta_los_puntos:
	ld de,0e055h		;452c   ; el marcador
	ld hl,03804h		;452f   ; en 0x3804
	call L_453B		;4532
	ld hl,03824h		;4535   ; y el record en 0x3824
	ld de,0e058h		;4538
L_453B:
	ld b,003h		;453b   ; tres bytes, o sea seis cifras
	jr escribe_en_bcd		;453d

; ----------------------------------------------------------------------
; LAS CIFRAS SUELTAS DEL MARCADOR
; ----------------------------------------------------------------------
pinta_el_nivel:
	ld hl,0383ah		;453f   ; 0x383A: el numero de nivel
	ld de,0e067h		;4542   ; en BCD, tal como lo dejo nivel_en_decimal
	ld b,001h		;4545
	call escribe_en_bcd		;4547
pinta_la_sala:
	ld hl,0383dh		;454a   ; 0x383D: el numero de sala
	ld a,(0e062h)		;454d   ; la sala, de 0 a 3
	inc a			;4550   ; mas uno, que es como se le ensena al jugador
	ld de,0e069h		;4551
	ld (de),a			;4554
	jr L_455A		;4555
pinta_la_ronda:
	ld de,0e06ch		;4557   ; la ronda
L_455A:
	ld b,001h		;455a
escribe_en_bcd:
	ld a,(de)			;455c   ; el byte
	rra			;455d   ; cuatro rotaciones bajan el nibble alto
	rra			;455e
	rra			;455f
	rra			;4560
	and 00fh		;4561
	add a,010h		;4563   ; y 0x10 lleva de la cifra a su casilla: los digitos estan del 0x10 al 0x19
	call 0004dh		;4565   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4568
	ld a,(de)			;4569   ; y el nibble bajo, igual
	and 00fh		;456a
	add a,010h		;456c
	call 0004dh		;456e   ; BIOS WRTVRM - Writes data in VRAM
	dec de			;4571   ; se va hacia atras porque las cifras se escriben de derecha a izquierda
	inc hl			;4572
	djnz escribe_en_bcd		;4573
	ret			;4575
parpadea_la_fila_de_abajo:
	ld a,(0e130h)		;4576   ; los amigos que se llevan
	cp 007h		;4579   ; con menos de siete no parpadea
	jr c,devuelve_la_fila_de_abajo		;457b
	ld a,(0e003h)		;457d   ; y con siete, el bit 4 del contador
	and 010h		;4580
	jr z,devuelve_la_fila_de_abajo		;4582
borra_la_fila_de_abajo:
	ld hl,03adbh		;4584   ; las cinco casillas del rotulo
	ld bc,00005h		;4587
	ld a,093h		;458a   ; al fondo de la fila
	call 00056h		;458c   ; BIOS FILVRM - Fills VRAM with value
	ld hl,03afbh		;458f   ; y las tres de la derecha, a cero
	ld bc,00003h		;4592
	xor a			;4595
	jp 00056h		;4596   ; BIOS FILVRM - Fills VRAM with value
devuelve_la_fila_de_abajo:
	ld hl,03adbh		;4599   ; lo que el marcador guarda en RAM
	ld de,0e075h		;459c   ; sus cuatro primeras casillas
	ld bc,00004h		;459f
	call vuelca_bc_bytes		;45a2
	ld hl,03afbh		;45a5   ; y las otras tres
	ld de,0e079h		;45a8
	ld bc,00003h		;45ab
	jp vuelca_bc_bytes		;45ae
casilla_de_la_sala_de_ahora:
	ld a,(0e062h)		;45b1   ; la sala en la que anda el jugador
casilla_de_la_sala_en_pixeles:
	push de			;45b4   ; igual que 0x45DA, pero con la coordenada en PIXELES
	push hl			;45b5
	ld hl,045ffh		;45b6   ; las cuatro bases
	call puntero_numero_a		;45b9
	pop hl			;45bc
	jr $+6		;45bd

; ----------------------------------------------------------------------
; DATOS cuatro_bytes_sin_lector: nadie los carga con una constante y el
;   trazado no entra; quedan aqui declarados y sin explicar mas
;   0x45bf..0x45c3  (4 bytes)
DATA_cuatro_bytes_sin_lector:
	defb 0d5h,011h,000h,038h	; 45bf

; ======================================================================
; CODIGO 0x45c3..0x45ff  (60 bytes)
; ======================================================================


de_pixeles_a_direccion:
	ld a,l			;45c3   ; la fila entre ocho y por 32, hecho con rotaciones
	rra			;45c4
	rra			;45c5
	rra			;45c6
	rra			;45c7
	rr h		;45c8   ; arrastrando el bajo de la columna
	rra			;45ca
	rr h		;45cb
	rra			;45cd
	rr h		;45ce
	ld l,h			;45d0
	and 003h		;45d1   ; el resultado se queda en trece bits
	ld h,a			;45d3
	add hl,de			;45d4   ; mas la base de la sala
	pop de			;45d5
	ret			;45d6
L_45D7:
	ld a,(0e062h)		;45d7

; ----------------------------------------------------------------------
; DE COORDENADA A DIRECCION: la misma cuenta, tres bases distintas
; ----------------------------------------------------------------------
casilla_de_la_sala:
	push de			;45da   ; entra con h = columna, l = fila, y a = que sala
	push hl			;45db
	ld hl,045ffh		;45dc   ; las cuatro bases de las salas, con dos filas de sesgo
	call puntero_numero_a		;45df   ; de = base de la sala que toca
	pop hl			;45e2
	jr L_45E9		;45e3   ; y a hacer la cuenta
casilla_de_la_pantalla:
	push de			;45e5   ; la misma cuenta pero contra la tabla de nombres
	ld de,03800h		;45e6   ; 0x3800, que es donde el registro 2 pone los nombres
L_45E9:
	ld a,h			;45e9   ; lo que viene es fila*32 + columna, hecho a base de rotaciones
	rla			;45ea   ; tres veces a la izquierda: la fila se sube a su sitio
	rla			;45eb
	rla			;45ec
	ld h,a			;45ed
	ld a,l			;45ee   ; y tres a la derecha arrastrando el bajo, que es lo que mete la columna por debajo
	rra			;45ef
	rr h		;45f0
	rra			;45f2
	rr h		;45f3
	rra			;45f5
	rr h		;45f6
	ld l,h			;45f8
	and 01fh		;45f9   ; el resultado se queda en trece bits, que es lo que ocupa la VRAM
	ld h,a			;45fb
	add hl,de			;45fc   ; y se le suma la base
	pop de			;45fd
	ret			;45fe

; ----------------------------------------------------------------------
; DATOS bases_de_las_cuatro_salas: 0xE5C0, 0xE840, 0xEAC0 y 0xED40: las cuatro
;   salas, pero con DOS FILAS de sesgo, porque el mapa empieza a contar en la
;   fila 2
;   0x45ff..0x4607  (8 bytes)
DATA_bases_de_las_cuatro_salas:
	defw 0e5c0h,0e840h,0eac0h,0ed40h	; 45ff

; ======================================================================
; CODIGO 0x4607..0x467e  (119 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; SACAR UN PUNTERO DE UNA TABLA POR INDICE
; ----------------------------------------------------------------------
puntero_numero_a:
	add a,a			;4607   ; dos bytes por entrada
	call suma_a_a_hl		;4608   ; hl = tabla + a*2
	ld e,(hl)			;460b   ; y de se queda con el puntero
	inc hl			;460c
	ld d,(hl)			;460d
	ret			;460e
nivel_en_decimal:
	ld a,(0e061h)		;460f   ; el nivel va en binario de 1 a 25
	ld b,a			;4612
	ld c,000h		;4613
L_4615:
	ld a,b			;4615   ; restar diez y llevar la cuenta en el nibble alto es hacer la division sin dividir
	sub 00ah		;4616
	jr c,L_4621		;4618
	ld b,a			;461a
	ld a,c			;461b
	add a,010h		;461c
	ld c,a			;461e
	jr L_4615		;461f
L_4621:
	ld a,c			;4621
	or b			;4622
	ld (0e067h),a		;4623   ; y en (0xE067) queda en BCD, listo para pintarlo
	ret			;4626

; ----------------------------------------------------------------------
; BORRAR LA PANTALLA
; ----------------------------------------------------------------------
limpia_la_pantalla:
	call aparca_los_sprites_en_vram		;4627
	ld hl,03800h		;462a   ; la tabla de nombres
	ld bc,00300h		;462d   ; las 768 casillas de 32x24
	xor a			;4630
	jp 00056h		;4631   ; BIOS FILVRM - Fills VRAM with value | a cero de un golpe

; ----------------------------------------------------------------------
; LOS VOLCADOS A VRAM
; ----------------------------------------------------------------------
abre_para_escribir:
	ex af,af'			;4634   ; guarda a, que el interprete lo esta usando
	call 00053h		;4635   ; BIOS SETWRT - Enables VDP to write | SETWRT deja el VDP apuntando a hl y listo para recibir bytes
	exx			;4638
	ld a,(00007h)		;4639   ; 0x0007 de la ROM del BIOS trae el puerto de datos del VDP
	ld c,a			;463c   ; y se queda en c', en el juego alterno, para poder hacer `out (c),a` sin tocar el bc de trabajo
	exx			;463d
	ex af,af'			;463e
	ret			;463f
vuelca_c_bytes:
	ld b,000h		;4640   ; la version corta: solo el byte bajo de la cuenta
vuelca_bc_bytes:
	ex de,hl			;4642   ; LDIRVM quiere hl origen y de destino, y aqui llegan al reves
	jp 0005ch		;4643   ; BIOS LDIRVM - Block transfers to VRAM from memory
vuelca_en_los_tres_bancos:
	exx			;4646
	ld b,003h		;4647   ; tres bancos
vuelca_un_banco:
	exx			;4649   ; el mismo volcado, banco a banco
	push bc			;464a
	push de			;464b
	call vuelca_bc_bytes		;464c
	ld de,00800h		;464f   ; y cada uno 0x800 mas alla que el anterior
	add hl,de			;4652   ; y 0x800 mas alla el siguiente
	pop de			;4653
	pop bc			;4654
	exx			;4655
	djnz vuelca_un_banco		;4656
	ret			;4658
rellena_los_tres_bancos:
	ld d,003h		;4659   ; lo mismo pero rellenando con un valor
L_465B:
	push bc			;465b
	push de			;465c
	call 00056h		;465d   ; BIOS FILVRM - Fills VRAM with value
	ld de,00800h		;4660
	add hl,de			;4663
	pop de			;4664
	pop bc			;4665
	dec d			;4666
	jr nz,L_465B		;4667
	ret			;4669

; ----------------------------------------------------------------------
; DESCOMPRIMIR EN VARIOS BANCOS
; ----------------------------------------------------------------------
guion_en_tres_bancos:
	ld b,003h		;466a   ; los tres bancos de la pantalla
	jr L_4670		;466c
guion_en_dos_bancos:
	ld b,002h		;466e   ; o solo los dos primeros, para las casillas que nunca bajan al ultimo tercio
L_4670:
	push bc			;4670
	push de			;4671
	call L_46A3		;4672   ; cada pasada relee el guion entero desde el principio
	ld de,00800h		;4675   ; y sube 0x800
	add hl,de			;4678
	pop de			;4679
	pop bc			;467a
	djnz L_4670		;467b
	ret			;467d

; ----------------------------------------------------------------------
; DATOS cuatro_bytes_sin_lector_467e: lo mismo: caen entre L_466E y L_4682 y
;   no los lee nadie
;   0x467e..0x4682  (4 bytes)
DATA_cuatro_bytes_sin_lector_467e:
	defb 00eh,0ffh,018h,008h	; 467e

; ======================================================================
; CODIGO 0x4682..0x4720  (158 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL GUION LITERAL: el mismo sirve para pintar y para borrar
; ----------------------------------------------------------------------
pinta_guion:
	ld c,0ffh		;4682   ; c = 0xFF: los bytes pasan tal cual
guion_literal:
	ex de,hl			;4684   ; los dos primeros bytes son la direccion de VRAM
	ld e,(hl)			;4685
	inc hl			;4686
	ld d,(hl)			;4687
	ex de,hl			;4688
	inc de			;4689   ; y el guion sigue detras
byte_del_guion:
	ld a,(de)			;468a   ; siguiente byte
	inc de			;468b
	ld b,a			;468c
	inc b			;468d   ; 0xFF: se acabo
	ret z			;468e
	inc b			;468f   ; 0xFE: cambia de sitio y sigue, que es como un guion pinta varios trozos sueltos
	jr z,guion_literal		;4690
	and c			;4692   ; aqui es donde la mascara decide: con 0xFF el byte pasa entero, con 0x00 sale un cero
	call 0004dh		;4693   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM de uno en uno, que es lento pero da igual: estos guiones son cortos
	inc hl			;4696
	jr byte_del_guion		;4697
borra_guion:
	ld c,000h		;4699   ; c = 0: el mismo guion, pero escribiendo ceros. Asi se borra exactamente lo que se pinto, sin guardar nada aparte
	jr guion_literal		;469b

; ----------------------------------------------------------------------
; EL GUION COMPRIMIDO, por el puerto del VDP
; ----------------------------------------------------------------------
guion_rle:
	ex de,hl			;469d   ; la direccion de VRAM, dentro del guion
	ld e,(hl)			;469e
	inc hl			;469f
	ld d,(hl)			;46a0
	ex de,hl			;46a1
	inc de			;46a2
L_46A3:
	call abre_para_escribir		;46a3   ; abre el VDP y deja el puerto en c'
orden_del_rle:
	ld a,(de)			;46a6   ; 0x00 cierra el guion
	and a			;46a7
	ret z			;46a8
	inc de			;46a9
	ld b,a			;46aa   ; b se queda con la orden entera
	and 07fh		;46ab   ; y a con ella sin el bit 7
	cp b			;46ad   ; si son iguales, el bit 7 estaba a cero
	jr z,repite_un_byte		;46ae   ; y entonces es una REPETICION, no un literal
	and a			;46b0   ; el 0x80 pelado pide otra direccion de VRAM
	jr z,guion_rle		;46b1
	ld b,a			;46b3   ; lo que queda es la cuenta
L_46B4:
	ld a,(de)			;46b4   ; y aqui se relee el guion en cada vuelta: por eso este es el caso LITERAL
	inc de			;46b5
	exx			;46b6
	out (c),a		;46b7   ; al puerto, sin pasar por el BIOS
	exx			;46b9
	djnz L_46B4		;46ba   ; el `djnz` vuelve al `ld a,(de)`, o sea a leer otro byte
	jr orden_del_rle		;46bc
repite_un_byte:
	ld a,(de)			;46be   ; un solo byte
	inc de			;46bf
L_46C0:
	exx			;46c0
	out (c),a		;46c1   ; y este `djnz` vuelve al `out`, no al `ld`: por eso se repite
	exx			;46c3
	djnz L_46C0		;46c4
	jr orden_del_rle		;46c6

; ----------------------------------------------------------------------
; FABRICAR LOS SPRITES QUE MIRAN AL OTRO LADO
; ----------------------------------------------------------------------
espeja_sprites:
	call espeja_un_sprite		;46c8   ; uno
	ld a,020h		;46cb   ; y el siguiente, 32 bytes mas alla
	call suma_a_a_de		;46cd
	dec c			;46d0
	jr nz,espeja_sprites		;46d1   ; c patrones
	ret			;46d3
espeja_un_sprite:
	push de			;46d4
L_46D5:
	ld b,010h		;46d5   ; dieciseis filas de golpe
L_46D7:
	call 0004ah		;46d7   ; BIOS RDVRM - Reads the content of VRAM | lee de la VRAM
	call vuelve_los_bits		;46da   ; le da la vuelta a los ocho bits
	ex de,hl			;46dd
	call 0004dh		;46de   ; BIOS WRTVRM - Writes data in VRAM | y la escribe en el destino
	ex de,hl			;46e1
	inc e			;46e2   ; ojo: sube SOLO el byte bajo, asi que se queda dentro de la misma pagina
	inc hl			;46e3
	djnz L_46D7		;46e4
	ld a,e			;46e6
	sub 020h		;46e7   ; y aqui baja 0x20, que junto al `inc e` de arriba deja las dos columnas del sprite CAMBIADAS DE SITIO. Espejar un 16x16 es eso: invertir los bits y cambiar la mitad izquierda por la derecha
	ld e,a			;46e9
	bit 4,e		;46ea   ; el bit 4 dice cuando se han hecho las dos mitades
	jr z,L_46D5		;46ec
	pop de			;46ee
	ret			;46ef
vuelve_los_bits:
	push bc			;46f0   ; saca por la izquierda de a lo que entra por la derecha de c: ocho vueltas y el byte queda del reves
	ld c,a			;46f1
	ld b,008h		;46f2
L_46F4:
	rr c		;46f4
	rla			;46f6
	djnz L_46F4		;46f7
	pop bc			;46f9
	ret			;46fa

; ----------------------------------------------------------------------
; EL MONTAJE DE ARRANQUE
; ----------------------------------------------------------------------
arranca_la_pantalla:
	ld a,0b8h		;46fb   ; pide la pieza 0xB8
	call escribe_el_mezclador		;46fd
	ld a,0adh		;4700   ; y la 0xAD con la pantalla apagada
	call suena_con_pantalla_apagada		;4702
	ld hl,00000h		;4705   ; borra los 16 KB de VRAM enteros
	ld bc,04000h		;4708
	xor a			;470b
	call 00056h		;470c   ; BIOS FILVRM - Fills VRAM with value
pon_los_registros_del_vdp:
	ld hl,04720h		;470f   ; y pone los registros
	ld d,008h		;4712   ; registros 0 a 7
	ld c,000h		;4714   ; empezando por el 0
L_4716:
	ld b,(hl)			;4716
	call 00047h		;4717   ; BIOS WRTVDP - Writes data in the VDP-register | uno por vuelta
	inc hl			;471a
	inc c			;471b
	dec d			;471c
	jr nz,L_4716		;471d
	ret			;471f

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: los ocho bytes de R0 a R7, en orden; los vuelca
;   L_470F
;   0x4720..0x4728  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e4h	; 4720  .....v..

; ======================================================================
; CODIGO 0x4728..0x477b  (83 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL COLOR DEL BORDE
; ----------------------------------------------------------------------
pon_el_borde:
	ld c,007h		;4728   ; el registro 7 lleva el color del borde en el nibble bajo
	jp pon_registro_del_vdp		;472a

; ----------------------------------------------------------------------
; LEER LOS MANDOS
; ----------------------------------------------------------------------
lee_los_mandos:
	call lee_mando_y_teclado		;472d   ; a = lo que esta pulsado ahora
mete_estos_mandos:
	ld hl,0e009h		;4730   ; aqui se entra tambien DESDE LA DEMOSTRACION, con `a` puesto a mano: por eso la grabacion puede hacerse pasar por el jugador
L_4733:
	ld c,(hl)			;4733   ; c = lo de antes
	ld (hl),a			;4734
	xor c			;4735   ; lo que ha cambiado
	and (hl)			;4736   ; y de eso, lo que se acaba de PULSAR
	dec hl			;4737
	ld c,(hl)			;4738
	ld (hl),a			;4739
	push af			;473a
	dec hl			;473b
	ld (hl),c			;473c   ; 0xE007 guarda el estado crudo
	dec hl			;473d
	or c			;473e   ; y 0xE006 acumula, para las teclas que se leen una vez y se olvidan
	ld (hl),a			;473f
	pop af			;4740
	ret			;4741

; ----------------------------------------------------------------------
; LOS DOS MANDOS Y EL TECLADO, EN UN SOLO BYTE
; ----------------------------------------------------------------------
lee_mando_y_teclado:
	ld e,08fh		;4742   ; 0x8F selecciona el puerto A del PSG como entrada
	ld a,00fh		;4744
	call 00093h		;4746   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;4749   ; y el registro 14 trae el mando
	di			;474b
	call 00096h		;474c   ; BIOS RDPSG - Reads value from PSG-register
	ei			;474f
	cpl			;4750   ; el mando da los bits al reves
	and 03fh		;4751   ; y solo interesan seis
	push af			;4753
	ld a,007h		;4754   ; fila 7 del teclado
	call 00141h		;4756   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4759
	rrca			;475a
	and 020h		;475b
	ld e,a			;475d
	ld a,008h		;475e   ; fila 8
	call 00141h		;4760   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4763
	rrca			;4764
	rrca			;4765
	ld b,a			;4766
	and 004h		;4767
	or e			;4769
	ld c,a			;476a
	ld a,b			;476b
	rrca			;476c
	rrca			;476d
	ld b,a			;476e
	and 018h		;476f
	or c			;4771
	ld c,a			;4772
	ld a,b			;4773
	rrca			;4774
	and 003h		;4775
	or c			;4777
	pop bc			;4778
	or b			;4779   ; y las dos cosas se juntan en el mismo byte, asi que al juego le da igual de donde venga
	ret			;477a

; ----------------------------------------------------------------------
; DATOS guion_del_marcador: RLE de 17 bytes, 20 a VRAM en dos tramos; lo pinta
;   0x4113
;   0x477b..0x478c  (17 bytes)
DATA_guion_del_marcador:
	defb 04ah,039h,00ch,05ah,080h,06ch,039h,088h,033h,02fh,026h,034h,037h,021h,032h,025h	; 477b  J9.Z.l9.3/&47!2%
	defb 000h	; 478b

; ----------------------------------------------------------------------
; DATOS guion_de_la_pantalla_de_juego: literal, siete tramos: el marcador
;   entero
;   0x478c..0x47b5  (41 bytes)
DATA_guion_de_la_pantalla_de_juego:
	defb 001h,038h,028h,029h,020h,0feh,021h,038h,011h,030h,020h,0feh,01ah,038h,033h,023h	; 478c  .8() .!8.0 ..83#
	defb 025h,02eh,025h,0feh,03ch,038h,020h,0feh,00bh,038h,036h,029h,034h,0feh,02bh,038h	; 479c  %.%.<8 ..86)4.+8
	defb 025h,038h,030h,0feh,0d9h,03ah,002h,0b5h,0ffh	; 47ac  %80..:...

; ----------------------------------------------------------------------
; DATOS guion_de_las_vidas: literal, 8 bytes en 0x38EC
;   0x47b5..0x47c0  (11 bytes)
DATA_guion_de_las_vidas:
	defb 0ech,038h,033h,034h,021h,027h,025h,000h,000h,000h,0ffh	; 47b5  .834!'%....

; ----------------------------------------------------------------------
; DATOS guion_de_la_llave: literal, 12 bytes en 0x394A
;   0x47c0..0x47cf  (15 bytes)
DATA_guion_de_la_llave:
	defb 04ah,039h,01ah,02bh,02fh,02eh,021h,02dh,029h,000h,011h,019h,018h,016h,0ffh	; 47c0  J9.+/.!-)......

; ----------------------------------------------------------------------
; DATOS guion_de_la_fila_de_abajo: literal, 10 bytes en 0x3A8B
;   0x47cf..0x47dc  (13 bytes)
DATA_guion_de_la_fila_de_abajo:
	defb 08bh,03ah,030h,02ch,021h,039h,000h,033h,034h,021h,032h,034h,0ffh	; 47cf  .:0,!9.34!24.

; ----------------------------------------------------------------------
; DATOS guion_de_la_fila_de_arriba: literal, 10 bytes en 0x396B
;   0x47dc..0x47e9  (13 bytes)
DATA_guion_de_la_fila_de_arriba:
	defb 06bh,039h,027h,021h,02dh,025h,000h,000h,02fh,036h,025h,032h,0ffh	; 47dc  k9'!-%../6%2.

; ----------------------------------------------------------------------
; DATOS guion_del_recuadro: literal, cuatro tramos de 27, 19, 22 y 20 bytes
;   0x47e9..0x484d  (100 bytes)
DATA_guion_del_recuadro:
	defb 0c3h,039h,034h,028h,025h,000h,027h,02fh,02fh,02eh,029h,025h,033h,0f0h,0f1h,029h	; 47e9  .94(%.'//.)%3..)
	defb 033h,000h,021h,000h,034h,032h,021h,024h,025h,02dh,021h,032h,02bh,0feh,0e3h,039h	; 47f9  3.!.42!$%-!2+..9
	defb 02fh,026h,000h,037h,021h,032h,02eh,025h,032h,000h,022h,032h,02fh,033h,03dh,029h	; 4809  /&.7!2.%2."2/3=)
	defb 02eh,023h,03dh,0feh,025h,03ah,01ah,011h,019h,018h,015h,000h,037h,021h,032h,02eh	; 4819  .#=.%:......7!2.
	defb 025h,032h,000h,022h,032h,02fh,033h,03dh,029h,02eh,023h,03dh,0feh,045h,03ah,021h	; 4829  %2."2/3=).#=.E:!
	defb 02ch,02ch,000h,032h,029h,027h,028h,034h,033h,000h,032h,025h,033h,025h,032h,036h	; 4839  ,,.2)'(43.2%3%26
	defb 025h,024h,03dh,0ffh	; 4849

; ======================================================================
; CODIGO 0x484d..0x4885  (56 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA FUENTE
; ----------------------------------------------------------------------
monta_la_fuente:
	call limpia_la_fuente		;484d   ; limpia la zona
	ld de,04885h		;4850   ; el guion de la presentacion
	ld hl,02080h		;4853   ; en los tres bancos desde 0x2080, o sea desde la casilla 0x10
	call guion_en_tres_bancos		;4856
	ld a,0f0h		;4859   ; 0xF0 es tinta blanca sobre papel negro
	ld hl,00080h		;485b   ; y ese color para las casillas 0x10 en adelante
	ld bc,00180h		;485e
	jp rellena_los_tres_bancos		;4861
limpia_la_fuente:
	ld hl,02000h		;4864   ; las 16 primeras casillas
	ld bc,00080h		;4867
	xor a			;486a
	call rellena_los_tres_bancos		;486b   ; a cero
	ld hl,00000h		;486e   ; el color
	ld de,00008h		;4871   ; ocho bytes por casilla
	ld b,010h		;4874   ; dieciseis casillas
L_4876:
	push bc			;4876
	ld bc,00008h		;4877
	push hl			;487a
	call rellena_los_tres_bancos		;487b
	pop hl			;487e
	add hl,de			;487f
	inc a			;4880   ; y cada una de un color distinto: sale una rampa de dieciseis colores, que es lo que se usa de fondo
	pop bc			;4881
	djnz L_4876		;4882
	ret			;4884

; ----------------------------------------------------------------------
; DATOS guion_de_la_presentacion: RLE, 368 bytes a VRAM; lo carga 0x4850
;   0x4885..0x49bb  (310 bytes)
DATA_guion_de_la_presentacion:
	defb 08bh,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h,004h,018h,0c9h,07eh	; 4885  ..."ccc"...8...~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh	; 4895  .>c..<p..>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h,003h,063h,03eh	; 48a5  ...6ff....`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,006h,00ch,018h,018h,018h	; 48b5  .>c`~cc>..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh	; 48c5  .>cc>cc>.>cc?.c>
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,028h,000h,004h,000h,001h,07eh,004h,000h	; 48d5  <B....B<(....~..
	defb 0c1h,01ch,036h,063h,063h,07fh,063h,063h,000h,07eh,063h,063h,07eh,063h,063h,07eh	; 48e5  ..6cc.cc.~cc~cc~
	defb 000h,03eh,063h,060h,060h,060h,063h,03eh,000h,07ch,066h,063h,063h,063h,066h,07ch	; 48f5  .>c```c>.|fcccf|
	defb 000h,07fh,060h,060h,07eh,060h,060h,07fh,000h,07fh,060h,060h,07eh,060h,060h,060h	; 4905  ..``~``...``~```
	defb 000h,03eh,063h,060h,067h,063h,063h,03fh,000h,063h,063h,063h,07fh,063h,063h,063h	; 4915  .>c`gcc?.ccc.ccc
	defb 000h,03ch,005h,018h,083h,03ch,000h,01fh,004h,006h,08bh,066h,03ch,000h,063h,066h	; 4925  .<...<.....f<.cf
	defb 06ch,078h,07ch,06eh,067h,000h,006h,060h,093h,07fh,000h,063h,077h,07fh,07fh,06bh	; 4935  lx|ng..`...cw..k
	defb 063h,063h,000h,063h,073h,07bh,07fh,06fh,067h,063h,000h,03eh,005h,063h,0a3h,03eh	; 4945  cc.cs{.ogc.>.c.>
	defb 000h,07eh,063h,063h,063h,07eh,060h,060h,000h,03eh,063h,063h,063h,06fh,066h,03dh	; 4955  .~ccc~``.>cccof=
	defb 000h,07eh,063h,063h,062h,07ch,066h,063h,000h,03eh,063h,060h,03eh,003h,063h,03eh	; 4965  .~ccb|fc.>c`>.c>
	defb 000h,07eh,006h,018h,001h,000h,006h,063h,082h,03eh,000h,004h,063h,0b3h,036h,01ch	; 4975  .~.....c.>..c.6.
	defb 008h,000h,063h,063h,06bh,06bh,07fh,077h,022h,000h,063h,076h,03ch,01ch,01eh,037h	; 4985  ..cckk.w".cv<..7
	defb 063h,000h,066h,066h,07eh,03ch,018h,018h,018h,000h,07fh,007h,00eh,01ch,038h,070h	; 4995  c.ff~<........8p
	defb 07fh,03ch,066h,066h,00ch,018h,018h,000h,018h,008h,01ch,01ch,01ch,008h,008h,000h	; 49a5  .<ff............
	defb 008h,006h,000h,002h,030h,000h	; 49b5

; ======================================================================
; CODIGO 0x49bb..0x4a0f  (84 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA PRESENTACION QUE BAJA
; ----------------------------------------------------------------------
arranca_la_presentacion:
	ld a,00eh		;49bb   ; catorce pasos
	ld (0e00ah),a		;49bd
	ld hl,03aaah		;49c0   ; empezando por la ultima fila de la pantalla
	ld (0e00eh),hl		;49c3
	jp prepara_el_titulo		;49c6
monta_el_cartel:
	ld de,04a0fh		;49c9   ; el guion del cartel
	ld hl,06200h		;49cc   ; en los tres bancos desde 0x6200, que es 0x2200 con el bit 14 puesto: SETWRT lo tira, asi que da igual
	call guion_en_tres_bancos		;49cf
	ld hl,00200h		;49d2   ; y su color
	ld bc,000d8h		;49d5
	ld a,0f0h		;49d8   ; blanco sobre negro
	jp rellena_los_tres_bancos		;49da
baja_un_paso:
	ld hl,(0e00eh)		;49dd   ; por donde va
	ld de,0ffe0h		;49e0   ; una fila menos: 0x20 casillas hacia atras
	add hl,de			;49e3
	ld (0e00eh),hl		;49e4
	ld a,040h		;49e7   ; la casilla 0x40
	ld b,003h		;49e9   ; tres seguidas
	call escribe_seguidas_subiendo		;49eb
	ld bc,00b0ch		;49ee   ; luego once, empezando por la 0x0C
	call escribe_seguidas_subiendo		;49f1
	ld b,c			;49f4   ; y otras once
	call escribe_seguidas_subiendo		;49f5
	xor a			;49f8   ; y lo que queda de fila, a cero
	call 00056h		;49f9   ; BIOS FILVRM - Fills VRAM with value
	ld hl,0e00ah		;49fc   ; un paso menos
	dec (hl)			;49ff
	ret			;4a00
escribe_seguidas_subiendo:
	push hl			;4a01
L_4A02:
	call 0004dh		;4a02   ; BIOS WRTVRM - Writes data in VRAM | casilla
	inc hl			;4a05
	inc a			;4a06   ; y la siguiente, una mas
	djnz L_4A02		;4a07
	pop de			;4a09
	ld hl,00020h		;4a0a   ; al acabar, se baja una fila
	add hl,de			;4a0d
	ret			;4a0e

; ----------------------------------------------------------------------
; DATOS guion_del_cartel: RLE, 216 bytes a VRAM; lo carga 0x49C9
;   0x4a0f..0x4aa6  (151 bytes)
DATA_guion_del_cartel:
	defb 00fh,000h,001h,001h,006h,000h,082h,0ffh,0feh,008h,00fh,084h,0c3h,0c7h,0cfh,0dfh	; 4a0f  ................
	defb 003h,0ffh,089h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,007h,007h,005h,000h,083h,003h	; 4a1f  ................
	defb 0cfh,0dfh,005h,000h,083h,0e1h,0f9h,07dh,005h,000h,083h,0efh,0ffh,0f7h,005h,000h	; 4a2f  .......}........
	defb 083h,007h,08fh,09eh,005h,000h,083h,0f0h,0f8h,078h,005h,000h,083h,0f7h,0ffh,0fbh	; 4a3f  .........x......
	defb 005h,000h,08bh,08fh,0dfh,0f7h,00ch,01eh,01eh,00ch,000h,01eh,09eh,09eh,008h,00fh	; 4a4f  ................
	defb 090h,0ffh,0ffh,0dfh,0cfh,0c7h,0c3h,0c1h,0c0h,007h,087h,0c7h,0efh,0ffh,0ffh,0ffh	; 4a5f  ................
	defb 0fch,004h,0deh,084h,09eh,09fh,00fh,003h,005h,03dh,083h,07dh,0f9h,0e1h,008h,0e3h	; 4a6f  .........=.}....
	defb 090h,0dch,0c0h,0c7h,0deh,0dch,0deh,0cfh,0c3h,03ch,07ch,0fch,03ch,03ch,07ch,0fch	; 4a7f  .........<|.<<|.
	defb 0deh,008h,0f1h,008h,0e3h,008h,0deh,088h,038h,044h,0bah,0aah,0b2h,0aah,044h,038h	; 4a8f  ........8D....D8
	defb 003h,000h,001h,0ffh,004h,000h,000h	; 4a9f

; ======================================================================
; CODIGO 0x4aa6..0x4b16  (112 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA PANTALLA DEL TITULO
; ----------------------------------------------------------------------
monta_el_titulo:
	ld b,0e0h		;4aa6   ; borde 0
	call pon_el_borde		;4aa8
	call limpia_la_pantalla		;4aab   ; borra las 768 casillas
	call monta_la_fuente		;4aae
	ld hl,06580h		;4ab1   ; los patrones del rotulo, en los tres bancos desde 0x2580
	ld de,04b16h		;4ab4
	call guion_en_tres_bancos		;4ab7   ; o sea a partir de la casilla 0xB0
	ld hl,04580h		;4aba   ; y su color, en los tres bancos desde 0x0580
	ld de,04ccch		;4abd
	call guion_en_tres_bancos		;4ac0
	ld hl,00580h		;4ac3   ; dieciseis vueltas
	ld b,010h		;4ac6
L_4AC8:
	push bc			;4ac8
	ld b,003h		;4ac9   ; de tres casillas cada una
	ld a,0b0h		;4acb   ; 0xB0 es la primera casilla del rotulo
L_4ACD:
	call 0004dh		;4acd   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4ad0
	djnz L_4ACD		;4ad1
	ld a,005h		;4ad3   ; y de cinco en cinco: el rotulo se pinta dejando huecos
	call suma_a_a_hl		;4ad5
	pop bc			;4ad8
	djnz L_4AC8		;4ad9
	ret			;4adb
monta_el_titulo_y_el_rotulo:
	call monta_el_titulo		;4adc   ; la pantalla
	ld a,0b0h		;4adf   ; la primera casilla del rotulo
	ld de,00010h		;4ae1   ; dieciseis por fila
	ld hl,038a8h		;4ae4   ; la fila 5, columna 8
	call L_4B0C		;4ae7   ; y tres filas de dieciseis
	add hl,de			;4aea
	call L_4B0C		;4aeb
	add hl,de			;4aee
	call L_4B0C		;4aef
	add hl,de			;4af2
	ld b,012h		;4af3   ; la cuarta lleva dieciocho
	call L_4B0E		;4af5
	ld b,002h		;4af8   ; y dos casillas sueltas
	ld hl,0388fh		;4afa   ; en la fila 4
	call L_4B0E		;4afd
	ld de,047c0h		;4b00   ; el guion de KONAMI y el ano
	call pinta_guion		;4b03
	ld de,047e9h		;4b06   ; y el del aviso de marca
	jp pinta_guion		;4b09
L_4B0C:
	ld b,010h		;4b0c
L_4B0E:
	call 0004dh		;4b0e   ; BIOS WRTVRM - Writes data in VRAM
	inc a			;4b11
	inc hl			;4b12
	djnz L_4B0E		;4b13
	ret			;4b15

; ----------------------------------------------------------------------
; DATOS casillas_del_titulo: RLE, 544 bytes en los tres bancos de patrones
;   desde 0x2580; lo carga 0x4AB4
;   0x4b16..0x4ccc  (438 bytes)
DATA_casillas_del_titulo:
	defb 085h,000h,001h,003h,007h,00fh,003h,01fh,081h,000h,007h,0ffh,085h,000h,0f0h,0f8h	; 4b16  ................
	defb 0f8h,0fch,003h,0fdh,084h,000h,01fh,03fh,07fh,004h,0ffh,092h,000h,0e0h,0f8h,0fch	; 4b26  .......?........
	defb 0feh,0feh,0ffh,0ffh,000h,000h,003h,007h,00fh,01fh,03fh,07fh,000h,000h,006h,0ffh	; 4b36  ..........?.....
	defb 002h,000h,091h,09fh,08fh,0cfh,0e7h,0e7h,0f3h,000h,0f0h,0f0h,0f8h,0f8h,0fch,0fch	; 4b46  ................
	defb 0feh,000h,07fh,07fh,005h,03fh,092h,007h,00fh,099h,0d1h,0d1h,0ceh,0cch,0c7h,080h	; 4b56  .....?..........
	defb 0c0h,061h,023h,027h,0efh,0cfh,0cfh,003h,07fh,005h,0ffh,08bh,0e3h,080h,0c0h,0e0h	; 4b66  .a#'............
	defb 0f1h,0f9h,0f9h,0fbh,0fbh,003h,07fh,005h,0ffh,08bh,0fch,0f0h,0fch,0fch,0feh,0fch	; 4b76  ................
	defb 0feh,0ffh,07fh,01fh,01fh,006h,03fh,083h,0c1h,09dh,0a1h,004h,0a0h,08bh,021h,0f9h	; 4b86  ......?.......!.
	defb 0f9h,0f1h,005h,0f9h,001h,001h,0f1h,0ffh,0fch,003h,0fdh,086h,0f9h,0fah,0fah,0ffh	; 4b96  ................
	defb 03fh,0bfh,005h,03fh,081h,07fh,007h,03fh,083h,0ffh,0c7h,097h,003h,0a7h,082h,027h	; 4ba6  ?..?...?.......'
	defb 047h,008h,0e3h,008h,0ffh,002h,03fh,002h,09fh,081h,0dfh,003h,0ffh,084h,0c3h,0c0h	; 4bb6  G.....?.........
	defb 080h,083h,003h,0c7h,084h,0cfh,08fh,00fh,04fh,005h,0cfh,002h,0e9h,082h,0ebh,0e7h	; 4bc6  ........O.......
	defb 004h,0ffh,003h,0fbh,005h,0f3h,084h,0fah,0f4h,0f4h,0f0h,004h,0ffh,089h,07eh,079h	; 4bd6  ..............~y
	defb 066h,000h,0f0h,0f8h,0f8h,0fch,03fh,006h,07fh,081h,07eh,006h,05fh,082h,043h,003h	; 4be6  f.....?...~._.C.
	defb 003h,0f5h,085h,0f3h,0e3h,0cbh,0ebh,0ebh,008h,0fah,006h,03fh,002h,07fh,008h,03fh	; 4bf6  ...........?...?
	defb 007h,047h,081h,01fh,006h,0f7h,002h,0f3h,083h,0ffh,0f7h,0f7h,003h,0f3h,002h,0f5h	; 4c06  .G..............
	defb 008h,0ffh,083h,0dfh,09fh,09fh,004h,08fh,081h,0c7h,008h,0cfh,08bh,0ffh,0feh,0fch	; 4c16  ................
	defb 0f8h,0e1h,0e3h,0e7h,0e3h,083h,003h,031h,003h,0f0h,09ah,0f1h,0f3h,0ffh,0ffh,087h	; 4c26  .......1........
	defb 000h,000h,070h,0f0h,0f0h,0feh,0ffh,0ffh,07fh,07fh,07eh,07eh,0feh,07fh,07fh,0ffh	; 4c36  ..p.......~~....
	defb 0ffh,07fh,03fh,01fh,00eh,007h,0ffh,08ah,000h,0f3h,0f3h,0f5h,0e5h,0c8h,090h,020h	; 4c46  ..?............ 
	defb 0c0h,0f9h,005h,0ffh,082h,07fh,000h,005h,0ffh,002h,0feh,081h,03ch,004h,03fh,084h	; 4c56  ............<.?.
	defb 05fh,04fh,087h,080h,006h,0ffh,08eh,0c0h,01fh,0fbh,0fbh,0f3h,0ebh,0e8h,0c0h,020h	; 4c66  _O............. 
	defb 0c0h,0f4h,0e4h,0c8h,090h,004h,000h,08ah,0ffh,07fh,03fh,01fh,003h,001h,000h,000h	; 4c76  ..........?.....
	defb 0c7h,0c7h,004h,0cfh,08ah,01eh,000h,0cfh,0cfh,0c7h,0d3h,0d3h,091h,021h,000h,006h	; 4c86  .............!..
	defb 0ffh,082h,0c7h,000h,004h,0f3h,084h,0e1h,0c8h,090h,020h,006h,0ffh,08ah,07ch,001h	; 4c96  .......... ...|.
	defb 0feh,0feh,0fdh,0fdh,0fah,0f4h,008h,0f0h,003h,000h,081h,07dh,004h,011h,003h,000h	; 4ca6  ...........}....
	defb 087h,010h,0b0h,050h,010h,010h,0ffh,0f3h,003h,033h,003h,032h,088h,04eh,05ah,05ah	; 4cb6  ...P.....3.2.NZZ
	defb 0deh,0d8h,05ah,05eh,000h,000h	; 4cc6

; ----------------------------------------------------------------------
; DATOS color_del_titulo: RLE, los mismos 544 bytes de color desde 0x0580; lo
;   carga 0x4ABD
;   0x4ccc..0x4cd9  (13 bytes)
DATA_color_del_titulo:
	defb 07fh,080h,07fh,080h,07fh,080h,07fh,080h,004h,080h,020h,0f0h,000h	; 4ccc  .......... ..

; ======================================================================
; CODIGO 0x4cd9..0x4e03  (298 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LOS SPRITES DEL JUEGO
; ----------------------------------------------------------------------
monta_los_sprites:
	ld de,0927fh		;4cd9   ; el guion trae la direccion dentro: 1344 bytes en 0x1800, que son 42 patrones de 16x16
	call guion_rle		;4cdc
	ld hl,01a80h		;4cdf   ; a partir del patron 20
	ld de,01d50h		;4ce2   ; y hacia el final de la zona de sprites
	ld c,016h		;4ce5   ; veintidos patrones
	jp espeja_sprites		;4ce7   ; espejados: asi el cartucho guarda 42 y la maquina se encuentra con 64

; ----------------------------------------------------------------------
; LAS CASILLAS DEL JUEGO, guion a guion
; ----------------------------------------------------------------------
monta_las_casillas:
	ld hl,02200h		;4cea   ; la casilla 0x40
	ld de,095dbh		;4ced
	call guion_en_tres_bancos		;4cf0   ; 85 casillas, en los tres bancos
	ld hl,024a8h		;4cf3   ; la casilla 0x95
	ld de,09822h		;4cf6
	push de			;4cf9   ; se guarda el guion
	call L_46A3		;4cfa
	pop de			;4cfd
	ld hl,024f0h		;4cfe   ; porque el MISMO se carga otra vez en la 0x9E
	call L_46A3		;4d01
	ld hl,02530h		;4d04   ; la casilla 0xA6
	ld de,09845h		;4d07
	call guion_en_dos_bancos		;4d0a   ; 21 casillas, y solo en dos bancos: no bajan al ultimo tercio
	ld hl,025e0h		;4d0d   ; la casilla 0xBC
	ld de,098d3h		;4d10
	call guion_en_tres_bancos		;4d13   ; las 34 que luego se espejan
	ld hl,00200h		;4d16   ; y ahora el color, que va DEBAJO: 0x0200 es el color de la casilla 0x40
	ld de,099d2h		;4d19
	call guion_en_tres_bancos		;4d1c
	ld hl,004a8h		;4d1f   ; color de la 0x95
	ld b,009h		;4d22   ; nueve casillas
	xor a			;4d24
	call repite_patron		;4d25   ; todas con el mismo patron de ocho bytes
	ld hl,004f0h		;4d28   ; color de la 0x9E
	ld b,008h		;4d2b
	ld a,001h		;4d2d
	call repite_patron		;4d2f   ; ocho, con el otro patron
	ld hl,00530h		;4d32   ; color de la 0xA6
	ld de,09b46h		;4d35
	call guion_en_dos_bancos		;4d38
	ld hl,005e0h		;4d3b   ; color de la 0xBC
	ld de,09b65h		;4d3e
	call guion_en_tres_bancos		;4d41
	ld hl,006f0h		;4d44   ; y el MISMO guion otra vez en la 0xDE: las casillas espejadas llevan el color de las originales sin tocar, porque dar la vuelta a una fila de ocho pixeles no cambia sus colores
	ld de,09b65h		;4d47
	call guion_en_tres_bancos		;4d4a
	call recolorea		;4d4d   ; y ahora el color del nivel
	ld hl,03010h		;4d50   ; el marcador: 16 bytes crudos
	ld de,09d01h		;4d53
	ld bc,00010h		;4d56
	call vuelca_bc_bytes		;4d59
	ld hl,03020h		;4d5c   ; y cuatro tandas de casillas de 0x20
	ld de,09be5h		;4d5f
	ld b,002h		;4d62
	call repite_cuatro_casillas		;4d64
	ld de,09c05h		;4d67
	ld b,003h		;4d6a
	call repite_cuatro_casillas		;4d6c
	ld de,09c25h		;4d6f
	ld b,003h		;4d72
	call repite_cuatro_casillas		;4d74
	ld de,09c45h		;4d77
	ld b,007h		;4d7a
	call repite_cuatro_casillas		;4d7c
	ld hl,034a8h		;4d7f
	ld de,09c65h		;4d82
	ld b,004h		;4d85
	call repite_cuatro_casillas		;4d87
	ld de,09c85h		;4d8a
	call L_46A3		;4d8d   ; lo que queda del marcador, comprimido
	ld hl,01010h		;4d90   ; color del marcador de arriba
	ld de,09d11h		;4d93
	call L_46A3		;4d96
	ld hl,014a8h		;4d99   ; y del de abajo
	ld de,09d3ch		;4d9c
	call L_46A3		;4d9f
	ld hl,01020h		;4da2   ; quince retoques de color
	ld b,00fh		;4da5
	call retoca_color		;4da7
	ld hl,014a8h		;4daa   ; y nueve mas
	ld b,009h		;4dad
	call retoca_color		;4daf
	ld hl,025e0h		;4db2   ; y por ultimo las casillas espejadas: 0x110 bytes son 34 casillas
	ld de,026f0h		;4db5
	ld bc,00110h		;4db8
	call espeja_casillas		;4dbb
	ld hl,02de0h		;4dbe   ; el segundo banco
	ld de,02ef0h		;4dc1
	ld bc,00110h		;4dc4
	call espeja_casillas		;4dc7
	ld hl,035e0h		;4dca   ; y el tercero
	ld de,036f0h		;4dcd
	ld bc,00110h		;4dd0

; ----------------------------------------------------------------------
; ESPEJAR UN TROZO DE VRAM
; ----------------------------------------------------------------------
espeja_casillas:
	call 0004ah		;4dd3   ; BIOS RDVRM - Reads the content of VRAM | lee del original
	call vuelve_los_bits		;4dd6   ; le da la vuelta a los ocho bits
	ex de,hl			;4dd9
	call 0004dh		;4dda   ; BIOS WRTVRM - Writes data in VRAM | y lo deja 0x110 bytes mas alla
	ex de,hl			;4ddd
	inc hl			;4dde
	inc de			;4ddf
	dec bc			;4de0
	ld a,b			;4de1
	or c			;4de2
	jr nz,espeja_casillas		;4de3
	ret			;4de5

; ----------------------------------------------------------------------
; RELLENAR CASILLAS CON UN PATRON FIJO
; ----------------------------------------------------------------------
repite_patron:
	ld de,04e03h		;4de6   ; uno de los dos patrones
	and a			;4de9
	jr z,L_4DEF		;4dea
	ld de,04e0bh		;4dec   ; o el otro, segun a
L_4DEF:
	push bc			;4def
	ld bc,00008h		;4df0   ; ocho bytes, que es una casilla
	push de			;4df3
	push hl			;4df4
	call vuelca_bc_bytes		;4df5
	pop hl			;4df8
	pop de			;4df9
	ld a,008h		;4dfa   ; y a la siguiente
	call suma_a_a_hl		;4dfc
	pop bc			;4dff
	djnz L_4DEF		;4e00
	ret			;4e02

; ----------------------------------------------------------------------
; DATOS dos_patrones_de_relleno: dos casillas de ocho bytes; L_4DE6 repite la
;   primera nueve veces y la segunda ocho
;   0x4e03..0x4e13  (16 bytes)
DATA_dos_patrones_de_relleno:
	defb 0f0h,040h,040h,040h,040h,040h,0f0h,000h	; 4e03  .@@@@@..
	defb 0f0h,0c0h,0c0h,0c0h,0c0h,0c0h,0f0h,000h	; 4e0b  ........

; ======================================================================
; CODIGO 0x4e13..0x4e3f  (44 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; COPIAR CUATRO CASILLAS, VARIAS VECES
; ----------------------------------------------------------------------
repite_cuatro_casillas:
	push bc			;4e13
	push de			;4e14
	push hl			;4e15
	ld bc,00020h		;4e16   ; 0x20 bytes son cuatro casillas
	call vuelca_bc_bytes		;4e19
	pop hl			;4e1c
	ld de,00020h		;4e1d   ; el destino avanza
	add hl,de			;4e20
	pop de			;4e21   ; pero el origen NO: el `pop de` lo devuelve, asi que las b copias son la misma
	pop bc			;4e22
	djnz repite_cuatro_casillas		;4e23
	ret			;4e25

; ----------------------------------------------------------------------
; DOS RETOQUES DE COLOR CADA CUATRO CASILLAS
; ----------------------------------------------------------------------
retoca_color:
	push bc			;4e26
	ld a,00fh		;4e27   ; 0x0F: tinta negra sobre papel blanco
	push af			;4e29
	call 0004dh		;4e2a   ; BIOS WRTVRM - Writes data in VRAM
	ld a,008h		;4e2d   ; una casilla mas alla
	call suma_a_a_hl		;4e2f
	pop af			;4e32
	call 0004dh		;4e33   ; BIOS WRTVRM - Writes data in VRAM
	ld a,018h		;4e36   ; y luego se salta tres
	call suma_a_a_hl		;4e38
	pop bc			;4e3b
	djnz retoca_color		;4e3c
	ret			;4e3e

; ----------------------------------------------------------------------
; DATOS recoloreado_de_cada_nivel: un byte por nivel, veinticinco; el nibble
;   bajo elige pareja de colores y el 0 dice que no se toque nada
;   0x4e3f..0x4e58  (25 bytes)
DATA_recoloreado_de_cada_nivel:
	defb 000h,081h,080h,003h,080h,000h,003h,081h,000h,083h,000h,081h,003h,000h,081h,003h,081h,000h,081h,002h,000h,081h,000h,083h,001h	; 4e3f  .........................

; ======================================================================
; CODIGO 0x4e58..0x4edb  (131 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL COLOR QUE LE TOCA A CADA NIVEL
; ----------------------------------------------------------------------
recoloreado_del_nivel:
	ld a,(0e061h)		;4e58   ; el nivel, de 1 a 25
	dec a			;4e5b
	ld hl,04e3fh		;4e5c   ; y su byte en la tabla de veinticinco
	call suma_a_a_hl		;4e5f
	ld a,(hl)			;4e62
	ret			;4e63

; ----------------------------------------------------------------------
; CAMBIAR LOS CUATRO COLORES DEL DECORADO
; ----------------------------------------------------------------------
recolorea:
	call recoloreado_del_nivel		;4e64
	and 00fh		;4e67   ; el nibble bajo elige
	ret z			;4e69   ; y el 0 quiere decir que el nivel se queda con los colores de los dibujos
	dec a			;4e6a   ; cuatro bytes por pareja
	add a,a			;4e6b
	add a,a			;4e6c
	ld hl,04edbh		;4e6d
	call suma_a_a_hl		;4e70
	ld de,0e1c0h		;4e73   ; los cuatro colores del nivel, a 0xE1C0
	ld bc,00004h		;4e76
	ldir		;4e79
	ld hl,04ee7h		;4e7b   ; y los cuatro de los dibujos, a 0xE1C4: son los que hay que buscar y cambiar
	ld bc,00004h		;4e7e
	ldir		;4e81
	ld hl,00200h		;4e83   ; el color de las 32 primeras casillas
	ld bc,00100h		;4e86
	call barre_color		;4e89
	ld hl,003a0h		;4e8c   ; un retoque de dieciseis bytes
	ld c,010h		;4e8f
	call barre_color_corto		;4e91
	ld hl,005e0h		;4e94   ; el color de las 34 espejables
	ld c,068h		;4e97
	call barre_color_corto		;4e99
	ld hl,006f0h		;4e9c   ; y el de su copia espejada, que tiene que quedar igual
	ld c,068h		;4e9f
	call barre_color_corto		;4ea1
	ld hl,00300h		;4ea4   ; diez tandas salteadas
	ld b,00ah		;4ea7
	call salta_cuatro_y_cambia_cuatro		;4ea9
	ld hl,005b0h		;4eac
	ld b,005h		;4eaf
	call salta_cuatro_y_cambia_cuatro		;4eb1
	ld hl,00648h		;4eb4
	ld b,003h		;4eb7
	call salta_cuatro_y_cambia_cuatro		;4eb9
	ld hl,00758h		;4ebc
	ld b,003h		;4ebf
	call salta_cuatro_y_cambia_cuatro		;4ec1
	call recoloreado_del_nivel		;4ec4   ; y si el nivel es de los del 1, todavia hay un segundo cambio
	and 00fh		;4ec7
	dec a			;4ec9
	jr z,$+33		;4eca
	ret			;4ecc
salta_cuatro_y_cambia_cuatro:
	push bc			;4ecd
	inc hl			;4ece   ; cuatro bytes sin tocar
	inc hl			;4ecf
	inc hl			;4ed0
	inc hl			;4ed1
	ld c,004h		;4ed2   ; y cuatro cambiados
	call barre_color_corto		;4ed4
	pop bc			;4ed7
	djnz salta_cuatro_y_cambia_cuatro		;4ed8
	ret			;4eda

; ----------------------------------------------------------------------
; DATOS parejas_de_colores: cuatro tandas de cuatro; la ultima, 09 08 06 0B,
;   es la que llevan los dibujos, asi que el nivel que la elige se queda igual
;   0x4edb..0x4eeb  (16 bytes)
DATA_parejas_de_colores:
	defb 007h,005h,004h,005h	; 4edb
	defb 00eh,00bh,00ah,00bh	; 4edf
	defb 003h,002h,00ch,002h	; 4ee3
	defb 009h,008h,006h,00bh	; 4ee7

; ======================================================================
; CODIGO 0x4eeb..0x4f17  (44 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL SEGUNDO CAMBIO DE COLOR
; ----------------------------------------------------------------------
recolorea_otra_vez:
	ld hl,04f17h		;4eeb   ; otros cuatro colores de origen y cuatro de destino, los ocho de un tiron
	ld de,0e1c0h		;4eee
	ld bc,00008h		;4ef1
	ldir		;4ef4
	ld hl,00350h		;4ef6   ; tres tramos mas
	ld c,030h		;4ef9
	call barre_color_corto		;4efb
	ld hl,00660h		;4efe
	ld c,020h		;4f01
	call barre_color_corto		;4f03
	ld hl,00770h		;4f06
	ld c,020h		;4f09
	call barre_color_corto		;4f0b
	ld de,04f1fh		;4f0e   ; y un parche comprimido encima
	ld hl,003a2h		;4f11
	jp guion_en_tres_bancos		;4f14

; ----------------------------------------------------------------------
; DATOS segundo_cambio_de_color: los cuatro colores de origen y los cuatro de
;   destino, para los niveles cuyo byte de 0x4E3F acaba en 1
;   0x4f17..0x4f1f  (8 bytes)
DATA_segundo_cambio_de_color:
	defb 006h,008h,009h,006h	; 4f17
	defb 007h,005h,00fh,00eh	; 4f1b

; ----------------------------------------------------------------------
; DATOS parche_de_color: RLE de 13 bytes, 14 a VRAM desde 0x03A2, para esos
;   mismos niveles
;   0x4f1f..0x4f2c  (13 bytes)
DATA_parche_de_color:
	defb 082h,05fh,064h,004h,068h,084h,057h,054h,054h,064h,004h,068h,000h	; 4f1f  ._d.h.WTTd.h.

; ======================================================================
; CODIGO 0x4f2c..0x5037  (267 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; BARRER LA TABLA DE COLOR CAMBIANDO COLORES
; ----------------------------------------------------------------------
barre_color_corto:
	ld b,000h		;4f2c   ; solo el byte bajo de la cuenta
barre_color:
	push bc			;4f2e
	push hl			;4f2f
	call 0004ah		;4f30   ; BIOS RDVRM - Reads the content of VRAM | lee el byte de color de la VRAM
	ld b,a			;4f33   ; y lo guarda entero
	and 0f0h		;4f34   ; el nibble alto es la tinta
	rra			;4f36
	rra			;4f37
	rra			;4f38
	rra			;4f39
	call cambia_un_color		;4f3a   ; que se cambia si esta en la lista
	rla			;4f3d   ; y vuelve a su sitio
	rla			;4f3e
	rla			;4f3f
	rla			;4f40
	ld c,a			;4f41
	ld a,b			;4f42   ; el bajo es el papel
	and 00fh		;4f43
	call cambia_un_color		;4f45
	or c			;4f48
	cp b			;4f49   ; si el byte no ha cambiado no se escribe: la VRAM es lenta y esto se hace sobre cientos de bytes
	pop hl			;4f4a
	push hl			;4f4b
	call nz,escribe_en_los_tres_bancos		;4f4c   ; y si ha cambiado, en los tres bancos
	pop hl			;4f4f
	inc hl			;4f50
	pop bc			;4f51
	dec bc			;4f52
	ld a,b			;4f53
	or c			;4f54
	jr nz,barre_color		;4f55
	ret			;4f57

; ----------------------------------------------------------------------
; CAMBIAR UN COLOR POR EL DEL NIVEL
; ----------------------------------------------------------------------
cambia_un_color:
	ld de,0e1c0h		;4f58   ; los cuatro del nivel
	ld hl,0e1c4h		;4f5b   ; y los cuatro de los dibujos
	cp (hl)			;4f5e   ; cuatro comparaciones desplegadas, sin bucle: es codigo que se ejecuta dos veces por byte de color
	jr z,L_4F70		;4f5f
	inc de			;4f61
	inc hl			;4f62
	cp (hl)			;4f63
	jr z,L_4F70		;4f64
	inc de			;4f66
	inc hl			;4f67
	cp (hl)			;4f68
	jr z,L_4F70		;4f69
	inc de			;4f6b
	inc hl			;4f6c
	cp (hl)			;4f6d
	jr nz,L_4F71		;4f6e
L_4F70:
	ld a,(de)			;4f70
L_4F71:
	and 00fh		;4f71   ; y lo que no esta en la lista pasa tal cual
	ret			;4f73
escribe_en_los_tres_bancos:
	call 0004dh		;4f74   ; BIOS WRTVRM - Writes data in VRAM
	ld de,00800h		;4f77   ; los bancos van de 0x800 en 0x800
	add hl,de			;4f7a
	call 0004dh		;4f7b   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;4f7e
	jp 0004dh		;4f7f   ; BIOS WRTVRM - Writes data in VRAM

; ----------------------------------------------------------------------
; EMPEZAR UN NIVEL
; ----------------------------------------------------------------------
empieza_el_nivel:
	ld hl,09d67h		;4f82   ; la tabla de un byte por nivel
	ld a,(0e061h)		;4f85   ; el nivel, de 1 a 25
	dec a			;4f88
	call suma_a_a_hl		;4f89
	ld a,(hl)			;4f8c
	ld (0e06ah),a		;4f8d   ; y ese byte se queda en (0xE06A)
	ld hl,0e248h		;4f90   ; borra de 0xE248 a 0xE327: los bichos y las fichas de la sala
	ld de,0e249h		;4f93
	ld bc,000dfh		;4f96
	ld (hl),000h		;4f99
	ldir		;4f9b
	ld hl,0e4d0h		;4f9d
	ld de,0e4d1h		;4fa0
	ld bc,000bch		;4fa3   ; y de 0xE4D0 a 0xE58C
	ld (hl),000h		;4fa6
	ldir		;4fa8
	call aparca_los_sprites		;4faa   ; aparca todos los sprites
	xor a			;4fad
	ld (0e120h),a		;4fae
	ld (0e110h),a		;4fb1
	ld (0e116h),a		;4fb4
	ld (0e117h),a		;4fb7
	ld (0e1b1h),a		;4fba
	ld (0e126h),a		;4fbd
	ld (0e127h),a		;4fc0
	ld (0e129h),a		;4fc3
	ld (0e12ch),a		;4fc6
	ld (0e00dh),a		;4fc9
	ld (0e06bh),a		;4fcc
	ld c,012h		;4fcf   ; el aviso 0x12
	call se_lleva_el_objeto		;4fd1   ; si estaba pedido
	jr z,L_4FE7		;4fd4
	ld a,c			;4fd6
	ld hl,0e150h		;4fd7   ; su contador
	call suma_a_a_hl		;4fda
	ld a,(hl)			;4fdd
	and a			;4fde
	jr z,L_4FE7		;4fdf
	dec (hl)			;4fe1   ; baja
	ld a,(hl)			;4fe2
	and a			;4fe3
	call z,saca_del_inventario		;4fe4   ; y al llegar a cero se apaga
L_4FE7:
	ret			;4fe7

; ----------------------------------------------------------------------
; BORRAR LO QUE LLEVA MONTADO LA SALA
; ----------------------------------------------------------------------
borra_los_trastos:
	ld hl,0e327h		;4fe8   ; de 0xE327 a 0xE465
	ld de,0e328h		;4feb
	ld bc,0013eh		;4fee
	ld (hl),000h		;4ff1
	ldir		;4ff3

; ----------------------------------------------------------------------
; APARCAR TODOS LOS SPRITES
; ----------------------------------------------------------------------
aparca_los_sprites:
	ld hl,0e080h		;4ff5   ; el bufer de atributos de sprite
	ld bc,0007fh		;4ff8   ; 128 bytes, que son 32 sprites
	ld de,0e081h		;4ffb
	ld (hl),0e0h		;4ffe   ; 0xE0 de coordenada de arriba deja al sprite debajo del borde de la pantalla: es la manera de no dibujarlo sin tocar la lista
	ldir		;5000
	ret			;5002

; ----------------------------------------------------------------------
; COLOCAR AL JUGADOR DONDE LE TOCA
; ----------------------------------------------------------------------
coloca_al_jugador:
	ld a,(0e122h)		;5003   ; cual de los cuatro
L_5006:
	ld hl,05037h		;5006   ; y su ficha
	call puntero_numero_a		;5009
	ld hl,0e111h		;500c   ; la ficha del jugador empieza en 0xE111
	ld a,(de)			;500f
	ld (hl),a			;5010
	ld (0e062h),a		;5011   ; la sala en la que aparece
	inc hl			;5014
	inc hl			;5015
	inc de			;5016
	ld a,(de)			;5017   ; la FILA, que es lo que el registro guarda en seis bits
	add a,003h		;5018   ; mas tres casillas, por ocho, y tres pixeles: es la coordenada del sprite, y por eso 0x42AB la lee como fila
	add a,a			;501a
	add a,a			;501b
	add a,a			;501c
	add a,003h		;501d
	ld (hl),a			;501f
	inc de			;5020
	inc hl			;5021
	inc hl			;5022
	ld a,(de)			;5023   ; y la columna, que ocupa un byte entero
	inc a			;5024   ; mas una casilla, por ocho, y cuatro pixeles
	add a,a			;5025
	add a,a			;5026
	add a,a			;5027
	add a,004h		;5028
	ld (hl),a			;502a
	ld a,006h		;502b   ; seis bytes mas alla
	call suma_a_a_hl		;502d
	xor a			;5030   ; quieto
	ld (hl),a			;5031
	inc hl			;5032
	ld a,002h		;5033   ; y mirando a un lado
	ld (hl),a			;5035
	ret			;5036

; ----------------------------------------------------------------------
; DATOS cuatro_fichas: cuatro punteros a 0xE2BE, 0xE2C6, 0xE2CE y 0xE2D6;
;   0x5006 elige con (0xE122)
;   0x5037..0x503f  (8 bytes)
DATA_cuatro_fichas:
	defw 0e2beh,0e2c6h,0e2ceh,0e2d6h	; 5037

; ======================================================================
; CODIGO 0x503f..0x5067  (40 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; PONER EL MARCADOR A CERO
; ----------------------------------------------------------------------
limpia_el_marcador:
	xor a			;503f
	ld hl,0e131h		;5040   ; de 0xE131 a 0xE14D
	ld de,0e132h		;5043
	ld bc,0001ch		;5046
	ld (hl),a			;5049
	ldir		;504a
	ld (0e130h),a		;504c   ; y el contador de 0xE130
	ld hl,0e075h		;504f   ; los siete bytes que se vuelcan a la fila de abajo
	ld b,004h		;5052   ; cuatro
	ld a,0d3h		;5054   ; con las casillas 0xD3 a 0xD6
	call escribe_seguidas		;5056
	ld b,003h		;5059   ; y tres mas
	inc a			;505b   ; con las 0xD7, 0xD8 y 0xD9
escribe_seguidas:
	ld (hl),a			;505c
	inc hl			;505d
	djnz escribe_seguidas		;505e
	ret			;5060

; ----------------------------------------------------------------------
; EL REPARTO DE LA PARTIDA
; ----------------------------------------------------------------------
reparte_la_partida:
	ld a,(0e06bh)		;5061   ; (0xE06B) dice en que va la partida: colocarse, jugar, o morirse
	call reparte_por_tabla		;5064   ; cuatro entradas

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_5067: 4 entradas; detras sigue la primera, 0x506F
;   0x5067..0x506f  (8 bytes)
DATA_tabla_de_subescenas_5067:
	defw 0506fh,0507ah,05097h,050a1h	; 5067  -> se_coloca_el_jugador cae_el_jugador espera_y_sigue juega

; ======================================================================
; CODIGO 0x506f..0x514e  (223 bytes)
; ======================================================================


se_coloca_el_jugador:
	ld ix,0e110h		;506f
	call pinta_al_jugador		;5073   ; lo dibuja
	ld a,020h		;5076   ; y se queda 32 cuadros asi
	jr L_508F		;5078
cae_el_jugador:
	ld hl,0e004h		;507a
	dec (hl)			;507d   ; cuenta atras
	ret nz			;507e
	ld hl,0e113h		;507f   ; dos pixeles mas abajo cada vez
	ld a,(hl)			;5082
	add a,002h		;5083
	ld (hl),a			;5085
	ld ix,0e110h		;5086
	call pinta_al_jugador		;508a
	ld a,020h		;508d
L_508F:
	ld (0e004h),a		;508f   ; otros 32 cuadros
L_5092:
	ld hl,0e06bh		;5092   ; y a la siguiente fase
	inc (hl)			;5095
	ret			;5096
espera_y_sigue:
	ld hl,0e004h		;5097
	dec (hl)			;509a
	ret nz			;509b
	call quita_la_puerta		;509c
	jr L_5092		;509f
juega:
	call pinta_el_recuadro		;50a1   ; los sprites del cuadro anterior, a la VRAM
	call un_cuadro_de_juego		;50a4   ; el cuadro entero
	call mira_si_cambia_de_sala		;50a7   ; mira si se ha acabado
	ret z			;50aa
	jp entra_de_nuevo_en_la_sala		;50ab   ; y si si, a lo que toque

; ----------------------------------------------------------------------
; UN CUADRO DE JUEGO
; ----------------------------------------------------------------------
un_cuadro_de_juego:
	ld a,(0e003h)		;50ae   ; uno de cada cuatro
	and 003h		;50b1
	jr nz,L_50E0		;50b3
	ld hl,0e1b1h		;50b5   ; el contador de lo que dura el efecto
	ld a,(hl)			;50b8
	and a			;50b9
	jr z,L_50E0		;50ba
	dec (hl)			;50bc   ; baja
	ld a,(hl)			;50bd
	ld b,0adh		;50be   ; la pieza por defecto
	cp 0f7h		;50c0   ; en el 0xF7 suena una
	jr z,L_50D0		;50c2
	ld b,00fh		;50c4   ; en el 0xF6 otra
	cp 0f6h		;50c6
	jr z,L_50D0		;50c8
	ld b,010h		;50ca   ; y en el 0x30 la tercera: tres avisos repartidos por la cuenta atras
	cp 030h		;50cc
	jr nz,L_50D4		;50ce
L_50D0:
	ld a,b			;50d0
	call pide_pieza		;50d1
L_50D4:
	ld a,(hl)			;50d4   ; al llegar a cero
	and a			;50d5
	jr nz,L_50E0		;50d6
	ld c,016h		;50d8   ; se quita el aviso 0x16
	call saca_del_inventario		;50da
	call pieza_del_nivel		;50dd   ; y pasa lo que tenga que pasar
L_50E0:
	ld a,(0e003h)		;50e0   ; el jugador y los bichos se mueven en los cuadros PARES
	and 001h		;50e3
	jr nz,L_50EA		;50e5
	jp mueve_a_los_perseguidores		;50e7   ; y en los impares se hace otra cosa
L_50EA:
	call parpadea_la_fila_de_abajo		;50ea   ; la fila de abajo del marcador
	call mueve_los_peligros		;50ed   ; y de aqui abajo, el cuadro entero, cada llamada una parte: los trastos, los bichos, las fichas, el jugador, los choques y el remate
	call mueve_las_calaveras		;50f0
	call mueve_al_murcielago		;50f3
	call mueve_al_jugador		;50f6
	call reparte_las_jaulas		;50f9
	call mira_los_trastos		;50fc
	call mira_las_puertas		;50ff
	call pinta_los_trastos		;5102
	call mueve_los_objetos		;5105
	call pinta_la_llave		;5108
	jp mueve_al_bicho		;510b

; ----------------------------------------------------------------------
; LOS SPRITES A LA VRAM, CON LA VUELTA QUE EVITA EL PARPADEO
; ----------------------------------------------------------------------
vuelca_los_sprites:
	ld de,0e080h		;510e   ; el bufer
	ld hl,03b00h		;5111   ; la tabla de atributos
	ld c,02ch		;5114   ; los once primeros sprites van SIEMPRE en el mismo sitio: son el marcador y el jugador, que no pueden parpadear
	call vuelca_c_bytes		;5116
	ld hl,0e070h		;5119   ; el contador de la vuelta
	inc (hl)			;511c
	ld a,(hl)			;511d
	cp 00bh		;511e   ; once posiciones
	jr c,L_5123		;5120
	xor a			;5122   ; y vuelta a empezar
L_5123:
	ld (hl),a			;5123
	ld hl,0514eh		;5124   ; la tabla de la rotacion
	ld c,a			;5127
	add a,a			;5128   ; tres bytes por entrada
	add a,c			;5129
	call suma_a_a_hl		;512a
	ld e,(hl)			;512d   ; de donde arranca
	inc hl			;512e
	ld d,(hl)			;512f
	inc hl			;5130
	ld a,(hl)			;5131   ; y cuantos bytes van seguidos
	ld c,a			;5132
	ld hl,03b2ch		;5133   ; a partir del sprite once
	push bc			;5136
	call vuelca_c_bytes		;5137   ; la primera parte
	pop bc			;513a
	ld a,054h		;513b   ; 0x54 son los 21 sprites que quedan
	sub c			;513d
	ret z			;513e   ; si cabian todos, se acabo
	ld b,a			;513f   ; y si no, lo que sobra se coge del principio del bufer: los sprites se turnan, y el que un cuadro se quedaba fuera al siguiente entra el primero
	ld a,c			;5140
	ld hl,03b2ch		;5141
	call suma_a_a_hl		;5144
	ld c,b			;5147
	ld de,0e0ach		;5148
	jp vuelca_c_bytes		;514b

; ----------------------------------------------------------------------
; DATOS rotacion_de_los_sprites: once entradas de tres bytes: direccion de
;   arranque y cuantos bytes van seguidos
;   0x514e..0x516f  (33 bytes)
DATA_rotacion_de_los_sprites:
	defb 0ach,0e0h,054h	; 514e
	defb 0b4h,0e0h,04ch	; 5151
	defb 0bch,0e0h,044h	; 5154
	defb 0c4h,0e0h,03ch	; 5157
	defb 0cch,0e0h,034h	; 515a
	defb 0d4h,0e0h,02ch	; 515d
	defb 0dch,0e0h,024h	; 5160
	defb 0e4h,0e0h,01ch	; 5163
	defb 0ech,0e0h,014h	; 5166
	defb 0f4h,0e0h,00ch	; 5169
	defb 0fch,0e0h,004h	; 516c

; ======================================================================
; CODIGO 0x516f..0x518f  (32 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL RECUADRO DE ARRIBA
; ----------------------------------------------------------------------
pinta_el_recuadro:
	ld de,0e080h		;516f   ; los cuatro primeros sprites del bufer
	ld b,004h		;5172   ; cuatro
L_5174:
	push bc			;5174
	ld hl,0518fh		;5175   ; con el primer patron de cuatro bytes
	ld bc,00004h		;5178
	ldir		;517b
	pop bc			;517d
	djnz L_5174		;517e
	ld b,004h		;5180   ; y otros cuatro
L_5182:
	push bc			;5182
	ld hl,05193h		;5183   ; con el segundo
	ld bc,00004h		;5186
	ldir		;5189
	pop bc			;518b
	djnz L_5182		;518c
	ret			;518e

; ----------------------------------------------------------------------
; DATOS dos_patrones_de_cuatro: 0x518F y 0x5193, cada uno repetido cuatro
;   veces por 0x5172 y 0x5180
;   0x518f..0x5197  (8 bytes)
DATA_dos_patrones_de_cuatro:
	defb 0ffh,000h,000h,000h	; 518f
	defb 0afh,000h,000h,000h	; 5193

; ======================================================================
; CODIGO 0x5197..0x520e  (119 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EMPEZAR LA PARTIDA DE CERO
; ----------------------------------------------------------------------
empieza_la_partida:
	ld a,003h		;5197   ; el contador de cuadros arranca en 3
	ld (0e003h),a		;5199
	ld hl,0e060h		;519c   ; borra de 0xE060 a 0xE176: la partida entera
	ld de,0e061h		;519f
	ld bc,00115h		;51a2
	ld (hl),000h		;51a5
	ldir		;51a7
	call borra_lo_de_las_salas		;51a9
	call estado_de_arranque		;51ac
	call empieza_el_nivel		;51af   ; pone el nivel
	xor a			;51b2
	ld (0e00ch),a		;51b3   ; y la grabacion de la demostracion al principio
	ld (0e00bh),a		;51b6
	inc a			;51b9
	ld (0e066h),a		;51ba   ; se enciende la demostracion
	call monta_los_sprites		;51bd   ; los sprites
	call monta_las_casillas		;51c0   ; las casillas
	call monta_el_nivel		;51c3   ; las cuatro salas del nivel
	call borra_los_trastos		;51c6
	call entra_en_la_sala		;51c9   ; y se entra en la primera
	jp pinta_el_marcador		;51cc
vuelca_y_reparte:
	call vuelca_los_sprites		;51cf
	jp reparte_la_partida		;51d2

; ----------------------------------------------------------------------
; LA DEMOSTRACION NO SIMULA A NADIE: LEE UNA GRABACION
; ----------------------------------------------------------------------
mueve_la_demostracion:
	ld a,(0e003h)		;51d5   ; solo un cuadro de cada dos
	rra			;51d8
	ret nc			;51d9
	ld a,(0e00bh)		;51da   ; por donde va la grabacion
	ld hl,0520eh		;51dd   ; la tabla de estados de mando
	call suma_a_a_hl		;51e0
	ld b,(hl)			;51e3   ; b = lo que estaria pulsado ahora
	ld a,(0e00bh)		;51e4
	ld hl,05231h		;51e7   ; y la de duraciones, en paralelo
	call suma_a_a_hl		;51ea
	ld a,(0e00ch)		;51ed   ; el contador de cuadros de este tramo
	inc a			;51f0
	ld (0e00ch),a		;51f1
	cp (hl)			;51f4   ; cuando llega a la duracion
	jr nz,L_5202		;51f5
	ld a,(0e00bh)		;51f7   ; se pasa al siguiente
	inc a			;51fa
	ld (0e00bh),a		;51fb
	xor a			;51fe   ; y se reinicia la cuenta
	ld (0e00ch),a		;51ff
L_5202:
	ld a,b			;5202
	cp 0ffh		;5203   ; el 0xFF cierra la grabacion
	ld a,b			;5205
	jp nz,mete_estos_mandos		;5206   ; y si no, se le mete al juego por L_4730, que es el byte de detras de la lectura de verdad: el juego no puede distinguirlo de un jugador
	xor a			;5209
	ld (0e066h),a		;520a   ; al acabarse la cinta, se apaga la demostracion
	ret			;520d

; ----------------------------------------------------------------------
; DATOS mandos_de_la_demostracion: 34 estados de mando y el 0xFF que cierra
;   0x520e..0x5231  (35 bytes)
DATA_mandos_de_la_demostracion:
	defb 000h,008h,000h,008h,004h,010h,008h,001h,008h,000h,009h,008h,004h,008h,000h,008h,010h,008h,010h,008h,002h,000h,014h,000h,010h,000h,008h,000h,010h,004h,010h,004h,008h,000h,0ffh	; 520e  ...................................

; ----------------------------------------------------------------------
; DATOS duraciones_de_la_demostracion: cuantos cuadros dura cada uno de los 34
;   0x5231..0x5253  (34 bytes)
DATA_duraciones_de_la_demostracion:
	defb 040h,008h,010h,038h,054h,001h,088h,020h,010h,030h,003h,05ch,010h,001h,030h,098h,001h,01ch,001h,028h,020h,014h,001h,048h,001h,010h,058h,018h,001h,050h,001h,058h,018h,008h	; 5231  @..8T.. .0.\..0....( ..H..X..P.X..

; ======================================================================
; CODIGO 0x5253..0x52db  (136 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; MIRAR SI EL JUGADOR SE HA SALIDO DE LA SALA
; ----------------------------------------------------------------------
mira_si_cambia_de_sala:
	ld de,0e111h		;5253   ; la ficha del jugador
	ld hl,0e113h		;5256
	call a_que_sala_paso		;5259   ; devuelve z si sigue dentro
	ret z			;525c
	xor a			;525d
	ld (0e128h),a		;525e
	push bc			;5261
	call borra_el_rastro_de_dos		;5262   ; monta la sala nueva
	pop bc			;5265
	ld a,b			;5266
	ld (0e062h),a		;5267   ; y se apunta cual es
	or 001h		;526a
	ret			;526c

; ----------------------------------------------------------------------
; ======================================================================
; DECIDIR A QUE SALA SE PASA, Y COMO ESTAN PUESTAS LAS CUATRO
; ======================================================================
; Las cuatro salas de un nivel NO van en columna: van en un plano, y no
; el mismo en todos. Saliendo por los lados, la sala nueva sale de las
; tablas de 0x52DB y 0x5327; saliendo por arriba o por abajo, es la de
; ahora menos o mas uno.
;
; La FORMA del plano esta en el nibble ALTO de esos mismos bytes de
; 0x52DB: columna*4 + fila. Lo dice el perseguidor, que es quien lo usa
; aparte de aqui: 0x74C0 lo compara con 0xC0 -los dos bits altos, o sea
; la columna- para decidir si se mueve en horizontal, y 0x74C4 con 0x30
; -la fila- para la vertical. Montadas asi, las plataformas y las
; escaleras siguen de una sala a la de al lado; en columna, no.
; DECIDIR A QUE SALA SE PASA
; ----------------------------------------------------------------------
a_que_sala_paso:
	dec hl			;526d   ; tres bytes atras esta el estado
	dec hl			;526e
	dec hl			;526f
	ld b,(hl)			;5270
	ld a,007h		;5271   ; y siete mas alla, otra cosa suya
	call suma_a_a_hl		;5273
	ld c,(hl)			;5276
	dec hl			;5277
	dec hl			;5278
	dec hl			;5279
	dec hl			;527a
	ld a,b			;527b   ; el estado 3 salta el primer filtro
	cp 003h		;527c
	ld a,(de)			;527e   ; la columna del jugador
	ld b,a			;527f
	ld a,(hl)			;5280
	jr z,L_5292		;5281
	ld a,c			;5283
	and a			;5284   ; con c a cero
	jr z,L_528B		;5285
	cp 016h		;5287   ; o pasado de 0x16, no se cambia de sala
	jr c,L_5298		;5289
L_528B:
	ld a,(hl)			;528b
	ld c,0beh		;528c   ; la columna a la que se entra por la derecha
	cp 015h		;528e   ; si la columna es menor que 0x15 se sale POR LA IZQUIERDA
	jr c,sale_por_la_izquierda		;5290
L_5292:
	ld c,017h		;5292   ; y la columna a la que se entra por la izquierda
	cp 0c0h		;5294   ; si es 0xC0 o mas, se sale POR LA DERECHA
	jr nc,sale_por_la_derecha		;5296
L_5298:
	inc hl			;5298   ; y si no, se mira la fila
	inc hl			;5299
	dec b			;529a
	ld a,(hl)			;529b
	ld c,0f1h		;529c   ; la fila a la que se entra por abajo
	cp 008h		;529e   ; menos de 8 es salirse por arriba
	jr c,L_52BE		;52a0
	inc b			;52a2   ; una sala mas: arriba y abajo son la de ahora menos y mas uno, y la forma del plano la pone el nibble alto de 0x52DB
	inc b			;52a3
	ld c,00eh		;52a4   ; la fila a la que se entra por arriba
	cp 0f7h		;52a6   ; y 0xF7 o mas es salirse por abajo
	jr nc,L_52BE		;52a8
	and 000h		;52aa   ; si no se ha salido por ningun lado, vuelve sin z
	ret			;52ac
sale_por_la_izquierda:
	push hl			;52ad
	ld hl,052dbh		;52ae   ; la tabla de la izquierda
	jr L_52B7		;52b1
sale_por_la_derecha:
	push hl			;52b3
	ld hl,05327h		;52b4   ; y la de la derecha
L_52B7:
	call busca_en_la_tabla_de_salas		;52b7
	pop hl			;52ba
	and 00fh		;52bb   ; del byte se coge el nibble bajo
	ld b,a			;52bd
L_52BE:
	ld a,b			;52be
	ld (hl),c			;52bf   ; la coordenada por la que entra en la sala nueva
	ld (de),a			;52c0   ; y la otra, la que tenia
	or 001h		;52c1   ; vuelve sin z: si ha cambiado
	ret			;52c3

; ----------------------------------------------------------------------
; EL NIBBLE ALTO DE LA MISMA TABLA
; ----------------------------------------------------------------------
nibble_alto_de_la_tabla:
	ld hl,052dbh		;52c4
	call busca_en_la_tabla_de_salas		;52c7
	and 0f0h		;52ca
	ret			;52cc

; ----------------------------------------------------------------------
; BUSCAR EN LA TABLA DE SALAS
; ----------------------------------------------------------------------
busca_en_la_tabla_de_salas:
	ld a,(0e06ah)		;52cd   ; el reparto de salas que le toca al nivel
	add a,a			;52d0   ; cuatro bytes por fila, uno por sala
	add a,a			;52d1
	call suma_a_a_hl		;52d2
	ld a,b			;52d5   ; y b es la sala de ahora
	call suma_a_a_hl		;52d6
	ld a,(hl)			;52d9
	ret			;52da

; ----------------------------------------------------------------------
; DATOS salas_al_salir_por_la_izquierda: 19 filas de 4; la fila la da (0xE06A)
;   y la columna la sala de ahora. Cada byte lleva DOS cosas: el nibble BAJO
;   es la sala de la izquierda -0xF: no hay- y el ALTO es LA POSICION de esta
;   sala en el plano, columna*4 + fila. Que es la posicion lo dice el
;   perseguidor: 0x74C0 mira ese nibble con 0xC0 -los dos bits altos, la
;   columna- para moverse en horizontal y 0x74C4 con 0x30 -la fila- para la
;   vertical
;   0x52db..0x5327  (76 bytes)
DATA_salas_al_salir_por_la_izquierda:
	defb 00fh,01fh,02fh,03fh	; 52db
	defb 00fh,040h,05fh,06fh	; 52df
	defb 01fh,04fh,050h,06fh	; 52e3
	defb 02fh,04fh,05fh,060h	; 52e7
	defb 00fh,01fh,02fh,040h	; 52eb
	defb 00fh,01fh,02fh,051h	; 52ef
	defb 00fh,01fh,02fh,062h	; 52f3
	defb 00fh,01fh,040h,051h	; 52f7
	defb 00fh,01fh,051h,06fh	; 52fb
	defb 01fh,02fh,04fh,050h	; 52ff
	defb 00fh,040h,081h,09fh	; 5303
	defb 00fh,040h,05fh,081h	; 5307
	defb 00fh,01fh,040h,082h	; 530b
	defb 00fh,01fh,051h,092h	; 530f
	defb 01fh,04fh,050h,092h	; 5313
	defb 01fh,050h,08fh,091h	; 5317
	defb 00fh,040h,05fh,092h	; 531b
	defb 01fh,04fh,050h,081h	; 531f
	defb 00fh,040h,081h,0c2h	; 5323

; ----------------------------------------------------------------------
; DATOS salas_al_salir_por_la_derecha: la gemela, con la misma forma
;   0x5327..0x5373  (76 bytes)
DATA_salas_al_salir_por_la_derecha:
	defb 0ffh,0ffh,0ffh,0ffh	; 5327
	defb 001h,0ffh,0ffh,0ffh	; 532b
	defb 002h,0ffh,0ffh,0ffh	; 532f
	defb 003h,0ffh,0ffh,0ffh	; 5333
	defb 003h,0ffh,0ffh,0ffh	; 5337
	defb 0ffh,003h,0ffh,0ffh	; 533b
	defb 0ffh,0ffh,003h,0ffh	; 533f
	defb 002h,003h,0ffh,0ffh	; 5343
	defb 0ffh,002h,0ffh,0ffh	; 5347
	defb 003h,0ffh,0ffh,0ffh	; 534b
	defb 001h,002h,0ffh,0ffh	; 534f
	defb 001h,003h,0ffh,0ffh	; 5353
	defb 002h,0ffh,003h,0ffh	; 5357
	defb 0ffh,002h,003h,0ffh	; 535b
	defb 002h,0ffh,003h,0ffh	; 535f
	defb 001h,003h,0ffh,0ffh	; 5363
	defb 001h,0ffh,003h,0ffh	; 5367
	defb 002h,003h,0ffh,0ffh	; 536b
	defb 001h,002h,003h,0ffh	; 536f

; ======================================================================
; CODIGO 0x5373..0x53c0  (77 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; BORRAR EL RASTRO DE LOS DOS PRIMEROS TRASTOS
; ----------------------------------------------------------------------
borra_el_rastro_de_dos:
	ld ix,0e327h		;5373   ; las dos primeras fichas de la sala
	ld de,0000ah		;5377   ; diez bytes de una a otra: las fichas van de cinco en cinco y estas se cogen de dos en dos
	ld b,002h		;537a   ; dos
borra_el_rastro_bucle:
	exx			;537c   ; el `exx` guarda la cuenta: la rutina de dentro usa bc
	call borra_lo_que_ha_recorrido		;537d
	exx			;5380
	add ix,de		;5381
	djnz borra_el_rastro_bucle		;5383
	ret			;5385
borra_lo_que_ha_recorrido:
	ld a,(ix+000h)		;5386   ; si la ficha esta apagada, no hay nada que borrar
	and a			;5389
	ret z			;538a
	ld a,(ix+001h)		;538b   ; por donde va
	ld l,(ix+006h)		;538e   ; contra la fila por la que empezo
	sub l			;5391
	add a,004h		;5392   ; y cuatro filas mas: se borra todo lo que ha recorrido, no solo donde esta
	ld b,a			;5394
	ld h,(ix+002h)		;5395   ; la columna
	call L_45D7		;5398   ; a direccion dentro de la sala, que vive en RAM
borra_dos_casillas:
	xor a			;539b   ; dos casillas de ancho
	ld (hl),a			;539c
	inc hl			;539d
	ld (hl),a			;539e
	ld a,01fh		;539f   ; y a la fila de abajo
	call suma_a_a_hl		;53a1
	djnz borra_dos_casillas		;53a4
	ret			;53a6

; ----------------------------------------------------------------------
; LA CONTRASENA QUE TE DAN AL PASAR DE RONDA
; ----------------------------------------------------------------------
da_la_contrasena:
	ld hl,038ech		;53a7   ; el sitio de la pantalla
	ld de,0554ch		;53aa   ; los siete bytes de KEYWORD, saltandose la direccion de VRAM que el guion lleva delante
	ld c,007h		;53ad   ; siete letras
	call vuelca_c_bytes		;53af
	ld hl,053c0h		;53b2   ; los cuatro rotulos de ronda
	ld a,(0e06ch)		;53b5   ; la ronda a la que se pasa
	dec a			;53b8   ; menos dos: el primer rotulo es el de la ronda 2
	dec a			;53b9
	call puntero_numero_a		;53ba
	jp pinta_guion		;53bd   ; y se pinta: el nombre de la ronda ES su contrasena, los mismos bytes que 0x5444 compara

; ----------------------------------------------------------------------
; DATOS rotulos_de_ronda: cuatro punteros a los nombres de las rondas 2 a 5;
;   0x53B5 entra con (0xE06C)-2
;   0x53c0..0x53c8  (8 bytes)
DATA_rotulos_de_ronda:
	defw 0546ch,0547fh,05492h,054a5h	; 53c0  -> DATA_palabra_clave_mr_sloth DATA_palabra_clave_goon_docks DATA_palabra_clave_doubloon DATA_palabra_clave_one_eyed_willy

; ======================================================================
; CODIGO 0x53c8..0x543a  (114 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; TECLEAR LA PALABRA CLAVE
; ----------------------------------------------------------------------
lee_la_palabra_clave:
	ld a,007h		;53c8
	call 00141h		;53ca   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | fila 7 del teclado
	rla			;53cd   ; el bit 7 es la barra espaciadora
	jr nc,L_53FE		;53ce
	ld a,(0e008h)		;53d0   ; el estado del mando
	and 010h		;53d3
	ld a,000h		;53d5
	jr nz,L_53E7		;53d7
	call que_letra_se_pulsa		;53d9   ; saca que tecla se ha pulsado
	ld hl,0e073h		;53dc   ; la anterior
	ld c,(hl)			;53df
	ld (hl),a			;53e0
	cp c			;53e1   ; si es la misma, no cuenta: asi una tecla mantenida no se repite
	ret z			;53e2
	and a			;53e3
	ret z			;53e4
	add a,01bh		;53e5   ; y 0x1B lleva del codigo de tecla al de la fuente del cartucho
L_53E7:
	ld b,a			;53e7
	ld de,0e074h		;53e8   ; por donde va la palabra
	ld a,(de)			;53eb
	ld hl,0e4c0h		;53ec   ; el buzon de dieciseis letras
	call suma_a_a_hl		;53ef
	ld (hl),b			;53f2   ; se guarda la letra
	ex de,hl			;53f3
	inc (hl)			;53f4   ; y avanza el indice
	ld a,(hl)			;53f5
	push af			;53f6
	call pinta_lo_tecleado		;53f7   ; y se pinta
	pop af			;53fa
	cp 010h		;53fb   ; dieciseis letras y ni una mas
	ret c			;53fd
L_53FE:
	xor a			;53fe
	ld (0e07dh),a		;53ff   ; se sale del modo de teclear
	call busca_la_palabra		;5402   ; y se mira si lo escrito es una de las cinco palabras
	jr z,salta_de_ronda		;5405   ; si lo es, a saltar de ronda
	xor a			;5407
L_5408:
	ld hl,0e000h		;5408   ; y si no, vuelta al principio
	ld (hl),a			;540b
	xor a			;540c
	inc hl			;540d
	ld (hl),a			;540e
	ret			;540f

; ----------------------------------------------------------------------
; SALTAR A LA RONDA QUE PIDE LA PALABRA
; ----------------------------------------------------------------------
salta_de_ronda:
	push bc			;5410
	ld a,040h		;5411   ; el bit 6 de (0xE002)
	ld (0e002h),a		;5413
	call estado_de_arranque		;5416   ; estado inicial de la partida
	call marca_los_niveles_hechos		;5419
	call monta_los_sprites		;541c
	pop bc			;541f
	ld a,c			;5420
	ld hl,0543ah		;5421   ; la tabla de parejas nivel/ronda
	add a,a			;5424   ; dos bytes por palabra
	call suma_a_a_hl		;5425
	ld a,(hl)			;5428   ; el nivel
	ld (0e061h),a		;5429
	inc hl			;542c
	ld a,(hl)			;542d   ; y la ronda
	ld (0e06ch),a		;542e
	ld a,020h		;5431
	ld (0e004h),a		;5433
	ld a,004h		;5436
	jr L_5408		;5438

; ----------------------------------------------------------------------
; DATOS nivel_de_cada_palabra_clave: cinco parejas nivel/ronda, en el mismo
;   orden que los nombres
;   0x543a..0x5444  (10 bytes)
DATA_nivel_de_cada_palabra_clave:
	defb 006h,002h	; 543a
	defb 00bh,003h	; 543c
	defb 010h,004h	; 543e
	defb 015h,005h	; 5440
	defb 001h,001h	; 5442

; ======================================================================
; CODIGO 0x5444..0x546c  (40 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; COMPARAR LO TECLEADO CON LAS CINCO PALABRAS
; ----------------------------------------------------------------------
busca_la_palabra:
	ld c,000h		;5444   ; c ira contando cual es
	ld hl,0546eh		;5446   ; la primera palabra empieza DOS bytes despues del guion, saltandose su direccion de VRAM
	ld b,005h		;5449   ; cinco palabras
L_544B:
	push hl			;544b
	push bc			;544c
	call compara_dieciseis_letras		;544d   ; se compara
	pop bc			;5450
	pop hl			;5451
	ret z			;5452   ; y en cuanto una cuadra, se vuelve con c puesto
	inc c			;5453
	ld a,013h		;5454   ; 0x13 son los diecinueve bytes que ocupa cada guion: direccion, dieciseis letras y el 0xFF
	call suma_a_a_hl		;5456
	djnz L_544B		;5459
	or 001h		;545b   ; y si no cuadra ninguna, vuelve sin z
	ret			;545d
compara_dieciseis_letras:
	ld de,0e4c0h		;545e   ; lo tecleado
	ld b,010h		;5461   ; dieciseis letras
L_5463:
	ld a,(de)			;5463
	cp (hl)			;5464   ; a la primera diferencia se acaba
	ret nz			;5465
	inc de			;5466
	inc hl			;5467
	djnz L_5463		;5468
	xor a			;546a   ; y si llega al final, z: es esa
	ret			;546b

; ----------------------------------------------------------------------
; DATOS palabra_clave_mr_sloth: guion literal de 19 bytes: direccion 0x394C,
;   "MR SLOTH" y el 0xFF; los dieciseis de en medio son la contrasena de la
;   ronda 2
;   0x546c..0x547f  (19 bytes)
DATA_palabra_clave_mr_sloth:
	defb 04ch,039h,02dh,032h,000h,033h,02ch,02fh,034h,028h,000h,000h,000h,000h,000h,000h,000h,000h,0ffh	; 546c  L9-2.3,/4(.........

; ----------------------------------------------------------------------
; DATOS palabra_clave_goon_docks: igual, en 0x394B: la ronda 3
;   0x547f..0x5492  (19 bytes)
DATA_palabra_clave_goon_docks:
	defb 04bh,039h,027h,02fh,02fh,02eh,000h,024h,02fh,023h,02bh,033h,000h,000h,000h,000h,000h,000h,0ffh	; 547f  K9'//..$/#+3.......

; ----------------------------------------------------------------------
; DATOS palabra_clave_doubloon: igual, en 0x394C: la ronda 4
;   0x5492..0x54a5  (19 bytes)
DATA_palabra_clave_doubloon:
	defb 04ch,039h,024h,02fh,035h,022h,02ch,02fh,02fh,02eh,000h,000h,000h,000h,000h,000h,000h,000h,0ffh	; 5492  L9$/5",//..........

; ----------------------------------------------------------------------
; DATOS palabra_clave_one_eyed_willy: igual, en 0x3949: la ronda 5
;   0x54a5..0x54b8  (19 bytes)
DATA_palabra_clave_one_eyed_willy:
	defb 049h,039h,02fh,02eh,025h,000h,025h,039h,025h,024h,000h,037h,029h,02ch,02ch,039h,000h,000h,0ffh	; 54a5  I9/.%.%9%$.7),,9...

; ----------------------------------------------------------------------
; DATOS palabra_clave_goonies: la quinta, y la unica que NO lleva el 0xFF de
;   cierre: nunca se pinta, solo se compara. Los dos bytes de delante estan
;   ahi para que el paso de 19 cuadre; 0x54CA ya es codigo
;   0x54b8..0x54ca  (18 bytes)
DATA_palabra_clave_goonies:
	defb 04bh,039h,027h,02fh,02fh,02eh,029h,025h,033h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 54b8  K9'//.)%3.........

; ======================================================================
; CODIGO 0x54ca..0x554a  (128 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; QUE TECLA SE ESTA PULSANDO
; ----------------------------------------------------------------------
que_letra_se_pulsa:
	ld d,000h		;54ca   ; d va contando teclas
	ld a,002h		;54cc   ; de la fila 2 del teclado
	ld b,004h		;54ce   ; a la 5
letra_por_filas:
	push bc			;54d0
	push af			;54d1
	call 00141h		;54d2   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | fila a fila
	ld b,008h		;54d5   ; ocho teclas por fila
letra_por_bits:
	rra			;54d7   ; el bit que caiga a cero es la tecla pulsada
	jr nc,letra_encontrada		;54d8
	inc d			;54da   ; y hasta entonces, se cuenta
	djnz letra_por_bits		;54db
	pop af			;54dd
	inc a			;54de
	pop bc			;54df
	djnz letra_por_filas		;54e0
	ld d,000h		;54e2   ; si no hay ninguna pulsada, cero
	jr letra_devuelve		;54e4
letra_encontrada:
	pop af			;54e6
	pop bc			;54e7
letra_devuelve:
	ld a,d			;54e8
	cp 006h		;54e9   ; las seis primeras de la fila 2 son signos, no letras: solo valen de la 6 en adelante, que es la A
	ret nc			;54eb
	xor a			;54ec   ; y si es un signo, como si nada
	ret			;54ed
pinta_lo_tecleado:
	ld hl,0394bh		;54ee   ; las dieciseis casillas de la pantalla donde se va escribiendo
	ld de,0e4c0h		;54f1   ; el buzon de la palabra
	ld bc,00010h		;54f4   ; dieciseis letras
	jp vuelca_bc_bytes		;54f7   ; a la pantalla

; ----------------------------------------------------------------------
; LA PANTALLA DE TECLEAR LA CONTRASENA
; ----------------------------------------------------------------------
pide_la_contrasena:
	ld a,0adh		;54fa   ; la pieza 0xAD, que es el silencio
	call pide_pieza		;54fc
	ld hl,0e056h		;54ff   ; borra la partida entera, de 0xE056 a 0xE175
	ld bc,0011fh		;5502
	ld de,0e057h		;5505
	ld (hl),000h		;5508
	ldir		;550a
	call borra_lo_de_las_salas		;550c   ; y lo que llevan montado las salas
	ld b,0e0h		;550f   ; el borde a negro
	call pon_el_borde		;5511
	call limpia_la_pantalla		;5514
	call monta_la_fuente		;5517   ; hace falta la fuente: aqui se escribe
	ld a,001h		;551a   ; (0xE07D) enciende el modo de teclear
	ld (0e07dh),a		;551c
	ld a,010h		;551f   ; la tecla anterior, a un valor que no es ninguna
	ld (0e073h),a		;5521
	xor a			;5524   ; y por la primera letra
	ld (0e074h),a		;5525
	ld hl,0e4c0h		;5528   ; el buzon de dieciseis letras
	ld de,0e4c1h		;552b
	ld bc,0000fh		;552e
	ld (hl),000h		;5531   ; a cero
	ldir		;5533
	ld de,0554ah		;5535   ; y se pinta KEYWORD ?
	call pinta_guion		;5538
	ret			;553b
borra_lo_de_las_salas:
	ld hl,0e1b0h		;553c   ; de 0xE1B0 a 0xE58B: los bichos, las fichas y los trastos de las cuatro salas
	ld bc,003dch		;553f
	ld de,0e1b1h		;5542
	ld (hl),000h		;5545   ; a cero
	ldir		;5547
	ret			;5549

; ----------------------------------------------------------------------
; DATOS guion_keyword: literal, 9 bytes en 0x38EB: dice "KEYWORD ?" con la
;   fuente del cartucho, donde 0x3B es el interrogante
;   0x554a..0x5556  (12 bytes)
DATA_guion_keyword:
	defb 0ebh,038h,02bh,025h,039h,037h,02fh,032h,024h,000h,03bh,0ffh	; 554a  .8+%97/2$.;.

; ======================================================================
; CODIGO 0x5556..0x5576  (32 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LOS NIVELES QUE LA CONTRASENA DA POR HECHOS
; ----------------------------------------------------------------------
marca_los_niveles_hechos:
	ld b,017h		;5556   ; los veintitres objetos
marca_un_nivel:
	push bc			;5558
	ld c,b			;5559   ; el numero de objeto
	dec c			;555a
	call se_lleva_el_objeto		;555b   ; si no se lleva, no se marca nada
	call nz,marca_el_nivel_del_objeto		;555e
	pop bc			;5561
	djnz marca_un_nivel		;5562
	ret			;5564
marca_el_nivel_del_objeto:
	ld hl,05576h		;5565   ; en que nivel esta ese objeto
	ld a,c			;5568
	call suma_a_a_hl		;5569   ; uno por objeto
	ld a,(hl)			;556c
	ld hl,0e16fh		;556d   ; las dos marcas por nivel
	call marca_de_ese_nivel		;5570   ; el bit que le toca
	or (hl)			;5573   ; y se pone
	ld (hl),a			;5574
	ret			;5575

; ----------------------------------------------------------------------
; DATOS nivel_de_cada_objeto: veintitres bytes: en que nivel esta cada objeto
;   del inventario, contando desde cero. Son veintitres valores distintos de 0
;   a 24, y faltan justo el 5 y el 14: los niveles 6 y 15 no llevan objeto.
;   0x5565 los usa para reconstruir las marcas de nivel cuando se entra con la
;   contrasena
;   0x5576..0x558d  (23 bytes)
DATA_nivel_de_cada_objeto:
	defb 001h,014h,00ch,00ah,012h,007h,008h,009h,00fh,003h,002h,00bh,00dh,016h,010h,013h,000h,004h,006h,018h,015h,011h,017h	; 5576  .......................

; ======================================================================
; CODIGO 0x558d..0x5659  (204 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA PANTALLA DEL TITULO, QUE ES TAMBIEN LA DEL FINAL
; ----------------------------------------------------------------------
monta_la_pantalla_del_titulo:
	call aparca_los_sprites		;558d   ; todos los sprites fuera
	ld hl,0e200h		;5590   ; borra las nueve fichas
	ld bc,0005fh		;5593
	ld de,0e201h		;5596
	ld (hl),000h		;5599
	ldir		;559b
	ld hl,02200h		;559d   ; las casillas del titulo
	ld de,0b227h		;55a0
	call guion_en_tres_bancos		;55a3
	ld hl,02a58h		;55a6   ; cuarenta bytes espejados: media pantalla se dibuja y la otra media se fabrica
	ld de,02a80h		;55a9
	ld bc,00028h		;55ac
	call espeja_casillas		;55af
	ld hl,00200h		;55b2   ; su color
	ld de,0b29dh		;55b5
	call guion_en_tres_bancos		;55b8
	ld hl,00258h		;55bb
	ld de,0b2cah		;55be
	call guion_en_tres_bancos		;55c1
	ld hl,00280h		;55c4
	ld de,0b2cah		;55c7
	call guion_en_tres_bancos		;55ca
	ld de,0b2d7h		;55cd   ; y el dibujo grande, que ya trae su direccion dentro
	call guion_rle		;55d0
	ld hl,01940h		;55d3   ; catorce patrones de sprite, tambien espejados
	ld de,01c90h		;55d6
	ld c,00eh		;55d9
	call espeja_sprites		;55db
	ld hl,0e200h		;55de   ; la primera ficha, encendida
	ld (hl),001h		;55e1
	inc hl			;55e3
	ld b,009h		;55e4   ; y las nueve, colocadas
coloca_una_ficha:
	ld (hl),07fh		;55e6   ; fila 0x7F, que es media pantalla
	inc hl			;55e8
	ld (hl),008h		;55e9   ; columna 8, por la izquierda
	inc hl			;55eb
	ld a,b			;55ec   ; quien es: del 0 al 8
	neg		;55ed
	add a,009h		;55ef
	ld (hl),a			;55f1
	inc hl			;55f2
	ld (hl),098h		;55f3   ; y el contador
	ld a,005h		;55f5   ; ocho bytes por ficha
	add a,l			;55f7
	ld l,a			;55f8
	djnz coloca_una_ficha		;55f9
	ld a,002h		;55fb
	ld (0e242h),a		;55fd   ; la columna del ultimo
	ld (0e251h),a		;5600   ; y el contador del rotulo
	ret			;5603

; ----------------------------------------------------------------------
; EL SUELO DE LA PANTALLA DEL TITULO
; ----------------------------------------------------------------------
pinta_el_suelo:
	ld hl,03a00h		;5604   ; la fila 16
	ld b,020h		;5607   ; treinta y dos casillas
suelo_bucle:
	ld a,l			;5609   ; una si y una no
	and 001h		;560a
	ld a,041h		;560c
	jr z,L_5612		;560e
	ld a,042h		;5610
L_5612:
	call 0004dh		;5612   ; BIOS WRTVRM - Writes data in VRAM | alternando las casillas 0x41 y 0x42
	inc hl			;5615
	djnz suelo_bucle		;5616
	ld a,040h		;5618   ; y de la fila 17 abajo, todo de la 0x40
	ld bc,000a0h		;561a   ; cinco filas
	jp 00056h		;561d   ; BIOS FILVRM - Fills VRAM with value

; ----------------------------------------------------------------------
; UN CUADRO DE LA PANTALLA DEL TITULO
; ----------------------------------------------------------------------
mueve_a_los_nueve:
	ld ix,0e200h		;5620   ; el primero, que es el que abre y cierra la escena
	call mueve_al_primero		;5624
	ld b,007h		;5627   ; los siete que van llegando
	ld ix,0e208h		;5629   ; desde 0xE208
mueve_a_los_siete:
	push bc			;562d
	call mueve_a_uno_de_los_siete		;562e
	pop bc			;5631
	ld de,00008h		;5632   ; ocho bytes por ficha
	add ix,de		;5635
	djnz mueve_a_los_siete		;5637
	ld ix,0e240h		;5639   ; y el ultimo
	call mueve_al_ultimo		;563d
	ld de,0e080h		;5640   ; el bufer de atributos
	ld hl,03b00h		;5643   ; a la tabla de sprites
	ld bc,00080h		;5646   ; treinta y dos sprites de cuatro bytes
	jp vuelca_bc_bytes		;5649
mueve_al_primero:
	ld a,(ix+000h)		;564c   ; apagado, nada
	and a			;564f
	ret z			;5650
	dec a			;5651   ; el estado, del 1 al 7
	ld hl,05667h		;5652   ; la vuelta la empuja a mano: detras del `call` va la tabla
	push hl			;5655
	call reparte_por_tabla		;5656

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_5659: 7 entradas; el `ld hl,05667h / push hl` de
;   0x5652 la cierra
;   0x5659..0x5667  (14 bytes)
DATA_tabla_de_subescenas_5659:
	defw 056aeh,056eeh,05707h,056aeh,05727h,0573dh,056e1h	; 5659

; ======================================================================
; CODIGO 0x5667..0x569b  (52 bytes)
; ======================================================================


pinta_al_primero:
	ld de,058f5h		;5667   ; sus once posturas
	ld bc,0e080h		;566a   ; y su hueco en el bufer
	jp tres_sprites		;566d
mueve_a_uno_de_los_siete:
	ld a,(ix+000h)		;5670   ; apagado, nada
	and a			;5673
	ret z			;5674
	dec a			;5675
	ld hl,pinta_a_uno_de_los_siete		;5676   ; la vuelta, empujada a mano
	push hl			;5679
	jp z,uno_de_los_siete_anda		;567a   ; con el estado 1 anda
	cp 001h		;567d   ; con el 2 espera
	jp z,uno_de_los_siete_espera		;567f
	jp uno_de_los_siete_quieto		;5682   ; y de ahi en adelante, quieto
pinta_a_uno_de_los_siete:
	ld de,05958h		;5685   ; sus dos posturas
	ld bc,0e090h		;5688   ; y su hueco
	jp tres_sprites		;568b
mueve_al_ultimo:
	ld a,(ix+000h)		;568e   ; apagado, nada
	and a			;5691
	ret z			;5692
	dec a			;5693   ; el estado, del 1 al 5
	ld hl,056a5h		;5694   ; la vuelta, empujada a mano
	push hl			;5697
	call reparte_por_tabla		;5698

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_569b: 5 entradas; el `ld hl,056a5h / push hl` de
;   0x5694 la cierra
;   0x569b..0x56a5  (10 bytes)
DATA_tabla_de_subescenas_569b:
	defw 057c6h,057f7h,057fdh,05811h,0581ah	; 569b

; ======================================================================
; CODIGO 0x56a5..0x584b  (422 bytes)
; ======================================================================


pinta_al_ultimo:
	ld de,0596ah		;56a5   ; sus seis posturas
	ld bc,0e0a0h		;56a8   ; y su hueco
	jp tres_sprites		;56ab
el_primero_cruza:
	call postura_de_andar		;56ae   ; la postura que toca
	push ix		;56b1
	pop hl			;56b3
	ld a,(hl)			;56b4   ; el estado
	inc hl			;56b5
	inc hl			;56b6
	dec a			;56b7   ; con el 1 va a la derecha, con el 4 se vuelve
	jr nz,el_primero_se_vuelve		;56b8
	inc (hl)			;56ba   ; dos pixeles por cuadro
	inc (hl)			;56bb
	ld a,(hl)			;56bc
	cp 0d0h		;56bd   ; hasta la columna 0xD0
	ret nz			;56bf
	ld (ix+008h),001h		;56c0   ; y ahi arranca al primero de los siete
	dec hl			;56c4
	dec hl			;56c5
	inc (hl)			;56c6   ; y el pasa al estado 2
	ret			;56c7
el_primero_se_vuelve:
	dec (hl)			;56c8   ; dos pixeles a la izquierda
	dec (hl)			;56c9
	ld a,(hl)			;56ca
	inc hl			;56cb
	inc hl			;56cc
	inc hl			;56cd
	inc (hl)			;56ce   ; y tres posturas mas alla, que son las de mirar al otro lado
	inc (hl)			;56cf
	inc (hl)			;56d0
	cp 008h		;56d1   ; hasta la columna 8, por donde entro
	ret nz			;56d3
	ld (ix+001h),0f8h		;56d4   ; se va de la pantalla
	ld (ix+004h),058h		;56d8   ; la cuenta de la despedida
	ld (ix+000h),007h		;56dc   ; y al estado 7
	ret			;56e0
el_primero_se_despide:
	dec (ix+004h)		;56e1   ; la cuenta
	ld a,(ix+004h)		;56e4
	and a			;56e7
	ret nz			;56e8
se_acabo_la_escena:
	xor a			;56e9   ; (0xE251) a cero: es lo que 0x4146 y 0x43AF esperan para dejar seguir
	ld (0e251h),a		;56ea
	ret			;56ed
el_primero_espera:
	ld (ix+005h),006h		;56ee   ; parado
	ld a,(0e242h)		;56f2   ; hasta que el ultimo llega a la columna 0xE0
	cp 0e0h		;56f5
	ret nz			;56f7
	ld (ix+000h),003h		;56f8   ; y entonces se vuelve
	ld a,(0e06ch)		;56fc   ; salvo en la ronda 6, que es la de despues de pasarse el juego
	cp 006h		;56ff
	ret nz			;5701
	ld (ix+000h),005h		;5702   ; y ahi la escena es otra
	ret			;5706
el_primero_saluda:
	ld b,008h		;5707
	ld a,(0e003h)		;5709   ; el bit 4 del contador
	bit 4,a		;570c
	jr z,L_5711		;570e
	inc b			;5710
L_5711:
	ld (ix+005h),b		;5711   ; dos posturas que se turnan cada dieciseis cuadros
	ld a,(0e003h)		;5714   ; y la cuenta baja uno de cada dos cuadros
	and 001h		;5717
	ret nz			;5719
	dec (ix+004h)		;571a
	ld a,(ix+004h)		;571d
	and a			;5720
	ret nz			;5721
	ld (ix+000h),004h		;5722   ; hasta que se acaba y se vuelve
	ret			;5726
el_primero_en_el_final:
	push ix		;5727
	pop hl			;5729
	ld a,l			;572a
	add a,005h		;572b
	ld l,a			;572d
	ld (hl),007h		;572e   ; la postura de mirar al frente
	inc hl			;5730
	inc (hl)			;5731   ; y 0x20 cuadros
	ld a,(hl)			;5732
	cp 020h		;5733
	ret nz			;5735
	ld (hl),000h		;5736
	ld (ix+000h),006h		;5738   ; antes del rotulo
	ret			;573c
el_rotulo_que_parpadea:
	ld a,(0e003h)		;573d   ; el bit 5 del contador
	bit 5,a		;5740
	ld b,006h		;5742   ; dos posturas mas
	jr z,L_5748		;5744
	ld b,00ah		;5746
L_5748:
	ld (ix+005h),b		;5748
	and 001h		;574b   ; uno de cada dos cuadros
	ret nz			;574d
	ld hl,0e250h		;574e   ; el contador del rotulo
	inc (hl)			;5751
	ld a,(hl)			;5752
	and a			;5753
	jp z,se_acabo_la_escena		;5754   ; cuando da la vuelta entera, se acaba la escena
	cp 0a0h		;5757   ; de 0xA0 en adelante, THE END
	ld de,058c1h		;5759
	jp nc,pinta_guion		;575c
	ld de,058dah		;575f   ; de 0x50 a 0x9F, GOONIES!
	cp 050h		;5762
	jr nc,L_5769		;5764
	ld de,058cbh		;5766   ; y hasta 0x4F, GOOD ENOUGH!
L_5769:
	and 004h		;5769   ; el bit 2 lo pinta
	jp z,pinta_guion		;576b
	jp borra_guion		;576e   ; y lo borra: por eso parpadea
uno_de_los_siete_anda:
	call postura_de_andar		;5771   ; la postura
	push ix		;5774
	pop hl			;5776
	ld de,058e5h		;5777   ; hasta donde llega este
	inc hl			;577a
	inc hl			;577b
	inc hl			;577c
	ld a,(hl)			;577d   ; quien es
	dec a			;577e
	call suma_a_a_de		;577f   ; uno por personaje
	dec hl			;5782
	inc (hl)			;5783   ; dos pixeles por cuadro
	inc (hl)			;5784
	ld a,(de)			;5785   ; hasta pasarse de su sitio
	cp (hl)			;5786
	ret nc			;5787
	inc (ix+000h)		;5788   ; y ahi para
	ld (ix+001h),0f8h		;578b   ; el sprite se va de la pantalla
	ld (ix+008h),001h		;578f   ; y arranca al siguiente
	ld de,059a0h		;5793   ; porque a partir de aqui se dibuja con casillas
	jp planta_al_bicho		;5796
uno_de_los_siete_espera:
	ld a,(0e200h)		;5799   ; mientras el primero no llegue al rotulo
	cp 006h		;579c
	jr nz,L_57A5		;579e
	ld (ix+000h),003h		;57a0
	ret			;57a4
L_57A5:
	ld a,(0e242h)		;57a5   ; se espera a que el ultimo pase por su columna
	cp (ix+002h)		;57a8
	ret nz			;57ab
	ld (ix+000h),000h		;57ac   ; y entonces se apaga
	ld de,0e253h		;57b0   ; y se borra: los nueve bytes de 0xE253 estan a cero y nadie los toca
	jp planta_al_bicho		;57b3
uno_de_los_siete_quieto:
	ld de,059a0h		;57b6   ; una postura
	ld a,(0e003h)		;57b9   ; o la otra, segun el bit 5 del contador
	bit 5,a		;57bc
	jr z,L_57C3		;57be
	ld de,059a9h		;57c0
L_57C3:
	jp planta_al_bicho		;57c3   ; plantado con casillas
el_ultimo_cruza:
	call postura_de_andar		;57c6   ; la postura
	push ix		;57c9
	pop hl			;57cb
	inc hl			;57cc
	inc hl			;57cd
	dec (hl)			;57ce   ; de derecha a izquierda, un pixel por cuadro
	ld a,(hl)			;57cf
	ld b,001h		;57d0
	ld c,a			;57d2
	cp 0e0h		;57d3   ; al llegar a la columna 0xE0
	jr nz,el_ultimo_en_la_columna_0x28		;57d5
	ld a,(0e06ch)		;57d7   ; mira la ronda
	ld b,002h		;57da   ; estado 2
	cp 006h		;57dc   ; y en la 6, la de haberse pasado el juego
	jr nz,el_ultimo_en_la_columna_0x28		;57de
	ld b,005h		;57e0   ; estado 5
el_ultimo_en_la_columna_0x28:
	ld a,c			;57e2
	cp 028h		;57e3   ; en la columna 0x28
	jr nz,el_ultimo_en_la_columna_0x0c		;57e5
	ld b,003h		;57e7   ; estado 3
el_ultimo_en_la_columna_0x0c:
	cp 00ch		;57e9   ; y en la 0x0C
	jr nz,el_ultimo_cambia_de_estado		;57eb
	ld b,004h		;57ed   ; estado 4
el_ultimo_cambia_de_estado:
	ld (ix+000h),b		;57ef
	ld (ix+004h),000h		;57f2   ; con la cuenta a cero
	ret			;57f6
el_ultimo_espera_corto:
	ld b,002h		;57f7   ; una postura y 0x20 cuadros
	ld c,020h		;57f9
	jr el_ultimo_cuenta		;57fb
el_ultimo_espera_largo:
	ld b,005h		;57fd   ; otra postura y 0x60
	ld c,060h		;57ff
el_ultimo_cuenta:
	ld (ix+005h),b		;5801
	inc (ix+004h)		;5804   ; la cuenta
	ld a,(ix+004h)		;5807
	cp c			;580a   ; hasta la que toque
	ret nz			;580b
	ld (ix+000h),001h		;580c   ; y a andar otra vez
	ret			;5810
el_ultimo_se_va:
	ld (ix+001h),0f8h		;5811   ; fuera de la pantalla
	ld (ix+000h),000h		;5815   ; y apagado
	ret			;5819
el_ultimo_en_el_final:
	ld b,003h		;581a   ; dos posturas
	ld a,(0e003h)		;581c   ; que se turnan con el bit 4 del contador
	bit 4,a		;581f
	jr z,L_5824		;5821
	inc b			;5823
L_5824:
	ld (ix+005h),b		;5824
	ret			;5827
postura_de_andar:
	ld a,(ix+003h)		;5828   ; quien es
	ld hl,0584bh		;582b   ; el primero tiene tres posturas de andar
	and a			;582e
	jr z,L_583B		;582f
	ld hl,05853h		;5831   ; el ultimo, dos
	cp 008h		;5834
	jr z,L_583B		;5836
	ld hl,0584fh		;5838   ; y los siete de en medio, dos
L_583B:
	ld a,(0e003h)		;583b   ; los bits 3 y 4 del contador: cambia de postura cada ocho cuadros
	rra			;583e
	rra			;583f
	rra			;5840
	and 003h		;5841
	call suma_a_a_hl		;5843
	ld a,(hl)			;5846
	ld (ix+005h),a		;5847   ; y se guarda en la ficha
	ret			;584a

; ----------------------------------------------------------------------
; DATOS postura_por_cuadro: tres tandas de cuatro: 0x584B, 0x584F y 0x5853;
;   0x5828 elige tanda con (ix+003h) y byte con los bits 3 y 4 de (0xE003)
;   0x584b..0x5857  (12 bytes)
DATA_postura_por_cuadro:
	defb 000h,001h,000h,002h	; 584b
	defb 000h,001h,000h,001h	; 584f
	defb 000h,001h,000h,001h	; 5853

; ======================================================================
; CODIGO 0x5857..0x58c1  (106 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL BICHO QUE SE DIBUJA CON CASILLAS
; ----------------------------------------------------------------------
planta_al_bicho:
	ld a,(ix+002h)		;5857   ; su posicion
	dec a			;585a   ; dividida entre ocho, que es pasar de pixeles a casillas
	rra			;585b
	rra			;585c
	rra			;585d
	and 01fh		;585e
	dec a			;5860
	ld h,a			;5861
	ld l,00dh		;5862   ; fila 13
	ld bc,00303h		;5864   ; tres por tres casillas
	jp L_83F3		;5867

; ----------------------------------------------------------------------
; MONTAR TRES SPRITES DE GOLPE
; ----------------------------------------------------------------------
tres_sprites:
	ld l,(ix+001h)		;586a   ; la posicion
	ld h,(ix+002h)		;586d
	ld a,(ix+005h)		;5870   ; la postura
	ld (0e103h),hl		;5873   ; y se guarda para ir sumando los desplazamientos
	ld h,a			;5876   ; nueve bytes por postura, tres por sprite
	add a,a			;5877
	add a,a			;5878
	add a,a			;5879
	add a,h			;587a
	call suma_a_a_de		;587b   ; de = la entrada que toca
	xor a			;587e
	ld (0e252h),a		;587f
	ld (ix+007h),a		;5882
L_5885:
	ld hl,0e103h		;5885   ; se relee la posicion en cada sprite
	ld a,(de)			;5888   ; y a la coordenada de arriba se le suma el desplazamiento en y
	add a,(hl)			;5889
	ld (bc),a			;588a   ; al bufer de atributos
	inc de			;588b
	inc hl			;588c
	inc bc			;588d
	ld a,(de)			;588e   ; lo mismo con la x
	add a,(hl)			;588f
	ld (bc),a			;5890
	inc de			;5891
	inc bc			;5892
	ld a,(de)			;5893   ; y el numero de patron, tal cual
	ld (bc),a			;5894
	inc de			;5895
	inc bc			;5896
	exx			;5897
	ld a,(ix+003h)		;5898   ; el color depende del estado del bicho
	and a			;589b
	ld de,058ech		;589c   ; una terna
	jr z,L_58AB		;589f
	ld de,058efh		;58a1   ; otra
	cp 008h		;58a4
	jr c,L_58AB		;58a6
	ld de,058f2h		;58a8   ; o la tercera
L_58AB:
	ld hl,0e252h		;58ab
	ld a,(hl)			;58ae   ; y dentro de la terna, uno por sprite
	add a,e			;58af
	ld e,a			;58b0
	ld a,(de)			;58b1
	inc (hl)			;58b2
	exx			;58b3
	ld (bc),a			;58b4   ; el color va detras de los otros tres bytes
	inc bc			;58b5
	inc (ix+007h)		;58b6   ; tres sprites y se acaba
	ld a,(ix+007h)		;58b9
	cp 003h		;58bc
	ret nc			;58be
	jr L_5885		;58bf

; ----------------------------------------------------------------------
; DATOS guion_the_end: literal, 7 bytes en 0x390C: dice "THE END"
;   0x58c1..0x58cb  (10 bytes)
DATA_guion_the_end:
	defb 00ch,039h,034h,028h,025h,000h,025h,02eh,024h,0ffh	; 58c1  .94(%.%.$.

; ----------------------------------------------------------------------
; DATOS guion_good_enough: literal, 12 bytes en 0x390B: dice "GOOD ENOUGH!",
;   donde 0x3C es la exclamacion
;   0x58cb..0x58da  (15 bytes)
DATA_guion_good_enough:
	defb 00bh,039h,027h,02fh,02fh,024h,000h,025h,02eh,02fh,035h,027h,028h,03ch,0ffh	; 58cb  .9'//$.%./5'(<.

; ----------------------------------------------------------------------
; DATOS guion_goonies: literal, 8 bytes en 0x390C: dice "GOONIES!"
;   0x58da..0x58e5  (11 bytes)
DATA_guion_goonies:
	defb 00ch,039h,027h,02fh,02fh,02eh,029h,025h,033h,03ch,0ffh	; 58da  .9'//.)%3<.

; ----------------------------------------------------------------------
; DATOS columna_de_cada_uno: 7 bytes: la columna en la que se para cada uno de
;   los siete, de 0xBC a 0x2C, de 0x18 en 0x18; 0x5777 los indexa con
;   (ix+003h)-1
;   0x58e5..0x58ec  (7 bytes)
DATA_columna_de_cada_uno:
	defb 0bch,0a4h,08ch,074h,05ch,044h,02ch	; 58e5

; ----------------------------------------------------------------------
; DATOS colores_de_los_tres_sprites: tres tandas de tres bytes; 0x589C elige
;   cual segun (ix+003h)
;   0x58ec..0x58f5  (9 bytes)
DATA_colores_de_los_tres_sprites:
	defb 00dh,004h,00bh,00bh,008h,005h,00bh,008h,00ch	; 58ec  .........

; ----------------------------------------------------------------------
; DATOS tres_sprites_por_postura: 21 entradas de nueve bytes, en cuatro
;   grupos: 11 desde 0x58F5, 2 desde 0x5958, 6 desde 0x596A y 2 desde 0x59A0
;   0x58f5..0x59b2  (189 bytes)
DATA_tres_sprites_por_postura:
	defb 0e4h,0fah,0b0h,0f4h,0f4h,0b4h,0e6h,0f6h,0b8h,0e6h,0f9h,09ch,0f6h,0f8h,0a0h,0e8h	; 58f5  ................
	defb 0f8h,0a4h,0e6h,0f9h,0a8h,0f6h,0f7h,0ach,0e8h,0f8h,0a4h,0e4h,0f6h,048h,0f4h,0fch	; 5905  .............H..
	defb 04ch,0e6h,0fah,050h,0e6h,0f7h,034h,0f6h,0f8h,038h,0e8h,0f8h,03ch,0e6h,0f7h,040h	; 5915  L..P..4..8..<..@
	defb 0f6h,0f9h,044h,0e8h,0f8h,03ch,0e4h,0f8h,048h,0f4h,0fch,070h,0e6h,0fch,050h,0e5h	; 5925  ..D..<..H..p..P.
	defb 0fbh,060h,0f4h,0f7h,0a0h,0e7h,0fch,064h,070h,0f8h,000h,0f0h,0f8h,054h,0f0h,0f8h	; 5935  .`.....dp....T..
	defb 058h,070h,0f8h,000h,0f0h,0f8h,0bch,0f0h,0f8h,0c0h,0e4h,0f7h,068h,0f4h,0fch,05ch	; 5945  Xp..........h..\
	defb 0e3h,0f4h,06ch,0eah,0feh,000h,0e8h,0fch,004h,0f8h,0fch,008h,0ech,0fch,00ch,0eah	; 5955  ..l.............
	defb 0fah,010h,0fah,0f8h,014h,0e7h,0f8h,018h,0e4h,0fah,01ch,0f4h,0f9h,020h,0e5h,0f5h	; 5965  ............. ..
	defb 028h,0e2h,0f8h,02ch,0f2h,0fdh,030h,0e5h,0f8h,018h,0e2h,0fah,01ch,0f2h,0f8h,024h	; 5975  (..,..0........$
	defb 0f0h,0f8h,058h,070h,0f8h,000h,0f0h,0f8h,054h,0f0h,0f8h,0c0h,070h,0f8h,000h,0f0h	; 5985  ..Xp....T...p...
	defb 0f8h,0bch,0e5h,0fbh,090h,0e2h,0f8h,094h,0f2h,0f3h,098h,04bh,043h,050h,04ch,044h	; 5995  ...........KCPLD
	defb 051h,04dh,045h,052h,04eh,046h,053h,047h,048h,049h,04fh,04ah,054h	; 59a5  QMERNFSGHIOJT

; ======================================================================
; CODIGO 0x59b2..0x5a79  (199 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; MONTAR LAS CUATRO SALAS DEL NIVEL
; ----------------------------------------------------------------------
monta_el_nivel:
	ld hl,09d80h		;59b2   ; la tabla de los 25 mapas
	ld a,(0e061h)		;59b5   ; el nivel, de 1 a 25
	dec a			;59b8
	call puntero_numero_a		;59b9   ; de = el mapa que toca
	ld hl,00002h		;59bc   ; h = columna 0, l = fila 2: las dos de arriba son el marcador
	ld b,014h		;59bf   ; veinte filas de bloques
L_59C1:
	push bc			;59c1
	push hl			;59c2
	ld b,004h		;59c3   ; y cuatro columnas
L_59C5:
	push bc			;59c5
	ld a,(de)			;59c6   ; un byte del mapa es un bloque
	call planta_un_bloque		;59c7   ; que se descomprime y se planta
	inc de			;59ca
	ld a,008h		;59cb   ; ocho columnas mas alla, que es lo que mide un bloque de ancho
	add a,h			;59cd
	ld h,a			;59ce
	pop bc			;59cf
	djnz L_59C5		;59d0
	pop hl			;59d2
	ld a,004h		;59d3   ; y cuatro filas mas abajo, que es lo que mide de alto. Cuatro por ocho y veinte por cuatro dan 32x80 casillas, o sea las CUATRO salas de 32x20 una detras de otra
	add a,l			;59d5
	ld l,a			;59d6
	pop bc			;59d7
	djnz L_59C1		;59d8
	ex de,hl			;59da   ; de se ha quedado justo detras de los 80 bytes
	call reparte_los_objetos		;59db   ; y ahi empieza la lista de lo que hay repartido por las salas
	call planta_las_estalactitas		;59de   ; los bichos
	call coloca_al_jugador		;59e1   ; y las fichas
	jp L_6108		;59e4

; ----------------------------------------------------------------------
; PLANTAR UN BLOQUE DE 8x4 CASILLAS
; ----------------------------------------------------------------------
planta_un_bloque:
	push de			;59e7
	push hl			;59e8
	and a			;59e9   ; el bit 7 dice si el bloque va espejado
	push af			;59ea   ; y se guarda para despues
	and 07fh		;59eb   ; los otros siete bits son el numero de bloque
	ld hl,05b65h		;59ed   ; de los 108 que hay
	call puntero_numero_a		;59f0
	call descomprime_bloque		;59f3   ; se descomprime a 0xE1F0
	pop af			;59f6
	call m,espeja_bloque		;59f7   ; y si tocaba, se le da la vuelta
	ld bc,00408h		;59fa   ; cuatro filas de ocho columnas
	pop hl			;59fd
	push hl			;59fe
	call planta_en_la_sala_0		;59ff   ; y a la sala
	pop hl			;5a02
	pop de			;5a03
	ret			;5a04

; ----------------------------------------------------------------------
; DESCOMPRIMIR UN BLOQUE
; ----------------------------------------------------------------------
descomprime_bloque:
	ld hl,0e1f0h		;5a05   ; el bloque se arma aqui
orden_del_bloque:
	ld a,l			;5a08   ; el final se conoce por la direccion, no por una marca: 0xE1F0 + 32 casillas = 0xE210
	cp 010h		;5a09
	jr nz,L_5A12		;5a0b
	ld a,h			;5a0d
	cp 0e2h		;5a0e
	jr z,L_5A4C		;5a10
L_5A12:
	ld a,(de)			;5a12   ; el nibble alto manda
	and 0f0h		;5a13
	jr z,repite_ceros		;5a15   ; 0x0n: n ceros
	cp 010h		;5a17   ; 0x1n: n veces la casilla 0x40
	jr z,repite_la_casilla_40		;5a19
	cp 020h		;5a1b   ; 0x2n: n veces el byte que viene detras
	jr z,repite_el_byte_de_al_lado		;5a1d
	cp 030h		;5a1f   ; 0x3n: la fabrica de parejas
	jr z,llama_a_la_fabrica		;5a21
	ld a,(de)			;5a23   ; y cualquier otro byte es una casilla, tal cual
	ld (hl),a			;5a24
	inc hl			;5a25
	inc de			;5a26
	jr orden_del_bloque		;5a27
repite_el_byte_de_al_lado:
	ld a,(de)			;5a29
	and 00fh		;5a2a
	ld b,a			;5a2c   ; la cuenta
	inc de			;5a2d
	ld a,(de)			;5a2e   ; y el valor
	ld c,a			;5a2f
	jr mete_c_veces		;5a30
repite_la_casilla_40:
	ld c,040h		;5a32   ; 0x40 es el hueco por el que se anda
	jr L_5A38		;5a34
repite_ceros:
	ld c,000h		;5a36
L_5A38:
	ld a,(de)			;5a38
	and 00fh		;5a39
	ld b,a			;5a3b
mete_c_veces:
	ld (hl),c			;5a3c
	inc hl			;5a3d
	djnz mete_c_veces		;5a3e
	inc de			;5a40
	jr orden_del_bloque		;5a41
llama_a_la_fabrica:
	push de			;5a43
	call fabrica_ocho_casillas		;5a44
	pop de			;5a47
	inc de			;5a48   ; la orden gasta dos bytes pase lo que pase
	inc de			;5a49
	jr orden_del_bloque		;5a4a
L_5A4C:
	ld de,0e1f0h		;5a4c
	ret			;5a4f

; ----------------------------------------------------------------------
; LA FABRICA DE PAREJAS: ocho casillas de una mascara
; ----------------------------------------------------------------------
fabrica_ocho_casillas:
	ld a,(de)			;5a50
	inc de			;5a51
	and 00fh		;5a52   ; el numero de plantilla
	jp z,pareja_creciente		;5a54   ; la 0 y la 1 son casos aparte
	dec a			;5a57
	jp z,pareja_decreciente		;5a58
	dec a			;5a5b   ; las demas van a la tabla
	ld b,a			;5a5c
	ld a,(de)			;5a5d   ; c se queda con la mascara
	ld c,a			;5a5e
	ld de,05a79h		;5a5f   ; once plantillas de dieciseis bytes
	ld a,b			;5a62   ; y cada una son ocho parejas
	add a,a			;5a63
	add a,a			;5a64
	add a,a			;5a65
	add a,a			;5a66
	call suma_a_a_de		;5a67
	ld b,008h		;5a6a   ; ocho casillas
L_5A6C:
	ld a,(de)			;5a6c   ; la primera de la pareja
	inc de			;5a6d
	rl c		;5a6e   ; y el bit de mas peso de la mascara decide
	jr nc,L_5A73		;5a70
	ld a,(de)			;5a72   ; si se coge la segunda
L_5A73:
	inc de			;5a73   ; pero de se sube dos igual, para no perder el paso
	ld (hl),a			;5a74
	inc hl			;5a75
	djnz L_5A6C		;5a76
	ret			;5a78

; ----------------------------------------------------------------------
; DATOS parejas_de_casillas: once entradas de 16 bytes: ocho parejas cada una,
;   y la orden 0x3n elige de cada pareja con los bits de su mascara
;   0x5a79..0x5b29  (176 bytes)
DATA_parejas_de_casillas:
	defb 0e5h,0e3h,04dh,000h,04eh,053h,0c3h,000h,0e5h,000h,04dh,053h,04eh,000h,0c3h,0c1h	; 5a79  ..M.NS....MSN...
	defb 000h,0e2h,000h,000h,000h,054h,04dh,000h,04ch,000h,04dh,053h,04eh,000h,0c3h,0c1h	; 5a89  .....TM.L.MSN...
	defb 040h,0bdh,040h,000h,040h,041h,040h,000h,040h,000h,040h,041h,040h,000h,040h,0c2h	; 5a99  @.@.@A@.@.@A@.@.
	defb 040h,0e4h,040h,000h,040h,041h,040h,000h,040h,000h,040h,041h,040h,000h,040h,0dfh	; 5aa9  @.@.@A@.@.@A@.@.
	defb 000h,0e1h,000h,000h,000h,054h,0bdh,000h,040h,000h,040h,041h,040h,000h,040h,0c2h	; 5ab9  .....T..@.@A@.@.
	defb 000h,0e0h,000h,000h,000h,054h,000h,000h,000h,000h,000h,054h,000h,000h,000h,0beh	; 5ac9  .....T.....T....
	defb 000h,0e1h,000h,000h,000h,054h,000h,000h,000h,000h,000h,054h,000h,000h,000h,0bfh	; 5ad9  .....T.....T....
	defb 0e5h,083h,04dh,083h,04eh,083h,0c3h,083h,0e5h,083h,052h,000h,04eh,083h,0c3h,083h	; 5ae9  ..M.N.....R.N...
	defb 0e5h,000h,04dh,000h,04eh,053h,0c3h,000h,0e5h,000h,052h,000h,04eh,083h,0c3h,083h	; 5af9  ..M.NS....R.N...
	defb 000h,000h,000h,000h,000h,054h,000h,000h,000h,000h,084h,085h,000h,000h,000h,000h	; 5b09  .....T..........
	defb 040h,0bdh,040h,000h,040h,041h,040h,000h,040h,000h,040h,045h,040h,000h,040h,0dfh	; 5b19  @.@.@A@.@.@E@.@.

; ======================================================================
; CODIGO 0x5b29..0x5b65  (60 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS DOS PLANTILLAS FIJAS
; ----------------------------------------------------------------------
pareja_creciente:
	ld a,(de)			;5b29   ; el valor que viene en el guion
	ld c,a			;5b2a
	inc a			;5b2b   ; y el siguiente
	jr L_5B31		;5b2c
pareja_decreciente:
	ld a,(de)			;5b2e
	ld c,a			;5b2f
	dec a			;5b30   ; aqui, el anterior
L_5B31:
	ld b,004h		;5b31   ; cuatro parejas, que son las ocho casillas de una fila
L_5B33:
	ld (hl),c			;5b33   ; la casilla y la de al lado, que es la pareja
	inc hl			;5b34
	ld (hl),a			;5b35
	inc hl			;5b36
	djnz L_5B33		;5b37
	ret			;5b39

; ----------------------------------------------------------------------
; DAR LA VUELTA A UN BLOQUE
; ----------------------------------------------------------------------
espeja_bloque:
	ld a,007h		;5b3a   ; se pone al final de la primera fila
	call suma_a_a_de		;5b3c
	ld hl,0e1d0h		;5b3f   ; el bloque del reves se arma aparte
	ld b,004h		;5b42   ; cuatro filas
L_5B44:
	push de			;5b44
	push bc			;5b45
	ld b,008h		;5b46   ; de ocho casillas
L_5B48:
	ld a,(de)			;5b48
	cp 0bch		;5b49   ; y aqui esta el truco: las casillas de la 0xBC en adelante tienen su version espejada dibujada aparte
	jr c,L_5B53		;5b4b
	add a,022h		;5b4d   ; 0xBC..0xDD pasan a 0xDE..0xFF
	jr nc,L_5B53		;5b4f   ; y las de 0xDE..0xFF vuelven a 0xBC..0xDD, que es lo que dice el acarreo
	add a,0bch		;5b51
L_5B53:
	ld (hl),a			;5b53
	inc hl			;5b54
	dec de			;5b55   ; se lee hacia atras, que es lo que le da la vuelta a la fila
	djnz L_5B48		;5b56
	pop bc			;5b58
	pop de			;5b59
	ld a,008h		;5b5a   ; y la fila siguiente empieza ocho mas alla
	call suma_a_a_de		;5b5c
	djnz L_5B44		;5b5f
	ld de,0e1d0h		;5b61
	ret			;5b64

; ----------------------------------------------------------------------
; DATOS tabla_de_bloques: 108 punteros a bloques de 8x4 casillas
;   0x5b65..0x5c3d  (216 bytes)
DATA_tabla_de_bloques:
	defw 05c3dh,05c40h,05c48h,05c4eh,05c58h,05c60h,05c64h,05c6ch	; 5b65
	defw 05c70h,05c74h,05c76h,05c7ah,05c80h,05c88h,05c8ch,05c94h	; 5b75
	defw 05c96h,05c9eh,05ca6h,05caeh,05cb0h,05cb4h,05cbch,05cc4h	; 5b85
	defw 05ccch,05cceh,05cd1h,05cd5h,05cdbh,05ce1h,05ce7h,05cedh	; 5b95
	defw 05cf2h,05cf8h,05cfdh,05d04h,05d0bh,05d11h,05d17h,05d1dh	; 5ba5
	defw 05d23h,05d29h,05d2fh,05d35h,05d3bh,05d43h,05d49h,05d51h	; 5bb5
	defw 05d55h,05d5dh,05d63h,05d6bh,05d71h,05d79h,05d7fh,05d87h	; 5bc5
	defw 05d8fh,05d95h,05d97h,05d9bh,05da3h,05da5h,05dadh,05dafh	; 5bd5
	defw 05db7h,05dbfh,05dc5h,05dcbh,05dd2h,05dd8h,05ddeh,05de4h	; 5be5
	defw 05deah,05df0h,05df6h,05dfch,05e02h,05e0ah,05e11h,05e19h	; 5bf5
	defw 05e1eh,05e23h,05e2ah,05e2dh,05e31h,05e39h,05e41h,05e49h	; 5c05
	defw 05e4eh,05e56h,05e5eh,05e66h,05e6eh,05e76h,05e7ah,05e87h	; 5c15
	defw 05e94h,05ea3h,05eabh,05eb7h,05ec5h,05ecfh,05ed5h,05edeh	; 5c25
	defw 05eebh,05ef3h,05efdh,05f03h	; 5c35

; ----------------------------------------------------------------------
; DATOS definiciones_de_los_bloques: los 108 bloques de 8x4 casillas,
;   comprimidos y solapados entre si; lo comprueba tools/cobertura.py
;   0x5c3d..0x5f0a  (717 bytes)
DATA_definiciones_de_los_bloques:
	defb 00fh,00fh,002h,030h,05eh,031h,05fh,030h,05eh,031h,05fh,008h,018h,030h,074h,030h	; 5c3d  ...0^1_0^1_..0t0
	defb 06eh,005h,0c7h,001h,0e9h,015h,0bch,040h,0deh,030h,074h,030h,06eh,031h,06fh,030h	; 5c4d  n......@.0t0n1o0
	defb 06eh,031h,06fh,039h,000h,03bh,000h,03bh,000h,03bh,000h,03bh,004h,03ch,004h,039h	; 5c5d  n1o9.;.;.;.;.<.9
	defb 003h,00fh,009h,039h,0f8h,00fh,009h,039h,003h,03bh,000h,03bh,000h,03bh,000h,03bh	; 5c6d  ...9...9.;.;.;.;
	defb 000h,03bh,004h,03bh,000h,03bh,000h,03bh,004h,03ch,084h,039h,0fbh,03bh,000h,03bh	; 5c7d  .;.;.;.;.<.9.;.;
	defb 000h,03bh,000h,03bh,004h,03ch,005h,039h,0f8h,03bh,000h,03bh,000h,03bh,000h,03ch	; 5c8d  .;.;.<.9.;.;.;.<
	defb 004h,03ah,020h,03bh,020h,03bh,020h,03bh,024h,03ah,023h,037h,020h,037h,020h,037h	; 5c9d  .: ; ; ;$:#7 7 7
	defb 020h,03ah,023h,03bh,020h,03bh,020h,03bh,020h,03bh,020h,03bh,024h,03ch,025h,03bh	; 5cad   :#; ; ; ; ;$<%;
	defb 020h,03bh,020h,03bh,024h,03ch,024h,03bh,020h,03bh,020h,03bh,024h,03ch,0a4h,039h	; 5cbd   ; ;$<$; ; ;$<.9
	defb 0fbh,00fh,009h,018h,008h,018h,032h,020h,037h,020h,034h,020h,032h,004h,037h,004h	; 5ccd  ......2 7 4 2.7.
	defb 034h,084h,032h,020h,037h,020h,034h,0a0h,032h,004h,037h,004h,034h,084h,032h,000h	; 5cdd  4.2 7 4.2.7.4.2.
	defb 008h,034h,080h,032h,020h,037h,020h,034h,0a0h,032h,000h,008h,034h,080h,032h,000h	; 5ced  .4.2 7 4.2..4.2.
	defb 008h,034h,080h,032h,004h,038h,004h,037h,020h,034h,020h,032h,000h,008h,0e0h,007h	; 5cfd  .4.2.8.7 4 2....
	defb 035h,080h,032h,0a0h,037h,0a0h,036h,0a0h,033h,0a0h,037h,0a0h,038h,0a0h,037h,0a0h	; 5d0d  5.2.7.6.3.7.8.7.
	defb 037h,0a0h,035h,0a0h,032h,084h,037h,084h,038h,084h,037h,084h,037h,084h,035h,084h	; 5d1d  7.5.2.7.8.7.7.5.
	defb 032h,080h,037h,080h,038h,080h,037h,080h,037h,080h,035h,080h,032h,080h,037h,080h	; 5d2d  2.7.8.7.7.5.2.7.
	defb 035h,080h,032h,084h,038h,084h,037h,0a0h,035h,0a0h,032h,080h,037h,080h,035h,080h	; 5d3d  5.2.8.7.5.2.7.5.
	defb 032h,020h,038h,020h,008h,018h,032h,080h,037h,080h,035h,080h,030h,074h,030h,06eh	; 5d4d  2 8 ..2.7.5.0t0n
	defb 032h,080h,0e0h,007h,0e1h,007h,037h,080h,0e0h,007h,0e1h,007h,035h,080h,032h,0a0h	; 5d5d  2.....7.....5.2.
	defb 037h,0a0h,038h,0a0h,037h,0a0h,038h,0a0h,037h,0a0h,035h,0a0h,032h,084h,037h,084h	; 5d6d  7.8.7.8.7.5.2.7.
	defb 038h,084h,037h,084h,038h,084h,037h,084h,035h,084h,032h,080h,0e0h,007h,0e1h,007h	; 5d7d  8.7.8.7.5.2.....
	defb 035h,081h,032h,000h,008h,008h,034h,080h,033h,000h,00fh,009h,034h,080h,033h,004h	; 5d8d  5.2...4.3...4.3.
	defb 037h,004h,037h,004h,037h,004h,037h,020h,037h,020h,037h,020h,037h,020h,034h,0a0h	; 5d9d  7.7.7.7 7 7 7 4.
	defb 032h,004h,037h,004h,037h,004h,037h,004h,034h,084h,032h,080h,0e0h,007h,0e1h,007h	; 5dad  2.7.7.7.4.2.....
	defb 035h,080h,0e0h,007h,036h,080h,033h,080h,037h,080h,036h,080h,033h,084h,037h,084h	; 5dbd  5...6.3.7.6.3.7.
	defb 036h,084h,033h,080h,0e1h,007h,0beh,036h,001h,033h,001h,038h,001h,036h,001h,033h	; 5dcd  6.3....6.3.8.6.3
	defb 005h,037h,005h,034h,085h,032h,021h,037h,021h,034h,0a1h,032h,005h,038h,005h,034h	; 5ddd  .7.4.2!7!4.2.8.4
	defb 085h,032h,001h,007h,0beh,034h,081h,032h,021h,038h,021h,034h,0a1h,032h,001h,007h	; 5ded  .2...4.2!8!4.2..
	defb 0beh,034h,081h,032h,005h,037h,005h,038h,005h,037h,005h,034h,085h,008h,036h,000h	; 5dfd  .4.2.7.8.7.4..6.
	defb 033h,005h,038h,005h,037h,020h,036h,020h,033h,020h,038h,020h,008h,036h,000h,033h	; 5e0d  3.8.7 6 3 8 .6.3
	defb 000h,008h,036h,000h,033h,004h,037h,004h,036h,004h,033h,000h,008h,032h,000h,009h	; 5e1d  ..6.3.7.6.3..2..
	defb 00fh,00ch,0bdh,014h,032h,021h,037h,021h,038h,021h,034h,021h,037h,004h,037h,004h	; 5e2d  ....2!7!8!4!7.7.
	defb 037h,004h,036h,004h,037h,021h,038h,021h,037h,021h,034h,0a1h,032h,000h,008h,008h	; 5e3d  7.6.7!8!7!4.2...
	defb 018h,032h,020h,037h,020h,038h,020h,034h,020h,037h,020h,037h,020h,037h,020h,034h	; 5e4d  .2 7 8 4 7 7 7 4
	defb 020h,037h,084h,035h,084h,030h,074h,030h,06eh,037h,0a0h,035h,0a0h,030h,074h,030h	; 5e5d   7.5.0t0n7.5.0t0
	defb 06eh,037h,020h,034h,020h,030h,074h,030h,06eh,008h,018h,032h,000h,008h,013h,0dfh	; 5e6d  n7 4 0t0n..2....
	defb 042h,023h,043h,0e5h,04dh,04eh,0c4h,04fh,023h,050h,008h,013h,0dfh,042h,023h,043h	; 5e7d  B#C.MN.O#P...B#C
	defb 0e5h,04dh,053h,0c4h,04fh,023h,050h,037h,020h,012h,041h,0dfh,042h,023h,043h,0e5h	; 5e8d  .MS.O#P7 .A.B#C.
	defb 04dh,04eh,0c4h,04fh,023h,050h,008h,018h,032h,000h,005h,0c8h,059h,0eah,005h,0c7h	; 5e9d  MN.O#P..2...Y...
	defb 001h,0e9h,0bdh,014h,0bch,040h,0deh,032h,000h,008h,00ah,0c8h,059h,0eah,005h,0c7h	; 5ead  .....@.2....Y...
	defb 001h,0e9h,003h,012h,0bch,040h,0deh,013h,005h,0c7h,001h,0e9h,015h,0bch,040h,0deh	; 5ebd  .....@........@.
	defb 032h,000h,008h,028h,043h,028h,050h,008h,00dh,0c5h,057h,0e7h,005h,0c6h,058h,0e8h	; 5ecd  2..(C(P...W...X.
	defb 008h,00dh,0c8h,059h,0eah,005h,0c7h,001h,0e9h,0bdh,014h,0bch,040h,0deh,032h,000h	; 5edd  ...Y........@.2.
	defb 008h,008h,0c8h,059h,0eah,005h,032h,000h,0c5h,057h,0e7h,005h,0c6h,058h,0e8h,00dh	; 5eed  ...Y..2..W...X..
	defb 00fh,009h,0c8h,059h,0eah,005h,008h,034h,080h,032h,005h,038h,005h	; 5efd  ...Y...4.2.8.

; ======================================================================
; CODIGO 0x5f0a..0x5f40  (54 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ENTRAR EN UNA SALA
; ----------------------------------------------------------------------
entra_en_la_sala:
	ld a,(0e062h)		;5f0a   ; la sala, de 0 a 3
	ld hl,05f40h		;5f0d   ; y su bufer en RAM
	call puntero_numero_a		;5f10
	ld hl,03840h		;5f13   ; la tabla de nombres mas dos filas
	ld bc,00280h		;5f16   ; 640 bytes, que son 32x20
	call vuelca_bc_bytes		;5f19   ; de un solo volcado
	ld hl,0a304h		;5f1c   ; lo que lleva montado cada sala
	ld a,(0e061h)		;5f1f   ; por nivel
	dec a			;5f22
	call puntero_numero_a		;5f23
	ex de,hl			;5f26
	ld a,(0e062h)		;5f27   ; y por sala
	call puntero_numero_a		;5f2a
	ex de,hl			;5f2d
	call reparte_los_trastos		;5f2e   ; se reparte en las estructuras de RAM
	call mueve_las_bolas		;5f31
	call pinta_las_puertas		;5f34
	call pinta_la_puerta		;5f37
	call pinta_las_jaulas		;5f3a
	jp hasta_donde_llega_el_lanzador		;5f3d

; ----------------------------------------------------------------------
; DATOS salas_en_ram: 0xE600, 0xE880, 0xEB00 y 0xED80: las mismas cuatro, sin
;   sesgo; 0x5F13 vuelca 640 bytes de la que toca a la tabla de nombres
;   0x5f40..0x5f48  (8 bytes)
DATA_salas_en_ram:
	defw 0e600h,0e880h,0eb00h,0ed80h	; 5f40

; ======================================================================
; CODIGO 0x5f48..0x5f78  (48 bytes)
; ======================================================================


pinta_las_puertas:
	ld ix,0e2bdh		;5f48   ; el tipo 3 de la lista del nivel
	ld b,003h		;5f4c   ; tres
pinta_las_puertas_bucle:
	push bc			;5f4e
	ld a,(ix+000h)		;5f4f   ; si no la hay, nada
	and a			;5f52
	jr z,L_5F60		;5f53
	ld a,(0e062h)		;5f55   ; ni si esta en otra sala
	cp (ix+001h)		;5f58
	jr nz,L_5F60		;5f5b
	call pinta_una_puerta		;5f5d
L_5F60:
	pop bc			;5f60
	ld de,00008h		;5f61   ; ocho bytes de ficha
	add ix,de		;5f64
	djnz pinta_las_puertas_bucle		;5f66
	ret			;5f68
pinta_una_puerta:
	ld de,05f78h		;5f69   ; la calavera blanca
pinta_el_arco:
	ld bc,00403h		;5f6c   ; cuatro filas de tres casillas
	ld l,(ix+002h)		;5f6f
	ld h,(ix+003h)		;5f72
	jp L_83F3		;5f75

; ----------------------------------------------------------------------
; DATOS calavera: doce casillas, 4x3: la calavera blanca. Dibujada desde la
;   ROM en work/gfx/trastos.png
;   0x5f78..0x5f84  (12 bytes)
DATA_calavera:
	defb 0d2h,082h,0f4h	; 5f78
	defb 0d1h,081h,0f3h	; 5f7b
	defb 0d0h,000h,0f2h	; 5f7e
	defb 0c9h,040h,0ebh	; 5f81

; ======================================================================
; CODIGO 0x5f84..0x5fc3  (63 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA PUERTA DE LA CALAVERA
; ----------------------------------------------------------------------
pinta_la_puerta:
	ld ix,0e2d5h		;5f84   ; la puerta del nivel, que es una sola: el tipo 7 de la lista de objetos
	ld a,(ix+000h)		;5f88   ; si no la hay, nada
	and a			;5f8b
	ret z			;5f8c
	ld a,(0e062h)		;5f8d   ; y si esta en otra sala, tampoco
	cp (ix+001h)		;5f90
	ret nz			;5f93
	ld a,(ix+004h)		;5f94   ; cerrada o abierta
	and a			;5f97
	jr z,L_5FA4		;5f98
	ld de,05fc3h		;5f9a   ; cerrada: el arco con la calavera y las dos tibias
	ld a,(0e130h)		;5f9d   ; lo que se lleva recogido
	cp 007h		;5fa0   ; y con siete o mas la puerta se abre
	jr c,$-54		;5fa2
L_5FA4:
	ld de,05fcfh		;5fa4   ; abierta: el mismo arco, vacio
	jr $-59		;5fa7
quita_la_puerta:
	ld ix,0e2d5h		;5fa9
	ld a,(ix+000h)		;5fad   ; si no hay puerta, nada
	and a			;5fb0
	ret z			;5fb1
	ld a,(ix+004h)		;5fb2   ; ni si sigue cerrada
	and a			;5fb5
	ret nz			;5fb6
	ld (ix+000h),a		;5fb7   ; se marca como usada
	inc a			;5fba
	ld (0e071h),a		;5fbb   ; y se avisa al juego
	ld de,05fdbh		;5fbe   ; el arco borrado: solo queda la fila de suelo
	jr $-85		;5fc1

; ----------------------------------------------------------------------
; DATOS puerta_con_la_calavera: 4x3: el arco con la calavera y las dos tibias
;   dentro
;   0x5fc3..0x5fcf  (12 bytes)
DATA_puerta_con_la_calavera:
	defb 0a9h,0adh,0b3h	; 5fc3
	defb 0aah,0aeh,0b4h	; 5fc6
	defb 0abh,0afh,0b5h	; 5fc9
	defb 0b8h,0b9h,0bah	; 5fcc

; ----------------------------------------------------------------------
; DATOS puerta_vacia: el mismo arco, sin nada dentro
;   0x5fcf..0x5fdb  (12 bytes)
DATA_puerta_vacia:
	defb 0a6h,0ach,0b0h	; 5fcf
	defb 0a7h,000h,0b1h	; 5fd2
	defb 0a8h,000h,0b2h	; 5fd5
	defb 0b6h,040h,0b7h	; 5fd8

; ----------------------------------------------------------------------
; DATOS puerta_borrada: ceros y la fila de suelo: con esto se quita el arco
;   0x5fdb..0x5fe7  (12 bytes)
DATA_puerta_borrada:
	defb 000h,000h,000h	; 5fdb
	defb 000h,000h,000h	; 5fde
	defb 000h,000h,000h	; 5fe1
	defb 040h,040h,040h	; 5fe4

; ======================================================================
; CODIGO 0x5fe7..0x606c  (133 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS TRES JAULAS
; ----------------------------------------------------------------------
pinta_las_jaulas:
	ld ix,0e2f9h		;5fe7   ; las jaulas del nivel, el tipo 5 de la lista
	ld b,003h		;5feb   ; TRES por nivel
L_5FED:
	push bc			;5fed
	call pinta_una_jaula		;5fee
	pop bc			;5ff1
	ld de,00006h		;5ff2   ; seis bytes cada una
	add ix,de		;5ff5
	djnz L_5FED		;5ff7
	ret			;5ff9
pinta_una_jaula:
	ld a,(ix+000h)		;5ffa   ; si no hay jaula, nada
	and a			;5ffd
	ret z			;5ffe
	ld a,(0e062h)		;5fff   ; ni si esta en otra sala
	cp (ix+001h)		;6002
	ret nz			;6005
L_6006:
	call estado_de_la_jaula		;6006   ; lo que hay dentro de esta
	ld d,000h		;6009   ; d = 0: los barrotes cerrados
	ld c,a			;600b
	ld a,(ix+004h)		;600c   ; lo que la jaula pide
	and 00fh		;600f
	ld b,a			;6011
	ld a,c			;6012
	and 003h		;6013   ; contra lo que se lleva
	cp b			;6015
	jr nz,L_602E		;6016   ; si no cuadra, se queda cerrada
	inc d			;6018   ; y si cuadra, se abre
	ld a,(ix+004h)		;6019   ; y lo que queda dentro
	rla			;601c
	jr nc,L_6027		;601d
	ld a,c			;601f
	and 008h		;6020
	jr nz,L_602E		;6022
	inc d			;6024   ; d = 2: el amigo preso
	jr L_602E		;6025
L_6027:
	ld a,c			;6027
	and 004h		;6028
	jr nz,L_602E		;602a
	inc d			;602c   ; d = 3: el frasco
	inc d			;602d
L_602E:
	ld hl,0606ch		;602e   ; los cuatro estados de la jaula
	ld a,d			;6031
	ld (ix+005h),a		;6032
	call puntero_numero_a		;6035   ; el que toque
	ld l,(ix+002h)		;6038
	ld h,(ix+003h)		;603b
	push bc			;603e
	push hl			;603f
	ld bc,00403h		;6040
	call L_83F3		;6043   ; y se pinta
	pop hl			;6046
	pop bc			;6047
	dec l			;6048
	dec h			;6049
	ld a,c			;604a
	and 003h		;604b
	ld c,a			;604d
	ld a,004h		;604e
	sub b			;6050
	add a,l			;6051
	ld l,a			;6052
	ld a,004h		;6053
	sub c			;6055
	ld de,060a4h		;6056   ; la fila de abajo de la jaula, aparte
	call suma_a_a_de		;6059
pinta_una_columna:
	call casilla_de_la_pantalla		;605c
L_605F:
	ld a,(de)			;605f   ; casilla
	call 0004dh		;6060   ; BIOS WRTVRM - Writes data in VRAM
	ld a,020h		;6063   ; y la de debajo, 32 mas alla
	call suma_a_a_hl		;6065
	inc de			;6068
	djnz L_605F		;6069
	ret			;606b

; ----------------------------------------------------------------------
; DATOS punteros_de_la_jaula: cuatro punteros: los cuatro estados de la jaula
;   0x606c..0x6074  (8 bytes)
DATA_punteros_de_la_jaula:
	defw 06074h,06080h,0608ch,06098h	; 606c  -> DATA_jaula_cerrada DATA_jaula_vacia DATA_jaula_con_el_goonie DATA_jaula_con_el_frasco

; ----------------------------------------------------------------------
; DATOS jaula_cerrada: 4x3: los barrotes verdes
;   0x6074..0x6080  (12 bytes)
DATA_jaula_cerrada:
	defb 0d5h,076h,0f7h	; 6074
	defb 0d6h,077h,0f8h	; 6077
	defb 0d7h,07ah,0f9h	; 607a
	defb 0cbh,069h,0edh	; 607d

; ----------------------------------------------------------------------
; DATOS jaula_vacia: el arco abierto, sin nadie
;   0x6080..0x608c  (12 bytes)
DATA_jaula_vacia:
	defb 087h,088h,089h	; 6080
	defb 08ah,08bh,08ch	; 6083
	defb 08dh,000h,08eh	; 6086
	defb 065h,040h,067h	; 6089

; ----------------------------------------------------------------------
; DATOS jaula_con_el_goonie: el arco con el amigo preso dentro
;   0x608c..0x6098  (12 bytes)
DATA_jaula_con_el_goonie:
	defb 087h,088h,089h	; 608c
	defb 08ah,08bh,08ch	; 608f
	defb 08dh,090h,08eh	; 6092
	defb 065h,068h,067h	; 6095

; ----------------------------------------------------------------------
; DATOS jaula_con_el_frasco: el arco con el frasco
;   0x6098..0x60a4  (12 bytes)
DATA_jaula_con_el_frasco:
	defb 087h,088h,089h	; 6098
	defb 08ah,08bh,08ch	; 609b
	defb 08dh,094h,08eh	; 609e
	defb 065h,040h,067h	; 60a1

; ----------------------------------------------------------------------
; DATOS columnita_de_al_lado_de_la_jaula: ocho bytes en dos mitades: las
;   cuatro primeras a cero y las cuatro siguientes la casilla 0x92. 0x605C
;   pinta con ellos una columnita en la casilla de la IZQUIERDA de la jaula,
;   tantas casillas como diga (ix+004h) y acabando en la tercera fila del
;   arco. 0x6056 entra con cuatro menos los dos bits bajos del estado, asi que
;   cuanto mas alto es el estado mas ceros -que borran- vienen por delante de
;   las 0x92
;   0x60a4..0x60ac  (8 bytes)
DATA_columnita_de_al_lado_de_la_jaula:
	defb 000h,000h,000h,000h,092h,092h,092h,092h	; 60a4  ........

; ======================================================================
; CODIGO 0x60ac..0x61e6  (314 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL ESTADO DE CADA JAULA, EN MEDIO BYTE
; ----------------------------------------------------------------------
estado_de_la_jaula:
	call donde_esta_ese_estado		;60ac
	ld a,(hl)			;60af   ; el byte de las dos
	bit 0,b		;60b0   ; y el bit 0 dice cual de las dos mitades
	jr z,L_60B8		;60b2
	rra			;60b4   ; la de arriba baja
	rra			;60b5
	rra			;60b6
	rra			;60b7
L_60B8:
	and 00fh		;60b8   ; y se queda en cuatro bits: cada jaula gasta un nibble
	ret			;60ba
donde_esta_ese_estado:
	ld a,003h		;60bb   ; las jaulas se numeran al reves
	sub b			;60bd
	ld b,a			;60be
	ld hl,0e136h		;60bf   ; la tabla de estados
	call la_ronda_de_ahora		;60c2
	add a,a			;60c5   ; dos jaulas por byte
	bit 1,b		;60c6
	jr z,L_60CB		;60c8
	inc a			;60ca
L_60CB:
	jp suma_a_a_hl		;60cb

; ----------------------------------------------------------------------
; LOS CUATRO TRASTOS QUE PARPADEAN
; ----------------------------------------------------------------------
pinta_los_trastos:
	ld hl,0e2ddh		;60ce   ; el tipo 4 de la lista, cuatro por nivel
	ld b,004h		;60d1
	ld c,086h		;60d3   ; la casilla 0x86
L_60D5:
	push hl			;60d5
	call pinta_un_trasto		;60d6
	pop hl			;60d9
	ld de,00004h		;60da   ; cuatro bytes cada uno
	add hl,de			;60dd
	djnz L_60D5		;60de
	ret			;60e0
pinta_un_trasto:
	ld a,(hl)			;60e1   ; si no lo hay, nada
	and a			;60e2
	ret z			;60e3
	inc hl			;60e4
	ld a,(0e062h)		;60e5   ; ni si esta en otra sala
	cp (hl)			;60e8
	ret nz			;60e9
	inc hl			;60ea
	ex de,hl			;60eb
	ld a,(de)			;60ec   ; su sitio, dos bytes
	ld l,a			;60ed
	inc de			;60ee
	ld a,(de)			;60ef
	ld h,a			;60f0
	call casilla_de_la_pantalla		;60f1
	call 0004ah		;60f4   ; BIOS RDVRM - Reads the content of VRAM | lo que hay en esa casilla ahora
	and a			;60f7
	jr z,L_60FC		;60f8   ; si esta vacia, se pinta
	cp c			;60fa   ; y si hay algo que no sea el propio trasto, no se toca nada
	ret nz			;60fb
L_60FC:
	ld a,(0e003h)		;60fc   ; el contador de cuadros
	bit 2,a		;60ff   ; su bit 2: cuatro cuadros se ve y cuatro no
	ld a,c			;6101
	jr nz,L_6105		;6102
	xor a			;6104   ; y en los que no, se borra
L_6105:
	jp 0004dh		;6105   ; BIOS WRTVRM - Writes data in VRAM
L_6108:
	ld hl,0e2ddh		;6108
	ld b,004h		;610b
borra_los_trastos_cogidos:
	push bc			;610d   ; los cuatro del nivel
	push hl			;610e
	ld a,004h		;610f
	sub b			;6111
	call mira_la_marca_del_trasto		;6112
	pop hl			;6115
	jr nc,L_611A		;6116
	ld (hl),000h		;6118
L_611A:
	ld de,00004h		;611a
	add hl,de			;611d
	pop bc			;611e
	djnz borra_los_trastos_cogidos		;611f
	ret			;6121
mira_la_marca_del_trasto:
	inc a			;6122   ; su bit
	ld b,a			;6123
	call donde_vive_la_marca_del_trasto		;6124   ; donde vive
	ld a,(hl)			;6127
	jr nc,L_612E		;6128
	rra			;612a   ; el nibble de arriba
	rra			;612b
	rra			;612c
	rra			;612d
L_612E:
	and 00fh		;612e   ; y de los cuatro bits
rota_hasta_el_suyo:
	rra			;6130   ; se saca el que toca
	djnz rota_hasta_el_suyo		;6131
	ret			;6133
donde_vive_la_marca_del_trasto:
	ld hl,0e131h		;6134   ; la tabla de marcas
	call la_ronda_de_ahora		;6137   ; la ronda de ahora
	rra			;613a   ; dos trastos por byte
	push af			;613b
	call suma_a_a_hl		;613c
	pop af			;613f
	ret			;6140
la_ronda_de_ahora:
	ld a,(0e067h)		;6141   ; el nibble bajo de la ronda
	and 00fh		;6144
	jr nz,L_614A		;6146   ; y el cero cuenta como diez
	ld a,00ah		;6148
L_614A:
	dec a			;614a
	ret			;614b
pinta_la_llave:
	ld a,(0e121h)		;614c   ; si no se lleva llave
	and a			;614f
	ld c,086h		;6150   ; la casilla 0x86
	ld hl,03af9h		;6152   ; en el hueco del marcador
	ld b,000h		;6155
	jr z,L_6161		;6157   ; el bit 2 del contador
	ld a,(0e003h)		;6159
	bit 2,a		;615c
	jr z,L_6161		;615e
	ld b,c			;6160   ; la hace parpadear
L_6161:
	ld a,b			;6161
	jp 0004dh		;6162   ; BIOS WRTVRM - Writes data in VRAM
hasta_donde_llega_el_lanzador:
	ld de,0e3bdh		;6165   ; el tipo 4 de la sala
	ld a,(de)			;6168   ; si no lo hay, nada
	and a			;6169
	ret z			;616a
	inc de			;616b
	ld a,(de)			;616c
	ld l,a			;616d   ; su fila, una mas abajo
	inc l			;616e
	inc de			;616f
	ld a,(de)			;6170
	ld (0e12bh),a		;6171   ; y su columna
	ld h,a			;6174
	push hl			;6175
	ld a,(0e062h)		;6176
	call L_45D7		;6179   ; a direccion dentro de la sala
	ld b,000h		;617c
busca_el_suelo_hacia_abajo:
	ld a,(hl)			;617e   ; hasta dar con la casilla 0x40
	cp 040h		;617f
	jr z,L_618B		;6181
	ld a,020h		;6183   ; una fila cada vez
	call suma_a_a_hl		;6185
	inc b			;6188
	jr busca_el_suelo_hacia_abajo		;6189
L_618B:
	pop hl			;618b
	ld a,l			;618c
	add a,b			;618d
	ld (0e12ah),a		;618e   ; y ahi es donde caen sus gotas
	ret			;6191

; ----------------------------------------------------------------------
; EL JUGADOR
; ----------------------------------------------------------------------
mueve_al_jugador:
	ld ix,0e110h		;6192   ; su ficha
	call mira_todos_los_choques		;6196
	ld c,000h		;6199   ; el objeto 0
	call se_lleva_el_objeto		;619b   ; si se lleva
	ld hl,00110h		;619e   ; uno y un dieciseisavo de pixel por cuadro
	jr z,L_61A6		;61a1
	ld hl,00180h		;61a3   ; y con el, uno y medio: el byte bajo es la fraccion
L_61A6:
	ld a,(0e006h)		;61a6   ; lo que se ha pulsado y no se ha atendido
	ld e,a			;61a9
	ld a,(0e009h)		;61aa   ; y lo que se acaba de pulsar
	ld d,a			;61ad
	call reparte_por_el_estado		;61ae
	call mira_que_le_ha_hecho_dano		;61b1
pinta_al_jugador:
	ld l,(ix+003h)		;61b4   ; la fila
	ld h,(ix+005h)		;61b7   ; y la columna
	ld de,065b7h		;61ba   ; sus dibujos
	ld bc,0e0a0h		;61bd   ; y su hueco en el bufer de atributos
	xor a			;61c0
	jp monta_los_sprites_de_la_ficha		;61c1
pega_al_jugador_al_suelo:
	ld b,005h		;61c4   ; cinco pixeles
	ld a,(ix+00ah)		;61c6   ; o uno, si viene de chocar
	and 080h		;61c9
	jr z,L_61CF		;61cb
	ld b,001h		;61cd
L_61CF:
	ld a,(ix+003h)		;61cf   ; los tres bits bajos de la fila: el ajuste fino para que los pies queden en la casilla
	and 0f8h		;61d2
	or b			;61d4
	ld (ix+003h),a		;61d5
	ret			;61d8
reparte_por_el_estado:
	ld (0e101h),hl		;61d9   ; la velocidad
	ld (0e105h),de		;61dc   ; y el mando, a mano para que los seis estados los tengan a tiro
	ld a,(ix+000h)		;61e0   ; el estado
	call reparte_por_tabla		;61e3   ; y la tabla va pegada detras del `call`

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_61e6: 6 entradas; detras sigue la primera, 0x61F2
;   0x61e6..0x61f2  (12 bytes)
DATA_tabla_de_subescenas_61e6:
	defw 061f2h,0636fh,06439h,06321h,0648eh,06365h	; 61e6

; ======================================================================
; CODIGO 0x61f2..0x635c  (362 bytes)
; ======================================================================


jugador_andando:
	ld (ix+006h),000h		;61f2   ; quieto mientras no se diga lo contrario
	call esta_sobre_0x4d_o_0x4e		;61f6
	call pega_al_jugador_al_suelo		;61f9   ; pegado al suelo
	ld a,(0e106h)		;61fc   ; arriba y abajo a la vez no es nada
	and 003h		;61ff
	cp 003h		;6201
	ret z			;6203
	call mira_la_escalera		;6204   ; mira si donde esta se puede subir o bajar
	ld a,(ix+009h)		;6207   ; y si no hay por donde, a andar
	and a			;620a
	jr z,jugador_pasos		;620b
	ld b,001h		;620d   ; solo arriba
	dec a			;620f
	jr z,jugador_a_la_escalera		;6210
	inc b			;6212   ; solo abajo
	dec a			;6213
	jr z,jugador_a_la_escalera		;6214
	inc b			;6216   ; o las dos
jugador_a_la_escalera:
	ld a,(0e105h)		;6217   ; lo que se ha pulsado, filtrado por lo que se puede hacer aqui
	and b			;621a
	rra			;621b   ; con arriba, se sube donde esta
	jr c,jugador_engancha_la_escalera		;621c
	rra			;621e   ; con abajo
	jr nc,jugador_pasos		;621f
	ld a,(ix+003h)		;6221   ; se baja dos casillas primero: el agujero esta debajo de los pies
	add a,010h		;6224
	ld (ix+003h),a		;6226
jugador_engancha_la_escalera:
	ld (ix+000h),002h		;6229   ; estado 2
	ld (ix+00ch),008h		;622d   ; y la postura de trepar
	ret			;6231
jugador_pasos:
	ld hl,(0e101h)		;6232   ; la velocidad
	ld b,004h		;6235
	ld a,l			;6237
	cp 010h		;6238   ; sin las botas, un paso cada cuatro cuadros
	jr z,L_6242		;623a
	dec b			;623c
	cp 080h		;623d   ; con ellas, cada tres: las piernas van mas deprisa
	jr z,L_6242		;623f
	dec b			;6241
L_6242:
	ld a,(ix+00dh)		;6242   ; el contador de la animacion
	ld l,a			;6245
	inc a			;6246   ; el nibble bajo cuenta cuadros
	and 00fh		;6247
	ld h,a			;6249
	cp b			;624a   ; y al llegar a la cuenta
	ld a,l			;624b
	jr nz,L_6252		;624c
	ld h,000h		;624e   ; vuelve a cero
	add a,010h		;6250   ; y el alto avanza un paso
L_6252:
	and 0f0h		;6252
	or h			;6254
	ld (ix+00dh),a		;6255
	call jugador_postura_de_andar		;6258   ; la postura
	call jugador_se_queda_sin_suelo		;625b   ; mira si se ha quedado sin suelo
	call jugador_anda_a_los_lados		;625e   ; y lo que se anda
	ld a,(0e105h)		;6261   ; arriba o disparo
	and 011h		;6264
	ret z			;6266
	rra			;6267   ; con arriba
	ld a,001h		;6268   ; estado 1, el salto
	jr c,L_6272		;626a
	ld a,004h		;626c   ; y con el disparo, estado 4
	ld (ix+00dh),000h		;626e   ; que empieza su cuenta de cero
L_6272:
	ld (ix+000h),a		;6272
	ret			;6275
jugador_anda_a_los_lados:
	ld a,(0e106h)		;6276   ; los bits 2 y 3 son izquierda y derecha
	rra			;6279
	rra			;627a
	and 003h		;627b
	ret z			;627d   ; si no se pulsa ninguno, quieto
	cp 003h		;627e   ; y los dos a la vez tampoco valen
	ret z			;6280
	rra			;6281   ; el carry se queda con si es a la izquierda
	push af			;6282
	jr nc,jugador_hacia_la_derecha		;6283
	call pared_a_la_izquierda		;6285   ; mira si hay pared a la izquierda
	jr nz,jugador_avanza		;6288
	ld d,0ffh		;628a   ; hacia alla se mira la casilla de al lado
jugador_contra_la_pared:
	call jugador_mira_encima_de_la_pared		;628c   ; con la pared delante no se avanza nada
	ld de,00000h		;628f
	jr jugador_suma_el_paso		;6292
jugador_hacia_la_derecha:
	call pared_a_la_derecha		;6294   ; y lo mismo por la derecha
	ld d,001h		;6297
	jr z,jugador_contra_la_pared		;6299
jugador_avanza:
	ld de,(0e101h)		;629b   ; con el camino libre, lo que da la velocidad
jugador_suma_el_paso:
	ld b,000h		;629f   ; mirando a la derecha
	ld c,002h		;62a1   ; y andando
	ld h,(ix+005h)		;62a3   ; la columna
	ld l,(ix+004h)		;62a6   ; con su fraccion, que es lo que hace que la velocidad no sea entera
	pop af			;62a9
jugador_suma_o_resta:
	jr nc,L_62B3		;62aa   ; a la derecha se suma
	inc b			;62ac   ; y a la izquierda se resta, y ademas se le da la vuelta al dibujo
	dec c			;62ad
	xor a			;62ae
	sbc hl,de		;62af
	jr L_62B4		;62b1
L_62B3:
	add hl,de			;62b3
L_62B4:
	ld (ix+00bh),b		;62b4   ; a que lado mira
	ld (ix+006h),c		;62b7   ; si anda
	ld (ix+004h),l		;62ba   ; y donde acaba
	ld (ix+005h),h		;62bd
	ret			;62c0
jugador_mira_encima_de_la_pared:
	ld a,(ix+003h)		;62c1   ; tres casillas por encima de los pies
	sub 018h		;62c4   ; fuera de la sala, nada
	ret c			;62c6
	cp 010h		;62c7
	ret c			;62c9
	ld l,a			;62ca   ; la fila
	ld h,(ix+005h)		;62cb   ; y la columna
	ld a,(ix+001h)		;62ce   ; de la sala en la que esta
	call casilla_de_la_sala_en_pixeles		;62d1   ; a direccion dentro de la sala
	ld a,(hl)			;62d4   ; si ahi hay algo, nada
	and a			;62d5
	ret nz			;62d6
	ld a,l			;62d7   ; y la de al lado, hacia donde se empujaba
	add a,d			;62d8
	ld l,a			;62d9
	ld a,(hl)			;62da
	and a			;62db
	ret nz			;62dc
	ld a,080h		;62dd   ; con las dos libres se enciende el bit 7 de (ix+00Eh)
	or (ix+00eh)		;62df
	ld (ix+00eh),a		;62e2
	ret			;62e5
jugador_se_queda_sin_suelo:
	ld a,(ix+007h)		;62e6   ; saltando no
	and a			;62e9
	ret nz			;62ea
	call hay_suelo		;62eb   ; mira que hay debajo
	ret z			;62ee   ; con suelo, nada
	ld (ix+000h),003h		;62ef   ; y sin el, estado 3: a caer
	ld (ix+00dh),000h		;62f3   ; desde el principio de la tabla
	ret			;62f7
jugador_postura_de_andar:
	call es_el_jugador		;62f8
	jr z,L_6303		;62fb
	ld a,(ix+010h)		;62fd   ; la postura 6
	cp 006h		;6300
	ret z			;6302
L_6303:
	ld b,002h		;6303   ; quieto, la postura 2
	ld a,(0e106h)		;6305   ; si se anda
	and 00ch		;6308
	jr z,jugador_pon_la_postura		;630a
	ld a,(ix+00dh)		;630c   ; el contador
	ld b,002h		;630f
	bit 4,a		;6311   ; sus bits 4 y 5 dan las tres posturas del paso
	jr nz,jugador_pon_la_postura		;6313
	ld b,000h		;6315
	bit 5,a		;6317
	jr nz,jugador_pon_la_postura		;6319
	ld b,004h		;631b   ; en el orden 2, 0 y 4
jugador_pon_la_postura:
	ld (ix+00ch),b		;631d   ; la postura, que es lo unico que el montador de sprites mira
	ret			;6320
jugador_cayendo:
	ld b,002h		;6321   ; la postura 2
	call jugador_pon_la_postura		;6323
	ld a,(ix+00dh)		;6326   ; por donde va la caida
	ld de,0635ch		;6329   ; los nueve valores
	call suma_a_a_de		;632c
	ld a,(de)			;632f
	cp 0afh		;6330   ; el ultimo se repite: la caida no acelera mas
	jr nz,L_6338		;6332
	dec de			;6334
	dec (ix+00dh)		;6335
L_6338:
	ld a,(de)			;6338   ; lo que baja este cuadro
	add a,(ix+003h)		;6339
	ld (ix+003h),a		;633c
	inc (ix+00dh)		;633f   ; y a la siguiente
	call hay_suelo		;6342   ; mira si ya hay suelo
	jr z,jugador_aterriza		;6345
	ld a,(ix+00ah)		;6347   ; si viene de chocar
	and 080h		;634a
	ret z			;634c
	ld a,(ix+003h)		;634d   ; se le suben seis pixeles
	add a,0fah		;6350
	ld (ix+003h),a		;6352
jugador_aterriza:
	xor a			;6355   ; estado 0, a andar
	ld (ix+000h),a		;6356
	jp jugador_borra_el_salto		;6359

; ----------------------------------------------------------------------
; DATOS nueve_casillas: 0x6329 entra con (ix+00dh) y compara con 0xAF
;   0x635c..0x6365  (9 bytes)
DATA_nueve_casillas:
	defb 001h,001h,001h,002h,002h,003h,003h,004h,0afh	; 635c  .........

; ======================================================================
; CODIGO 0x6365..0x6420  (187 bytes)
; ======================================================================


jugador_patada_en_el_aire:
	ld b,00eh		;6365   ; la postura 0x0E
	call jugador_pon_la_postura		;6367
	call jugador_cuenta_la_patada		;636a   ; la cuenta que la acaba
	jr jugador_sigue_el_salto		;636d   ; y por lo demas sigue siendo un salto
jugador_saltando:
	ld b,006h		;636f   ; la postura 6
	call jugador_pon_la_postura		;6371
jugador_sigue_el_salto:
	ld a,(ix+007h)		;6374   ; en el primer cuadro
	cp 001h		;6377
	jr nz,L_6380		;6379
	ld a,081h		;637b   ; suena la pieza 0x81
	call pieza_si_es_el_jugador		;637d
L_6380:
	ld a,(ix+007h)		;6380   ; pasada la mitad de la curva, o sea ya bajando
	cp 009h		;6383
	jr c,jugador_da_un_cabezazo		;6385
	call hay_suelo		;6387   ; mira si hay suelo
	jr z,jugador_acaba_el_salto		;638a
	ld a,(ix+00ah)		;638c   ; y si venia de chocar
	and 080h		;638f
	jr z,jugador_en_el_aire_a_los_lados		;6391
	ld a,(ix+003h)		;6393   ; se le suben seis pixeles
	add a,0fah		;6396
	ld (ix+003h),a		;6398
jugador_acaba_el_salto:
	xor a			;639b   ; se olvida por donde iba
	ld (ix+007h),a		;639c
	ld (ix+000h),a		;639f   ; y a andar
	ret			;63a2
jugador_da_un_cabezazo:
	call hay_techo		;63a3   ; mira si hay techo
	jr nz,jugador_en_el_aire_a_los_lados		;63a6
	ld (ix+000h),003h		;63a8   ; y con el, estado 3: se cae en seco
	jp jugador_borra_el_salto		;63ac
jugador_en_el_aire_a_los_lados:
	ld a,(ix+006h)		;63af   ; a que lado va
	and a			;63b2
	cp 001h		;63b3   ; quieto, nada
	jr c,jugador_dispara_en_el_aire		;63b5
	jr z,L_63C0		;63b7
	call pared_a_la_derecha		;63b9   ; a la derecha, mira la pared
	jr z,jugador_choca_de_lado		;63bc
	jr jugador_avanza_en_el_aire		;63be
L_63C0:
	call pared_a_la_izquierda		;63c0   ; y a la izquierda, la otra
	jr z,jugador_choca_de_lado		;63c3
jugador_avanza_en_el_aire:
	ld b,000h		;63c5   ; mirando a la derecha
	ld c,002h		;63c7   ; y andando
	ld h,(ix+005h)		;63c9   ; la columna
	ld l,(ix+004h)		;63cc
	ld de,00180h		;63cf   ; en el aire se va a uno y medio, se lleven botas o no
	ld a,(ix+006h)		;63d2
	dec a			;63d5
	jr nz,L_63DB		;63d6
	scf			;63d8
	jr L_63DC		;63d9
L_63DB:
	xor a			;63db
L_63DC:
	call jugador_suma_o_resta		;63dc
jugador_dispara_en_el_aire:
	ld a,(0e105h)		;63df   ; el disparo
	bit 4,a		;63e2
	jr z,jugador_curva_del_salto		;63e4
	ld (ix+000h),005h		;63e6   ; estado 5, la patada en el aire
	ld (ix+00dh),000h		;63ea   ; con su cuenta a cero
	ret			;63ee
jugador_curva_del_salto:
	ld hl,06420h		;63ef   ; los veinticuatro pasos del salto
	ld a,(ix+007h)		;63f2   ; por donde va
	ld c,a			;63f5
	call suma_a_a_hl		;63f6
	ld a,(hl)			;63f9   ; lo que sube o baja este cuadro: de 0xFC arriba a 0x04 abajo
	ld b,(ix+003h)		;63fa
	add a,b			;63fd
	ld (ix+003h),a		;63fe
	inc c			;6401
	inc hl			;6402
	ld a,(hl)			;6403   ; y el 0xAF del final
	cp 0afh		;6404
	jr nz,L_6409		;6406
	dec c			;6408   ; deja el salto colgado en el ultimo paso hasta que haya suelo
L_6409:
	ld (ix+007h),c		;6409
	ret			;640c
jugador_choca_de_lado:
	ld a,(ix+007h)		;640d   ; chocarse de lado subiendo no hace nada
	cp 00ch		;6410
	jr c,jugador_dispara_en_el_aire		;6412
	ld (ix+000h),003h		;6414   ; y bajando, se cae
jugador_borra_el_salto:
	xor a			;6418   ; sin salto
	ld (ix+007h),a		;6419   ; y sin cuenta
	ld (ix+00dh),a		;641c
	ret			;641f

; ----------------------------------------------------------------------
; DATOS curva_del_salto: veinticuatro desplazamientos y el 0xAF de cierre: de
;   -4 subiendo a +4 bajando, y suman cero, o sea que el salto vuelve justo a
;   la altura de partida. 0x63EF entra con (ix+007h)
;   0x6420..0x6439  (25 bytes)
DATA_curva_del_salto:
	defb 0fch,0fdh,0fdh,0feh,0feh,0feh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,001h,001h,001h,001h,002h,002h,002h,003h,003h,004h,0afh	; 6420  .........................

; ======================================================================
; CODIGO 0x6439..0x6543  (266 bytes)
; ======================================================================


jugador_en_la_escalera:
	ld a,(ix+005h)		;6439   ; la columna, pegada a la casilla: en la escalera no hay medio paso
	and 0f8h		;643c
	or 004h		;643e
	ld (ix+005h),a		;6440
	ld a,(0e106h)		;6443   ; abajo
	bit 1,a		;6446
	call nz,jugador_baja_por_la_escalera		;6448   ; baja
	ld a,(0e106h)		;644b   ; arriba
	bit 0,a		;644e
	ret z			;6450
	call jugador_postura_de_trepar		;6451   ; la postura de trepar
	dec (ix+003h)		;6454   ; un pixel por cuadro
	call hay_escalera_debajo		;6457   ; hasta que se acaba la escalera
	ret nz			;645a
jugador_sale_por_arriba:
	ld (ix+000h),000h		;645b   ; y ahi se planta
	ld a,(ix+003h)		;645f   ; dos casillas mas arriba, que es donde estaba el agujero
	sub 010h		;6462
	ld (ix+003h),a		;6464
	ret			;6467
jugador_baja_por_la_escalera:
	call jugador_postura_de_trepar		;6468   ; la postura
	inc (ix+003h)		;646b   ; un pixel hacia abajo
	call hay_suelo		;646e   ; hasta que haya suelo
	ret nz			;6471
	ld (ix+000h),000h		;6472   ; y a andar
	ret			;6476
jugador_postura_de_trepar:
	ld b,008h		;6477   ; la postura 8
	ld a,(0e106h)		;6479   ; arriba y abajo a la vez
	and 003h		;647c
	cp 003h		;647e
	jr z,L_648B		;6480
	ld a,(0e003h)		;6482   ; y el bit 3 del contador de cuadros
	and 008h		;6485
	jr z,L_648B		;6487
	ld b,00ah		;6489   ; turnan la 8 y la 0x0A: las manos se cambian cada ocho cuadros
L_648B:
	jp jugador_pon_la_postura		;648b
jugador_patada:
	ld b,00ch		;648e   ; la postura 0x0C
	call jugador_pon_la_postura		;6490
jugador_cuenta_la_patada:
	inc (ix+00dh)		;6493   ; cuatro cuadros
	ld a,(ix+00dh)		;6496
	cp 004h		;6499
	ret nz			;649b
	ld (ix+00dh),000h		;649c
	ld a,(ix+000h)		;64a0   ; desde el aire se vuelve al salto
	cp 005h		;64a3
	ld c,001h		;64a5
	jr z,L_64AA		;64a7
	dec c			;64a9   ; y desde el suelo, a andar
L_64AA:
	ld (ix+000h),c		;64aa
	ret			;64ad

; ----------------------------------------------------------------------
; MONTAR LOS SPRITES DE UNA FICHA
; ----------------------------------------------------------------------
monta_los_sprites_de_la_ficha:
	push bc			;64ae   ; el hueco del bufer
	push af			;64af
	call coloca_los_sprites		;64b0   ; las posiciones y los patrones
	pop af			;64b3
	pop de			;64b4   ; y el hueco, otra vez
	and a			;64b5   ; con a a cero es el jugador
	jr z,monta_los_tres_del_jugador		;64b6
	dec a			;64b8
	ld hl,06546h		;64b9   ; y con cualquier otra cosa, un bicho: un color por clase
	call suma_a_a_hl		;64bc
	ld b,001h		;64bf   ; y un solo sprite
	jr escribe_los_colores		;64c1
monta_los_tres_del_jugador:
	ld hl,06543h		;64c3   ; tres colores
	ld b,003h		;64c6
escribe_los_colores:
	push bc			;64c8
	push de			;64c9
escribe_un_color:
	inc de			;64ca   ; el color va en el cuarto byte de cada sprite
	inc de			;64cb
	inc de			;64cc
	ld a,(hl)			;64cd
	ld (de),a			;64ce
	inc hl			;64cf
	inc de			;64d0
	djnz escribe_un_color		;64d1
	call es_el_jugador		;64d3   ; y si esto no es un cuadro de juego, ahi se queda
	pop de			;64d6
	pop bc			;64d7
	jr nz,color_por_el_estado		;64d8
	ld a,(0e12dh)		;64da   ; el parpadeo de despues del golpe
	ld h,001h		;64dd
	ld c,000h		;64df
	and a			;64e1
	jr nz,alterna_los_dos_colores		;64e2
	ld a,(ix+00fh)		;64e4   ; o el de la ficha
	and a			;64e7
	jr z,mira_la_bandera_de_e465		;64e8
	ld c,00fh		;64ea   ; blanco
	ld h,000h		;64ec
	jp p,L_64F5		;64ee
	ld c,007h		;64f1   ; o rojo, segun el bit 7
	ld h,00ah		;64f3
L_64F5:
	dec (ix+00fh)		;64f5   ; la cuenta del parpadeo
	ld a,(ix+00fh)		;64f8
	and 00fh		;64fb
	jr nz,alterna_los_dos_colores		;64fd
	ld (ix+00fh),000h		;64ff
	jr alterna_los_dos_colores		;6503
mira_la_bandera_de_e465:
	ld a,(0e465h)		;6505   ; y blanco tambien mientras (0xE465) este puesto
	ld c,00fh		;6508
	and a			;650a
	jr nz,color_sin_parpadeo		;650b
color_por_el_estado:
	ld a,(ix+00ah)		;650d   ; los bits 0, 3 y 5 de (ix+00Ah): el agua, la llamarada y la fuga de la tuberia
	and 029h		;6510
	ret z			;6512
	ld c,006h		;6513   ; con la llamarada se pone de cian
	bit 3,a		;6515
	jr nz,color_sin_parpadeo		;6517
	ld c,007h		;6519   ; con la fuga, de blanco
	bit 5,a		;651b
	jr nz,color_sin_parpadeo		;651d
	ld c,00fh		;651f
	exx			;6521   ; y con el resto, el color depende del recoloreado del nivel
	call recoloreado_del_nivel		;6522
	exx			;6525
	and 00fh		;6526
	dec a			;6528
	jr nz,color_sin_parpadeo		;6529
	ld c,006h		;652b   ; que en el primero deja el cian
color_sin_parpadeo:
	ld h,000h		;652d
alterna_los_dos_colores:
	ld a,(0e003h)		;652f   ; el bit 1 del contador de cuadros
	bit 1,a		;6532
	ld a,c			;6534   ; turna los dos colores cada dos cuadros
	jr nz,L_6538		;6535
	ld a,h			;6537
L_6538:
	cp 001h		;6538   ; y con el color 1 no se toca nada
	ret z			;653a
escribe_el_mismo_color:
	inc de			;653b   ; otra vez de cuatro en cuatro
	inc de			;653c
	inc de			;653d
	ld (de),a			;653e
	inc de			;653f
	djnz escribe_el_mismo_color		;6540
	ret			;6542

; ----------------------------------------------------------------------
; DATOS colores_de_las_fichas: nueve colores: los TRES primeros son los del
;   jugador, y los seis de 0x6546 uno por clase de bicho; 0x64B9 entra con a-1
;   y 0x64C3 coge los tres de golpe
;   0x6543..0x654c  (9 bytes)
DATA_colores_de_las_fichas:
	defb 004h,00dh,00bh,00fh,00ah,007h,002h,009h,00eh	; 6543  .........

; ======================================================================
; CODIGO 0x654c..0x65b7  (107 bytes)
; ======================================================================


coloca_los_sprites:
	push af			;654c
	ld (0e103h),hl		;654d   ; la posicion, que hay que ir sumando a cada sprite
	ld a,(ix+00bh)		;6550   ; mirando a la izquierda
	and a			;6553
	ld a,(ix+00ch)		;6554   ; la postura
	jr z,L_655A		;6557
	inc a			;6559   ; la de al lado: los dibujos van en parejas, uno por lado
L_655A:
	ld h,a			;655a
	pop af			;655b
	and a			;655c
	ld a,h			;655d
	jr nz,coloca_un_solo_sprite		;655e   ; con un solo sprite, por el otro camino
	add a,a			;6560   ; nueve bytes por postura
	add a,a			;6561
	add a,a			;6562
	add a,h			;6563
	call suma_a_a_de		;6564   ; el dibujo que toca
	ld h,b			;6567   ; el hueco del bufer
	ld l,c			;6568
	ld b,003h		;6569   ; y tres sprites
coloca_un_sprite:
	ld a,(0e062h)		;656b   ; si la ficha esta en otra sala
	cp (ix+001h)		;656e
	ld a,0e0h		;6571   ; el sprite se manda a la fila 0xE0, fuera de la pantalla
	jr nz,L_6580		;6573
	ld a,(de)			;6575   ; y lo mismo con el 0xC0 del dibujo, que es como se apaga un sprite suelto
	cp 0c0h		;6576
	jr z,L_6580		;6578
	ld a,(0e103h)		;657a   ; la fila
	ld c,a			;657d
	ld a,(de)			;657e
	add a,c			;657f
L_6580:
	ld (hl),a			;6580
	inc de			;6581
	inc hl			;6582
	ld a,(0e104h)		;6583   ; la columna
	ld c,a			;6586
	ld a,(de)			;6587
	add a,c			;6588
	ld (hl),a			;6589
	inc de			;658a
	inc hl			;658b
	ld a,(de)			;658c   ; y el patron, tal cual
	ld (hl),a			;658d
	inc de			;658e
	inc hl			;658f
	inc hl			;6590   ; el cuarto byte es el color, y lo pone el otro
	djnz coloca_un_sprite		;6591
	ret			;6593
coloca_un_solo_sprite:
	call suma_a_a_de		;6594   ; tres bytes por postura
	ld hl,0e103h		;6597
	ld a,(0e062h)		;659a   ; en otra sala
	cp (ix+001h)		;659d
	ld a,0e0h		;65a0   ; fuera de la pantalla
	jr nz,L_65AC		;65a2
	ld a,(de)			;65a4
	cp 0c0h		;65a5
	jr z,L_65AC		;65a7
	ld a,0f0h		;65a9   ; dieciseis pixeles por encima de la posicion
	add a,(hl)			;65ab
L_65AC:
	ld (bc),a			;65ac
	inc hl			;65ad
	inc bc			;65ae
	ld a,0f8h		;65af   ; y ocho a la izquierda: la posicion es el centro de los pies
	add a,(hl)			;65b1
	ld (bc),a			;65b2
	inc bc			;65b3
	ld a,(de)			;65b4
	ld (bc),a			;65b5
	ret			;65b6

; ----------------------------------------------------------------------
; DATOS sprites_del_jugador: dieciseis posturas de nueve bytes: tres sprites
;   de fila, columna y patron. Van en parejas -una por lado-, y son las ocho
;   del jugador: andar A, quieto, andar C, saltar, trepar A, trepar B, patada
;   y patada en el aire. 0x61BA se las pasa a L_64AE con bc = 0xE0A0, el bufer
;   de atributos
;   0x65b7..0x6647  (144 bytes)
DATA_sprites_del_jugador:
	defb 0fch,0f7h,058h,0ech,0f7h,050h,0ech,0f7h,054h,0fch,0f9h,0b0h,0ech,0f9h,0a8h,0ech	; 65b7  ..X..P..T.......
	defb 0f9h,0ach,0fbh,0f8h,064h,0ebh,0f8h,05ch,0ebh,0f8h,060h,0fbh,0f8h,0bch,0ebh,0f8h	; 65c7  ....d..\..`.....
	defb 0b4h,0ebh,0f8h,0b8h,0fch,0f7h,06ch,0ech,0f7h,068h,0ech,0f7h,054h,0fch,0f9h,0c4h	; 65d7  ......l..h..T...
	defb 0ech,0f9h,0c0h,0ech,0f9h,0ach,0fbh,0f7h,070h,0ebh,0f7h,068h,0ebh,0f7h,054h,0fbh	; 65e7  ........p..h..T.
	defb 0f9h,0c8h,0ebh,0f9h,0c0h,0ebh,0f9h,0ach,0fbh,0f8h,034h,0f0h,0f8h,030h,0c0h,0f8h	; 65f7  ..........4..0..
	defb 030h,0fbh,0f8h,034h,0f0h,0f8h,030h,0c0h,0f8h,030h,0fah,0f8h,03ch,0f0h,0f8h,038h	; 6607  0..4..0..0..<..8
	defb 0c0h,0f8h,038h,0fah,0f8h,03ch,0f0h,0f8h,038h,0c0h,0f8h,038h,0fbh,0f7h,07ch,0ebh	; 6617  ..8..<..8..8..|.
	defb 0f7h,074h,0ebh,0f9h,078h,0fbh,0f9h,0d4h,0ebh,0f9h,0cch,0ebh,0f7h,0d0h,0fbh,0f7h	; 6627  .t..x...........
	defb 070h,0ebh,0f7h,074h,0ebh,0f9h,078h,0fbh,0f9h,0c8h,0ebh,0f9h,0cch,0ebh,0f7h,0d0h	; 6637  p..t..x.........

; ======================================================================
; CODIGO 0x6647..0x667c  (53 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; QUE HAY DEBAJO DE LOS PIES
; ----------------------------------------------------------------------
hay_suelo:
	ld a,(ix+003h)		;6647   ; la fila
	ld l,a			;664a
	sub 010h		;664b   ; una casilla mas abajo
	cp 0a0h		;664d   ; fuera de la sala no hay suelo
	jr nc,no_hay_suelo		;664f
	ld a,(ix+005h)		;6651   ; la columna
	ld c,a			;6654
	add a,0fdh		;6655   ; tres pixeles a la izquierda
	ld h,a			;6657
	ld a,(ix+001h)		;6658
	call casilla_de_la_sala_en_pixeles		;665b   ; a direccion dentro de la sala
	ld a,(hl)			;665e
	ex de,hl			;665f
	call es_casilla_solida		;6660   ; si esa casilla es de las que aguantan, hay suelo
	ex de,hl			;6663
	ret z			;6664
	ld a,c			;6665   ; y si no, se mira la de al lado, salvo en el tercio de en medio de la casilla
	and 007h		;6666
	sub 003h		;6668
	jr c,mira_la_casilla_de_al_lado		;666a
	cp 003h		;666c
	jr nc,mira_la_casilla_de_al_lado		;666e
no_hay_suelo:
	or 001h		;6670   ; vuelve sin z
	ret			;6672
mira_la_casilla_de_al_lado:
	inc hl			;6673
	ld a,(hl)			;6674
es_casilla_solida:
	ld b,003h		;6675   ; tres parejas de topes
	ld hl,0667ch		;6677   ; 0x40..0x47, 0xBC..0xBD y 0xDE..0xDF
	jr $+85		;667a

; ----------------------------------------------------------------------
; DATOS tres_topes_667c: 0x6677 los recorre con b=3 comparando
;   0x667c..0x6682  (6 bytes)
DATA_tres_topes_667c:
	defb 040h,048h,0bch,0beh,0deh,0e0h	; 667c

; ======================================================================
; CODIGO 0x6682..0x66de  (92 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; QUE HAY A LOS LADOS
; ----------------------------------------------------------------------
pared_a_la_izquierda:
	ld e,0fbh		;6682   ; cinco pixeles a la izquierda
	call hay_pared		;6684
	ld d,002h		;6687   ; y se apunta con que se ha chocado
	jr apunta_el_choque		;6689
pared_a_la_derecha:
	ld e,005h		;668b   ; cinco a la derecha
	call hay_pared		;668d
	ld d,001h		;6690
apunta_el_choque:
	jr z,L_6696		;6692   ; con el camino libre no hay choque
	ld d,000h		;6694
L_6696:
	ld (ix+00eh),d		;6696   ; y (ix+00Eh) se queda con contra que lado ha sido
	ret			;6699
hay_pared:
	ld a,(ix+003h)		;669a   ; la fila, trece pixeles mas arriba: se mira a la altura del cuerpo, no de los pies
	add a,0f3h		;669d
	ld l,a			;669f
	cp 011h		;66a0   ; y sin salirse de la sala por arriba
	jr nc,L_66A6		;66a2
	ld l,012h		;66a4
L_66A6:
	cp 0a8h		;66a6   ; ni por abajo
	jr c,L_66AC		;66a8
	ld l,0a7h		;66aa
L_66AC:
	ld a,(ix+005h)		;66ac   ; la columna, mas lo que se pida
	add a,e			;66af
	ld h,a			;66b0
	push hl			;66b1
	ld a,(ix+001h)		;66b2
	call casilla_de_la_sala_en_pixeles		;66b5   ; a direccion dentro de la sala
	push hl			;66b8
	call casilla_que_frena		;66b9   ; la casilla de esa altura
	pop hl			;66bc
	pop de			;66bd
	ret z			;66be
	ld a,e			;66bf   ; si la fila cae justa, con una basta
	and 00fh		;66c0
	jr z,no_frena		;66c2
	ld a,020h		;66c4   ; y si no, se mira tambien la de abajo
	call suma_a_a_hl		;66c6
casilla_que_frena:
	ld a,(hl)			;66c9   ; tres parejas de topes, distintas de las del suelo
	ld b,003h		;66ca
	ld hl,066deh		;66cc
casilla_que_frena_bucle:
	cp (hl)			;66cf   ; por debajo del primero, no frena
	jr c,no_frena		;66d0
	inc hl			;66d2
	cp (hl)			;66d3   ; y entre los dos, si
	jr c,si_frena		;66d4
	inc hl			;66d6
	djnz casilla_que_frena_bucle		;66d7
no_frena:
	or 001h		;66d9
	ret			;66db
si_frena:
	xor a			;66dc
	ret			;66dd

; ----------------------------------------------------------------------
; DATOS tres_topes_66de: 0x66CC los compara uno a uno con `cp (hl)`
;   0x66de..0x66e4  (6 bytes)
DATA_tres_topes_66de:
	defb 046h,04eh,0bdh,0c4h,0dfh,0e6h	; 66de

; ======================================================================
; CODIGO 0x66e4..0x6749  (101 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; SI AQUI SE PUEDE SUBIR O BAJAR
; ----------------------------------------------------------------------
mira_la_escalera:
	ld l,(ix+003h)		;66e4   ; donde esta el jugador
	ld h,(ix+005h)		;66e7
	ld a,(ix+001h)		;66ea
	call casilla_de_la_sala_en_pixeles		;66ed   ; a direccion dentro de la sala
	ld b,000h		;66f0
	ld a,(hl)			;66f2
	cp 041h		;66f3   ; la casilla 0x41 es el PIE DE LA CUERDA, la verde que cuelga de las plataformas: ahi se sube
	jr nz,L_66F9		;66f5
	set 0,b		;66f7
L_66F9:
	ld a,(ix+003h)		;66f9   ; y si no esta al borde de abajo
	cp 0a8h		;66fc
	jr nc,L_670C		;66fe
	ld a,020h		;6700   ; la casilla de debajo
	call suma_a_a_hl		;6702
	ld a,(hl)			;6705
	cp 053h		;6706   ; y si es la 0x53, que es la CABEZA de esa misma cuerda, por ahi se baja
	jr nz,L_670C		;6708
	set 1,b		;670a
L_670C:
	ld (ix+009h),b		;670c   ; las dos cosas caben en (ix+009h)
	ret			;670f
hay_techo:
	ld a,(ix+003h)		;6710   ; quince pixeles por encima de los pies, que es la cabeza
	add a,0f1h		;6713
	ld l,a			;6715
	jr L_6718		;6716
L_6718:
	sub 010h		;6718
	cp 0a0h		;671a   ; fuera de la sala, no hay techo
	jr c,L_6721		;671c
	or 001h		;671e
	ret			;6720
L_6721:
	ld a,(ix+005h)		;6721   ; tres pixeles a la izquierda
	add a,0fdh		;6724
	ld h,a			;6726
	ld bc,00500h		;6727   ; y cinco a la derecha
	push hl			;672a
	push bc			;672b
	ld a,(ix+001h)		;672c
	call casilla_de_la_sala_en_pixeles		;672f
	ld a,(hl)			;6732
	call L_6741		;6733
	pop bc			;6736
	pop hl			;6737
	ret z			;6738
	add hl,bc			;6739
	ld a,(ix+001h)		;673a
	call casilla_de_la_sala_en_pixeles		;673d
	ld a,(hl)			;6740
L_6741:
	ld b,003h		;6741
	ld hl,06749h		;6743
	jp casilla_que_frena_bucle		;6746

; ----------------------------------------------------------------------
; DATOS tres_topes_6749: 0x6743 los manda al mismo bucle de 0x66CF
;   0x6749..0x674f  (6 bytes)
DATA_tres_topes_6749:
	defb 046h,054h,0beh,0c5h,0e0h,0e7h	; 6749

; ======================================================================
; CODIGO 0x674f..0x6789  (58 bytes)
; ======================================================================


hay_escalera_debajo:
	ld a,(ix+003h)		;674f   ; quince pixeles por debajo
	add a,0f1h		;6752
	ld l,a			;6754
	sub 010h		;6755
	cp 0a0h		;6757   ; fuera de la sala, no
	jr c,hay_escalera_mira		;6759
	or 001h		;675b
	ret			;675d
hay_escalera_mira:
	ld a,(ix+005h)		;675e   ; dos pixeles a la izquierda
	add a,0feh		;6761
	ld h,a			;6763
	ld bc,00400h		;6764   ; y cuatro a la derecha
	push hl			;6767
	push bc			;6768
	ld a,(ix+001h)		;6769
	call casilla_de_la_sala_en_pixeles		;676c   ; a direccion dentro de la sala
	ld a,(hl)			;676f
	call casilla_de_escalera		;6770
	pop bc			;6773
	pop hl			;6774
	ret z			;6775
	add hl,bc			;6776
	ld a,(ix+001h)		;6777
	call casilla_de_la_sala_en_pixeles		;677a
	ld a,(hl)			;677d
casilla_de_escalera:
	ld b,005h		;677e   ; cinco casillas
	ld hl,06789h		;6780   ; las 0x40, 0x41, 0x45, 0xBC y 0xDE
casilla_de_escalera_bucle:
	cp (hl)			;6783
	ret z			;6784
	inc hl			;6785
	djnz casilla_de_escalera_bucle		;6786
	ret			;6788

; ----------------------------------------------------------------------
; DATOS cinco_valores_a_cazar: 0x6780 los compara con b=5 y vuelve con z en
;   cuanto uno cuadra
;   0x6789..0x678e  (5 bytes)
DATA_cinco_valores_a_cazar:
	defb 040h,041h,045h,0bch,0deh	; 6789

; ======================================================================
; CODIGO 0x678e..0x67c4  (54 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS CINCO CALAVERAS
; ----------------------------------------------------------------------
mueve_las_calaveras:
	ld ix,0e3fdh		;678e   ; el tipo 5 de la sala
	ld b,005h		;6792   ; cinco
L_6794:
	exx			;6794
	call mueve_una_calavera		;6795   ; se mueve
	exx			;6798
	call monta_el_sprite_de_la_calavera		;6799   ; y se monta su sprite
	ld de,0000eh		;679c   ; catorce bytes de ficha
	add ix,de		;679f
	djnz L_6794		;67a1
	ret			;67a3
mueve_una_calavera:
	ld a,(ix+000h)		;67a4   ; apagada, nada
	and a			;67a7
	ret z			;67a8
	cp 004h		;67a9   ; en los estados 4 a 8
	jr c,L_67B4		;67ab
	cp 009h		;67ad
	jr nc,L_67B4		;67af
	call mira_si_le_da_una_patada		;67b1   ; se mira si le ha dado al jugador
L_67B4:
	ld a,(0e1b1h)		;67b4   ; con la partida parada
	and a			;67b7
	ld a,(ix+000h)		;67b8
	jr z,L_67C0		;67bb
	cp 009h		;67bd   ; solo siguen los estados 9 y 10, que son los de morirse
	ret c			;67bf
L_67C0:
	dec a			;67c0   ; el estado, del 1 al 10
	call reparte_por_tabla		;67c1   ; y la tabla va pegada detras del `call`

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_67c4: 10 entradas; detras sigue la primera, 0x67D8
;   0x67c4..0x67d8  (20 bytes)
DATA_tabla_de_subescenas_67c4:
	defw 067d8h,067fch,0680bh,06833h,06846h,06881h,06889h,068bbh	; 67c4
	defw 068f5h,068fdh	; 67d4  -> calavera_se_va calavera_desaparece

; ======================================================================
; CODIGO 0x67d8..0x68e4  (268 bytes)
; ======================================================================


calavera_arranca:
	ld (ix+009h),030h		;67d8   ; 0x30 cuadros de espera
	ld (ix+006h),080h		;67dc   ; un pixel y medio por cuadro
	ld (ix+007h),001h		;67e0
	ld a,(ix+003h)		;67e4   ; se apunta la fila por la que sale
	ld (ix+00bh),a		;67e7
	inc (ix+000h)		;67ea   ; y al estado 2
	ld (ix+00ch),000h		;67ed   ; sin dibujo
	ld a,(ix+001h)		;67f1   ; las tres primeras clases
	cp 003h		;67f4
	ret nc			;67f6
	ld (ix+000h),003h		;67f7   ; se saltan la espera y salen ya
	ret			;67fb
calavera_espera_al_jugador:
	ld (ix+00ch),000h		;67fc   ; sin dibujo
	ld a,(0e113h)		;6800   ; hasta que el jugador esta a su altura
	cp (ix+003h)		;6803
	ret nz			;6806
	inc (ix+000h)		;6807   ; y entonces aparece
	ret			;680a
calavera_aparece:
	ld a,(ix+009h)		;680b   ; a los dieciseis cuadros
	cp 020h		;680e
	ld a,002h		;6810   ; suena la pieza 2
	call z,pide_pieza		;6812
	ld b,048h		;6815   ; la nube
	ld a,(0e003h)		;6817   ; el bit 4 del contador
	and 010h		;681a
	jr z,L_6820		;681c
	ld b,04ch		;681e   ; la turna con la otra
L_6820:
	ld (ix+00ch),b		;6820
	dec (ix+009h)		;6823   ; y cuando se acaba la cuenta
	ld a,(ix+009h)		;6826
	and a			;6829
	ret nz			;682a
	ld (ix+00ch),001h		;682b   ; se queda la calavera
	inc (ix+000h)		;682f   ; y al estado 4
	ret			;6832
calavera_elige_lado:
	inc (ix+000h)		;6833
	ld a,(0e115h)		;6836   ; la columna del jugador
	cp (ix+005h)		;6839
	ld (ix+00ah),000h		;683c   ; a la derecha
	ret nc			;6840
	ld (ix+00ah),001h		;6841   ; o a la izquierda: sale hacia el
	ret			;6845
calavera_anda:
	ld a,(ix+001h)		;6846   ; las clases 1 y 4
	cp 001h		;6849
	jr z,calavera_a_desaparecer		;684b
	cp 004h		;684d   ; se van directas a saltar
	jr z,calavera_a_desaparecer		;684f
	ld (ix+009h),001h		;6851   ; un cuadro de cuenta
	call calavera_paso		;6855   ; y andar
	ld a,(ix+001h)		;6858   ; las clases 2 y 5
	cp 002h		;685b
	jr z,L_6862		;685d
	cp 005h		;685f
	ret nz			;6861
L_6862:
	ld b,(ix+003h)		;6862   ; miran si el jugador esta a su altura
	ld a,(0e113h)		;6865
	cp b			;6868
	ret nz			;6869
	ld b,(ix+005h)		;686a   ; y a menos de veinte pixeles
	ld a,(0e115h)		;686d
	add a,014h		;6870
	cp b			;6872
	ret c			;6873
	sub 028h		;6874   ; por delante o por detras
	cp b			;6876
	ret nc			;6877
	inc (ix+000h)		;6878   ; y entonces saltan
	ret			;687b
calavera_a_desaparecer:
	ld (ix+000h),008h		;687c   ; estado 8
	ret			;6880
calavera_cuenta:
	dec (ix+009h)		;6881   ; la cuenta, y al acabarse el estado siguiente
	ret nz			;6884
	inc (ix+000h)		;6885
	ret			;6888
calavera_saltando:
	call calavera_salta		;6889   ; el salto
	ld a,(ix+008h)		;688c   ; hasta que se acaba la curva
	and a			;688f
	ret nz			;6890
	ld (ix+000h),005h		;6891   ; y de vuelta a andar
	ret			;6895
calavera_paso:
	call calavera_en_el_borde		;6896   ; si pisa un borde
	call z,calavera_da_la_vuelta		;6899   ; se da la vuelta
calavera_suma_el_paso:
	ld h,(ix+005h)		;689c   ; la columna, con su fraccion
	ld l,(ix+004h)		;689f
	ld d,(ix+007h)		;68a2   ; la velocidad
	ld e,(ix+006h)		;68a5
	ld a,(ix+00ah)		;68a8   ; a que lado va
	and a			;68ab
	jr nz,L_68B1		;68ac
	add hl,de			;68ae   ; a la derecha se suma
	jr L_68B4		;68af
L_68B1:
	xor a			;68b1
	sbc hl,de		;68b2   ; y a la izquierda se resta
L_68B4:
	ld (ix+005h),h		;68b4
	ld (ix+004h),l		;68b7
	ret			;68ba
calavera_salta:
	call calavera_en_el_borde		;68bb   ; tambien se da la vuelta en los bordes
	call z,calavera_da_la_vuelta		;68be
	ld hl,068e4h		;68c1   ; la curva del salto
	ld a,(ix+008h)		;68c4   ; por donde va
	call suma_a_a_hl		;68c7
	push hl			;68ca
	ld a,(hl)			;68cb   ; lo que sube o baja este cuadro
	ld b,(ix+003h)		;68cc
	add a,b			;68cf
	ld (ix+003h),a		;68d0
	inc (ix+008h)		;68d3   ; y a la siguiente
	call calavera_suma_el_paso		;68d6   ; mientras, sigue avanzando
	pop hl			;68d9
	inc hl			;68da
	ld a,(hl)			;68db   ; con el 0xAF del final
	cp 0afh		;68dc
	ret nz			;68de
	ld (ix+008h),000h		;68df   ; vuelve al principio
	ret			;68e3

; ----------------------------------------------------------------------
; DATOS curva_del_salto_de_la_calavera: dieciseis desplazamientos y el 0xAF;
;   la misma idea que la del jugador pero mas corta. 0x68C1 entra con
;   (ix+008h)
;   0x68e4..0x68f5  (17 bytes)
DATA_curva_del_salto_de_la_calavera:
	defb 0fch,0fdh,0feh,0feh,0ffh,0ffh,000h,000h,000h,000h,001h,001h,002h,002h,003h,004h,0afh	; 68e4  .................

; ======================================================================
; CODIGO 0x68f5..0x6939  (68 bytes)
; ======================================================================


calavera_se_va:
	ld (ix+009h),010h		;68f5   ; 0x10 cuadros
	inc (ix+000h)		;68f9
	ret			;68fc
calavera_desaparece:
	ld a,(ix+00dh)		;68fd   ; su hueco en el bufer
	ld hl,0e0e0h		;6900
	call suma_a_a_hl		;6903
	ld (ix+00ch),004h		;6906   ; la nube, otra vez
	dec (ix+009h)		;690a   ; la cuenta
	ld a,(ix+009h)		;690d
	and a			;6910
	ret nz			;6911
	ld (ix+000h),000h		;6912   ; y se apaga
	ld (hl),0e0h		;6916   ; con el sprite mandado a la fila 0xE0, fuera de la pantalla
	ret			;6918
calavera_en_el_borde:
	ld a,(ix+005h)		;6919   ; doce pixeles a la izquierda
	sub 00ch		;691c
	cp 0e8h		;691e   ; fuera de la sala, no
	jr c,L_6924		;6920
	xor a			;6922
	ret			;6923
L_6924:
	ld l,(ix+00bh)		;6924   ; la fila por la que salio: las calaveras andan siempre a la misma altura
	ld h,(ix+005h)		;6927
	call casilla_de_la_sala_de_ahora		;692a   ; a direccion dentro de la sala
	ld a,(hl)			;692d
	ld b,004h		;692e   ; cuatro casillas
	ld hl,06939h		;6930
calavera_borde_bucle:
	cp (hl)			;6933   ; y con cualquiera de ellas, se vuelve
	ret z			;6934
	inc hl			;6935
	djnz calavera_borde_bucle		;6936
	ret			;6938

; ----------------------------------------------------------------------
; DATOS cuatro_valores_a_cazar: 0x6930 los compara con b=4 y vuelve con z si
;   cuadra
;   0x6939..0x693d  (4 bytes)
DATA_cuatro_valores_a_cazar:
	defb 0bdh,0dfh,0c2h,0e4h	; 6939

; ======================================================================
; CODIGO 0x693d..0x6996  (89 bytes)
; ======================================================================


calavera_da_la_vuelta:
	ld a,(ix+00ah)		;693d   ; cambia de lado
	xor 001h		;6940
	ld (ix+00ah),a		;6942
	ret			;6945

; ----------------------------------------------------------------------
; EL SPRITE DE LA CALAVERA
; ----------------------------------------------------------------------
monta_el_sprite_de_la_calavera:
	ld a,(ix+000h)		;6946   ; en el estado 6 no se dibuja
	cp 006h		;6949
	ret z			;694b
	and a			;694c   ; ni apagada
	ret z			;694d
	ld hl,06996h		;694e   ; las dos posturas, cada una con su desplazamiento
	ld a,(0e003h)		;6951   ; el bit 3 del contador abre y cierra la mandibula
	rra			;6954
	rra			;6955
	and 002h		;6956
	ld c,a			;6958
	ld a,(ix+00ah)		;6959   ; y el lado elige entre el dibujo y su espejo
	and a			;695c
	jr z,L_6960		;695d
	inc c			;695f
L_6960:
	ld a,c			;6960
	add a,a			;6961
	call suma_a_a_hl		;6962
	ld a,005h		;6965   ; el hueco: uno por calavera, de cuatro en cuatro
	sub b			;6967
	add a,a			;6968
	add a,a			;6969
	ld (ix+00dh),a		;696a
	ld de,0e0e0h		;696d
	call suma_a_a_de		;6970
	ld a,(ix+003h)		;6973   ; doce pixeles por encima de la posicion
	add a,0f4h		;6976
	ld (de),a			;6978
	inc de			;6979
	ld a,(ix+005h)		;697a   ; la columna, mas lo que pida la postura: el espejo esta corrido cuatro pixeles
	add a,(hl)			;697d
	ld (de),a			;697e
	inc hl			;697f
	inc de			;6980
	ld a,(ix+00ch)		;6981   ; con la nube se pinta lo que diga la ficha
	cp 004h		;6984
	jr nc,L_6989		;6986
	ld a,(hl)			;6988   ; y con la calavera, lo que diga la tabla
L_6989:
	ld (de),a			;6989
	inc de			;698a
	ld a,(ix+00ch)		;698b   ; parada
	and a			;698e
	ld a,00fh		;698f   ; se ve
	jr nz,L_6994		;6991
	xor a			;6993   ; y sin dibujo, el color a cero: asi se apaga sin mover el sprite
L_6994:
	ld (de),a			;6994
	ret			;6995

; ----------------------------------------------------------------------
; DATOS sprite_de_la_calavera: cuatro parejas de desplazamiento en columna y
;   patron: la calavera con la mandibula abierta y cerrada, y sus dos espejos.
;   0x694E entra con el bit 3 de (0xE003) y con el lado
;   0x6996..0x699e  (8 bytes)
DATA_sprite_de_la_calavera:
	defb 0f4h,0f8h,0fch,0a0h,0f4h,0feh,0fch,0a4h	; 6996  ........

; ======================================================================
; CODIGO 0x699e..0x6a02  (100 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL MURCIELAGO
; ----------------------------------------------------------------------
mueve_al_murcielago:
	ld ix,0e443h		;699e   ; el tipo 6 de la sala, y no hay mas que uno
	ld a,(ix+000h)		;69a2   ; apagado, nada
	and a			;69a5
	ret z			;69a6
	dec a			;69a7   ; en el estado 1 no cuenta el tiempo
	jr z,murcielago_sigue		;69a8
	ld a,(0e003h)		;69aa   ; uno de cada dos cuadros
	and 002h		;69ad
	jr nz,murcielago_sigue		;69af
	inc (ix+008h)		;69b1
murcielago_sigue:
	call murcielago_estado		;69b4   ; se mueve
	ld a,(ix+000h)		;69b7   ; y en los estados 3 a 10
	sub 003h		;69ba
	cp 008h		;69bc
	jp nc,monta_el_sprite_del_murcielago		;69be
	call mira_patada_del_otro		;69c1   ; se mira si le ha dado al jugador
	jp monta_el_sprite_del_murcielago		;69c4
murcielago_estado:
	ld a,(0e1b1h)		;69c7   ; con la partida parada
	and a			;69ca
	jr z,L_69D6		;69cb
	ld a,(ix+000h)		;69cd   ; solo siguen los estados 8 y 9
	cp 008h		;69d0
	ret c			;69d2
	cp 00ah		;69d3
	ret nc			;69d5
L_69D6:
	ld a,(0e003h)		;69d6   ; el bit 3 del contador
	bit 3,a		;69d9
	ld a,024h		;69db   ; las alas abiertas
	jr z,L_69E1		;69dd
	ld a,028h		;69df   ; o recogidas
L_69E1:
	ld (ix+00eh),a		;69e1
	ld a,(ix+008h)		;69e4   ; a los 0x60 cuadros
	cp 060h		;69e7
	jr nz,L_69FB		;69e9
	ld (ix+008h),000h		;69eb
	ld a,(ix+000h)		;69ef   ; y si no esta ya de salida
	dec a			;69f2
	cp 009h		;69f3
	jr nc,L_69FB		;69f5
	ld (ix+000h),003h		;69f7   ; vuelve al estado 3, que es el que le busca rumbo nuevo
L_69FB:
	ld a,(ix+000h)		;69fb   ; doce estados
	dec a			;69fe
	call reparte_por_tabla		;69ff

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_6a02: 12 entradas; detras sigue la primera, 0x6A1A
;   0x6a02..0x6a1a  (24 bytes)
DATA_tabla_de_subescenas_6a02:
	defw 06a1ah,06a31h,06a4eh,06a77h,06aa1h,06ac2h,06ae3h,06b16h	; 6a02
	defw 06b4ch,06b83h,06b65h,06b6dh	; 6a12  -> murcielago_parado murcielago_saliendo murcielago_se_marcha murcielago_desaparece

; ======================================================================
; CODIGO 0x6a1a..0x6bc5  (427 bytes)
; ======================================================================


murcielago_arranca:
	ld a,(0e124h)		;6a1a   ; la fila por la que sale
	ld (ix+002h),a		;6a1d
	ld a,(0e125h)		;6a20   ; y su columna
	ld (ix+004h),a		;6a23
	ld (ix+00fh),010h		;6a26   ; 0x10 cuadros de aparecer
	ld (ix+00ch),0e0h		;6a2a   ; y hasta entonces, fuera de la pantalla
	jp mira_por_arriba_y_por_abajo		;6a2e
murcielago_apareciendo:
	ld a,(ix+00fh)		;6a31   ; con la cuenta a cero, ya esta
	and a			;6a34
	inc (ix+000h)		;6a35
	ret z			;6a38
	dec (ix+000h)		;6a39
	ld a,(ix+002h)		;6a3c   ; se pinta donde toca
	ld (ix+00ch),a		;6a3f
	dec (ix+00fh)		;6a42   ; y se cuenta
	ld a,(ix+00fh)		;6a45
	and a			;6a48
	ret nz			;6a49
	inc (ix+000h)		;6a4a
	ret			;6a4d
murcielago_busca_rumbo:
	inc (ix+000h)		;6a4e
	ld a,(ix+00dh)		;6a51   ; despues de veinticuatro correcciones
	cp 018h		;6a54
	jr c,murcielago_apunta_al_jugador		;6a56
	ld (ix+006h),0e0h		;6a58   ; se va por la esquina de abajo a la derecha
	ld (ix+007h),080h		;6a5c
	ld (ix+000h),00ah		;6a60   ; y al estado 10, el de marcharse
	ret			;6a64
murcielago_apunta_al_jugador:
	ld a,(0e113h)		;6a65   ; la fila del jugador
	sub 00ch		;6a68   ; doce pixeles mas arriba, que es a la altura del cuerpo
	ld (ix+006h),a		;6a6a
	ld a,(0e115h)		;6a6d   ; y su columna
	ld (ix+007h),a		;6a70
	inc (ix+00dh)		;6a73   ; una correccion mas
	ret			;6a76
murcielago_sube_o_baja:
	ld a,(ix+006h)		;6a77   ; a donde va
	cp (ix+002h)		;6a7a   ; contra donde esta
	ld b,005h		;6a7d   ; si esta por encima, el estado 5: subir
	ld c,000h		;6a7f
	jr c,L_6A85		;6a81
	inc b			;6a83   ; y si no, el 6: bajar
	inc c			;6a84
L_6A85:
	ld (ix+000h),b		;6a85
	ld (ix+00ah),c		;6a88
	ret			;6a8b
murcielago_a_los_lados:
	ld a,(ix+002h)		;6a8c   ; se pinta a su altura
	ld (ix+00ch),a		;6a8f
	ld a,(ix+007h)		;6a92   ; la columna a la que va
	cp (ix+004h)		;6a95
	ld b,007h		;6a98   ; el estado 7 va a la izquierda
	jr c,L_6A9D		;6a9a
	inc b			;6a9c   ; y el 8 a la derecha
L_6A9D:
	ld (ix+000h),b		;6a9d
	ret			;6aa0
murcielago_subiendo:
	dec (ix+002h)		;6aa1   ; un pixel arriba
	xor a			;6aa4   ; sin onda
	ld (ix+009h),a		;6aa5
	ld (ix+00bh),a		;6aa8
	ld a,(ix+006h)		;6aab   ; si ya esta a la altura
	cp (ix+002h)		;6aae
	jr z,murcielago_a_los_lados		;6ab1
	call murcielago_mira_arriba		;6ab3   ; mira si hay techo
	ld a,(ix+002h)		;6ab6
	ld (ix+00ch),a		;6ab9
	ret nz			;6abc
	inc (ix+002h)		;6abd   ; y con el, se para y pasa a moverse de lado
	jr murcielago_a_los_lados		;6ac0
murcielago_bajando:
	inc (ix+002h)		;6ac2   ; un pixel abajo
	xor a			;6ac5
	ld (ix+009h),a		;6ac6
	ld (ix+00bh),a		;6ac9
	ld a,(ix+006h)		;6acc   ; lo mismo al reves
	cp (ix+002h)		;6acf
	jr z,murcielago_a_los_lados		;6ad2
	call murcielago_mira_abajo		;6ad4   ; mirando el suelo
	ld a,(ix+002h)		;6ad7
	ld (ix+00ch),a		;6ada
	ret nz			;6add
	dec (ix+002h)		;6ade
	jr murcielago_a_los_lados		;6ae1
murcielago_a_la_izquierda:
	or a			;6ae3   ; sin carry: hacia la izquierda
	call murcielago_paso		;6ae4
	jr z,L_6AEE		;6ae7   ; con pared delante, al estado 9
	ld (ix+000h),009h		;6ae9
	ret			;6aed
L_6AEE:
	call murcielago_borde_izquierdo		;6aee   ; si se sale por la izquierda
	jr nz,L_6AF7		;6af1
	ld (ix+000h),008h		;6af3   ; al estado 8, que va al otro lado
L_6AF7:
	ld a,(ix+00ah)		;6af7   ; segun por donde iba
	and a			;6afa
	jr z,L_6B03		;6afb
	call murcielago_techo		;6afd   ; mira si ha llegado
	ret nz			;6b00
	jr L_6B07		;6b01
L_6B03:
	call murcielago_suelo		;6b03
	ret nz			;6b06
L_6B07:
	ld (ix+009h),010h		;6b07   ; y ahi se queda 0x10 cuadros
	ld a,(ix+000h)		;6b0b
	ld (ix+005h),a		;6b0e   ; apuntando por donde venia
	ld (ix+000h),009h		;6b11   ; en el estado 9
	ret			;6b15
murcielago_a_la_derecha:
	scf			;6b16   ; con carry: hacia la derecha
	call murcielago_paso		;6b17
	jr z,L_6B21		;6b1a
	ld (ix+000h),009h		;6b1c
	ret			;6b20
L_6B21:
	call murcielago_borde_derecho		;6b21   ; y si se sale por la derecha
	jr nz,L_6AF7		;6b24
	ld (ix+000h),007h		;6b26   ; al estado 7
	jr L_6AF7		;6b2a
murcielago_paso:
	ld h,(ix+004h)		;6b2c   ; la columna con su fraccion
	ld l,(ix+003h)		;6b2f
	ld d,001h		;6b32   ; 0x0130, o sea un pixel y pico por cuadro
	ld e,030h		;6b34
	jr c,L_6B3D		;6b36
	xor a			;6b38   ; a la izquierda se resta
	sbc hl,de		;6b39
	jr L_6B3E		;6b3b
L_6B3D:
	add hl,de			;6b3d   ; y a la derecha se suma
L_6B3E:
	ld (ix+004h),h		;6b3e
	ld (ix+003h),l		;6b41
	call murcielago_aletea		;6b44   ; la onda del vuelo
	ld a,(ix+009h)		;6b47   ; y se vuelve diciendo si toca parar
	and a			;6b4a
	ret			;6b4b
murcielago_parado:
	dec (ix+009h)		;6b4c   ; la cuenta
	ld a,(ix+009h)		;6b4f
	and a			;6b52
	jr nz,murcielago_sigue_su_lado		;6b53
	ld (ix+000h),003h		;6b55   ; y al acabarse, rumbo nuevo
	ret			;6b59
murcielago_sigue_su_lado:
	ld a,(ix+005h)		;6b5a   ; por donde iba
	cp 007h		;6b5d
	jp z,murcielago_a_la_izquierda		;6b5f   ; a la izquierda
	jp murcielago_a_la_derecha		;6b62   ; o a la derecha
murcielago_se_marcha:
	ld (ix+009h),010h		;6b65   ; 0x10 cuadros
	inc (ix+000h)		;6b69
	ret			;6b6c
murcielago_desaparece:
	ld (ix+00eh),004h		;6b6d   ; el patron 4, que es el de irse
	dec (ix+009h)		;6b71   ; la cuenta
	ld a,(ix+009h)		;6b74
	and a			;6b77
	ret nz			;6b78
	ld (ix+000h),001h		;6b79   ; y de vuelta al estado 1
	ld (ix+00ch),0e0h		;6b7d   ; fuera de la pantalla
	jr murcielago_borra_las_cuentas		;6b81
murcielago_saliendo:
	push ix		;6b83
	pop hl			;6b85
	inc hl			;6b86
	inc hl			;6b87
	inc (hl)			;6b88   ; un pixel hacia abajo
	ld (ix+009h),000h		;6b89
	ld (ix+00bh),000h		;6b8d
	ld a,(ix+006h)		;6b91
	cp (hl)			;6b94
	ld a,(hl)			;6b95
	ld (ix+00ch),a		;6b96   ; y ahi se pinta
	cp 0e0h		;6b99   ; hasta pasarse de la fila 0xE0
	ret c			;6b9b
	ld (ix+000h),001h		;6b9c   ; y entonces vuelve a empezar
murcielago_borra_las_cuentas:
	xor a			;6ba0
	ld (ix+008h),a		;6ba1
	ld (ix+00dh),a		;6ba4
	ret			;6ba7
murcielago_aletea:
	ld hl,06bc5h		;6ba8   ; los cuarenta y ocho pasos de la onda
	ld a,(ix+00bh)		;6bab   ; por donde va
	call suma_a_a_hl		;6bae
	ld a,(ix+002h)		;6bb1   ; su fila, mas lo que diga la onda
	add a,(hl)			;6bb4
	ld (ix+00ch),a		;6bb5
	inc (ix+00bh)		;6bb8   ; y al siguiente
	inc hl			;6bbb
	ld a,(hl)			;6bbc
	cp 0afh		;6bbd   ; con el 0xAF del final
	ret nz			;6bbf
	ld (ix+00bh),000h		;6bc0   ; vuelve al principio: la onda no se acaba nunca
	ret			;6bc4

; ----------------------------------------------------------------------
; DATOS onda_del_vuelo_del_murcielago: cuarenta y ocho valores y el 0xAF:
;   suben de 0 a +10, bajan a -10 y vuelven a 0, o sea una onda entera que
;   suma cero. 0x6BA8 la recorre con (ix+00bh) y se la suma a la fila
;   0x6bc5..0x6bfa  (53 bytes)
DATA_onda_del_vuelo_del_murcielago:
	defb 000h,002h,004h,005h,006h,007h,008h,008h,009h,009h,00ah,00ah,00ah,00ah,009h,009h	; 6bc5  ................
	defb 008h,008h,007h,006h,005h,004h,002h,000h,000h,0feh,0fch,0fbh,0fah,0f9h,0f8h,0f8h	; 6bd5  ................
	defb 0f7h,0f7h,0f6h,0f6h,0f6h,0f6h,0f7h,0f7h,0f8h,0f8h,0f9h,0fah,0fbh,0fch,0feh,000h	; 6be5  ................
	defb 0afh,016h,0f0h,018h,006h	; 6bf5

; ======================================================================
; CODIGO 0x6bfa..0x6c3b  (65 bytes)
; ======================================================================


murcielago_mira_arriba:
	ld d,0f4h		;6bfa   ; doce pixeles por encima
	jr L_6C00		;6bfc
murcielago_mira_abajo:
	ld d,008h		;6bfe   ; ocho por debajo
L_6C00:
	ld a,(ix+002h)		;6c00
	add a,d			;6c03
	ld l,a			;6c04
	ld h,(ix+004h)		;6c05
	jr murcielago_mira_la_casilla		;6c08
murcielago_borde_izquierdo:
	ld a,(ix+004h)		;6c0a   ; por la izquierda del todo
	cp 00ah		;6c0d
	jr nc,murcielago_mira_a_un_lado		;6c0f
	xor a			;6c11
	ret			;6c12
murcielago_mira_a_un_lado:
	ld b,000h		;6c13
	jr murcielago_casilla_de_al_lado		;6c15
murcielago_borde_derecho:
	ld a,(ix+004h)		;6c17   ; y por la derecha
	cp 0f6h		;6c1a
	jr c,L_6C20		;6c1c
	xor a			;6c1e
	ret			;6c1f
L_6C20:
	ld b,010h		;6c20
murcielago_casilla_de_al_lado:
	ld a,(ix+002h)		;6c22   ; tres pixeles arriba
	add a,0fdh		;6c25
	ld l,a			;6c27
	ld a,(ix+004h)		;6c28   ; y ocho a la izquierda, o a la derecha si b lo dice
	add a,0f8h		;6c2b
	add a,b			;6c2d
	ld h,a			;6c2e
murcielago_mira_la_casilla:
	call casilla_de_la_sala_de_ahora		;6c2f   ; a direccion dentro de la sala
	ld a,(hl)			;6c32
	ld b,003h		;6c33   ; las mismas tres parejas de topes que frenan al jugador
	ld hl,06c3bh		;6c35
	jp casilla_que_frena_bucle		;6c38

; ----------------------------------------------------------------------
; DATOS tres_topes_6c3b: 0x6C35 los manda al bucle de 0x66CF
;   0x6c3b..0x6c41  (6 bytes)
DATA_tres_topes_6c3b:
	defb 040h,053h,0bch,0c4h,0deh,0e6h	; 6c3b

; ======================================================================
; CODIGO 0x6c41..0x6c95  (84 bytes)
; ======================================================================


murcielago_suelo:
	ld b,0eeh		;6c41   ; dieciocho pixeles por debajo
	jr murcielago_mira_solido		;6c43
murcielago_techo:
	ld b,00ah		;6c45   ; diez por encima
murcielago_mira_solido:
	ld a,(ix+002h)		;6c47
	add a,b			;6c4a
	ld l,a			;6c4b
	ld h,(ix+004h)		;6c4c
	call casilla_de_la_sala_de_ahora		;6c4f
	ld a,(hl)			;6c52
	cp 0bdh		;6c53   ; la casilla 0xBD
	ret z			;6c55
	cp 0dfh		;6c56   ; o la 0xDF
	ret			;6c58
monta_el_sprite_del_murcielago:
	ld hl,0e0ech		;6c59   ; su hueco en el bufer
	ld a,(ix+00ch)		;6c5c   ; la fila que la onda deja
	sub 006h		;6c5f   ; seis pixeles mas arriba
	ld (hl),a			;6c61
	inc hl			;6c62
	ld a,(ix+004h)		;6c63   ; la columna
	sub 008h		;6c66   ; ocho a la izquierda
	ld (hl),a			;6c68
	inc hl			;6c69
	ld a,(ix+00eh)		;6c6a   ; el patron, que ya trae puesto
	ld (hl),a			;6c6d
	inc hl			;6c6e
	ld (hl),005h		;6c6f   ; y el color 5
	ret			;6c71
sube_la_primera_barra:
	ld hl,0e064h		;6c72   ; la barra
	ld a,(hl)			;6c75
	add a,b			;6c76
	ld (hl),a			;6c77
	cp 050h		;6c78   ; sin pasarse de 0x50
	jr c,$+74		;6c7a
	ld (hl),050h		;6c7c
	jr $+70		;6c7e
baja_la_primera_barra:
	ld a,b			;6c80   ; lo que quita cada cosa
	dec a			;6c81
	ld hl,06c95h		;6c82
	call suma_a_a_hl		;6c85
	ld b,(hl)			;6c88
	ld hl,0e064h		;6c89   ; de la barra
	ld a,(hl)			;6c8c
	sub b			;6c8d
	ld (hl),a			;6c8e
	jr nc,$+53		;6c8f   ; sin bajar de cero
	ld (hl),000h		;6c91
	jr $+49		;6c93

; ----------------------------------------------------------------------
; DATOS lo_que_da_y_quita_cada_cosa: doce bytes en dos mitades: los seis de
;   0x6C95 se restan de la primera barra y los seis de 0x6C9C se suman a la
;   segunda
;   0x6c95..0x6ca1  (12 bytes)
DATA_lo_que_da_y_quita_cada_cosa:
	defb 014h,008h,008h,00eh,00ch,00ah	; 6c95
	defb 00ch,000h,00ah,004h,008h,00ah	; 6c9b

; ======================================================================
; CODIGO 0x6ca1..0x6d40  (159 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS DOS BARRAS DEL MARCADOR
; ----------------------------------------------------------------------
sube_la_segunda_barra:
	ld a,b			;6ca1   ; con cero no se toca
	and a			;6ca2
	ret z			;6ca3
	ld hl,06c9ch		;6ca4   ; la tabla de subidas
	call suma_a_a_hl		;6ca7
	ld b,(hl)			;6caa
suma_a_la_segunda_barra:
	ld hl,0e065h		;6cab   ; la segunda barra
	ld a,(hl)			;6cae
	add a,b			;6caf
	ld (hl),a			;6cb0
	cp 050h		;6cb1   ; al pasarse de 0x50
	jr c,pinta_las_dos_barras		;6cb3
	ld (hl),000h		;6cb5   ; vuelve a cero
	ld hl,0e064h		;6cb7   ; y se le pasan doce a la primera
	ld a,(hl)			;6cba
	add a,00ch		;6cbb
	cp 050h		;6cbd   ; sin pasarse de 0x50
	jr c,L_6CC3		;6cbf
	ld a,050h		;6cc1
L_6CC3:
	ld (hl),a			;6cc3
pinta_las_dos_barras:
	ld hl,0e107h		;6cc4   ; el aviso de que queda poco
	ld a,(0e064h)		;6cc7   ; la primera barra
	cp 014h		;6cca   ; por debajo de 0x14
	push af			;6ccc
	jr nc,barras_sin_aviso		;6ccd
	ld a,(hl)			;6ccf   ; si no estaba avisado ya
	and a			;6cd0
	jr nz,barras_sin_aviso		;6cd1
	ld (hl),001h		;6cd3
	ld a,00dh		;6cd5   ; suena la pieza 0x0D
	call pide_pieza_si_toca		;6cd7
barras_sin_aviso:
	pop af			;6cda
	jr c,barras_a_la_pantalla		;6cdb
	xor a			;6cdd   ; y por encima, se olvida el aviso
	ld (hl),a			;6cde
barras_a_la_pantalla:
	ld hl,0380eh		;6cdf   ; la fila de arriba
	ld de,06d50h		;6ce2   ; el guion del hueco de la barra
	push de			;6ce5
	call L_46A3		;6ce6
	ld hl,0382eh		;6ce9   ; y la de abajo, con el mismo
	pop de			;6cec
	call L_46A3		;6ced
	ld hl,0380fh		;6cf0   ; la primera barra empieza en 0x380F
	ld de,06d40h		;6cf3
	ld a,09ch		;6cf6   ; con la casilla 0x9C
	ld (0e068h),a		;6cf8
	ld a,(0e064h)		;6cfb
	call pinta_una_barra		;6cfe
	ld de,06d48h		;6d01   ; y la segunda en 0x382F
	ld hl,0382fh		;6d04
	ld a,0a5h		;6d07   ; con la 0xA5
	ld (0e068h),a		;6d09
	ld a,(0e065h)		;6d0c
pinta_una_barra:
	and 0f8h		;6d0f   ; entre ocho: cuantas casillas llenas
	rra			;6d11
	rra			;6d12
	rra			;6d13
	push af			;6d14
	and a			;6d15   ; con cero, ninguna
	jr z,barra_la_casilla_a_medias		;6d16
	ld b,000h		;6d18
	ld c,a			;6d1a
	ld a,(0e068h)		;6d1b
	call 00056h		;6d1e   ; BIOS FILVRM - Fills VRAM with value | se rellenan de un golpe
barra_la_casilla_a_medias:
	pop af			;6d21
	and a			;6d22   ; y si esta llena del todo, se acabo
	cp 00ah		;6d23
	ret z			;6d25
	call suma_a_a_hl		;6d26   ; detras de las llenas
	ld a,(0e068h)		;6d29   ; cual de las dos barras es
	cp 09ch		;6d2c
	ld a,(0e064h)		;6d2e
	jr z,L_6D36		;6d31
	ld a,(0e065h)		;6d33
L_6D36:
	and 007h		;6d36   ; los tres bits de abajo eligen entre las ocho casillas a medias
	call suma_a_a_de		;6d38
	ld a,(de)			;6d3b
	call 0004dh		;6d3c   ; BIOS WRTVRM - Writes data in VRAM | y esa es la punta de la barra
	ret			;6d3f

; ----------------------------------------------------------------------
; DATOS tres_guiones_del_marcador: 0x6D40, 0x6D48 y 0x6D50; los tres pasan por
;   L_46A3 sobre 0x380F, 0x380E y 0x382E
;   0x6d40..0x6d57  (23 bytes)
DATA_tres_guiones_del_marcador:
	defb 09dh,095h,096h,097h,098h,099h,09ah,09bh	; 6d40  ........
	defb 09dh,09eh,09fh,0a0h,0a1h,0a2h,0a3h,0a4h	; 6d48  ........
	defb 081h,0d8h,00ah,09dh,081h,0fah,000h	; 6d50

; ======================================================================
; CODIGO 0x6d57..0x6d82  (43 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LOS DOS OBJETOS ESCONDIDOS DEL NIVEL
; ----------------------------------------------------------------------
mueve_los_objetos:
	ld ix,0e2edh		;6d57   ; el tipo 6 de la lista del nivel
	ld c,000h		;6d5b   ; el primero
	call mueve_un_objeto		;6d5d
	ld ix,0e2f3h		;6d60   ; y el segundo, seis bytes mas alla
	ld c,001h		;6d64
	jp mueve_un_objeto		;6d66
mueve_un_objeto:
	ld a,(ix+000h)		;6d69   ; si no lo hay, nada
	and a			;6d6c
	ret z			;6d6d
	ld hl,0e16fh		;6d6e   ; las dos marcas del nivel
	call mira_la_marca		;6d71   ; y si ya esta cogido
	jr z,objeto_estado		;6d74
	ld (ix+000h),000h		;6d76   ; se apaga para siempre
	ret			;6d7a
objeto_estado:
	ld a,(ix+000h)		;6d7b   ; tres estados: escondido, a la vista y recogido
	dec a			;6d7e
	call reparte_por_tabla		;6d7f

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_6d82: 3 entradas; detras sigue la primera, 0x6D88
;   0x6d82..0x6d88  (6 bytes)
DATA_tabla_de_subescenas_6d82:
	defw 06d88h,06e04h,06e60h	; 6d82  -> objeto_escondido objeto_a_la_vista coge_el_objeto

; ======================================================================
; CODIGO 0x6d88..0x6dbd  (53 bytes)
; ======================================================================


objeto_escondido:
	ld hl,0e168h		;6d88   ; la otra tabla de marcas
	call mira_la_marca		;6d8b
	jr z,objeto_mira_su_condicion		;6d8e
	ld hl,0e16fh		;6d90   ; y la del nivel
	call mira_la_marca		;6d93
	jr nz,objeto_mira_su_condicion		;6d96
	ld (ix+000h),002h		;6d98   ; con las dos puestas, sale a la vista
	ret			;6d9c
objeto_mira_su_condicion:
	push bc			;6d9d
	ld c,012h		;6d9e   ; el objeto 0x12
	call se_lleva_el_objeto		;6da0
	jr z,objeto_reparte_por_clase		;6da3
	ld a,(0e162h)		;6da5   ; y el contador de 0xE162
	dec a			;6da8
	jr nz,objeto_reparte_por_clase		;6da9
	ld (ix+000h),002h		;6dab   ; tambien lo sacan
	pop bc			;6daf
	ret			;6db0
objeto_reparte_por_clase:
	pop bc			;6db1
	ld a,(ix+004h)		;6db2   ; cual de los veintisiete es
	ld hl,06df3h		;6db5   ; la vuelta la empuja a mano, que es lo que cierra la tabla
	push bc			;6db8
	push hl			;6db9
	call reparte_por_tabla		;6dba

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_6dbd: 27 entradas, la mas larga del cartucho; el
;   `ld hl,06df3h / push hl` de 0x6DB5 la cierra
;   0x6dbd..0x6df3  (54 bytes)
DATA_tabla_de_subescenas_6dbd:
	defw 06f86h,06f9fh,06fc4h,06fdfh,07004h,07096h,07041h,07061h	; 6dbd
	defw 07069h,07098h,070a6h,070beh,070f3h,07100h,07116h,0711fh	; 6dcd
	defw 07096h,07138h,0714dh,07188h,071aah,071deh,071fdh,07216h	; 6ddd
	defw 07235h,07096h,07096h	; 6ded  -> condicion_24_saltando_sobre_la_casilla condicion_no condicion_no

; ======================================================================
; CODIGO 0x6df3..0x6e2c  (57 bytes)
; ======================================================================


objeto_condicion_cumplida:
	pop bc			;6df3
	ret z			;6df4   ; si no se cumple, sigue escondido
objeto_sale_a_la_vista:
	ld hl,0e168h		;6df5   ; se marca
	call pon_la_marca		;6df8
	ld (ix+000h),002h		;6dfb   ; estado 2
	ld a,089h		;6dff   ; y suena la pieza 0x89
	jp pide_pieza		;6e01
objeto_a_la_vista:
	ld a,(0e062h)		;6e04   ; si esta en otra sala, no se pinta
	cp (ix+001h)		;6e07
	ret nz			;6e0a
	ld a,(0e003h)		;6e0b   ; el bit 4 del contador
	and 010h		;6e0e
	ld c,000h		;6e10   ; lo borra
	jr nz,L_6E16		;6e12
	ld c,091h		;6e14   ; y lo pinta: la casilla 0x91, la misma para los veintisiete
L_6E16:
	call pinta_el_objeto		;6e16
	call el_jugador_lo_pisa		;6e19   ; mira si el jugador lo pisa
	ret z			;6e1c
	ld (ix+000h),003h		;6e1d   ; y entonces se lo lleva
	ld a,(ix+004h)		;6e21   ; los que ademas hacen algo
	cp 016h		;6e24   ; son del 0x16 en adelante
	ret c			;6e26
	sub 016h		;6e27
	call reparte_por_tabla		;6e29

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_6e2c: 5 entradas; detras sigue la primera, 0x6E36
;   0x6e2c..0x6e36  (10 bytes)
DATA_tabla_de_subescenas_6e2c:
	defw 06e36h,06e3ch,06e41h,06e46h,06e46h	; 6e2c

; ======================================================================
; CODIGO 0x6e36..0x6f68  (306 bytes)
; ======================================================================


objeto_abre_la_escena:
	ld a,0ffh		;6e36   ; (0xE1B1) a 0xFF: para el juego y arranca lo suyo
	ld (0e1b1h),a		;6e38
	ret			;6e3b
objeto_da_energia:
	ld b,010h		;6e3c   ; 0x10 a la primera barra
	jp sube_la_primera_barra		;6e3e
objeto_da_de_la_otra:
	ld b,028h		;6e41   ; 0x28 a la segunda
	jp suma_a_la_segunda_barra		;6e43
objeto_da_puntos:
	ld c,001h		;6e46   ; puntos
	ld de,00000h		;6e48
	call suma_puntos		;6e4b
	ld b,010h		;6e4e   ; y 0x10 de barra
	jp sube_la_primera_barra		;6e50
pinta_el_objeto:
	ld h,(ix+003h)		;6e53   ; la columna
	ld l,(ix+002h)		;6e56   ; y la fila
	call casilla_de_la_pantalla		;6e59
	ld a,c			;6e5c
	jp 0004dh		;6e5d   ; BIOS WRTVRM - Writes data in VRAM

; ----------------------------------------------------------------------
; COGER UN OBJETO
; ----------------------------------------------------------------------
coge_el_objeto:
	ld a,089h		;6e60   ; la pieza 0x89
	call pide_pieza		;6e62
	exx			;6e65
	ld c,000h		;6e66   ; se borra del suelo
	call pinta_el_objeto		;6e68
	exx			;6e6b
	ld hl,0e16fh		;6e6c   ; se marca el nivel
	call pon_la_marca		;6e6f
	call mete_en_el_inventario		;6e72   ; entra en el inventario
	call pinta_el_inventario		;6e75   ; que se repinta
	ld (ix+000h),000h		;6e78   ; y la ficha se apaga
	ret			;6e7c

; ----------------------------------------------------------------------
; LA FILA DE ABAJO: EL INVENTARIO
; ----------------------------------------------------------------------
pinta_el_inventario:
	ld hl,03ac0h		;6e7d   ; la fila 22
	ld bc,00019h		;6e80   ; veinticinco casillas
	ld a,093h		;6e83   ; de la 0x93, que es el fondo de la fila
	call 00056h		;6e85   ; BIOS FILVRM - Fills VRAM with value
	ld hl,03ae0h		;6e88   ; y la 23, a cero
	ld bc,00019h		;6e8b
	xor a			;6e8e
	call 00056h		;6e8f   ; BIOS FILVRM - Fills VRAM with value
	ld b,017h		;6e92   ; los veintitres objetos
	ld hl,0e180h		;6e94
inventario_bucle:
	ld a,(hl)			;6e97   ; el sitio que ocupa este
	dec a			;6e98
	cp 00ch		;6e99   ; y solo caben doce
	jr nc,inventario_siguiente		;6e9b
	ld c,a			;6e9d
	ld a,b			;6e9e   ; cual es
	neg		;6e9f
	add a,017h		;6ea1
	push hl			;6ea3
	push bc			;6ea4
	call pinta_un_icono		;6ea5
	pop bc			;6ea8
	pop hl			;6ea9
inventario_siguiente:
	inc hl			;6eaa
	djnz inventario_bucle		;6eab
	ret			;6ead
pinta_un_icono:
	ld hl,06f68h		;6eae   ; la casilla de cada objeto
	call suma_a_a_hl		;6eb1
	ld de,0e10bh		;6eb4   ; los cuatro trozos van seguidos
	ld a,(hl)			;6eb7
	ld b,004h		;6eb8
icono_cuatro_casillas:
	ld (de),a			;6eba   ; la casilla y las tres de detras
	inc a			;6ebb
	inc de			;6ebc
	djnz icono_cuatro_casillas		;6ebd
	ld l,016h		;6ebf   ; la fila 22
	ld a,c			;6ec1   ; y la columna, dos por objeto
	add a,a			;6ec2
	inc a			;6ec3
	ld h,a			;6ec4
	ld de,0e10bh		;6ec5
	ld bc,00202h		;6ec8   ; dos por dos
	jp L_83F3		;6ecb

; ----------------------------------------------------------------------
; LAS DOS MARCAS DE CADA NIVEL
; ----------------------------------------------------------------------
pon_la_marca:
	call marca_del_nivel_de_ahora		;6ece   ; se pone
	or (hl)			;6ed1
	ld (hl),a			;6ed2
	ret			;6ed3
mira_la_marca:
	call marca_del_nivel_de_ahora		;6ed4   ; se mira
	and (hl)			;6ed7
	ret			;6ed8
marca_de_ese_nivel:
	ld c,000h		;6ed9   ; la marca 0 del nivel que se pida
	jr saca_la_marca		;6edb
marca_del_nivel_de_ahora:
	ld a,(0e061h)		;6edd   ; el nivel en el que se esta
	dec a			;6ee0
saca_la_marca:
	ld b,a			;6ee1
	and 0fch		;6ee2   ; cuatro niveles por byte
	rra			;6ee4
	rra			;6ee5
	call suma_a_a_hl		;6ee6
	ld a,b			;6ee9
	and 003h		;6eea   ; los dos bits que le tocan
	add a,a			;6eec   ; dos marcas por nivel
	add a,c			;6eed
	ld b,a			;6eee
	inc b			;6eef
	xor a			;6ef0   ; y la mascara se fabrica rotando
	scf			;6ef1
L_6EF2:
	rla			;6ef2
	djnz L_6EF2		;6ef3
	ret			;6ef5
el_jugador_lo_pisa:
	ld a,(ix+002h)		;6ef6   ; la columna del objeto
	ld b,(ix+003h)		;6ef9   ; y su fila
	jp caja_de_ocho_por_ocho		;6efc

; ----------------------------------------------------------------------
; METER Y SACAR DEL INVENTARIO
; ----------------------------------------------------------------------
mete_en_el_inventario:
	ld c,(ix+004h)		;6eff   ; que objeto es
	call bit_del_objeto		;6f02   ; se enciende su bit
	or (hl)			;6f05
	ld (hl),a			;6f06
	ld a,c			;6f07   ; y si es de los veintitres que se ensenan
	cp 017h		;6f08
	ret nc			;6f0a
	ld hl,0e180h		;6f0b   ; los sitios
	ld b,017h		;6f0e
empuja_los_iconos:
	ld a,(hl)			;6f10   ; cada uno que ya hubiera
	and a			;6f11
	jr z,L_6F15		;6f12
	inc (hl)			;6f14   ; se corre un sitio
L_6F15:
	inc hl			;6f15
	djnz empuja_los_iconos		;6f16
	call sitio_del_objeto		;6f18   ; y el nuevo
	ld (hl),001h		;6f1b   ; se pone el primero
	ret			;6f1d
sitio_del_objeto:
	ld hl,0e180h		;6f1e
	ld a,c			;6f21
	jp suma_a_a_hl		;6f22
saca_del_inventario:
	call bit_del_objeto		;6f25   ; se apaga su bit
	cpl			;6f28
	and (hl)			;6f29
	ld (hl),a			;6f2a
	call sitio_del_objeto		;6f2b   ; el sitio que ocupaba
	ld a,(hl)			;6f2e
	ld (hl),000h		;6f2f   ; y se olvida
	and a			;6f31
	jr z,repinta_el_inventario		;6f32   ; si no estaba, no hay nada que cerrar
	ld hl,0e180h		;6f34
	ld b,017h		;6f37
cierra_el_hueco:
	cp (hl)			;6f39   ; los que estaban detras
	jr nc,cierra_el_hueco_sigue		;6f3a
	dec (hl)			;6f3c   ; se corren uno hacia delante
cierra_el_hueco_sigue:
	inc hl			;6f3d
	djnz cierra_el_hueco		;6f3e
repinta_el_inventario:
	jp pinta_el_inventario		;6f40
se_lleva_el_objeto:
	call bit_del_objeto		;6f43   ; el bit del objeto
	and (hl)			;6f46
	ret			;6f47
bit_del_objeto:
	ld a,(0e002h)		;6f48   ; sin partida en marcha
	bit 6,a		;6f4b
	jr nz,bit_del_objeto_sigue		;6f4d
	pop de			;6f4f   ; se vuelve al llamante del llamante: asi el inventario no se toca en el titulo
	ret			;6f50
bit_del_objeto_sigue:
	ld a,c			;6f51   ; ocho objetos por byte
	rra			;6f52
	rra			;6f53
	rra			;6f54
	and 01fh		;6f55
	ld hl,0e176h		;6f57   ; los tres bytes de marcas
	call suma_a_a_hl		;6f5a
	ld a,c			;6f5d   ; y el bit dentro del byte
	and 007h		;6f5e
	ld b,a			;6f60
	ld a,001h		;6f61
	ret z			;6f63
bit_del_objeto_rota:
	rla			;6f64
	djnz bit_del_objeto_rota		;6f65
	ret			;6f67

; ----------------------------------------------------------------------
; DATOS casillas_de_cada_objeto: veintitres casillas, una por objeto del
;   inventario: 0x6EAE coge esa y las tres de detras, que son el icono de 2x2
;   que se pinta en la fila de abajo
;   0x6f68..0x6f7f  (23 bytes)
DATA_casillas_de_cada_objeto:
	defb 0a5h,024h,028h,02ch,030h,034h,038h,03ch,095h,099h,09dh,0a1h,018h,01ch,020h,004h,008h,0a9h,0b1h,00ch,010h,014h,0adh	; 6f68  .$(,048<...... ........

; ======================================================================
; CODIGO 0x6f7f..0x7323  (932 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS VEINTISIETE CONDICIONES DE LOS OBJETOS
; ----------------------------------------------------------------------
esta_en_su_sala:
	ld a,(0e062h)		;6f7f   ; la sala de ahora
	cp (ix+001h)		;6f82   ; contra la del objeto
	ret			;6f85
condicion_00_jaulas:
	call esta_en_su_sala		;6f86   ; en su sala
	jp nz,L_7213		;6f89
	ld a,(0e121h)		;6f8c   ; y sin nada en marcha
	and a			;6f8f
	jp nz,L_7213		;6f90
	push ix		;6f93
	ld ix,0e2f9h		;6f95   ; se mira lo de las jaulas
	call toca_la_jaula		;6f99
	pop ix		;6f9c
	ret			;6f9e
condicion_01_dos_golpes_al_2:
	call esta_en_su_sala		;6f9f
	jp nz,condicion_no		;6fa2
	ld hl,0e128h		;6fa5   ; hasta que no haya golpe, nada
	ld a,(hl)			;6fa8
	and a			;6fa9
	ret z			;6faa
	ld a,(0e126h)		;6fab   ; y tiene que ser al 2
	cp 002h		;6fae
	jp nz,condicion_no		;6fb0
	xor a			;6fb3   ; el golpe se consume
	ld (hl),a			;6fb4
	ld a,(ix+005h)		;6fb5   ; una vez mas
	inc a			;6fb8
	ld (ix+005h),a		;6fb9
	cp 002h		;6fbc   ; y a las dos, sale
	jp c,condicion_no		;6fbe
	jp condicion_si		;6fc1
condicion_02_sitio_y_quieto:
	call esta_en_su_sala		;6fc4   ; en su sala
	jp nz,condicion_no		;6fc7
	call en_el_sitio_del_chorro		;6fca   ; en el sitio que marca el chorro de agua
	ret z			;6fcd
	ld a,(0e110h)		;6fce   ; con el jugador andando
	dec a			;6fd1
	jp nz,condicion_no		;6fd2
	ld a,(0e116h)		;6fd5   ; y sin nada encima
	and a			;6fd8
	jp nz,condicion_no		;6fd9
	jp condicion_si		;6fdc
condicion_03_tres_golpes_al_4:
	call esta_en_su_sala		;6fdf
	jp nz,condicion_no		;6fe2
	ld hl,0e128h		;6fe5
	ld a,(hl)			;6fe8
	and a			;6fe9
	ret z			;6fea
	ld a,(0e126h)		;6feb   ; al 4
	cp 004h		;6fee
	jp nz,condicion_no		;6ff0
	xor a			;6ff3
	ld (hl),a			;6ff4
	ld a,(ix+005h)		;6ff5
	inc a			;6ff8
	ld (ix+005h),a		;6ff9
	cp 003h		;6ffc   ; y tres veces
	jp c,condicion_no		;6ffe
	jp condicion_si		;7001
condicion_04_dos_al_1_seguidos:
	call esta_en_su_sala		;7004
	jr nz,condicion_cuenta_a_cero		;7007
	ld de,0e128h		;7009
	ld a,(de)			;700c
	and a			;700d
	ret z			;700e
	ld hl,0e126h		;700f
	ld a,(hl)			;7012
	and 00fh		;7013   ; el nibble bajo del golpe
	dec a			;7015   ; tiene que ser 1
	jp nz,condicion_no		;7016
	xor a			;7019
	ld (de),a			;701a
	ld a,(ix+005h)		;701b   ; si ya llevaba uno
	and a			;701e
	jr z,condicion_04_cuenta		;701f
	ld a,(hl)			;7021   ; el de antes tiene que ser el MISMO sitio
	inc hl			;7022
	cp (hl)			;7023
	jr z,condicion_04_cuenta		;7024
	ld a,(hl)			;7026   ; y si fue otro, la cuenta vuelve a uno
	and a			;7027
	jr nz,condicion_cuenta_a_uno		;7028
condicion_04_cuenta:
	ld a,(ix+005h)		;702a
	inc a			;702d
	ld (ix+005h),a		;702e
	cp 002h		;7031   ; dos veces
	jr c,condicion_no		;7033
	jr condicion_si		;7035
condicion_cuenta_a_cero:
	xor a			;7037
	jr L_703C		;7038
condicion_cuenta_a_uno:
	ld a,001h		;703a
L_703C:
	ld (ix+005h),a		;703c
	jr condicion_no		;703f
condicion_06_patadas_a_los_dos_lados:
	ld a,(ix+005h)		;7041   ; 0x50 intentos
	cp 050h		;7044
	jr nc,condicion_no		;7046
	ld a,(0e11ch)		;7048   ; la postura 0x0C, que es la patada
	cp 00ch		;704b
	jr nz,condicion_06_cuenta		;704d
	ld a,(0e11bh)		;704f   ; hacia que lado mira
	ld hl,0e129h		;7052   ; y los dos lados se juntan en (0xE129)
	inc a			;7055
	or (hl)			;7056
	ld (hl),a			;7057
	cp 003h		;7058   ; con los dos bits, sale: hay que dar una patada a cada lado
	jr z,condicion_si		;705a
condicion_06_cuenta:
	inc (ix+005h)		;705c
	jr condicion_no		;705f
condicion_07:
	call esta_en_su_sala		;7061
	jr nz,condicion_no		;7064
	jp caja_de_la_bola		;7066   ; lo que diga 0x80BE
condicion_08:
	call esta_en_su_sala		;7069
	jr nz,condicion_no		;706c
	ld a,(0e121h)		;706e   ; hasta que (0xE121) no se ponga, nada
	and a			;7071
	ret z			;7072
en_el_sitio_del_chorro:
	ld de,0e347h		;7073   ; la columna del primer chorro de agua de la sala
	ld hl,0e115h		;7076
	ld a,(de)			;7079
	add a,a			;707a   ; de casillas a pixeles
	add a,a			;707b
	add a,a			;707c
	add a,00ah		;707d   ; mas diez
	cp (hl)			;707f   ; el jugador tiene que estar pasado de ahi
	jr nc,condicion_no		;7080
	add a,004h		;7082   ; y de cuatro pixeles mas alla, no
	cp (hl)			;7084
	jr c,condicion_no		;7085
	dec de			;7087   ; y su fila
	dec hl			;7088
	dec hl			;7089
	ld a,(de)			;708a
	add a,a			;708b
	add a,a			;708c
	add a,a			;708d
	add a,010h		;708e   ; dieciseis pixeles por debajo del chorro
	cp (hl)			;7090
	jr nc,condicion_no		;7091
condicion_si:
	or 001h		;7093
	ret			;7095
condicion_no:
	xor a			;7096
	ret			;7097
condicion_09:
	call esta_en_su_sala		;7098
	jr nz,condicion_no		;709b
	ld a,(0e121h)		;709d   ; con algo en marcha, no
	and a			;70a0
	jr nz,condicion_no		;70a1
	jp caja_del_murcielago		;70a3   ; y si no, lo de 0x83A8
condicion_10:
	call esta_en_su_sala		;70a6
	jp nz,condicion_no		;70a9
	call caja_del_lanzador		;70ac   ; lo del tipo 4 de la sala
	ret z			;70af
	ld a,(0e110h)		;70b0   ; con el jugador andando
	dec a			;70b3
	jr nz,condicion_no		;70b4
	ld a,(0e116h)		;70b6   ; y sin nada encima
	and a			;70b9
	jr nz,condicion_no		;70ba
	jr condicion_si		;70bc
condicion_11_dos_veces:
	call esta_en_su_sala		;70be
	jr nz,condicion_11_se_olvida		;70c1
	ld a,(0e110h)		;70c3   ; con el jugador dando una patada
	cp 004h		;70c6
	jr c,condicion_11_se_olvida		;70c8
	ld a,(0e14ch)		;70ca   ; y si no lo ha hecho ya
	and a			;70cd
	jr nz,condicion_no		;70ce
	call caja_de_la_columna		;70d0   ; mira si acierta
	jr z,condicion_11_se_olvida		;70d3
	ld a,003h		;70d5   ; suena la pieza 3
	call pide_pieza		;70d7
	ld a,001h		;70da   ; se apunta para que no valga dos veces seguidas
	ld (0e14ch),a		;70dc
	ld hl,0e14dh		;70df   ; y se cuenta
	inc (hl)			;70e2
	ld a,(hl)			;70e3
	cp 002h		;70e4   ; a la segunda, sale
	jr c,condicion_no		;70e6
	xor a			;70e8
	ld (hl),a			;70e9
	jp condicion_si		;70ea
condicion_11_se_olvida:
	xor a			;70ed
	ld (0e14ch),a		;70ee   ; en cuanto deja de dar patadas, se puede volver a contar
	jr condicion_no		;70f1
condicion_12:
	call esta_en_su_sala		;70f3
	jr nz,condicion_no		;70f6
	ld a,(0e121h)		;70f8   ; hasta que (0xE121) no se ponga, nada
	and a			;70fb
	ret z			;70fc
	jp caja_del_murcielago		;70fd
condicion_13:
	call esta_en_su_sala		;7100
	jr nz,condicion_no		;7103
	ld a,(0e121h)		;7105
	and a			;7108
	ret z			;7109
	push ix		;710a   ; y entonces se mira la ficha del tipo 3
	ld ix,0e2bdh		;710c
	call toca_la_puerta		;7110
	pop ix		;7113
	ret			;7115
condicion_14:
	call esta_en_su_sala		;7116
	jp nz,condicion_no		;7119
	jp caja_del_murcielago		;711c
condicion_15_un_golpe_al_5:
	call esta_en_su_sala		;711f   ; en su sala
	jp nz,condicion_no		;7122
	ld hl,0e128h		;7125   ; hasta que no haya golpe, nada
	ld a,(hl)			;7128
	and a			;7129
	ret z			;712a
	ld a,(0e126h)		;712b
	cp 005h		;712e   ; al 5, y con uno basta
	jp nz,condicion_no		;7130
	xor a			;7133   ; el golpe se consume
	ld (hl),a			;7134
	jp condicion_si		;7135
condicion_17_patada_con_el_bit_0:
	call esta_en_su_sala		;7138
	jr nz,condicion_no_salta		;713b
	ld a,(0e11ah)		;713d   ; el bit 0 de (0xE11A)
	and 001h		;7140
	ret z			;7142
condicion_pide_patada:
	ld a,(0e110h)		;7143   ; y el estado 4: la patada de pie
	cp 004h		;7146
	jr nz,condicion_no_salta		;7148
	jp condicion_si		;714a
condicion_18_patada_a_la_bola:
	call esta_en_su_sala		;714d
	jr nz,condicion_no_salta		;7150
	ld iy,0e327h		;7152   ; la bola de piedra de la sala
	ld a,(iy+001h)		;7156   ; su fila, mas cuatro casillas
	add a,004h		;7159
	add a,a			;715b
	add a,a			;715c
	add a,a			;715d
	ld d,a			;715e
	ld a,(iy+002h)		;715f   ; y su columna
	add a,a			;7162
	add a,a			;7163
	add a,a			;7164
	add a,006h		;7165
	ld e,a			;7167
	ld a,(iy+005h)		;7168   ; lo que lleve descolgado
	and a			;716b
	jr nz,L_7171		;716c
	ld a,(iy+004h)		;716e
L_7171:
	add a,001h		;7171
	add a,(iy+006h)		;7173
	add a,004h		;7176
	add a,a			;7178
	add a,a			;7179
	add a,a			;717a
	sub d			;717b
	ld h,a			;717c
	ld l,004h		;717d
	call toca_al_jugador		;717f   ; si el jugador la toca
	ret z			;7182
	jr condicion_pide_patada		;7183   ; y le esta dando una patada
condicion_no_salta:
	jp condicion_no		;7185
condicion_19_dos_golpes_al_9:
	call esta_en_su_sala		;7188
	jr nz,condicion_no_salta		;718b
	ld hl,0e128h		;718d
	ld a,(hl)			;7190
	and a			;7191
	ret z			;7192
	ld a,(0e126h)		;7193
	cp 009h		;7196   ; al 9
	jr nz,condicion_no_salta		;7198
	xor a			;719a
	ld (hl),a			;719b
	ld a,(ix+005h)		;719c
	inc a			;719f
	ld (ix+005h),a		;71a0
	cp 002h		;71a3   ; dos veces
	jr c,condicion_no_salta		;71a5
	jp condicion_si		;71a7
condicion_20_dos_al_8_seguidos:
	call esta_en_su_sala		;71aa   ; en su sala
	jp nz,condicion_cuenta_a_cero		;71ad
	ld de,0e128h		;71b0   ; hasta que no haya golpe, nada
	ld a,(de)			;71b3
	and a			;71b4
	ret z			;71b5
	ld hl,0e126h		;71b6   ; el ultimo golpe
	ld a,(hl)			;71b9
	cp 008h		;71ba   ; al 8
	jr nz,condicion_no_salta		;71bc
	xor a			;71be   ; se consume
	ld (de),a			;71bf
	ld a,(ix+005h)		;71c0   ; si ya llevaba uno
	and a			;71c3
	jr z,condicion_20_cuenta		;71c4
	ld a,(hl)			;71c6   ; y el de antes, en el mismo sitio
	inc hl			;71c7
	cp (hl)			;71c8   ; el de antes tiene que ser el mismo sitio
	jr z,condicion_20_cuenta		;71c9
	ld a,(hl)			;71cb   ; y si fue otro, la cuenta vuelve a uno
	and a			;71cc
	jp nz,condicion_cuenta_a_uno		;71cd
condicion_20_cuenta:
	ld a,(ix+005h)		;71d0   ; la cuenta
	inc a			;71d3   ; una vez mas
	ld (ix+005h),a		;71d4
	cp 002h		;71d7
	jr c,condicion_no_salta		;71d9
	jp condicion_si		;71db
condicion_21_patada_a_la_llamarada:
	call esta_en_su_sala		;71de   ; en su sala
	jr nz,condicion_no_salta		;71e1
	push ix		;71e3
	call condicion_21_mira_la_llamarada		;71e5   ; se mira la llamarada
	pop ix		;71e8
	ret			;71ea
condicion_21_mira_la_llamarada:
	ld ix,0e363h		;71eb   ; la primera llamarada de la sala
	ld a,(ix+000h)		;71ef   ; tiene que estar en su fase 3
	cp 003h		;71f2
	jr nz,condicion_no_salta		;71f4
	call el_jugador_esta_ante_la_llamarada		;71f6   ; y tocando al jugador
	ret z			;71f9
	jp condicion_pide_patada		;71fa
condicion_22_las_dos_barras:
	call esta_en_su_sala		;71fd
	jr nz,L_7213		;7200
	ld hl,0e064h		;7202   ; la primera barra
	ld a,(hl)			;7205
	cp 028h		;7206   ; por encima de 0x28
	jr c,L_7213		;7208
	inc hl			;720a   ; y la segunda
	ld a,(hl)			;720b
	cp 028h		;720c   ; tambien
	jr c,L_7213		;720e
	jp condicion_si		;7210
L_7213:
	jp condicion_no		;7213
condicion_23_quieto_0x60_cuadros:
	ld a,(ix+005h)		;7216   ; 0x60 cuadros
	cp 060h		;7219
	jr nc,L_7213		;721b
	ld a,(0e11ch)		;721d   ; con la postura 2, que es la de estar quieto
	cp 002h		;7220
	jr z,condicion_23_cuenta		;7222
	ld (ix+005h),060h		;7224   ; y si se mueve, la cuenta se va al tope y no sale
condicion_23_cuenta:
	inc (ix+005h)		;7228
	ld a,(ix+005h)		;722b
	cp 060h		;722e
	jr nz,L_7213		;7230
	jp condicion_si		;7232
condicion_24_saltando_sobre_la_casilla:
	call esta_en_su_sala		;7235
	jp nz,condicion_no		;7238
	ld a,(0e110h)		;723b   ; el estado 1, que es el salto
	cp 001h		;723e
	jp nz,condicion_no		;7240
	ld a,(0e117h)		;7243   ; con (0xE117) entre 0x0A y 0x0D
	sub 00ah		;7246
	cp 004h		;7248
	jp nc,condicion_no		;724a
	call esta_sobre_0x78_o_0x79		;724d   ; sin estar sobre las casillas 0x78 ni 0x79
	jp nz,condicion_no		;7250
	ld a,(0e108h)		;7253   ; y con (0xE108) puesto
	and a			;7256
	jp z,condicion_no		;7257
	jp condicion_si		;725a
casilla_bajo_el_jugador:
	ld a,(0e113h)		;725d   ; su fila
	ld l,a			;7260
	ld a,(0e115h)		;7261   ; y su columna
	ld h,a			;7264
	call casilla_de_la_sala_de_ahora		;7265   ; a direccion dentro de la sala
	ld a,(hl)			;7268
	ret			;7269
esta_sobre_0x78_o_0x79:
	call casilla_bajo_el_jugador		;726a
	cp 078h		;726d
	ret z			;726f
	cp 079h		;7270
	ret			;7272
esta_sobre_0x4d_o_0x4e:
	xor a			;7273   ; (0xE108) se apaga
	ld (0e108h),a		;7274
	call casilla_bajo_el_jugador		;7277
	cp 04dh		;727a   ; y con las casillas 0x4D y 0x4E se queda apagado
	ret z			;727c
	cp 04eh		;727d
	ret z			;727f
	ld a,001h		;7280   ; y con cualquier otra, encendido
	ld (0e108h),a		;7282
	ret			;7285
saca_el_objeto_de_esa_clase:
	ld ix,0e2edh		;7286   ; los dos objetos del nivel
	ld c,000h		;728a
	call L_7295		;728c
	ld ix,0e2f3h		;728f
	ld c,001h		;7293
L_7295:
	ld a,(ix+000h)		;7295   ; si no lo hay, nada
	and a			;7298
	ret z			;7299
	ld a,b			;729a   ; y si es de la clase que se pide
	cp (ix+004h)		;729b
	ret nz			;729e
	jp objeto_sale_a_la_vista		;729f   ; sale a la vista

; ----------------------------------------------------------------------
; EL BICHO QUE PERSIGUE POR TODO EL NIVEL
; ----------------------------------------------------------------------
mueve_a_los_perseguidores:
	call mueve_a_los_cuatro		;72a2
	call mueve_los_disparos		;72a5
	ret			;72a8
mueve_a_los_cuatro:
	ld ix,0e4d0h		;72a9   ; las cuatro fichas
	ld hl,0e0ach		;72ad   ; y sus cuatro huecos del bufer de sprites
	ld b,004h		;72b0   ; cuatro
mueve_a_los_cuatro_bucle:
	ld (0e14eh),bc		;72b2   ; cual va, para que las rutinas de dentro lo sepan
	push hl			;72b6
	call mueve_a_un_perseguidor		;72b7
	ld a,(0e1b1h)		;72ba   ; con la partida parada no se mira si toca al jugador
	and a			;72bd
	jr nz,L_72C3		;72be
	call perseguidor_puede_disparar		;72c0
L_72C3:
	pop bc			;72c3
	push bc			;72c4
	call monta_el_sprite_del_perseguidor		;72c5   ; su sprite
	pop hl			;72c8
	ld a,004h		;72c9   ; cuatro bytes de bufer
	call suma_a_a_hl		;72cb
	ld bc,(0e14eh)		;72ce
	ld de,00023h		;72d2   ; y treinta y cinco de ficha
	add ix,de		;72d5
	djnz mueve_a_los_cuatro_bucle		;72d7
	ret			;72d9
mueve_a_un_perseguidor:
	ld a,(ix+010h)		;72da   ; apagado, nada
	and a			;72dd
	ret z			;72de
	push ix		;72df
	pop de			;72e1
	inc de			;72e2   ; se mira si se ha salido de la sala, con la misma rutina que el jugador
	ld h,d			;72e3
	ld l,e			;72e4
	inc hl			;72e5
	inc hl			;72e6
	call a_que_sala_paso		;72e7
	ld a,(ix+010h)		;72ea   ; en los estados 6 y del 9 en adelante
	cp 006h		;72ed
	jr z,L_72F8		;72ef
	cp 009h		;72f1
	jr nc,L_72F8		;72f3
	call perseguidor_recibe_patada		;72f5   ; no se mira el choque
L_72F8:
	xor a			;72f8   ; se empieza sin nada apuntado
	ld (ix+01eh),a		;72f9
	ld (ix+01fh),a		;72fc
	ld a,(0e1b1h)		;72ff   ; con la partida parada
	and a			;7302
	jr z,perseguidor_reparte		;7303
	ld a,(ix+010h)		;7305   ; solo siguen los estados 9, 10 y 11
	cp 009h		;7308
	ret c			;730a
	cp 00ch		;730b
	ret nc			;730d
perseguidor_reparte:
	ld a,(ix+010h)		;730e   ; el estado 6 va todos los cuadros
	cp 006h		;7311
	jr z,perseguidor_estado		;7313
	ld a,(ix+000h)		;7315   ; y los demas uno de cada dos
	and 003h		;7318
	rra			;731a
	ret c			;731b
perseguidor_estado:
	ld a,(ix+010h)		;731c   ; trece estados
	dec a			;731f
	call reparte_por_tabla		;7320

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_7323: 13 entradas; detras sigue la primera, 0x733D
;   0x7323..0x733d  (26 bytes)
DATA_tabla_de_subescenas_7323:
	defw 0733dh,073d7h,07428h,0743ch,074ech,07733h,07765h,077f7h	; 7323
	defw 07803h,0781fh,07823h,07852h,07856h	; 7333

; ======================================================================
; CODIGO 0x733d..0x750f  (466 bytes)
; ======================================================================


perseguidor_mira_las_salidas:
	ld b,(ix+001h)		;733d   ; su sala
	ld hl,05327h		;7340   ; la tabla de a donde se sale por la derecha
	call busca_en_la_tabla_de_salas		;7343
	ld d,a			;7346
	ld hl,052dbh		;7347   ; y la de la izquierda
	call busca_en_la_tabla_de_salas		;734a
	and 00fh		;734d
	ld e,a			;734f
	ld a,(ix+003h)		;7350   ; su fila
	cp 098h		;7353   ; si esta abajo del todo
	jr c,perseguidor_por_arriba		;7355
	ld a,(0e111h)		;7357   ; y el jugador esta en la sala de al lado
	cp d			;735a
	jr nz,perseguidor_por_arriba		;735b
	ld a,(0e113h)		;735d   ; y arriba
	cp 028h		;7360
	jr nc,perseguidor_por_arriba		;7362
	ld b,096h		;7364   ; se planta en la fila 0x96
	ld c,002h		;7366
	jr perseguidor_cambia_de_piso		;7368
perseguidor_por_arriba:
	ld a,(ix+003h)		;736a   ; y al reves: si esta arriba
	cp 028h		;736d
	jr nc,perseguidor_rumbo_por_defecto		;736f
	ld a,(0e111h)		;7371   ; con el jugador en la otra sala
	cp e			;7374
	jr nz,perseguidor_rumbo_por_defecto		;7375
	ld a,(0e113h)		;7377   ; y abajo
	cp 098h		;737a
	jr c,perseguidor_rumbo_por_defecto		;737c
	ld b,02ah		;737e   ; se planta en la 0x2A
	ld c,001h		;7380
perseguidor_cambia_de_piso:
	ld a,(0e115h)		;7382   ; la columna del jugador
	cp (ix+005h)		;7385   ; tiene que cuadrar con la suya
	jr nz,perseguidor_rumbo_por_defecto		;7388
	ld a,(ix+000h)		;738a   ; y el jugador estar andando
	cp 002h		;738d
	jr nz,perseguidor_rumbo_por_defecto		;738f
	ld (ix+003h),b		;7391   ; se le pone la fila nueva
	ld (ix+016h),c		;7394
	ld h,(ix+005h)		;7397   ; y se mira la casilla de destino
	ld a,b			;739a
	add a,0f0h		;739b
	ld l,a			;739d
	cp 010h		;739e
	ret c			;73a0
	ld a,(ix+001h)		;73a1
	call casilla_de_la_sala_en_pixeles		;73a4
	ld a,(hl)			;73a7
	cp 053h		;73a8   ; si es la 0x53 o la 0x54, se queda
	ret z			;73aa
	cp 054h		;73ab
	ret z			;73ad
	ld (ix+016h),000h		;73ae   ; y si no, sube por la cuerda como el jugador
	jp jugador_sale_por_arriba		;73b2
perseguidor_rumbo_por_defecto:
	ld a,(ix+016h)		;73b5
	dec a			;73b8
	ld c,001h		;73b9
	jr nz,L_73BF		;73bb
	ld c,002h		;73bd
L_73BF:
	ld a,(ix+000h)		;73bf   ; con el jugador andando
	cp 002h		;73c2
	jr nz,perseguidor_a_lo_suyo		;73c4
	ld (ix+01fh),c		;73c6   ; se apunta el rumbo
	ret			;73c9
perseguidor_a_lo_suyo:
	ld (ix+017h),010h		;73ca   ; 0x10 cuadros
	xor a			;73ce
	ld (ix+01ah),a		;73cf
	ld (ix+016h),a		;73d2
	jr L_7424		;73d5
perseguidor_esperando:
	ld a,(ix+000h)		;73d7   ; cayendo, no
	cp 003h		;73da
	ret z			;73dc
	ld a,(0e003h)		;73dd   ; el bit 4 del contador
	bit 4,a		;73e0
	ld a,001h		;73e2   ; le hace mirar a un lado
	jr z,perseguidor_mira_al_otro		;73e4
	dec a			;73e6
perseguidor_mira_al_otro:
	ld (ix+00bh),a		;73e7   ; y al otro: mientras espera, se gira
	dec (ix+017h)		;73ea   ; la cuenta
	ret nz			;73ed
	ld a,(0e115h)		;73ee   ; la columna del jugador
	cp (ix+005h)		;73f1   ; contra la suya
	ld a,001h		;73f4
	jr c,perseguidor_arranca		;73f6
	xor a			;73f8
perseguidor_arranca:
	ld (ix+00bh),a		;73f9   ; y se pone mirando hacia el
	ld hl,07a76h		;73fc   ; lo que tarda cada clase en soltar el siguiente
	ld a,(ix+011h)		;73ff
	and 00fh		;7402
	call suma_a_a_hl		;7404
	ld b,(hl)			;7407
	ld (ix+018h),b		;7408
	ld hl,07a7eh		;740b   ; y su cuenta de rumbo
	ld a,(ix+011h)		;740e
	and 00fh		;7411
	call suma_a_a_hl		;7413
	ld a,(ix+014h)		;7416   ; si ya la traia, se le resta una
	sub 001h		;7419
	jr nc,L_741E		;741b
	ld a,(hl)			;741d   ; y si no, la de su clase
L_741E:
	ld (ix+014h),a		;741e
	call nc,L_7424		;7421
L_7424:
	inc (ix+010h)		;7424
	ret			;7427
perseguidor_apunta_al_jugador:
	ld a,(0e111h)		;7428   ; la sala en la que lo vio
	ld (ix+019h),a		;742b
	ld a,(0e113h)		;742e   ; su fila
	ld (ix+012h),a		;7431
	ld a,(0e115h)		;7434   ; y su columna: eso es lo que persigue
	ld (ix+013h),a		;7437
	jr L_7424		;743a
perseguidor_elige_rumbo:
	ld a,(ix+016h)		;743c   ; si ya viene de chocar, nada
	and a			;743f
	jr nz,L_7424		;7440
	ld a,(ix+011h)		;7442   ; de que clase es
	and 00fh		;7445
	cp 005h		;7447   ; las cinco primeras
	jr nc,perseguidor_mira_de_lado		;7449
	call perseguidor_por_la_izquierda		;744b   ; miran si el jugador esta en otra sala
	jr nz,perseguidor_guarda_el_rumbo		;744e
	ld a,(ix+003h)		;7450   ; su fila
	sub (ix+012h)		;7453   ; contra la que le vio
	ld b,000h		;7456
	jr nc,L_745D		;7458
	neg		;745a
	inc b			;745c
L_745D:
	ld d,a			;745d
	ld a,(0e110h)		;745e   ; con el jugador andando
	cp 002h		;7461
	ld e,008h		;7463   ; ocho pixeles de margen
	jr z,L_7469		;7465
	ld e,012h		;7467   ; y si no, dieciocho
L_7469:
	ld a,d			;7469
	cp e			;746a
	jr nc,perseguidor_guarda_el_rumbo		;746b
perseguidor_mira_de_lado:
	call perseguidor_por_la_derecha		;746d   ; lo mismo por los lados
	jr nz,perseguidor_guarda_el_rumbo		;7470
	ld b,002h		;7472
	ld a,(ix+013h)		;7474   ; la columna que le vio
	sub (ix+005h)		;7477   ; contra la suya
	jr nc,perseguidor_guarda_el_rumbo		;747a
	inc b			;747c
perseguidor_guarda_el_rumbo:
	ld (ix+015h),b		;747d   ; hacia donde va
	ld a,(ix+011h)		;7480   ; la clase 4
	cp 004h		;7483
	jr z,perseguidor_puede_atacar		;7485
	ld a,b			;7487   ; y con rumbo 0 o 1, a lo suyo
	cp 002h		;7488
	jp c,L_7424		;748a
perseguidor_puede_atacar:
	ld a,(0e062h)		;748d   ; si no esta en la sala del jugador, nada
	cp (ix+001h)		;7490
	jr nz,L_7424		;7493
	ld hl,07a96h		;7495   ; la tabla que dice cuales atacan
	ld a,(ix+011h)		;7498
	bit 4,a		;749b   ; con el bit 4 de la clase, tampoco
	jr nz,L_7424		;749d
	and 00fh		;749f
	ld b,a			;74a1
	call suma_a_a_hl		;74a2
	ld a,(hl)			;74a5   ; y si su entrada esta a cero, no ataca
	and a			;74a6
	jp z,L_7424		;74a7
	ld a,b			;74aa
	cp 005h		;74ab   ; las cinco primeras clases
	jr nc,perseguidor_ataca		;74ad
	ld c,004h		;74af   ; miran el objeto 4
	call se_lleva_el_objeto		;74b1   ; y si se lleva, no atacan
	jp nz,L_7424		;74b4
perseguidor_ataca:
	ld (ix+010h),007h		;74b7   ; el estado 7
	ld (ix+017h),008h		;74bb   ; con 8 cuadros
	ret			;74bf
perseguidor_por_la_izquierda:
	ld d,0c0h		;74c0   ; los dos bits altos
	jr perseguidor_compara_salas		;74c2
perseguidor_por_la_derecha:
	ld d,030h		;74c4   ; y los dos de en medio
perseguidor_compara_salas:
	ld b,(ix+001h)		;74c6   ; su sala
	call nibble_alto_de_la_tabla		;74c9   ; en la tabla de conexiones
	and d			;74cc
	ld c,a			;74cd
	ld b,(ix+019h)		;74ce   ; contra la del jugador
	call nibble_alto_de_la_tabla		;74d1
	and d			;74d4
	cp c			;74d5   ; si coinciden, no hay que cambiar de sala
	ret z			;74d6
	push af			;74d7
	bit 4,d		;74d8   ; y si no, el rumbo sale de cual queda antes
	jr nz,L_74E3		;74da
	pop af			;74dc
	ld b,000h		;74dd
	jr c,L_74E9		;74df
	jr L_74E8		;74e1
L_74E3:
	pop af			;74e3
	ld b,002h		;74e4
	jr nc,L_74E9		;74e6
L_74E8:
	inc b			;74e8
L_74E9:
	or 001h		;74e9
	ret			;74eb
perseguidor_anda:
	dec (ix+018h)		;74ec   ; la cuenta
	jp z,perseguidor_vuelve_al_estado_2		;74ef   ; y al acabarse, se acabo lo que estaba haciendo
	ld a,(ix+000h)		;74f2   ; si viene de chocar
	cp 003h		;74f5
	jr nz,perseguidor_por_rumbo		;74f7
	ld (ix+010h),002h		;74f9   ; al estado 2
	ld (ix+017h),010h		;74fd   ; con 0x10 cuadros
	xor a			;7501
	ld (ix+01ah),a		;7502
	ld (ix+016h),a		;7505
	ret			;7508
perseguidor_por_rumbo:
	ld a,(ix+015h)		;7509   ; cuatro rumbos
	call reparte_por_tabla		;750c

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_750f: 4 entradas; detras sigue la primera, 0x7517
;   0x750f..0x7517  (8 bytes)
DATA_tabla_de_subescenas_750f:
	defw 07517h,07561h,07619h,07621h	; 750f  -> perseguidor_subestado perseguidor_subestado_otro_orden perseguidor_hacia_la_izquierda perseguidor_hacia_la_derecha

; ======================================================================
; CODIGO 0x7517..0x751d  (6 bytes)
; ======================================================================


perseguidor_subestado:
	ld a,(ix+01bh)		;7517   ; y dentro de cada uno, su subestado
	call reparte_por_tabla		;751a

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_751d: 3 entradas; detras sigue la primera, 0x7523
;   0x751d..0x7523  (6 bytes)
DATA_tabla_de_subescenas_751d:
	defw 07523h,07539h,0754eh	; 751d  -> perseguidor_busca_para_subir perseguidor_mira_si_puede_bajar perseguidor_rumbo_al_azar

; ======================================================================
; CODIGO 0x7523..0x7567  (68 bytes)
; ======================================================================


perseguidor_busca_para_subir:
	call busca_la_cuerda_de_subir		;7523   ; busca la cuerda hacia arriba
	ld a,(ix+01ch)		;7526   ; y hasta que no la encuentra, no cambia
	and a			;7529
	ret nz			;752a
perseguidor_siguiente_subestado:
	inc (ix+01bh)		;752b
	ld a,(ix+015h)		;752e   ; si va de lado
	cp 002h		;7531
	ret c			;7533
	ld (ix+01bh),000h		;7534   ; vuelve al primero
	ret			;7538
perseguidor_mira_si_puede_bajar:
	ld a,(ix+003h)		;7539   ; su fila
	cp 0a8h		;753c   ; por debajo de 0xA8 ya no hay a donde bajar
	jr c,perseguidor_busca_para_bajar		;753e
	inc (ix+01bh)		;7540
	ret			;7543
perseguidor_busca_para_bajar:
	call busca_la_cuerda_de_bajar		;7544   ; y si no, busca la cuerda hacia abajo
	ld a,(ix+01ch)		;7547
	and a			;754a
	ret nz			;754b
	jr perseguidor_siguiente_subestado		;754c
perseguidor_rumbo_al_azar:
	ld (ix+01bh),000h		;754e   ; el subestado, a cero
	ld a,(0e003h)		;7552   ; el bit 3 del contador de cuadros
	rra			;7555
	rra			;7556
	rra			;7557
	ld a,002h		;7558   ; elige uno de los dos lados
	jr c,L_755D		;755a
	inc a			;755c
L_755D:
	ld (ix+015h),a		;755d
	ret			;7560
perseguidor_subestado_otro_orden:
	ld a,(ix+01bh)		;7561   ; los mismos tres, en otro orden
	call reparte_por_tabla		;7564

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_7567: 3 entradas, los mismos tres destinos que la
;   de 0x751D pero en otro orden; la cierra el `call 0756dh` de 0x7544
;   0x7567..0x756d  (6 bytes)
DATA_tabla_de_subescenas_7567:
	defw 07539h,07523h,0754eh	; 7567  -> perseguidor_mira_si_puede_bajar perseguidor_busca_para_subir perseguidor_rumbo_al_azar

; ======================================================================
; CODIGO 0x756d..0x78f5  (904 bytes)
; ======================================================================


busca_la_cuerda_de_bajar:
	ld c,000h		;756d   ; c a cero: se busca la 0x53
	ld a,(ix+003h)		;756f   ; la fila, ocho pixeles mas abajo
	add a,008h		;7572
	ld l,a			;7574
	jr busca_la_cuerda		;7575
busca_la_cuerda_de_subir:
	ld c,001h		;7577   ; c a uno: se busca la 0x41
	ld l,(ix+003h)		;7579   ; y a su altura
busca_la_cuerda:
	ld h,(ix+005h)		;757c   ; la columna
	ld a,(ix+001h)		;757f   ; de su sala
	call casilla_de_la_sala_en_pixeles		;7582   ; a direccion dentro de la sala
	ld b,000h		;7585   ; b cuenta las casillas andadas
	ld a,(ix+01ch)		;7587   ; y si ya venia buscando hacia la izquierda, se sigue por ahi
	and a			;758a
	jr nz,busca_a_la_izquierda		;758b
busca_a_la_derecha:
	inc hl			;758d   ; una casilla mas
	ld a,l			;758e   ; al llegar al borde de la fila
	and 01fh		;758f
	jr nz,L_7597		;7591
	ld de,00260h		;7593   ; se salta a la de abajo
	add hl,de			;7596
L_7597:
	ld e,000h		;7597   ; mirando a la derecha
	call mira_esa_casilla		;7599   ; hasta que la casilla diga algo
	jr nz,busca_a_la_derecha		;759c
	ld (ix+01ch),b		;759e   ; y lo que salga se guarda
	ret			;75a1
mira_esa_casilla:
	ld a,c			;75a2   ; segun se busque una u otra
	and a			;75a3
	ld a,(hl)			;75a4
	ld d,041h		;75a5   ; la 0x41, el pie de la cuerda
	jr nz,L_75AE		;75a7
	and a			;75a9   ; con la casilla vacia se sigue
	jr z,busca_se_acabo		;75aa
	ld d,053h		;75ac   ; o la 0x53, la cabeza
L_75AE:
	cp d			;75ae   ; si es la que se busca, ahi esta
	jr z,busca_se_acabo		;75af
	call mira_la_casilla_de_mas_alla		;75b1   ; y si hay pared, se acabo la busqueda por ese lado
	jr nz,busca_no_hay_por_aqui		;75b4
	inc b			;75b6   ; una casilla mas de distancia
	or 001h		;75b7
	ret			;75b9
busca_no_hay_por_aqui:
	ld b,0ffh		;75ba   ; 0xFF: por este lado no hay
busca_se_acabo:
	and 000h		;75bc
	ret			;75be
busca_a_la_izquierda:
	dec hl			;75bf   ; una casilla menos
	ld a,l			;75c0
	and 01fh		;75c1   ; y al llegar al borde
	cp 01fh		;75c3
	jr nz,L_75CD		;75c5
	ld de,00260h		;75c7   ; se salta a la fila de arriba
	and a			;75ca
	sbc hl,de		;75cb
L_75CD:
	ld e,001h		;75cd   ; mirando a la izquierda
	call mira_esa_casilla		;75cf
	jr nz,busca_a_la_izquierda		;75d2
	inc c			;75d4   ; lo que costo por la izquierda
	ld e,c			;75d5
	ld c,(ix+01ch)		;75d6   ; contra lo que costo por la derecha
	ld (ix+01ch),000h		;75d9   ; y se cierra la busqueda
	ld a,c			;75dd
	inc a			;75de   ; si por un lado no habia
	jr nz,busca_elige_el_lado		;75df
	ld a,b			;75e1   ; y por el otro tampoco, no hay cuerda
	inc a			;75e2
	ret z			;75e3
busca_elige_el_lado:
	ld (ix+017h),010h		;75e4   ; 0x10 cuadros
	ld (ix+016h),e		;75e8   ; hacia el lado que sea
	ld a,(ix+00fh)		;75eb   ; el bit 0 de (ix+00Fh)
	rrca			;75ee   ; se gasta rotandolo
	ld (ix+00fh),a		;75ef
	jr nc,busca_compara		;75f2
	ld a,b			;75f4   ; y con el puesto se prueba el otro lado primero: asi dos bichos iguales no van los dos a la misma cuerda
	ld b,c			;75f5
	ld c,a			;75f6
busca_compara:
	ld a,b			;75f7   ; la distancia de un lado
	cp c			;75f8   ; contra la del otro
	ld a,002h		;75f9   ; y se va a por la mas corta
	jr nc,busca_guarda_el_rumbo		;75fb
	inc a			;75fd
busca_guarda_el_rumbo:
	ld (ix+015h),a		;75fe
	ret			;7601
mira_la_casilla_de_mas_alla:
	push hl			;7602
	push de			;7603
	ld de,00020h		;7604   ; una fila mas
	ld a,c			;7607   ; o dos, si se busca hacia abajo
	and a			;7608
	jr nz,L_760E		;7609
	ld de,00040h		;760b
L_760E:
	and a			;760e
	sbc hl,de		;760f   ; por encima
	ld a,(hl)			;7611
	pop de			;7612
	pop hl			;7613
	and a			;7614   ; con la casilla vacia, se puede pasar
	ret z			;7615
	cp 054h		;7616   ; y con la 0x54 tambien
	ret			;7618
perseguidor_hacia_la_izquierda:
	call perseguidor_espera		;7619   ; la cuenta de lo que esta haciendo
	ret z			;761c
	ld b,008h		;761d   ; el rumbo 8
	jr perseguidor_avanza_de_lado		;761f
perseguidor_hacia_la_derecha:
	call perseguidor_espera		;7621
	ret z			;7624
	ld b,004h		;7625   ; y el 4
perseguidor_avanza_de_lado:
	ld (ix+01fh),b		;7627   ; se apunta a que lado va
	ld a,(ix+016h)		;762a   ; si no venia de nada
	dec a			;762d
	jr z,perseguidor_se_sale_por_la_derecha		;762e
	ld a,(ix+011h)		;7630   ; su clase
	and 00fh		;7633
	ld b,a			;7635
	cp 007h		;7636   ; la 7 no mira la casilla
	jr z,perseguidor_se_sale_por_la_derecha		;7638
	ld l,(ix+003h)		;763a   ; su fila
	ld h,(ix+005h)		;763d   ; y su columna
	ld a,(ix+001h)		;7640
	call casilla_de_la_sala_en_pixeles		;7643   ; a direccion dentro de la sala
	ld a,(hl)			;7646
	and a			;7647   ; con la casilla vacia se pasa
	jr z,L_764E		;7648
	cp 054h		;764a   ; y con la 0x54 tambien
	jr nz,perseguidor_se_sale_por_la_derecha		;764c
L_764E:
	ld a,b			;764e   ; de la clase 6 en adelante
	cp 006h		;764f
	jr c,perseguidor_se_para		;7651
	dec hl			;7653   ; se mira la de al lado
	ld a,(hl)			;7654
	cp 0dfh		;7655
	jr perseguidor_se_da_la_vuelta		;7657
perseguidor_se_para:
	ld (ix+01eh),001h		;7659   ; y si no, se planta
	ret			;765d
perseguidor_se_sale_por_la_derecha:
	ld a,(ix+005h)		;765e   ; su columna
	cp 0d8h		;7661   ; pasada la 0xD8
	jr c,perseguidor_se_sale_por_la_izquierda		;7663
	ld b,(ix+001h)		;7665   ; la sala de al lado
	inc b			;7668
	ld a,(0e111h)		;7669   ; tiene que ser en la que esta el jugador
	cp b			;766c
	jr nz,perseguidor_se_sale_por_la_izquierda		;766d
	ld a,(0e115h)		;766f
	cp 028h		;7672
	jr nc,perseguidor_se_sale_por_la_izquierda		;7674
	ld b,0d6h		;7676
	ld c,003h		;7678
	jr perseguidor_cruza_de_sala		;767a
perseguidor_se_sale_por_la_izquierda:
	ld a,(ix+005h)		;767c
	cp 028h		;767f   ; y por debajo de 0x28
	jr nc,perseguidor_ha_chocado		;7681
	ld b,(ix+001h)		;7683
	dec b			;7686
	ld a,(0e111h)		;7687
	cp b			;768a
	jr nz,perseguidor_ha_chocado		;768b
	ld a,(0e115h)		;768d
	cp 0d8h		;7690
	jr c,perseguidor_ha_chocado		;7692
	ld b,02ah		;7694   ; aparece en la columna 0x2A
	ld c,002h		;7696
perseguidor_cruza_de_sala:
	ld a,(0e113h)		;7698   ; la fila del jugador
	sub (ix+003h)		;769b   ; contra la suya
	jr nc,L_76A2		;769e
	neg		;76a0
L_76A2:
	cp 010h		;76a2   ; a mas de dieciseis pixeles no cruza
	jr nc,perseguidor_ha_chocado		;76a4
	ld (ix+005h),b		;76a6   ; y si cuadra, aparece por el otro lado
	ld (ix+015h),c		;76a9
	ret			;76ac
perseguidor_ha_chocado:
	ld a,(ix+00eh)		;76ad   ; contra que se ha chocado
	and a			;76b0
	ret z			;76b1
	jp m,perseguidor_se_para		;76b2   ; con el bit 7, se planta
	and 003h		;76b5   ; los dos bits de abajo
	ld c,a			;76b7
	ld a,(ix+01fh)		;76b8   ; contra el lado al que iba
	rra			;76bb
	rra			;76bc
	and 003h		;76bd
	xor c			;76bf
	ret z			;76c0   ; si va justo hacia donde choco, nada
	ld a,c			;76c1
	dec a			;76c2
perseguidor_se_da_la_vuelta:
	ld b,002h		;76c3
	jr nz,L_76C8		;76c5
	inc b			;76c7
L_76C8:
	ld a,(ix+015h)		;76c8   ; si ya iba por ahi, nada
	cp b			;76cb
	ret z			;76cc
	ld a,(ix+011h)		;76cd   ; su clase
	and 00fh		;76d0
	cp 005h		;76d2   ; las cinco primeras aguantan dos intentos
	ld c,004h		;76d4
	jr nc,L_76DA		;76d6
	ld c,002h		;76d8   ; y las demas cuatro
L_76DA:
	ld a,(ix+01ah)		;76da   ; la cuenta de intentos
	inc a			;76dd
	ld (ix+01ah),a		;76de
	cp c			;76e1   ; hasta la que le toque
	jr c,perseguidor_guarda_el_lado		;76e2
	ld (ix+01ah),000h		;76e4
	ld a,c			;76e8
	cp 004h		;76e9   ; a los cuatro, se rinde
	jr z,perseguidor_se_rinde		;76eb
	ld a,(0e003h)		;76ed   ; y si no, cambia de lado con el bit 4 del contador
	rra			;76f0
	rra			;76f1
	rra			;76f2
	rra			;76f3
	and 001h		;76f4
	ld b,a			;76f6
perseguidor_guarda_el_lado:
	ld (ix+015h),b		;76f7
	ret			;76fa
perseguidor_se_rinde:
	ld (ix+010h),00bh		;76fb   ; el estado 11
	ld (ix+017h),008h		;76ff   ; con ocho cuadros
	ld (ix+01dh),001h		;7703   ; y se apunta que se rindio
	xor a			;7707
	ld (ix+00ah),a		;7708
	ld (ix+000h),a		;770b
	ret			;770e
perseguidor_espera:
	ld a,(ix+017h)		;770f   ; mientras le quede cuenta
	and a			;7712
	jr z,perseguidor_mira_si_puede_ir		;7713
	dec (ix+017h)		;7715   ; se descuenta
perseguidor_sigue_igual:
	or 001h		;7718
	ret			;771a
perseguidor_mira_si_puede_ir:
	ld a,(ix+016h)		;771b   ; a donde queria ir
	and a			;771e
	jr z,perseguidor_sigue_igual		;771f
	xor 003h		;7721   ; se le da la vuelta
	ld d,a			;7723
	ld a,(ix+009h)		;7724   ; contra lo que se puede hacer aqui
	and d			;7727
	jr z,perseguidor_sigue_igual		;7728   ; y si no se puede, nada
	ld a,d			;772a
	ld (ix+01eh),a		;772b
	ld (ix+010h),001h		;772e   ; y si se puede, al estado 1
	ret			;7732
perseguidor_pegando:
	call mira_los_choques_de_un_bicho		;7733   ; sus choques
	ld a,(ix+000h)		;7736   ; si esta cayendo
	cp 003h		;7739
	ld de,00000h		;773b
	jp z,reparte_por_el_estado		;773e   ; se sigue por el estado
	ld a,(ix+00ah)		;7741   ; y con la estalactita o la columna
	and 052h		;7744
	jp nz,perseguidor_se_rinde		;7746   ; se rinde
	call pega_al_jugador_al_suelo		;7749   ; pegado al suelo
	ld a,(ix+017h)		;774c   ; el bit 2 de la cuenta
	bit 2,a		;774f
	ld a,00eh		;7751   ; turna las dos posturas de pegar
	jr z,L_7757		;7753
	ld a,010h		;7755
L_7757:
	ld (ix+00ch),a		;7757
	dec (ix+017h)		;775a   ; y al acabarse la cuenta
	ret nz			;775d
	ld (ix+010h),001h		;775e   ; vuelve al estado 1
	jp perseguidor_a_lo_suyo		;7762
perseguidor_dispara:
	call perseguidor_mira_sus_choques		;7765
	ld a,(ix+011h)		;7768   ; su clase
	cp 004h		;776b
	ld c,004h		;776d   ; las tres primeras, la pieza 4
	ld b,00ch		;776f
	jr c,L_777B		;7771
	ld c,006h		;7773   ; la cuarta, la 6
	ld b,002h		;7775
	jr z,L_777B		;7777
	ld c,085h		;7779   ; y las demas, la 0x85
L_777B:
	ld (ix+00ch),b		;777b   ; la postura de disparar
	dec (ix+017h)		;777e   ; hasta que se acaba la cuenta
	ret nz			;7781
	ld a,c			;7782
	call pide_pieza		;7783   ; suena
	ld c,000h		;7786
	ld iy,0e55ch		;7788   ; los seis huecos de disparo
	ld de,00008h		;778c   ; ocho bytes cada uno
	ld b,006h		;778f
busca_hueco_de_disparo:
	ld a,(iy+000h)		;7791   ; el primero libre
	and a			;7794
	jr z,arranca_el_disparo		;7795
busca_hueco_de_disparo_sigue:
	add iy,de		;7797
	djnz busca_hueco_de_disparo		;7799
	ld a,001h		;779b   ; y si no hay, no sale ninguno
	jr remata_el_disparo		;779d
arranca_el_disparo:
	ld a,(ix+001h)		;779f   ; su sala
	ld (iy+001h),a		;77a2
	ld a,(ix+00bh)		;77a5   ; a que lado mira el que dispara
	inc a			;77a8
	ld (iy+000h),a		;77a9
	dec a			;77ac
	ld h,004h		;77ad   ; cuatro pixeles por delante
	jr z,L_77B3		;77af
	ld h,0fch		;77b1   ; o cuatro por detras
L_77B3:
	ld a,(ix+005h)		;77b3   ; desde su columna
	add a,h			;77b6   ; mas el desplazamiento
	ld (iy+005h),a		;77b7
	ld b,0f9h		;77ba   ; la fila de salida por defecto
	ld a,c			;77bc   ; cual de los tres va
	and a			;77bd
	jr z,arranca_el_disparo_fila		;77be
	ld b,0e9h		;77c0   ; el segundo sale mas alto
	dec a			;77c2
	jr z,arranca_el_disparo_fila		;77c3
	ld b,009h		;77c5   ; y el tercero mas bajo
arranca_el_disparo_fila:
	ld a,(ix+003h)		;77c7   ; la fila del que dispara
	add a,b			;77ca   ; mas lo que toque
	ld (iy+003h),a		;77cb
	ld a,(ix+011h)		;77ce   ; su clase
	cp 004h		;77d1
	ld h,000h		;77d3   ; las tres primeras, un solo disparo
	jr c,L_77DE		;77d5
	ld h,001h		;77d7   ; la cuarta, otro
	jr nz,L_77DE		;77d9
	ld h,c			;77db   ; y las demas, uno por cada tanda
	inc h			;77dc
	inc h			;77dd
L_77DE:
	ld (iy+006h),000h		;77de   ; sin recorrido todavia
	ld (iy+007h),h		;77e2
	cp 004h		;77e5   ; la clase 4
	jr nz,L_77EF		;77e7
	inc c			;77e9   ; suelta TRES de golpe
	ld a,c			;77ea
	cp 003h		;77eb
	jr c,busca_hueco_de_disparo_sigue		;77ed
L_77EF:
	ld a,010h		;77ef   ; y 0x10 cuadros hasta el siguiente
remata_el_disparo:
	ld (ix+017h),a		;77f1
	jp L_7424		;77f4
perseguidor_espera_tras_disparar:
	call perseguidor_mira_sus_choques		;77f7   ; sus choques
	dec (ix+017h)		;77fa   ; la cuenta
	ret nz			;77fd
	ld (ix+010h),005h		;77fe   ; y al estado 5
	ret			;7802
perseguidor_dolorido:
	ld a,(0e003h)		;7803   ; el bit 3 del contador
	bit 3,a		;7806
	ld a,00eh		;7808   ; turna las dos posturas
	jr z,L_780E		;780a
	ld a,010h		;780c
L_780E:
	ld (ix+00ch),a		;780e
	dec (ix+017h)		;7811   ; hasta que se acaba la cuenta
	ret nz			;7814
perseguidor_vuelve_al_estado_2:
	ld a,010h		;7815   ; 0x10 cuadros
perseguidor_pon_cuenta_y_estado:
	ld (ix+017h),a		;7817
	ld (ix+010h),002h		;781a
	ret			;781e
perseguidor_vuelve_con_cinco:
	ld a,005h		;781f   ; cinco cuadros
	jr perseguidor_pon_cuenta_y_estado		;7821
perseguidor_desaparece:
	ld (ix+00ch),012h		;7823   ; la postura 0x12
	dec (ix+017h)		;7827   ; la cuenta
	ret nz			;782a
	ld (ix+00ch),014h		;782b   ; la 0x14
	ld (ix+01ah),000h		;782f
	ld (ix+017h),0ffh		;7833   ; y a esperar sin plazo
	inc (ix+010h)		;7837
	ld a,(ix+01dh)		;783a   ; si se habia rendido
	and a			;783d
	ret z			;783e
	ld a,(ix+022h)		;783f   ; vuelve a la sala por la que entro
	ld (ix+001h),a		;7842
	ld a,(ix+020h)		;7845   ; a su fila
	ld (ix+003h),a		;7848
	ld a,(ix+021h)		;784b   ; y a su columna: los tres bytes que guardo al aparecer
	ld (ix+005h),a		;784e
	ret			;7851
perseguidor_esperando_a_volver:
	dec (ix+017h)		;7852   ; la cuenta
	ret nz			;7855
perseguidor_vuelve_a_salir:
	ld a,(ix+011h)		;7856   ; su clase
	and 00fh		;7859
	cp 005h		;785b   ; las cinco primeras
	jr nc,perseguidor_sale_con_ruido		;785d
	ld a,002h		;785f   ; al estado 2 con 0x10 cuadros
	ld b,010h		;7861
	jr perseguidor_pon_estado_y_cuenta		;7863
perseguidor_sale_con_ruido:
	ld a,002h		;7865   ; y las demas suenan al salir
	call pide_pieza		;7867
	ld a,009h		;786a   ; y arrancan en el estado 9 con 0x40
	ld b,040h		;786c
perseguidor_pon_estado_y_cuenta:
	ld (ix+010h),a		;786e
	ld (ix+017h),b		;7871
	ret			;7874
perseguidor_puede_disparar:
	ld a,(ix+010h)		;7875   ; en los estados 1, 2 y 5
	cp 001h		;7878
	jr z,perseguidor_prepara_el_disparo		;787a
	cp 002h		;787c
	jr z,perseguidor_prepara_el_disparo		;787e
	cp 005h		;7880
	ret nz			;7882
perseguidor_prepara_el_disparo:
	ld a,(ix+015h)		;7883   ; con rumbo 0 o 1 no dispara
	cp 002h		;7886
	ret c			;7888
	ld de,07a86h		;7889   ; la velocidad de cada clase
	ld a,(ix+011h)		;788c   ; dos bytes por clase
	and 00fh		;788f
	add a,a			;7891
	call suma_a_a_de		;7892
	ld a,(de)			;7895
	ld l,a			;7896
	inc de			;7897
	ld a,(de)			;7898
	ld h,a			;7899
	call velocidad_del_perseguidor		;789a   ; y el objeto que la frena
	ld e,(ix+01eh)		;789d   ; lo que lleva apuntado
	ld d,(ix+01fh)		;78a0
	call reparte_por_el_estado		;78a3   ; y de ahi sale lo que hace
perseguidor_mira_sus_choques:
	call mira_los_choques_de_un_bicho		;78a6   ; los mismos peligros que al jugador
	ld a,(ix+00ah)		;78a9
	ld b,a			;78ac
	and 050h		;78ad   ; con la columna o la fuga
	jp nz,perseguidor_se_rinde		;78af   ; se rinde
	ld a,b			;78b2
	and 002h		;78b3   ; y con la estalactita, otra cosa
	jp nz,L_7E00		;78b5
	ret			;78b8
velocidad_del_perseguidor:
	ld a,(ix+011h)		;78b9   ; su clase
	and 00fh		;78bc
	cp 005h		;78be   ; de la 5 en adelante, el objeto 0x14
	ld c,014h		;78c0
	jr nc,L_78C6		;78c2
	ld c,015h		;78c4   ; y por debajo, el 0x15
L_78C6:
	push hl			;78c6
	call se_lleva_el_objeto		;78c7   ; si se lleva
	pop hl			;78ca
	ret z			;78cb
	ld hl,001f0h		;78cc   ; la velocidad se queda en 0x01F0, sea la que sea la suya
	ret			;78cf
monta_el_sprite_del_perseguidor:
	ld a,(ix+010h)		;78d0   ; apagado, nada
	and a			;78d3
	ret z			;78d4
	ld l,(ix+003h)		;78d5   ; su fila
	ld h,(ix+005h)		;78d8   ; y su columna
	ld de,0790bh		;78db   ; los dibujos de las clases altas
	ld a,(ix+011h)		;78de
	and 00fh		;78e1
	cp 005h		;78e3   ; y de la 5 en adelante
	push bc			;78e5
	ld b,001h		;78e6   ; con un solo color
	jr nc,L_78F0		;78e8
	ld de,078f5h		;78ea   ; las clases bajas usan los otros
	add a,002h		;78ed   ; y su color sale de la clase
	ld b,a			;78ef
L_78F0:
	ld a,b			;78f0
	pop bc			;78f1
	jp monta_los_sprites_de_la_ficha		;78f2

; ----------------------------------------------------------------------
; DATOS patrones_del_perseguidor: cuarenta y cuatro patrones en dos tandas de
;   veintidos, en parejas -uno por lado-: la de 0x78F5 para las clases 0 a 4 y
;   la de 0x790B para las demas. Un solo byte por postura, porque el
;   perseguidor se monta con UN sprite
;   0x78f5..0x7921  (44 bytes)
DATA_patrones_del_perseguidor:
	defb 080h,0d8h,084h,0dch,088h,0e0h,088h,0e0h,030h,030h,038h,038h,08ch,0e4h,090h,090h	; 78f5  ........0088....
	defb 0e8h,0e8h,004h,004h,0c0h,0c0h,094h,0ech,098h,0f0h,094h,0ech,094h,0ech,004h,004h	; 7905  ................
	defb 0c0h,0c0h,098h,0f0h,048h,048h,04ch,04ch,004h,004h,0c0h,0c0h	; 7915  ....HHLL....

; ======================================================================
; CODIGO 0x7921..0x794c  (43 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LOS SEIS DISPAROS
; ----------------------------------------------------------------------
mueve_los_disparos:
	ld ix,0e55ch		;7921   ; los seis huecos
	ld iy,0e0bch		;7925   ; y su bufer de sprites
	ld de,00008h		;7929   ; ocho bytes de ficha
	ld b,006h		;792c   ; seis
mueve_los_disparos_bucle:
	exx			;792e
	call mueve_un_disparo		;792f
	ld de,00004h		;7932   ; cuatro de bufer
	add iy,de		;7935
	exx			;7937
	add ix,de		;7938
	djnz mueve_los_disparos_bucle		;793a
	ret			;793c
mueve_un_disparo:
	ld a,(ix+000h)		;793d   ; apagado, nada
	and a			;7940
	ret z			;7941
	call disparo_estado		;7942   ; se mueve
	jp monta_el_sprite_del_disparo		;7945   ; y se monta su sprite
disparo_estado:
	dec a			;7948   ; cuatro estados, y los dos primeros son el mismo
	call reparte_por_tabla		;7949

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_794c: 4 entradas; detras sigue la primera, 0x7954
;   0x794c..0x7954  (8 bytes)
DATA_tabla_de_subescenas_794c:
	defw 07954h,07954h,079b4h,079bch	; 794c  -> disparo_volando disparo_volando disparo_clavado disparo_se_borra

; ======================================================================
; CODIGO 0x7954..0x79aa  (86 bytes)
; ======================================================================


disparo_volando:
	ld a,(0e1b1h)		;7954   ; con la partida parada, quieto
	and a			;7957
	jr nz,$+100		;7958
	ld a,(ix+007h)		;795a   ; su clase
	cp 003h		;795d
	push af			;795f
	call nc,disparo_sube_o_baja		;7960   ; de la 3 en adelante, ademas cae o sube
	pop af			;7963
	ld hl,079aah		;7964   ; la velocidad de cada clase
	call puntero_numero_a		;7967
	ld a,(ix+000h)		;796a
	ld l,(ix+004h)		;796d   ; su columna, con fraccion
	ld h,(ix+005h)		;7970
	dec a			;7973   ; el estado 1 va a la derecha
	jr z,disparo_a_la_derecha		;7974
	and a			;7976
	sbc hl,de		;7977   ; y el 2 a la izquierda
	jr disparo_guarda_la_columna		;7979
disparo_a_la_derecha:
	add hl,de			;797b
disparo_guarda_la_columna:
	ld (ix+004h),l		;797c   ; donde queda
	ld (ix+005h),h		;797f
	call disparo_se_ha_estrellado		;7982   ; si se ha salido o ha dado en la pared
	jr nz,disparo_se_apaga		;7985
	ld a,(0e062h)		;7987   ; y si no esta en la sala del jugador, nada
	cp (ix+001h)		;798a
	ret nz			;798d
	call caja_de_dos_por_dos		;798e   ; si le toca
	jr nz,disparo_se_apaga		;7991
	ld a,(ix+007h)		;7993   ; la clase 1
	dec a			;7996
	ret nz			;7997
	call caja_de_siete_por_siete		;7998   ; tiene una caja mas grande
	ret z			;799b
	ld (ix+004h),008h		;799c   ; y el disparo se queda clavado
	ld a,003h		;79a0
	jr disparo_pon_estado		;79a2
disparo_se_apaga:
	ld a,004h		;79a4   ; al estado 4
disparo_pon_estado:
	ld (ix+000h),a		;79a6
	ret			;79a9

; ----------------------------------------------------------------------
; DATOS velocidad_de_cada_disparo: cinco palabras de dieciseis bits, una por
;   clase: de 0x0350 a 0x0260 pixeles por cuadro. 0x7964 entra con (ix+007h)
;   0x79aa..0x79b4  (10 bytes)
DATA_velocidad_de_cada_disparo:
	defw 00350h,002a0h,00300h,00260h,00260h	; 79aa

; ======================================================================
; CODIGO 0x79b4..0x7a60  (172 bytes)
; ======================================================================


disparo_clavado:
	dec (ix+004h)		;79b4   ; la cuenta
	ret nz			;79b7
	inc (ix+000h)		;79b8
	ret			;79bb
disparo_se_borra:
	ld (ix+003h),0e0h		;79bc   ; fuera de la pantalla
	ld (ix+000h),000h		;79c0   ; y el hueco queda libre
	ret			;79c4
disparo_sube_o_baja:
	ld l,(ix+002h)		;79c5   ; su fila, con fraccion
	ld h,(ix+003h)		;79c8
	ld de,000a0h		;79cb   ; 0x00A0, o sea algo mas de medio pixel por cuadro
	sub 003h		;79ce   ; la clase 3 sube
	jr z,L_79D5		;79d0
	add hl,de			;79d2   ; y las demas bajan
	jr L_79D8		;79d3
L_79D5:
	and a			;79d5
	sbc hl,de		;79d6
L_79D8:
	ld a,h			;79d8   ; sin salirse de la sala por arriba
	cp 010h		;79d9
	jr c,$-55		;79db
	cp 0b0h		;79dd   ; ni por abajo
	jr nc,$-59		;79df
	ld (ix+002h),l		;79e1
	ld (ix+003h),h		;79e4
	ret			;79e7
disparo_se_ha_estrellado:
	ld a,(ix+005h)		;79e8   ; su columna
	cp 008h		;79eb   ; fuera por la izquierda
	jr c,disparo_sigue		;79ed
	cp 0f8h		;79ef   ; o por la derecha
	jr nc,disparo_sigue		;79f1
	ld h,a			;79f3
	ld a,(ix+007h)		;79f4   ; las clases 2 y 3 no miran las paredes
	cp 002h		;79f7
	jr nc,disparo_muere		;79f9
	ld l,(ix+003h)		;79fb   ; su fila
	call casilla_de_la_sala_de_ahora		;79fe   ; a direccion dentro de la sala
	call casilla_que_frena		;7a01   ; y con una casilla que frene, se acabo
	jr nz,disparo_muere		;7a04
disparo_sigue:
	or 001h		;7a06
	ret			;7a08
disparo_muere:
	and 000h		;7a09
	ret			;7a0b
monta_el_sprite_del_disparo:
	ld hl,07a60h		;7a0c   ; los dibujos de cada clase
	ld a,(ix+007h)		;7a0f
	call puntero_numero_a		;7a12
	ex de,hl			;7a15
	push iy		;7a16
	pop de			;7a18
	ld a,(0e062h)		;7a19   ; si esta en otra sala
	cp (ix+001h)		;7a1c
	jr z,coloca_el_sprite_del_disparo		;7a1f
	ld a,0e0h		;7a21   ; el sprite se manda a la fila 0xE0
	ld (de),a			;7a23
	ret			;7a24
coloca_el_sprite_del_disparo:
	ld a,(ix+003h)		;7a25   ; la fila
	add a,(hl)			;7a28   ; mas el desplazamiento
	ld (de),a			;7a29
	inc de			;7a2a
	ld a,(ix+005h)		;7a2b   ; y la columna, con el MISMO desplazamiento: los disparos van en diagonal
	add a,(hl)			;7a2e
	ld (de),a			;7a2f
	inc de			;7a30
	inc hl			;7a31
	ld a,(ix+000h)		;7a32   ; del estado 3 en adelante
	cp 003h		;7a35
	ld a,004h		;7a37   ; el patron 4, que es el de estrellarse
	jr nc,disparo_guarda_el_patron		;7a39
	ld a,(0e003h)		;7a3b   ; y si no, el bit 1 del contador
	and 002h		;7a3e
	ld a,(ix+006h)		;7a40
	jr nz,L_7A4E		;7a43
	inc a			;7a45   ; pasa las tres posturas en rueda
	cp 003h		;7a46
	jr c,L_7A4B		;7a48
	xor a			;7a4a
L_7A4B:
	ld (ix+006h),a		;7a4b
L_7A4E:
	call suma_a_a_hl		;7a4e
	ld a,(hl)			;7a51
disparo_guarda_el_patron:
	ld (de),a			;7a52
	inc de			;7a53
	ld a,(ix+000h)		;7a54   ; en el estado 4
	cp 004h		;7a57
	ld a,00fh		;7a59
	jr nz,disparo_guarda_el_color		;7a5b
	xor a			;7a5d   ; el color a cero: asi se apaga sin mover el sprite
disparo_guarda_el_color:
	ld (de),a			;7a5e
	ret			;7a5f

; ----------------------------------------------------------------------
; DATOS punteros_de_los_dibujos_del_disparo: cinco punteros, uno por clase, a
;   las entradas de 0x7A6A: el desplazamiento y los tres patrones que se
;   turnan
;   0x7a60..0x7a6a  (10 bytes)
DATA_punteros_de_los_dibujos_del_disparo:
	defw 07a6ah,07a6eh,07a72h,07a72h,07a72h	; 7a60

; ----------------------------------------------------------------------
; DATOS dibujos_y_tiempos_del_perseguidor: cincuenta y dos bytes: los veinte
;   primeros son los dibujos de los disparos, y detras van las tablas por
;   clase que 0x73FC, 0x740B y 0x7495 leen -cada cuanto suelta uno, cuantos
;   rumbos aguanta y si ataca-
;   0x7a6a..0x7a9e  (52 bytes)
DATA_dibujos_y_tiempos_del_perseguidor:
	defb 000h,020h,020h,020h,0fbh,014h,018h,01ch,0fbh,02ch,02ch,02ch,040h,020h,040h,040h	; 7a6a  .   .....,,,@ @@
	defb 020h,030h,060h,060h,001h,004h,000h,000h,003h,001h,002h,002h,080h,001h,010h,001h	; 7a7a   0``............
	defb 0f0h,001h,080h,001h,010h,001h,080h,001h,080h,001h,080h,001h,001h,001h,000h,001h	; 7a8a  ................
	defb 001h,001h,001h,001h	; 7a9a

; ======================================================================
; CODIGO 0x7a9e..0x7d6a  (716 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; CONTRA QUE SE CHOCA
; ----------------------------------------------------------------------
mira_todos_los_choques:
	ld (ix+00ah),000h		;7a9e   ; se empieza sin ningun choque
	ld a,(0e1b1h)		;7aa2   ; con la partida parada, nada
	and a			;7aa5
	ret nz			;7aa6
	call choque_con_el_agua		;7aa7   ; el agua
	call choque_con_las_fichas_del_lanzador		;7aaa   ; las fichas del lanzador
	call choque_con_las_bolas		;7aad   ; las bolas de piedra
	call choque_con_las_estalactitas		;7ab0   ; las estalactitas
	call choque_con_las_llamaradas		;7ab3   ; las llamaradas
	call choque_con_las_columnas		;7ab6   ; las columnas
	jp choque_con_las_fugas		;7ab9   ; y las fugas de las tuberias
mira_los_choques_de_un_bicho:
	ld a,(0e062h)		;7abc   ; solo si esta en la sala
	cp (ix+001h)		;7abf
	ret nz			;7ac2
	ld (ix+00ah),000h		;7ac3   ; lo mismo, pero sin las columnas ni las fugas
	call choque_con_el_agua		;7ac7
	call choque_con_las_fichas_del_lanzador		;7aca
	call choque_con_las_bolas		;7acd
	call choque_con_las_estalactitas		;7ad0
	jp choque_con_las_columnas		;7ad3
choque_con_el_agua:
	ld iy,0e345h		;7ad6   ; los tres chorros
	ld b,003h		;7ada   ; tres
	ld de,0000ah		;7adc   ; diez bytes de ficha
choque_con_el_agua_bucle:
	exx			;7adf   ; la cuenta del bucle, a salvo en el otro juego de registros
	call mira_un_chorro		;7ae0
	exx			;7ae3
	add iy,de		;7ae4
	djnz choque_con_el_agua_bucle		;7ae6
	ret			;7ae8
mira_un_chorro:
	ld a,(iy+000h)		;7ae9   ; y si esta apagado
	and a			;7aec
	jr nz,chorro_su_rectangulo		;7aed
salta_esta_familia:
	exx			;7aef
	ld b,001h		;7af0   ; se pasa a la siguiente sin mirar
	exx			;7af2
	ret			;7af3
chorro_su_rectangulo:
	ld a,(iy+002h)		;7af4   ; su columna, de casillas a pixeles
	add a,a			;7af7
	add a,a			;7af8
	add a,a			;7af9
	ld e,a			;7afa
	ld c,(iy+005h)		;7afb   ; por donde va cayendo
	ld a,(iy+006h)		;7afe   ; y de donde salio
	add a,a			;7b01
	add a,a			;7b02
	add a,a			;7b03
	ld d,a			;7b04
	ld a,c			;7b05
	add a,a			;7b06
	add a,a			;7b07
	add a,a			;7b08
	add a,008h		;7b09   ; el chorro ocupa de la fila de arriba a la de ahora
	sub d			;7b0b
	ld h,a			;7b0c
	ld l,018h		;7b0d   ; veinticuatro pixeles de alto
	ld c,001h		;7b0f   ; y el bit 0
se_tocan_los_dos:
	ld a,(0e062h)		;7b11   ; si no estan en la misma sala, no hay choque
	cp (ix+001h)		;7b14
	ret nz			;7b17
	ld a,006h		;7b18   ; el alto del otro
	add a,l			;7b1a
	ld l,a			;7b1b
	ld a,(ix+005h)		;7b1c   ; la columna de la ficha
	add a,002h		;7b1f
	sub e			;7b21
	cp l			;7b22   ; tiene que caer dentro
	ret nc			;7b23
	ld a,00fh		;7b24   ; y lo mismo con la fila
	add a,h			;7b26
	ld h,a			;7b27
	ld a,(ix+003h)		;7b28
	sub d			;7b2b
	cp h			;7b2c
	ret nc			;7b2d
	ld a,(ix+00ah)		;7b2e   ; el bit de la familia
	or c			;7b31
	ld (ix+00ah),a		;7b32   ; se apunta en (ix+00Ah)
	ld c,000h		;7b35   ; y c a cero avisa al llamante de que ha habido choque
	ret			;7b37
choque_con_las_fichas_del_lanzador:
	ld iy,0e3d5h		;7b38   ; los ocho huecos
	ld b,008h		;7b3c
	ld de,00005h		;7b3e   ; cinco bytes cada uno
choque_con_las_fichas_bucle:
	exx			;7b41   ; lo mismo, ficha a ficha
	call mira_una_ficha_del_lanzador		;7b42
	exx			;7b45
	add iy,de		;7b46
	djnz choque_con_las_fichas_bucle		;7b48
	ret			;7b4a
mira_una_ficha_del_lanzador:
	ld a,(iy+000h)		;7b4b   ; el estado, sin el bit 7
	and 07fh		;7b4e
	cp 002h		;7b50   ; solo la 2, que es la que esta volando
	ret nz			;7b52
	ld a,(iy+001h)		;7b53   ; su fila
	add a,a			;7b56
	add a,a			;7b57
	add a,a			;7b58
	ld d,a			;7b59
	ld a,(iy+002h)		;7b5a   ; y su columna
	add a,a			;7b5d
	add a,a			;7b5e
	add a,a			;7b5f
	add a,001h		;7b60
	ld e,a			;7b62
	ld h,008h		;7b63   ; ocho por cuatro pixeles
	ld l,004h		;7b65
	ld c,004h		;7b67   ; y el bit 2
	call se_tocan_los_dos		;7b69
	ld a,c			;7b6c
	and a			;7b6d
	ret nz			;7b6e
	ld (iy+003h),006h		;7b6f   ; al chocar pasa a estado 3
	ld (iy+004h),001h		;7b73   ; con su cuenta
	inc (iy+000h)		;7b77
pieza_del_golpe:
	ld a,00ch		;7b7a   ; la pieza 0x0C
pieza_si_es_el_jugador:
	ld b,a			;7b7c
	call es_el_jugador		;7b7d   ; solo suena si el que choca es el jugador
	ret nz			;7b80
	ld a,b			;7b81
	jp pide_pieza		;7b82
es_el_jugador:
	push ix		;7b85   ; la ficha que se esta moviendo
	pop hl			;7b87
	ld a,l			;7b88
	cp 010h		;7b89   ; es la del jugador si vale 0xE110, y no otra cosa
	ret nz			;7b8b
	ld a,h			;7b8c
	cp 0e1h		;7b8d
	ret			;7b8f
choque_con_las_estalactitas:
	ld iy,0e270h		;7b90   ; las once
	ld b,00bh		;7b94
	ld de,00007h		;7b96   ; siete bytes cada una
choque_con_las_estalactitas_bucle:
	exx			;7b99   ; y otra vez
	call mira_una_estalactita		;7b9a
	exx			;7b9d
	add iy,de		;7b9e
	djnz choque_con_las_estalactitas_bucle		;7ba0
	ret			;7ba2
mira_una_estalactita:
	ld a,(iy+000h)		;7ba3   ; solo la que esta cayendo
	cp 002h		;7ba6
	ret nz			;7ba8
	ld a,(iy+002h)		;7ba9   ; su fila
	add a,a			;7bac
	add a,a			;7bad
	add a,a			;7bae
	ld d,a			;7baf
	ld a,(iy+003h)		;7bb0   ; y su columna
	add a,a			;7bb3
	add a,a			;7bb4
	add a,a			;7bb5
	add a,005h		;7bb6
	ld e,a			;7bb8
	ld h,008h		;7bb9   ; ocho por cinco
	ld l,005h		;7bbb
	ld c,002h		;7bbd   ; y el bit 1
	call se_tocan_los_dos		;7bbf
	ld a,c			;7bc2
	and a			;7bc3
	ret nz			;7bc4
	ld (iy+005h),004h		;7bc5   ; al chocar se rompe
	ld (iy+006h),001h		;7bc9
	inc (iy+000h)		;7bcd
	jr pieza_del_golpe		;7bd0
choque_con_las_llamaradas:
	ld iy,0e363h		;7bd2   ; las tres
	ld b,003h		;7bd6
	ld de,00006h		;7bd8   ; seis bytes cada una
choque_con_las_llamaradas_bucle:
	exx			;7bdb   ; una llamarada cada vez
	call mira_una_llamarada		;7bdc
	exx			;7bdf
	add iy,de		;7be0
	djnz choque_con_las_llamaradas_bucle		;7be2
	ret			;7be4
mira_una_llamarada:
	ld a,(iy+000h)		;7be5   ; apagada, se salta la familia entera
	and a			;7be8
	jp z,salta_esta_familia		;7be9
	cp 003h		;7bec   ; y solo quema en la fase 3
	ret nz			;7bee
	ld a,(iy+001h)		;7bef   ; su fila
	sub 003h		;7bf2   ; tres casillas mas arriba, que es lo que sube la llama
	add a,a			;7bf4
	add a,a			;7bf5
	add a,a			;7bf6
	ld d,a			;7bf7
	ld a,(iy+002h)		;7bf8
	add a,a			;7bfb
	add a,a			;7bfc
	add a,a			;7bfd
	ld e,a			;7bfe
	ld h,028h		;7bff   ; cuarenta pixeles de alto por seis de ancho
	ld l,006h		;7c01
	ld c,008h		;7c03   ; y el bit 3
	jp se_tocan_los_dos		;7c05
choque_con_las_columnas:
	ld iy,0e248h		;7c08   ; las cinco
	ld b,005h		;7c0c
	ld de,00008h		;7c0e   ; ocho bytes cada una
choque_con_las_columnas_bucle:
	exx			;7c11   ; una columna cada vez
	call mira_una_columna		;7c12
	exx			;7c15
	add iy,de		;7c16
	djnz choque_con_las_columnas_bucle		;7c18
	ret			;7c1a
mira_una_columna:
	ld a,(iy+000h)		;7c1b   ; apagada, se salta la familia
	and a			;7c1e
	jp z,salta_esta_familia		;7c1f
	cp 002h		;7c22   ; solo la que esta creciendo
	ret nz			;7c24
	ld a,(0e062h)		;7c25   ; y en esta sala
	cp (iy+001h)		;7c28
	ret nz			;7c2b
	ld a,(iy+005h)		;7c2c   ; si ya termino, tampoco
	and a			;7c2f
	ret nz			;7c30
	ld a,(iy+007h)		;7c31   ; por donde va la punta
	dec a			;7c34
	add a,a			;7c35
	add a,a			;7c36
	add a,a			;7c37
	ld d,a			;7c38
	ld a,(iy+003h)		;7c39   ; y su columna
	add a,a			;7c3c
	add a,a			;7c3d
	add a,a			;7c3e
	add a,004h		;7c3f
	ld e,a			;7c41
	ld h,008h		;7c42   ; ocho por ocho
	ld l,h			;7c44
	ld c,010h		;7c45   ; y el bit 4
	call se_tocan_los_dos		;7c47
	ld a,c			;7c4a
	and a			;7c4b
	ret nz			;7c4c
	ld a,(ix+000h)		;7c4d   ; si el jugador esta parado, nada
	and a			;7c50
	ret z			;7c51
	ld (ix+000h),003h		;7c52   ; y si no, se cae: estado 3
	xor a			;7c56
	ld (ix+00dh),a		;7c57
	ld (ix+007h),a		;7c5a
	ld a,(ix+00ah)		;7c5d   ; el bit se quita enseguida: la columna empuja una vez, no todo el rato
	and 0efh		;7c60
	ld (ix+00ah),a		;7c62
	ret			;7c65
choque_con_las_fugas:
	ld iy,0e375h		;7c66   ; las ocho
	ld b,008h		;7c6a
	ld de,00009h		;7c6c   ; nueve bytes cada una
choque_con_las_fugas_bucle:
	exx			;7c6f   ; una fuga cada vez
	call mira_una_fuga		;7c70
	exx			;7c73
	add iy,de		;7c74
	djnz choque_con_las_fugas_bucle		;7c76
	ret			;7c78
mira_una_fuga:
	ld (iy+007h),000h		;7c79   ; se empieza sin choque
	ld a,(iy+000h)		;7c7d   ; apagada, se salta la familia
	and a			;7c80
	jp z,salta_esta_familia		;7c81
	cp 004h		;7c84   ; y solo con el chorro fuera
	ret c			;7c86
	ld d,(iy+001h)		;7c87   ; su fila
	ld c,(iy+002h)		;7c8a   ; y su columna
	ld a,(iy+003h)		;7c8d
	inc c			;7c90   ; mas una
	and a			;7c91
	jr z,fuga_su_rectangulo		;7c92
	ld a,c			;7c94
	sub 003h		;7c95
	ld c,a			;7c97
fuga_su_rectangulo:
	ld a,d			;7c98
	add a,a			;7c99
	add a,a			;7c9a
	add a,a			;7c9b
	ld d,a			;7c9c
	ld a,c			;7c9d
	add a,a			;7c9e
	add a,a			;7c9f
	add a,a			;7ca0
	ld e,a			;7ca1
	ld h,010h		;7ca2   ; dieciseis por dieciseis
	ld l,h			;7ca4
	ld c,020h		;7ca5   ; y el bit 5
	call se_tocan_los_dos		;7ca7
	ld a,c			;7caa
	and a			;7cab
	ld a,001h		;7cac
	jr z,L_7CB1		;7cae
	dec a			;7cb0
L_7CB1:
	ld (iy+007h),a		;7cb1   ; la fuga se apunta si esta tocando, para que la condicion del objeto lo vea
	ret			;7cb4
choque_con_las_bolas:
	ld iy,0e327h		;7cb5   ; las dos
	ld b,002h		;7cb9
	ld de,0000ah		;7cbb   ; diez bytes cada una
choque_con_las_bolas_bucle:
	exx			;7cbe   ; y una bola cada vez
	call mira_una_bola		;7cbf
	exx			;7cc2
	add iy,de		;7cc3
	djnz choque_con_las_bolas_bucle		;7cc5
	ret			;7cc7
mira_una_bola:
	ld a,(iy+000h)		;7cc8   ; apagada, nada
	and a			;7ccb
	ret z			;7ccc
	ld a,(iy+001h)		;7ccd   ; donde cuelga
	inc a			;7cd0
	add a,a			;7cd1
	add a,a			;7cd2
	add a,a			;7cd3
	ld b,a			;7cd4
	add a,00ch		;7cd5   ; doce pixeles mas abajo
	ld d,a			;7cd7
	ld a,(iy+002h)		;7cd8   ; y su columna
	add a,a			;7cdb
	add a,a			;7cdc
	add a,a			;7cdd
	ld c,a			;7cde
	ld e,a			;7cdf
	push bc			;7ce0
	ld h,008h		;7ce1   ; ocho por quince
	ld l,00fh		;7ce3
	ld c,040h		;7ce5   ; y el bit 6
	call se_tocan_los_dos		;7ce7
	ld a,(ix+000h)		;7cea   ; con el jugador parado, nada
	and a			;7ced
	jr z,bola_su_cadena		;7cee
	ld a,(ix+00ah)		;7cf0   ; y si le ha dado
	and 040h		;7cf3
	jr z,L_7D04		;7cf5
	call hay_suelo		;7cf7   ; y hay suelo debajo
	jr z,bola_su_cadena		;7cfa
	ld a,(ix+003h)		;7cfc   ; se le hunden cuatro pixeles: la bola aplasta
	add a,004h		;7cff
	ld (ix+003h),a		;7d01
L_7D04:
	ld a,(ix+00ah)		;7d04   ; y el bit se quita
	and 0bfh		;7d07
	ld (ix+00ah),a		;7d09
bola_su_cadena:
	pop bc			;7d0c
	ld d,b			;7d0d   ; la cadena, que es el resto del dibujo
	ld e,c			;7d0e
	ld h,004h		;7d0f   ; cuatro por quince
	ld l,00fh		;7d11
	ld c,080h		;7d13   ; y el bit 7
	call se_tocan_los_dos		;7d15
	ld a,c			;7d18
	and a			;7d19
	ret nz			;7d1a
	exx			;7d1b
	ld (ix+008h),b		;7d1c   ; se apunta con que altura choco
	exx			;7d1f
	ld a,(ix+000h)		;7d20   ; si el jugador esta andando
	and a			;7d23
	ret nz			;7d24
	call hay_techo		;7d25   ; y tiene techo encima
	ret nz			;7d28
	ld (ix+00ah),040h		;7d29   ; se le pone el bit 6: la cadena tambien aplasta
	ret			;7d2d

; ----------------------------------------------------------------------
; EL DANO
; ----------------------------------------------------------------------
dano_de_la_fuga:
	ld c,007h		;7d2e   ; el peligro 7
	jr resta_de_la_barra		;7d30
mira_que_le_ha_hecho_dano:
	ld a,(0e11ah)		;7d32   ; los choques del jugador, los mismos bits que 0x7A9E apunta
	ld c,000h		;7d35   ; c va contando cual es
	ld b,007h		;7d37   ; siete peligros
dano_bit_a_bit:
	rra			;7d39   ; el primer bit puesto manda
	jr c,dano_de_ese_peligro		;7d3a
	inc c			;7d3c
	djnz dano_bit_a_bit		;7d3d
	ret			;7d3f
dano_de_ese_peligro:
	push bc			;7d40
	call lo_para_algun_objeto		;7d41   ; si un objeto lo para, no duele
	pop bc			;7d44
	ret nz			;7d45
resta_de_la_barra:
	ld hl,07d6ah		;7d46   ; lo que quita cada peligro
	ld a,c			;7d49
	call puntero_numero_a		;7d4a
	ld hl,(0e063h)		;7d4d   ; la barra, con su fraccion
	and a			;7d50
	sbc hl,de		;7d51   ; se resta
	jr nc,resta_no_se_pasa		;7d53
	ld hl,00000h		;7d55   ; sin bajar de cero
	jr resta_pinta		;7d58
resta_no_se_pasa:
	ld a,h			;7d5a
	and a			;7d5b   ; si la parte alta queda a cero, tambien
	jr nz,resta_guarda		;7d5c
	ld h,a			;7d5e
resta_guarda:
	ld a,d			;7d5f   ; y un dano de cero no toca nada
	or e			;7d60
	jr nz,resta_pinta		;7d61
	ex de,hl			;7d63
resta_pinta:
	ld (0e063h),hl		;7d64   ; se guarda
	jp pinta_las_dos_barras		;7d67   ; y se repintan las barras

; ----------------------------------------------------------------------
; DATOS dano_de_cada_peligro: ocho palabras de dieciseis bits: lo que le quita
;   a la barra cada peligro, con su fraccion. La estalactita y la ficha del
;   lanzador son las que mas duelen (0x0800 y 0x0A00); dos de las ocho no
;   quitan nada. 0x7D46 entra con c
;   0x7d6a..0x7d7a  (16 bytes)
DATA_dano_de_cada_peligro:
	defw 00030h,00800h,00a00h,00060h,00000h,00040h,00000h,00040h	; 7d6a

; ======================================================================
; CODIGO 0x7d7a..0x7d9b  (33 bytes)
; ======================================================================


lo_para_algun_objeto:
	ld a,c			;7d7a   ; la lista de objetos que protegen
	ld de,07d9bh		;7d7b
	call suma_a_a_de		;7d7e
	ld a,(de)			;7d81   ; el de este peligro
mira_ese_objeto:
	cp 0ffh		;7d82   ; con 0xFF no hay objeto que valga
	ret z			;7d84
	ld c,a			;7d85
	push bc			;7d86
	call se_lleva_el_objeto		;7d87   ; si no se lleva, tampoco
	pop bc			;7d8a
	ret z			;7d8b
	ld a,c			;7d8c
	ld hl,0e150h		;7d8d   ; los usos que le quedan
	call suma_a_a_hl		;7d90
	dec (hl)			;7d93   ; se gasta uno
	ret nz			;7d94
	call saca_del_inventario		;7d95   ; y al acabarse, el objeto se pierde
	or 001h		;7d98   ; pero el golpe queda parado igual
	ret			;7d9a

; ----------------------------------------------------------------------
; DATOS objeto_que_para_cada_peligro: ocho bytes, uno por peligro: que objeto
;   del inventario lo para, o 0xFF si no lo para ninguno. Llevandolo, en vez
;   de energia se gasta un uso, y al acabarse se pierde
;   0x7d9b..0x7da3  (8 bytes)
DATA_objeto_que_para_cada_peligro:
	defb 008h,010h,00ah,00bh,0ffh,009h,0ffh,0ffh	; 7d9b  ........

; ======================================================================
; CODIGO 0x7da3..0x8149  (934 bytes)
; ======================================================================


perseguidor_recibe:
	call caja_grande		;7da3   ; su caja
	ld b,001h		;7da6   ; el codigo 1
	ld a,(ix+011h)		;7da8   ; su clase
	cp 005h		;7dab
	jr c,perseguidor_le_han_dado		;7dad
	ld b,005h		;7daf   ; y de la 5 en adelante, el 5
perseguidor_le_han_dado:
	push bc			;7db1
	call toca_al_jugador_con_codigo		;7db2   ; si el jugador no le toca, nada
	pop bc			;7db5
	ret z			;7db6
	ld a,(0e1b1h)		;7db7   ; con algo en marcha
	and a			;7dba
	jr nz,L_7DF9		;7dbb
	push bc			;7dbd
	call separa_al_jugador_del_bicho		;7dbe   ; se separan
	pop bc			;7dc1
	ld a,b			;7dc2
	dec a			;7dc3
	ret z			;7dc4
	ld a,(0e1b0h)		;7dc5   ; y solo se lleva golpe si (0xE1B0) vale 2
	cp 002h		;7dc8
	jr z,L_7E00		;7dca
	ret			;7dcc
perseguidor_recibe_patada:
	ld a,(0e111h)		;7dcd   ; la sala del jugador
	cp (ix+001h)		;7dd0   ; contra la suya
	ret nz			;7dd3
	call caja_grande		;7dd4   ; su caja
	ld b,002h		;7dd7   ; el codigo 2
	ld a,(ix+011h)		;7dd9
	cp 005h		;7ddc
	jr nc,L_7DEB		;7dde
	ld bc,(0e14eh)		;7de0   ; y para las clases bajas, uno por cada bicho
	ld a,001h		;7de4
perseguidor_codigo_por_bicho:
	add a,010h		;7de6
	djnz perseguidor_codigo_por_bicho		;7de8
	ld b,a			;7dea
L_7DEB:
	call le_da_una_patada_con_codigo		;7deb   ; si no hay patada
	jp z,perseguidor_recibe		;7dee   ; se prueba con el toque
	ld c,000h		;7df1
	ld a,(0e1b1h)		;7df3
	and a			;7df6
	jr z,L_7E02		;7df7
L_7DF9:
	ld c,001h		;7df9
	ld de,01000h		;7dfb
	jr L_7E14		;7dfe
L_7E00:
	ld c,001h		;7e00
L_7E02:
	ld de,00100h		;7e02
	ld a,(ix+011h)		;7e05
	cp 005h		;7e08
	jr nc,L_7E0E		;7e0a
	ld d,002h		;7e0c
L_7E0E:
	ld a,006h		;7e0e
	ld b,060h		;7e10
	jr c,perseguidor_apunta_el_golpe		;7e12
L_7E14:
	ld a,00bh		;7e14
	ld b,010h		;7e16
perseguidor_apunta_el_golpe:
	ld (ix+01dh),c		;7e18   ; si el golpe cuenta
	ld (ix+010h),a		;7e1b   ; el estado nuevo
	ld (ix+017h),b		;7e1e   ; y su cuenta
	jr nc,L_7E2F		;7e21
	ld (ix+00dh),000h		;7e23   ; sin recorrido
	ld a,(ix+000h)		;7e27   ; si venia andando, se cae
	and a			;7e2a
	ld a,003h		;7e2b
	jr nz,L_7E30		;7e2d
L_7E2F:
	xor a			;7e2f
L_7E30:
	ld (ix+000h),a		;7e30
	ld (ix+007h),a		;7e33
pieza_del_choque:
	call suma_c_cero		;7e36   ; los puntos que da
	ld a,003h		;7e39   ; y la pieza 3
	jp pide_pieza		;7e3b
caja_grande:
	ld a,(ix+003h)		;7e3e   ; la fila
	sub 00dh		;7e41   ; trece pixeles mas arriba
	ld d,a			;7e43
	ld a,(ix+005h)		;7e44   ; la columna
	sub 003h		;7e47   ; tres a la izquierda
	ld e,a			;7e49
	ld h,00bh		;7e4a   ; once de alto por seis de ancho
	ld l,006h		;7e4c
	ret			;7e4e
caja_de_dos_por_dos:
	ld d,(ix+003h)		;7e4f   ; sin desplazar
	ld e,(ix+005h)		;7e52
	ld h,002h		;7e55   ; dos por dos
	ld l,002h		;7e57
	ld a,(ix+007h)		;7e59   ; y el codigo, del 2 al 4 segun por donde vaya
	ld b,002h		;7e5c
	and a			;7e5e
	jr z,caja_de_dos_por_dos_mira		;7e5f
	inc b			;7e61
	dec a			;7e62
	jr z,caja_de_dos_por_dos_mira		;7e63
	inc b			;7e65
caja_de_dos_por_dos_mira:
	jp toca_al_jugador_con_codigo		;7e66
caja_de_siete_por_siete:
	ld a,(ix+003h)		;7e69
	add a,0fch		;7e6c   ; cuatro pixeles arriba
	ld d,a			;7e6e
	ld a,(ix+005h)		;7e6f   ; y cuatro a la izquierda
	add a,0fch		;7e72
	ld e,a			;7e74
	ld h,007h		;7e75   ; siete por siete
	ld l,007h		;7e77
	ld b,003h		;7e79   ; el codigo 3
	call le_da_una_patada_con_codigo		;7e7b   ; y solo cuenta a patadas
	ret z			;7e7e
	ld de,00100h		;7e7f   ; 0x0100 puntos
	jr remata_el_choque		;7e82
mira_si_lo_toca_el_jugador:
	call caja_de_ocho_por_seis		;7e84
	ld b,006h		;7e87   ; el codigo 6
	call toca_al_jugador_con_codigo		;7e89
	ret z			;7e8c
	ld a,(0e1b1h)		;7e8d   ; con la partida parada
	and a			;7e90
	jr nz,puntos_gordos		;7e91
	ld a,(0e1b0h)		;7e93   ; solo cuenta si (0xE1B0) vale 2
	cp 002h		;7e96
	jr z,puntos_normales		;7e98
	ret			;7e9a
mira_si_le_da_una_patada:
	call caja_de_ocho_por_seis		;7e9b
	ld b,004h		;7e9e   ; el codigo 4
	call le_da_una_patada_con_codigo		;7ea0   ; y si no hay patada
	jr z,mira_si_lo_toca_el_jugador		;7ea3   ; se prueba con el toque
	ld a,(0e1b1h)		;7ea5
	and a			;7ea8
	jr z,puntos_normales		;7ea9
puntos_gordos:
	ld de,01000h		;7eab   ; 0x1000 puntos
	jr se_pone_en_el_estado_9		;7eae
puntos_normales:
	ld de,00050h		;7eb0   ; y 0x50
se_pone_en_el_estado_9:
	ld (ix+000h),009h		;7eb3
remata_el_choque:
	call pieza_del_choque		;7eb7   ; los puntos y la pieza
	or 001h		;7eba   ; y se vuelve diciendo que si
	ret			;7ebc
caja_de_ocho_por_seis:
	ld a,(ix+003h)		;7ebd
	add a,0f6h		;7ec0   ; diez pixeles arriba
	ld d,a			;7ec2
	ld a,(ix+005h)		;7ec3   ; tres a la izquierda
	add a,0fdh		;7ec6
	ld e,a			;7ec8
	ld h,008h		;7ec9   ; ocho por seis
	ld l,006h		;7ecb
	ret			;7ecd
mira_toque_del_otro:
	call caja_de_cuatro_por_ocho		;7ece   ; su caja
	ld b,007h		;7ed1   ; el codigo 7
	call toca_al_jugador_con_codigo		;7ed3   ; y si el jugador no la toca, nada
	ret z			;7ed6
	ld a,(0e1b1h)		;7ed7
	and a			;7eda
	jr nz,puntos_gordos_2		;7edb
	ld a,(0e1b0h)		;7edd   ; con (0xE1B0) a 2, el golpe cuenta
	cp 002h		;7ee0
	jr z,puntos_normales_2		;7ee2
	ret			;7ee4
mira_patada_del_otro:
	call caja_de_cuatro_por_ocho		;7ee5
	ld b,005h		;7ee8   ; el codigo 5
	call le_da_una_patada_con_codigo		;7eea
	jr z,mira_toque_del_otro		;7eed
	ld a,(0e1b1h)		;7eef
	and a			;7ef2
	jr z,puntos_normales_2		;7ef3
puntos_gordos_2:
	ld de,01000h		;7ef5
	jr se_pone_en_el_estado_11		;7ef8
puntos_normales_2:
	ld de,00100h		;7efa
se_pone_en_el_estado_11:
	ld (ix+000h),00bh		;7efd
	jr remata_el_choque		;7f01
caja_por_debajo:
	ld b,0bah		;7f03   ; 0xBA: setenta pixeles por debajo
	jr caja_a_esa_altura		;7f05
caja_por_encima:
	ld b,03ah		;7f07   ; 0x3A: cincuenta y ocho por encima
caja_a_esa_altura:
	ld a,(ix+004h)		;7f09   ; la columna
	add a,b			;7f0c
	ld e,a			;7f0d
	ld a,(ix+002h)		;7f0e   ; y la fila
	add a,0fah		;7f11   ; seis pixeles arriba
	ld d,a			;7f13
	jr caja_de_cuatro_por_ocho_2		;7f14
caja_de_cuatro_por_ocho:
	ld a,(ix+00ch)		;7f16   ; la fila que se pinta
	add a,0fah		;7f19   ; seis arriba
	ld d,a			;7f1b
	ld a,(ix+004h)		;7f1c   ; y la columna, seis a la izquierda
	add a,0fah		;7f1f
	ld e,a			;7f21
caja_de_cuatro_por_ocho_2:
	ld h,004h		;7f22   ; cuatro de alto por ocho de ancho
	ld l,008h		;7f24
	ret			;7f26
mira_por_arriba_y_por_abajo:
	call caja_por_debajo		;7f27   ; primero por debajo
	call toca_al_jugador		;7f2a
	jr nz,L_7F36		;7f2d
	call caja_por_encima		;7f2f   ; y luego por encima
	call toca_al_jugador		;7f32
	ret z			;7f35
L_7F36:
	inc (ix+000h)		;7f36   ; con cualquiera de las dos, se avanza de estado
	ret			;7f39
mira_el_choque_de_la_ficha:
	ld a,(0e111h)		;7f3a   ; la sala del jugador
	cp (ix+001h)		;7f3d   ; contra la de la ficha
	ret nz			;7f40
	ld a,(ix+002h)		;7f41   ; la fila, siete arriba
	add a,0f9h		;7f44
	ld d,a			;7f46
	ld a,(ix+004h)		;7f47   ; la columna, cuatro a la izquierda
	add a,0fch		;7f4a
	ld e,a			;7f4c
	ld h,00ah		;7f4d   ; diez por ocho
	ld l,008h		;7f4f
	call toca_al_jugador		;7f51
	ret z			;7f54
	ld (ix+000h),003h		;7f55   ; al chocar, estado 3
	ld de,00500h		;7f59   ; 0x0500 puntos
	call suma_c_cero		;7f5c
	ld a,00bh		;7f5f   ; y la pieza 0x0B
	jp pide_pieza		;7f61
toca_al_jugador:
	ld b,000h		;7f64   ; sin codigo que apuntar
toca_al_jugador_con_codigo:
	ld a,006h		;7f66   ; seis pixeles de margen por abajo
	add a,l			;7f68
	ld l,a			;7f69
	ld a,(0e115h)		;7f6a   ; la columna del jugador
	add a,003h		;7f6d   ; tres pixeles de margen
	sub e			;7f6f
	cp l			;7f70   ; tiene que caer dentro del ancho
	jr nc,no_le_toca		;7f71
	ld a,00bh		;7f73   ; y once de margen por arriba
	add a,h			;7f75
	ld h,a			;7f76
	ld a,(0e113h)		;7f77   ; con su fila
	sub 002h		;7f7a
	sub d			;7f7c
	cp h			;7f7d
	jr nc,no_le_toca		;7f7e
	ld a,b			;7f80   ; sin codigo, solo se dice que si
	and a			;7f81
	jr z,si_le_toca		;7f82
	ld a,(0e1b1h)		;7f84   ; con algo en marcha, tampoco duele
	and a			;7f87
	jr nz,si_le_toca		;7f88
	ld a,(0e11fh)		;7f8a   ; ni mientras dure la espera de (0xE11F)
	and a			;7f8d
	jr nz,si_le_toca		;7f8e
	push bc			;7f90
	call lleva_el_objeto_de_la_lista		;7f91   ; se mira si algun objeto lo para
	ld a,c			;7f94
	ld (0e1b0h),a		;7f95   ; y (0xE1B0) se queda con el resultado
	pop bc			;7f98
	ld c,090h		;7f99   ; la pieza 0x90, que no suena
	dec a			;7f9b
	jr z,golpe_parado		;7f9c
	ld c,000h		;7f9e   ; o ninguna
	dec a			;7fa0
	jr z,guarda_la_espera_del_golpe		;7fa1
	ld a,b			;7fa3   ; y si hay codigo
	and a			;7fa4
	jr z,golpe_al_jugador		;7fa5
	add a,005h		;7fa7   ; se le suman cinco: el mismo sitio tocado y golpeado son cosas distintas
golpe_al_jugador:
	push bc			;7fa9   ; se apunta
	ld b,a			;7faa
	call apunta_el_golpe		;7fab
	pop bc			;7fae
	call baja_la_primera_barra		;7faf   ; se le quita de la barra
	ld c,020h		;7fb2   ; 0x20 cuadros sin poder volver a hacerle dano
	ld a,00ch		;7fb4   ; y la pieza 0x0C
	jr suena_el_golpe		;7fb6
golpe_parado:
	ld a,007h		;7fb8   ; la pieza 7: el objeto lo ha parado
suena_el_golpe:
	call pide_pieza		;7fba
guarda_la_espera_del_golpe:
	ld a,c			;7fbd
	ld (0e11fh),a		;7fbe
si_le_toca:
	or 001h		;7fc1
	ret			;7fc3
no_le_toca:
	xor a			;7fc4
	ret			;7fc5
le_da_una_patada:
	ld b,000h		;7fc6   ; sin codigo
le_da_una_patada_con_codigo:
	ld a,(0e110h)		;7fc8   ; el estado del jugador
	cp 004h		;7fcb   ; el 4 es la patada de pie
	jr z,patada_por_delante		;7fcd
	cp 005h		;7fcf   ; y el 5 la del aire
	jr z,patada_por_delante		;7fd1
	jr no_le_toca		;7fd3   ; con cualquier otro, no hay patada
patada_por_delante:
	ld a,003h		;7fd5   ; tres pixeles mas
	add a,l			;7fd7
	ld l,a			;7fd8
	ld c,00ah		;7fd9   ; diez por delante
	ld a,(0e11bh)		;7fdb   ; a que lado mira
	and a			;7fde
	jr z,patada_dentro		;7fdf
	ld c,0f9h		;7fe1   ; o siete por detras
patada_dentro:
	ld a,(0e115h)		;7fe3   ; la columna del jugador
	add a,c			;7fe6
	sub e			;7fe7
	cp l			;7fe8   ; tiene que caer dentro
	jr nc,no_le_toca		;7fe9
	ld a,003h		;7feb   ; tres pixeles de margen
	add a,h			;7fed
	ld h,a			;7fee
	ld a,(0e113h)		;7fef   ; y la fila, ocho mas arriba
	add a,0f8h		;7ff2
	sub d			;7ff4
	cp h			;7ff5
	jr nc,no_le_toca		;7ff6
	call apunta_el_golpe		;7ff8   ; y si cuadra, se apunta el codigo
	ld a,b			;7ffb   ; si el codigo era cero, no da nada
	and a			;7ffc
	jr z,si_le_toca		;7ffd
	dec b			;7fff   ; y si no, sube la segunda barra
	call sube_la_segunda_barra		;8000
	jr si_le_toca		;8003
apunta_el_golpe:
	ld a,b			;8005   ; con codigo cero no se apunta nada
	and a			;8006
	ret z			;8007
	ld hl,0e126h		;8008   ; el ultimo golpe
	ld a,(hl)			;800b
	ld (hl),b			;800c   ; pasa a ser el penultimo
	inc hl			;800d
	ld (hl),a			;800e   ; y este ocupa su sitio
	ld a,b			;800f
	and 00fh		;8010
	ld b,a			;8012
	ld a,001h		;8013   ; (0xE128) avisa de que acaba de haber uno: las condiciones de los objetos lo consumen
	ld (0e128h),a		;8015
	ret			;8018

; ----------------------------------------------------------------------
; COGER UN TRASTO DE LOS QUE PARPADEAN
; ----------------------------------------------------------------------
mira_los_trastos:
	ld ix,0e2ddh		;8019   ; el tipo 4 de la lista del nivel
	ld b,004h		;801d   ; cuatro por nivel
	ld de,00004h		;801f   ; cuatro bytes de ficha
mira_los_trastos_bucle:
	exx			;8022   ; un trasto cada vez
	call mira_un_trasto		;8023
	exx			;8026
	add ix,de		;8027
	djnz mira_los_trastos_bucle		;8029
	ret			;802b
mira_un_trasto:
	ld a,(0e121h)		;802c   ; si ya se cogio uno en esta sala, ninguno mas
	and a			;802f
	ret nz			;8030
	ld a,(ix+000h)		;8031   ; apagado, nada
	and a			;8034
	ret z			;8035
	ld a,(0e062h)		;8036   ; ni si esta en otra sala
	cp (ix+001h)		;8039
	ret nz			;803c
	ld b,(ix+003h)		;803d   ; su columna
	ld a,(ix+002h)		;8040   ; y su fila
	call caja_de_ocho_por_ocho		;8043   ; si el jugador no lo toca, nada
	ret z			;8046
	call borra_el_trasto		;8047   ; se borra de la pantalla
	ld a,00ah		;804a   ; la pieza 0x0A
	call pide_pieza		;804c
	ld (ix+000h),000h		;804f   ; y la ficha se apaga
	ld a,(0e110h)		;8053   ; si se cogio dando una patada en el aire
	cp 005h		;8056
	jr nz,marca_el_trasto_cogido		;8058
	push ix		;805a
	ld b,005h		;805c
	call saca_el_objeto_de_esa_clase		;805e   ; sale el objeto de la clase 5
	pop ix		;8061
marca_el_trasto_cogido:
	exx			;8063
	ld a,b			;8064
	exx			;8065
	ld b,a			;8066   ; cual de los cuatro era
	ld a,004h		;8067   ; se numeran al reves
	sub b			;8069
	ld b,a			;806a
	push bc			;806b
	call donde_vive_la_marca_del_trasto		;806c   ; donde se guarda su marca
	pop bc			;806f
	ld a,001h		;8070   ; un nibble por trasto
	jr nc,L_8076		;8072
	ld a,010h		;8074   ; y el otro nibble si es de los de arriba
L_8076:
	inc b			;8076
rota_hasta_su_bit:
	dec b			;8077
	jr z,pon_la_marca_del_trasto		;8078
	sla a		;807a
	jr rota_hasta_su_bit		;807c
pon_la_marca_del_trasto:
	or (hl)			;807e   ; se enciende
	ld (hl),a			;807f
	ld a,001h		;8080   ; (0xE121) dice que en esta sala ya se cogio uno
	ld (0e121h),a		;8082
	push ix		;8085
	ld b,019h		;8087   ; y salen los objetos de las clases 0x19
	call saca_el_objeto_de_esa_clase		;8089
	ld b,010h		;808c   ; y 0x10
	call saca_el_objeto_de_esa_clase		;808e
	pop ix		;8091
	ld de,00200h		;8093   ; mas 0x0200 puntos
	jp suma_c_cero		;8096
caja_de_ocho_por_ocho:
	add a,a			;8099   ; la fila, de casillas a pixeles
	add a,a			;809a
	add a,a			;809b
	ld d,a			;809c
	ld a,b			;809d   ; y la columna
	add a,a			;809e
	add a,a			;809f
	add a,a			;80a0
	ld e,a			;80a1
	ld h,008h		;80a2   ; ocho por ocho
	ld l,h			;80a4
	jp toca_al_jugador		;80a5
borra_el_trasto:
	ld l,(ix+002h)		;80a8   ; su sitio
	ld h,(ix+003h)		;80ab
	call casilla_de_la_pantalla		;80ae   ; en la pantalla
	call 0004ah		;80b1   ; BIOS RDVRM - Reads the content of VRAM | lo que haya ahi
	and a			;80b4
	jr z,borra_esa_casilla		;80b5
	cp 086h		;80b7   ; y solo se borra si sigue siendo el trasto
	ret nz			;80b9
borra_esa_casilla:
	xor a			;80ba
	jp 0004dh		;80bb   ; BIOS WRTVRM - Writes data in VRAM
caja_de_la_bola:
	ld hl,0e328h		;80be   ; la primera bola de la sala
	ld a,(hl)			;80c1
	inc a			;80c2   ; una fila mas abajo
	add a,a			;80c3
	add a,a			;80c4
	add a,a			;80c5
	add a,004h		;80c6
	ld d,a			;80c8
	inc hl			;80c9
	ld a,(hl)			;80ca
	add a,a			;80cb
	add a,a			;80cc
	add a,a			;80cd
	ld e,a			;80ce
	ld h,014h		;80cf   ; veinte por dieciseis
	ld l,010h		;80d1
	jp le_da_una_patada		;80d3   ; y a patadas
caja_de_la_columna:
	ld iy,0e248h		;80d6   ; la primera columna del nivel
	ld a,(iy+000h)		;80da
	cp 001h		;80dd   ; si esta esperando, no
	ret z			;80df
	ld a,(iy+002h)		;80e0   ; su fila
	add a,a			;80e3
	add a,a			;80e4
	add a,a			;80e5
	ld d,a			;80e6
	ld a,(iy+003h)		;80e7   ; y su columna
	add a,a			;80ea
	add a,a			;80eb
	add a,a			;80ec
	add a,004h		;80ed
	ld e,a			;80ef
	ld a,(iy+005h)		;80f0   ; si esta quieta
	and a			;80f3
	ld a,(iy+004h)		;80f4   ; mide lo que le toca
	jr nz,L_8100		;80f7
	ld a,(iy+007h)		;80f9   ; y si crece, lo que lleva crecido
	sub (iy+002h)		;80fc
	inc a			;80ff
L_8100:
	add a,a			;8100
	add a,a			;8101
	add a,a			;8102
	ld h,a			;8103
	ld l,008h		;8104   ; por ocho de ancho
	jp le_da_una_patada		;8106   ; y a patadas
caja_del_lanzador:
	ld a,(0e3bdh)		;8109   ; si no hay ninguno, nada
	and a			;810c
	ret z			;810d
	ld hl,0e12ah		;810e   ; el sitio que 0x6165 dejo calculado
	ld a,(hl)			;8111
	add a,a			;8112
	add a,a			;8113
	add a,a			;8114
	ld d,a			;8115
	inc hl			;8116
	ld a,(hl)			;8117
	add a,a			;8118
	add a,a			;8119
	add a,a			;811a
	add a,002h		;811b
	ld e,a			;811d
	ld h,008h		;811e   ; ocho por cuatro
	ld l,004h		;8120
	jp toca_al_jugador		;8122
lleva_el_objeto_de_la_lista:
	ld a,b			;8125   ; de la clase 5 en adelante
	cp 005h		;8126
	jr c,lleva_el_objeto_normal		;8128
	add a,003h		;812a   ; se prueba primero tres mas alla
	call mira_el_objeto_de_la_lista		;812c
	ld c,002h		;812f   ; y si lo lleva, c vale 2
	ret nz			;8131
	ld a,b			;8132
lleva_el_objeto_normal:
	call mira_el_objeto_de_la_lista		;8133   ; y si no, el suyo
	ld c,000h		;8136   ; c a cero si no lo lleva
	ret z			;8138
	inc c			;8139
	ret			;813a
mira_el_objeto_de_la_lista:
	push bc			;813b
	dec a			;813c
	ld de,08149h		;813d   ; la lista de objetos
	call suma_a_a_de		;8140
	ld a,(de)			;8143
	call mira_ese_objeto		;8144   ; y se gasta un uso, como en el dano
	pop bc			;8147
	ret			;8148

; ----------------------------------------------------------------------
; DATOS objeto_que_para_cada_bicho: diez bytes, uno por clase de bicho: que
;   objeto del inventario para su golpe, o 0xFF si no lo para ninguno. El
;   mismo mecanismo que el de los peligros de 0x7D9B
;   0x8149..0x8153  (10 bytes)
DATA_objeto_que_para_cada_bicho:
	defb 0ffh,00ch,00dh,00eh,001h,003h,00fh,002h,005h,007h	; 8149  ..........

; ======================================================================
; CODIGO 0x8153..0x81e9  (150 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL EMPUJON: EL JUGADOR Y EL BICHO NO CABEN EN EL MISMO SITIO
; ----------------------------------------------------------------------
separa_al_jugador_del_bicho:
	ld d,000h		;8153
	ld a,(0e110h)		;8155   ; con el jugador andando
	cp 002h		;8158
	jr nz,L_815D		;815a
	inc d			;815c
L_815D:
	ld e,000h		;815d
	ld a,(ix+000h)		;815f   ; y el bicho tambien
	cp 002h		;8162
	jr nz,L_8168		;8164
	ld e,002h		;8166
L_8168:
	ld a,e			;8168
	or d			;8169
	ld e,a			;816a
	cp 003h		;816b   ; si los dos estan quietos
	jr nz,empuja_a_los_dos		;816d
	ld a,(0e113h)		;816f   ; se mira quien esta mas arriba
	cp (ix+003h)		;8172
	ld a,001h		;8175
	jr c,L_817A		;8177
	inc a			;8179
L_817A:
	ld (ix+016h),a		;817a   ; y se apunta, sin empujar
	ret			;817d
empuja_a_los_dos:
	push de			;817e
	ld a,(0e115h)		;817f   ; la columna del jugador
	sub (ix+005h)		;8182   ; contra la del bicho
	push af			;8185
	jr c,L_818D		;8186
	call pared_a_la_izquierda		;8188   ; se mira si el bicho tiene pared por su lado
	jr empuja_mira_al_jugador		;818b
L_818D:
	call pared_a_la_derecha		;818d   ; o por el otro
empuja_mira_al_jugador:
	pop af			;8190
	push ix		;8191
	ld ix,0e110h		;8193   ; y lo mismo con el jugador
	jr c,empuja_pared_del_jugador		;8197
	call pared_a_la_derecha		;8199
	jr empuja_reparte		;819c
empuja_pared_del_jugador:
	call pared_a_la_izquierda		;819e
empuja_reparte:
	pop ix		;81a1
	pop de			;81a3
	ld a,(0e115h)		;81a4   ; la columna del jugador
	ld c,a			;81a7
	ld b,(ix+005h)		;81a8   ; y la del bicho
	sub b			;81ab   ; lo que se llevan
	push af			;81ac
	jr nc,empuja_calcula		;81ad
	neg		;81af
empuja_calcula:
	and a			;81b1
	rra			;81b2   ; la mitad
	ld d,a			;81b3
	ld a,005h		;81b4   ; y cinco menos: cuanto mas juntos, mas fuerte
	sub d			;81b6
	ld d,a			;81b7
	neg		;81b8
	ld h,a			;81ba
	call reparte_el_empujon		;81bb   ; se reparte entre los dos
	ld e,h			;81be
	pop af			;81bf
	ld hl,081e9h		;81c0   ; y las dos ternas dicen como quedan
	jr nc,L_81D0		;81c3
	ld hl,081ech		;81c5
	ld a,d			;81c8
	neg		;81c9
	ld d,a			;81cb
	ld a,e			;81cc
	neg		;81cd
	ld e,a			;81cf
L_81D0:
	ld a,c			;81d0   ; el jugador se mueve
	add a,d			;81d1
	ld (0e115h),a		;81d2
	ld a,b			;81d5   ; el bicho tambien
	add a,e			;81d6
	ld (ix+005h),a		;81d7
	ld a,(hl)			;81da   ; y los tres bytes que rematan: (0xE116), (ix+015h) y (ix+006h)
	ld (0e116h),a		;81db
	inc hl			;81de
	ld a,(hl)			;81df
	ld (ix+015h),a		;81e0
	inc hl			;81e3
	ld a,(hl)			;81e4
	ld (ix+006h),a		;81e5
	ret			;81e8

; ----------------------------------------------------------------------
; DATOS dos_ternas: 0x81E9 y 0x81EC, tres bytes cada una; 0x81C0 elige una y
;   0x81C5 la otra segun el acarreo
;   0x81e9..0x81ef  (6 bytes)
DATA_dos_ternas:
	defb 002h,003h,001h	; 81e9
	defb 001h,002h,002h	; 81ec

; ======================================================================
; CODIGO 0x81ef..0x824c  (93 bytes)
; ======================================================================


reparte_el_empujon:
	ld a,e			;81ef   ; si el jugador estaba quieto
	and a			;81f0
	jr z,L_81F8		;81f1
	dec a			;81f3
	jr z,empujon_todo_al_bicho		;81f4
	jr empujon_todo_al_jugador		;81f6
L_81F8:
	ld a,(0e11eh)		;81f8   ; y (0xE11E) no dice lo contrario
	and a			;81fb
	jr nz,empujon_todo_al_bicho		;81fc
	ld a,(ix+00eh)		;81fe   ; con el bicho tampoco chocado, no se empuja a nadie
	and a			;8201
	ret z			;8202
empujon_todo_al_jugador:
	ld a,d			;8203
	rla			;8204
	ld a,003h		;8205   ; tres pixeles
	jr c,L_820B		;8207
	neg		;8209
L_820B:
	ld e,a			;820b
	ld a,d			;820c
	add a,a			;820d   ; mas el triple de lo calculado
	add a,e			;820e
	ld d,a			;820f
	ld h,000h		;8210   ; y el bicho no se mueve
	ret			;8212
empujon_todo_al_bicho:
	ld a,h			;8213
	rla			;8214
	ld a,003h		;8215
	jr c,L_821B		;8217
	neg		;8219
L_821B:
	ld e,a			;821b
	ld a,h			;821c
	add a,a			;821d
	add a,e			;821e
	ld h,a			;821f
	ld d,000h		;8220   ; y aqui al reves
	ret			;8222

; ----------------------------------------------------------------------
; LAS TRES JAULAS, POR ESTADO
; ----------------------------------------------------------------------
reparte_las_jaulas:
	ld ix,0e2f9h		;8223   ; el tipo 5 de la lista del nivel
	ld b,003h		;8227   ; tres
reparte_las_jaulas_bucle:
	push bc			;8229
	call reparte_una_jaula		;822a
	pop bc			;822d
	ld de,00006h		;822e   ; seis bytes de ficha
	add ix,de		;8231
	djnz reparte_las_jaulas_bucle		;8233
	ret			;8235
reparte_una_jaula:
	ld a,(ix+000h)		;8236   ; apagada, nada
	and a			;8239
	ret z			;823a
	ld a,(0e062h)		;823b   ; ni en otra sala
	cp (ix+001h)		;823e
	ret nz			;8241
	ld a,b			;8242
	ld (0e1c0h),a		;8243   ; cual de las tres es
	ld a,(ix+005h)		;8246   ; y su estado manda
	call reparte_por_tabla		;8249

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_824c: 4 entradas; detras sigue la primera, 0x8254
;   0x824c..0x8254  (8 bytes)
DATA_tabla_de_subescenas_824c:
	defw 08254h,08284h,08285h,082d3h	; 824c  -> jaula_cerrada jaula_abierta_y_vacia jaula_con_el_amigo jaula_con_el_frasco

; ======================================================================
; CODIGO 0x8254..0x8385  (305 bytes)
; ======================================================================


jaula_cerrada:
	ld a,(0e121h)		;8254   ; sin la llave no se abre
	and a			;8257
	ret z			;8258
	ld b,00ah		;8259   ; su rectangulo, diez pixeles mas abajo
	ld c,0f8h		;825b
	call rectangulo_de_la_ficha		;825d
	ld h,010h		;8260
	ld l,008h		;8262
	call toca_al_jugador		;8264   ; y si el jugador no la toca, nada
	ret z			;8267
	xor a			;8268   ; la llave se gasta
	ld (0e121h),a		;8269
	ld a,(0e1c0h)		;826c   ; cual de las tres es
	ld b,a			;826f
	call donde_esta_ese_estado		;8270   ; donde vive su medio byte
	ld a,001h		;8273
	bit 0,b		;8275   ; el nibble de abajo
	jr z,L_827B		;8277
	ld a,010h		;8279   ; o el de arriba
L_827B:
	add a,(hl)			;827b   ; se le suma uno: pasa al estado siguiente
	ld (hl),a			;827c
	ld a,008h		;827d   ; con la pieza 8
	call pide_pieza		;827f
	jr repinta_la_jaula		;8282
jaula_abierta_y_vacia:
	ret			;8284   ; no hay nada que hacer
jaula_con_el_amigo:
	call toca_la_jaula		;8285   ; si el jugador no llega, nada
	ret z			;8288
	ld a,(0e1c0h)		;8289   ; cual es
	ld b,a			;828c
	call donde_esta_ese_estado		;828d
	ld a,008h		;8290   ; al estado 3
	bit 0,b		;8292
	jr z,L_8298		;8294
	ld a,080h		;8296   ; en su nibble
L_8298:
	or (hl)			;8298
	ld (hl),a			;8299
	ld hl,0e130h		;829a   ; un amigo mas
	inc (hl)			;829d
	ld de,0e075h		;829e   ; la fila de abajo, donde se ensenan
	ld b,001h		;82a1
pinta_los_amigos:
	ld a,b			;82a3
	cp 005h		;82a4   ; los cuatro primeros con una casilla
	ld a,002h		;82a6
	jr c,L_82AB		;82a8
	inc a			;82aa   ; y del quinto en adelante, con otra
L_82AB:
	ld (de),a			;82ab
	inc de			;82ac
	ld a,b			;82ad
	inc b			;82ae
	cp (hl)			;82af   ; hasta llegar a los que hay
	jr c,pinta_los_amigos		;82b0
	ld de,02000h		;82b2   ; 0x2000 puntos
	call suma_c_cero		;82b5
	ld a,(0e1b1h)		;82b8   ; y si no hay nada en marcha
	and a			;82bb
	jr nz,L_82C3		;82bc
	ld a,098h		;82be   ; suena la pieza 0x98
	call pide_pieza		;82c0
L_82C3:
	push ix		;82c3
	ld b,01ah		;82c5   ; sale el objeto de la clase 0x1A
	call saca_el_objeto_de_esa_clase		;82c7
	pop ix		;82ca
repinta_la_jaula:
	ld a,(0e1c0h)		;82cc   ; cual era
	ld b,a			;82cf
	jp L_6006		;82d0   ; y se repinta con su estado nuevo
jaula_con_el_frasco:
	call toca_la_jaula		;82d3   ; si el jugador no llega, nada
	ret z			;82d6
	ld a,(0e1c0h)		;82d7
	ld b,a			;82da
	call donde_esta_ese_estado		;82db
	ld a,004h		;82de   ; al estado 2
	bit 0,b		;82e0
	jr z,L_82E6		;82e2
	ld a,040h		;82e4
L_82E6:
	or (hl)			;82e6
	ld (hl),a			;82e7
	ld de,00500h		;82e8   ; 0x0500 puntos
	call suma_c_cero		;82eb
	ld b,008h		;82ee   ; ocho de barra
	call sube_la_primera_barra		;82f0
	ld a,089h		;82f3   ; y la pieza 0x89
	call pide_pieza		;82f5
	jr repinta_la_jaula		;82f8
toca_la_jaula:
	ld b,010h		;82fa   ; dieciseis pixeles mas abajo
	ld c,008h		;82fc   ; y ocho a la derecha
	call rectangulo_de_la_ficha		;82fe
	ld h,008h		;8301   ; ocho por ocho
	ld l,008h		;8303
	jp toca_al_jugador		;8305
rectangulo_de_la_ficha:
	ld a,(ix+002h)		;8308   ; la fila, de casillas a pixeles
	add a,a			;830b
	add a,a			;830c
	add a,a			;830d
	add a,b			;830e   ; mas lo que se pida
	ld d,a			;830f
	ld a,(ix+003h)		;8310   ; y la columna igual
	add a,a			;8313
	add a,a			;8314
	add a,a			;8315
	add a,c			;8316
	ld e,a			;8317
	ret			;8318

; ----------------------------------------------------------------------
; LAS PUERTAS QUE LLEVAN AL NIVEL SIGUIENTE
; ----------------------------------------------------------------------
mira_las_puertas:
	ld ix,0e2bdh		;8319   ; el tipo 3 de la lista del nivel
	ld b,003h		;831d   ; tres
	ld de,00008h		;831f   ; ocho bytes de ficha
mira_las_puertas_bucle:
	exx			;8322   ; una puerta cada vez
	call mira_una_puerta		;8323
	exx			;8326
	add ix,de		;8327
	djnz mira_las_puertas_bucle		;8329
	jr mira_la_puerta_de_la_calavera		;832b
mira_una_puerta:
	ld a,(0e062h)		;832d   ; si esta en otra sala, nada
	cp (ix+001h)		;8330
	ret nz			;8333
	call toca_la_puerta		;8334   ; ni si el jugador no la toca
	ret z			;8337
	ld a,(0e006h)		;8338   ; hace falta pulsar arriba
	and 001h		;833b
	ret z			;833d
	exx			;833e
	ld a,b			;833f   ; cual de las tres es
	exx			;8340
	ld b,a			;8341
	ld a,003h		;8342
	sub b			;8344
	ld hl,0e123h		;8345   ; se apunta en (0xE123)
	ld (hl),a			;8348
	ld a,(ix+004h)		;8349   ; el nivel al que lleva
	ld (0e061h),a		;834c
	ld a,(ix+005h)		;834f   ; y por que entrada se aparece
	ld (0e122h),a		;8352
	ld a,(hl)			;8355   ; las dos primeras
	cp 003h		;8356
	ld a,001h		;8358
	jr c,L_835D		;835a
	inc a			;835c
L_835D:
	ld (0e00dh),a		;835d   ; dejan (0xE00D) a uno, y la tercera a dos
	ld a,01eh		;8360   ; con la pieza 0x1E
	jp pide_pieza		;8362
toca_la_puerta:
	ld b,008h		;8365   ; ocho por ocho de desplazamiento
	ld c,b			;8367
	call rectangulo_de_la_ficha		;8368
	ld h,010h		;836b   ; dieciseis de alto por ocho de ancho
	ld l,008h		;836d
	jp toca_al_jugador		;836f
mira_la_puerta_de_la_calavera:
	ld ix,0e2d5h		;8372   ; la puerta del nivel
	exx			;8376
	call mira_la_puerta_estado		;8377
	exx			;837a
	ret			;837b
mira_la_puerta_estado:
	ld a,(ix+000h)		;837c   ; si no la hay, nada
	and a			;837f
	ret z			;8380
	dec a			;8381   ; dos estados: cerrada y abierta
	call reparte_por_tabla		;8382

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_8385: 2 entradas; detras sigue la primera, 0x8389
;   0x8385..0x8389  (4 bytes)
DATA_tabla_de_subescenas_8385:
	defw 08389h,08396h	; 8385  -> puerta_cerrada puerta_abierta

; ======================================================================
; CODIGO 0x8389..0x83c3  (58 bytes)
; ======================================================================


puerta_cerrada:
	ld a,(0e130h)		;8389   ; los amigos que se llevan sueltos
	cp 007h		;838c   ; con menos de siete, sigue cerrada
	ret c			;838e
	call pinta_la_puerta		;838f   ; se pinta abierta
	inc (ix+000h)		;8392   ; y pasa al estado 2
	ret			;8395
puerta_abierta:
	call mira_una_puerta		;8396   ; se comporta como las otras puertas
	ld a,(0e00dh)		;8399   ; y solo si (0xE00D) vale 2
	dec a			;839c
	dec a			;839d
	ret nz			;839e
	xor a			;839f   ; se avisa
	ld (0e071h),a		;83a0
	ld a,0a1h		;83a3   ; con la pieza 0xA1
	jp pide_pieza		;83a5
caja_del_murcielago:
	ld a,(0e124h)		;83a8   ; por donde salio
	add a,0fch		;83ab   ; cuatro pixeles arriba
	ld d,a			;83ad
	ld a,(0e125h)		;83ae   ; y dos a la izquierda
	add a,0feh		;83b1
	ld e,a			;83b3
	ld h,004h		;83b4   ; cuatro por cuatro
	ld l,004h		;83b6
	jp toca_al_jugador		;83b8

; ----------------------------------------------------------------------
; PLANTAR UN RECTANGULO DE CASILLAS EN UNA SALA
; ----------------------------------------------------------------------
planta_en_la_sala_0:
	xor a			;83bb   ; a = 0: siempre la primera sala, que es donde el constructor escribe las cuatro seguidas
	jr $+16		;83bc
planta_en_la_sala_de_ahora:
	ld a,(0e062h)		;83be   ; la sala en la que anda el jugador
	jr $+11		;83c1

; ----------------------------------------------------------------------
; DATOS tres_bytes_saltados: el `jr $+16` de 0x83BC y el `jr $+11` de 0x83C1
;   se los saltan: son la version de L_83BB que lee b y c del propio guion
;   0x83c3..0x83c6  (3 bytes)
DATA_tres_bytes_saltados:
	defb 03ah,062h,0e0h	; 83c3

; ======================================================================
; CODIGO 0x83c6..0x8455  (143 bytes)
; ======================================================================


planta_leyendo_el_tamano:
	ex de,hl			;83c6
	ld b,(hl)			;83c7   ; aqui las filas y las columnas vienen delante del propio bloque
	inc hl			;83c8
	ld c,(hl)			;83c9
	inc hl			;83ca
	ex de,hl			;83cb
L_83CC:
	call casilla_de_la_sala		;83cc   ; de = de donde se copia, hl = a donde
fila_del_rectangulo:
	ld (0e1cah),de		;83cf   ; se apunta donde iba el origen
	push hl			;83d3
	push bc			;83d4
	ld b,000h		;83d5   ; c columnas
	ex de,hl			;83d7
	ldir		;83d8   ; una fila de un tiron
	ex de,hl			;83da
	pop bc			;83db
	pop hl			;83dc
	ld a,c			;83dd
	ld de,(0e1cah)		;83de   ; se recupera el origen
	call suma_a_a_de		;83e2   ; y avanza una fila de la fuente
	ld a,020h		;83e5   ; mientras el destino avanza 32, que es lo ancho que es una sala
	call suma_a_a_hl		;83e7
	djnz fila_del_rectangulo		;83ea
	ret			;83ec

; ----------------------------------------------------------------------
; PLANTAR UN RECTANGULO EN LA PANTALLA
; ----------------------------------------------------------------------
planta_en_la_pantalla:
	ld a,(de)			;83ed   ; las filas
	ld b,a			;83ee
	inc de			;83ef
	ld a,(de)			;83f0   ; y las columnas, delante del bloque
	ld c,a			;83f1
	inc de			;83f2
L_83F3:
	call casilla_de_la_pantalla		;83f3   ; aqui la cuenta va contra la tabla de nombres, no contra la sala
L_83F6:
	ld (0e1c4h),de		;83f6
	ld (0e1c2h),bc		;83fa
	call abre_para_escribir		;83fe   ; abre el VDP
	call vuelca_c_bytes		;8401   ; y vuelca la fila
	ld bc,(0e1c2h)		;8404
	ld a,c			;8408
	ld de,(0e1c4h)		;8409
	call suma_a_a_de		;840d
	ld a,020h		;8410   ; 32 casillas por fila
	call suma_a_a_hl		;8412
	djnz L_83F6		;8415
	ret			;8417

; ----------------------------------------------------------------------
; UN CUADRO DE TODOS LOS PELIGROS
; ----------------------------------------------------------------------
mueve_los_peligros:
	ld a,(0e1b1h)		;8418   ; con la partida parada, ninguno se mueve
	and a			;841b
	ret nz			;841c
	call mueve_las_bolas		;841d   ; las bolas de piedra
	call mueve_los_chorros		;8420   ; los chorros de agua
	call mueve_las_columnas		;8423   ; las columnas
	call mueve_las_llamaradas		;8426   ; las llamaradas
	call mueve_las_fugas		;8429   ; las fugas de las tuberias
	call mueve_los_lanzadores		;842c   ; los lanzadores
	call mueve_lo_que_dejan_las_gotas		;842f   ; lo que sueltan
	call mueve_las_estalactitas		;8432   ; las estalactitas
	call mueve_las_gotas		;8435   ; y las gotas
	ret			;8438
mueve_las_bolas:
	ld ix,0e327h		;8439   ; las dos del tipo 1 de la sala
	ld de,0000ah		;843d   ; diez bytes de ficha
	ld b,002h		;8440   ; dos
mueve_las_bolas_bucle:
	exx			;8442   ; una bola cada vez
	call mueve_una_bola		;8443
	exx			;8446
	add ix,de		;8447
	djnz mueve_las_bolas_bucle		;8449
	ret			;844b
mueve_una_bola:
	ld a,(ix+000h)		;844c   ; apagada, nada
	and a			;844f
	ret z			;8450
	dec a			;8451   ; cuatro estados
	call reparte_por_tabla		;8452

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_8455: 4 entradas; detras sigue la primera, 0x845D
;   0x8455..0x845d  (8 bytes)
DATA_tabla_de_subescenas_8455:
	defw 0845dh,08477h,08483h,084adh	; 8455  -> bola_arranca bola_espera_a_bajar bola_bajando bola_subiendo

; ======================================================================
; CODIGO 0x845d..0x8508  (171 bytes)
; ======================================================================


bola_arranca:
	ld a,(ix+001h)		;845d   ; la fila de donde cuelga
	ld (ix+006h),a		;8460
	ld a,(ix+004h)		;8463   ; y lo que baja
	ld (ix+007h),a		;8466
	ld a,003h		;8469   ; cuatro vueltas antes de descansar
	ld (ix+009h),a		;846b
	ld (ix+008h),001h		;846e   ; un cuadro
	call pinta_la_bola_cuatro_filas		;8472   ; se pinta corta
	jr bola_siguiente_estado		;8475
bola_espera_a_bajar:
	dec (ix+008h)		;8477   ; la cuenta
	ret nz			;847a
	ld (ix+008h),001h		;847b   ; y un cuadro por casilla
bola_siguiente_estado:
	inc (ix+000h)		;847f
	ret			;8482
bola_bajando:
	dec (ix+008h)		;8483   ; la cuenta
	ret nz			;8486
	ld a,002h		;8487   ; dos cuadros por casilla al bajar
	ld (ix+008h),a		;8489
	inc (ix+001h)		;848c   ; una fila mas
	call pinta_la_bola		;848f   ; se pinta con la cadena entera
	call la_bola_baja_a_los_de_dentro		;8492   ; y lo que tape se apunta
	dec (ix+007h)		;8495   ; hasta que baja lo suyo
	ret nz			;8498
	ld (ix+008h),020h		;8499   ; 0x20 cuadros abajo
	ld a,012h		;849d   ; con la pieza 0x12
	call pide_pieza		;849f
	ld a,(ix+009h)		;84a2   ; a la cuarta vuelta
	cp 004h		;84a5
	ld b,004h		;84a7   ; se queda quieta mas rato
	jr nz,bola_espera_corta		;84a9
	jr bola_espera_larga		;84ab
bola_subiendo:
	dec (ix+008h)		;84ad   ; la cuenta
	ret nz			;84b0
	ld a,(ix+003h)		;84b1   ; lo que tarda en subir cada casilla
	ld (ix+008h),a		;84b4
	dec (ix+001h)		;84b7   ; una fila menos
	call pinta_la_bola		;84ba   ; se repinta
	call la_bola_sube_a_los_de_dentro		;84bd   ; y se devuelve lo que tapaba
	dec (ix+007h)		;84c0   ; hasta arriba del todo
	ret nz			;84c3
	ld a,018h		;84c4   ; 0x18 cuadros de descanso
	ld (ix+008h),a		;84c6
	ld b,002h		;84c9
	dec (ix+009h)		;84cb   ; y una vuelta menos
	jr nz,bola_espera_corta		;84ce
	ld (ix+009h),004h		;84d0   ; a la cuarta, se cuentan otras cuatro
bola_espera_larga:
	ld a,(ix+005h)		;84d4   ; el descanso largo, si lo tiene
	and a			;84d7
	jr nz,bola_guarda_la_espera		;84d8
bola_espera_corta:
	ld a,(ix+004h)		;84da   ; y si no, el suyo
bola_guarda_la_espera:
	ld (ix+007h),a		;84dd
	ld (ix+000h),b		;84e0
	ret			;84e3

; ----------------------------------------------------------------------
; LA BOLA DE PIEDRA COLGADA DE SU CADENA
; ----------------------------------------------------------------------
pinta_la_bola_cuatro_filas:
	xor a			;84e4   ; con a a cero se pinta la version corta
	jr L_84EC		;84e5
pinta_la_bola:
	ld a,(ix+000h)		;84e7   ; el estado
	sub 003h		;84ea   ; el 3 es el que la deja corta
L_84EC:
	ld c,002h		;84ec   ; DOS columnas de ancho: eso lo dice el codigo, no el ojo
	ld b,004h		;84ee   ; cuatro filas
	jr z,L_84F3		;84f0
	inc b			;84f2   ; o cinco, que es la cadena entera
L_84F3:
	ld de,08508h		;84f3   ; el dibujo: cinco filas de dos casillas
	ld l,(ix+001h)		;84f6   ; donde cuelga
	ld h,(ix+002h)		;84f9
	push hl			;84fc
	push de			;84fd
	push bc			;84fe
	call L_83F3		;84ff   ; se pinta en la pantalla
	pop bc			;8502
	pop de			;8503
	pop hl			;8504
	jp planta_en_la_sala_de_ahora		;8505   ; y ademas en la sala, para que el juego sepa que ahi hay piedra

; ----------------------------------------------------------------------
; DATOS bola_con_cadena: cinco filas de DOS casillas -el `ld c,002h` de
;   0x84EC-, y a veces solo se pintan cuatro
;   0x8508..0x8512  (10 bytes)
DATA_bola_con_cadena:
	defb 078h,079h	; 8508
	defb 046h,047h	; 850a
	defb 048h,049h	; 850c
	defb 04ah,04bh	; 850e
	defb 000h,000h	; 8510

; ======================================================================
; CODIGO 0x8512..0x858c  (122 bytes)
; ======================================================================


la_bola_baja_a_los_de_dentro:
	ld c,000h		;8512   ; c a cero: la bola va hacia abajo
	jr arrastra_a_los_de_dentro		;8514
la_bola_sube_a_los_de_dentro:
	ld c,001h		;8516   ; y a uno: hacia arriba
arrastra_a_los_de_dentro:
	ld iy,0e110h		;8518   ; el jugador
	call arrastra_a_uno		;851c
	ld iy,0e4d0h		;851f   ; y los cuatro perseguidores
	ld b,004h		;8523   ; cuatro
arrastra_a_los_de_dentro_bucle:
	push bc			;8525
	call arrastra_a_uno		;8526
	pop bc			;8529
	ld de,00023h		;852a   ; treinta y cinco bytes de ficha
	add iy,de		;852d
	djnz arrastra_a_los_de_dentro_bucle		;852f
	ret			;8531
arrastra_a_uno:
	ld a,(iy+00ah)		;8532   ; si no ha chocado con la bola, nada
	and 080h		;8535
	ret z			;8537
	ld a,(iy+008h)		;8538   ; ni si fue con otra bola
	exx			;853b
	cp b			;853c
	exx			;853d
	ret nz			;853e
	ld a,c			;853f   ; hacia abajo, ocho pixeles
	and a			;8540
	ld a,008h		;8541
	jr z,arrastra_suma		;8543
	ld a,0f8h		;8545   ; y hacia arriba, ocho: la bola los lleva consigo
arrastra_suma:
	add a,(iy+003h)		;8547
	ld (iy+003h),a		;854a
	ret			;854d

; ----------------------------------------------------------------------
; EL AGUA QUE CORRE, sin tocar el mapa
; ----------------------------------------------------------------------
anima_el_agua:
	ld a,(0e345h)		;854e   ; si no hay agua en la sala, nada
	and a			;8551
	ret z			;8552
	ld de,0858ch		;8553   ; la mitad de arriba
	ld hl,0859ch		;8556   ; y la de abajo
	ld a,(0e003h)		;8559   ; el contador de cuadros
	bit 2,a		;855c   ; su bit 2
	jr z,L_8561		;855e
	ex de,hl			;8560   ; y con el puesto se cambian: las dos mitades de cada casilla se alternan cada cuatro cuadros y el agua parece correr
L_8561:
	push hl			;8561
	ld hl,02368h		;8562   ; las filas 0 a 3 de la casilla 0x6D
	call reescribe_tres_casillas		;8565
	pop hl			;8568
	ex de,hl			;8569
	ld hl,0236ch		;856a   ; y las filas 4 a 7
reescribe_tres_casillas:
	ld b,003h		;856d   ; tres casillas
L_856F:
	push bc			;856f
	ld bc,00004h		;8570   ; cuatro bytes de patron cada una
	push de			;8573
	push hl			;8574
	call vuelca_en_los_tres_bancos		;8575   ; en los TRES bancos, que si no el agua solo cambiaria en un tercio de la pantalla
	pop hl			;8578
	pop de			;8579
	inc de			;857a   ; los cuatro bytes que se acaban de usar
	inc de			;857b
	inc de			;857c
	inc de			;857d
	ld a,(de)			;857e   ; y detras van dos, que son el salto a la casilla siguiente
	ld b,a			;857f
	inc de			;8580
	push de			;8581
	ld a,(de)			;8582
	ld d,a			;8583
	ld e,b			;8584
	add hl,de			;8585   ; sumado a la direccion de VRAM
	pop de			;8586
	inc de			;8587
	pop bc			;8588
	djnz L_856F		;8589   ; el salto de la tercera vuelta se lee pero ya no se usa: por eso las dos tandas van a dieciseis bytes y no a dieciocho
	ret			;858b

; ----------------------------------------------------------------------
; DATOS mitad_de_arriba_del_agua: NO es un mapa de casillas: son tres tandas
;   de [4 bytes de patron][2 bytes de salto], que L_856D vuelca en los TRES
;   bancos. Escribe las filas 0 a 3 de las casillas 0x6D, 0xCF y 0xF1
;   0x858c..0x859c  (16 bytes)
DATA_mitad_de_arriba_del_agua:
	defb 0dbh,05ah,04eh,0ebh,010h,003h	; 858c
	defb 03bh,0bbh,0b5h,0d5h,010h,001h	; 8592
	defb 0dch,0ddh,0adh,0abh	; 8598

; ----------------------------------------------------------------------
; DATOS mitad_de_abajo_del_agua: las mismas tres casillas, filas 4 a 7. 0x8559
;   cambia las dos tandas de sitio con el bit 2 de (0xE003), asi que las dos
;   mitades de cada casilla se alternan cada cuatro cuadros y el dibujo parece
;   correr. Las dos ultimas bytes de cada tanda son un salto que ya no se usa:
;   por eso las dos tandas van a 16 bytes y no a 18
;   0x859c..0x85ac  (16 bytes)
DATA_mitad_de_abajo_del_agua:
	defb 06bh,0b7h,0bdh,0dfh,010h,003h	; 859c
	defb 0dfh,075h,06ch,065h,010h,001h	; 85a2
	defb 0fbh,0aeh,036h,0a6h	; 85a8

; ======================================================================
; CODIGO 0x85ac..0x85da  (46 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LOS TRES CHORROS DE AGUA
; ----------------------------------------------------------------------
mueve_los_chorros:
	call anima_el_agua		;85ac
	ld ix,0e345h		;85af   ; los del tipo 0 de la sala
	ld iy,0e1d0h		;85b3   ; con su cuaderno de trabajo aparte
	ld de,00028h		;85b7   ; cuarenta bytes de cuaderno
	ld b,003h		;85ba   ; TRES chorros por sala
L_85BC:
	exx			;85bc
	call mueve_un_chorro		;85bd
	ld de,0000ah		;85c0   ; diez bytes de ficha
	add ix,de		;85c3
	exx			;85c5
	add iy,de		;85c6
	djnz L_85BC		;85c8
	ret			;85ca
mueve_un_chorro:
	ld a,(0e003h)		;85cb   ; uno de cada dos cuadros: el agua va a media velocidad
	and 002h		;85ce
	ret nz			;85d0
	ld a,(ix+000h)		;85d1   ; el estado
	and a			;85d4
	ret z			;85d5   ; y con cero, quieto
	dec a			;85d6
	call reparte_por_tabla		;85d7   ; cuatro estados

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_85da: 4 entradas; detras sigue la primera, 0x85E2
;   0x85da..0x85e2  (8 bytes)
DATA_tabla_de_subescenas_85da:
	defw 085e2h,08607h,0863dh,08657h	; 85da  -> chorro_en_espera chorro_bajando chorro_parado chorro_recogiendose

; ======================================================================
; CODIGO 0x85e2..0x8652  (112 bytes)
; ======================================================================


chorro_en_espera:
	ld a,(ix+008h)		;85e2   ; la cuenta atras
	dec (ix+008h)		;85e5
	and a			;85e8
	ret nz			;85e9   ; y hasta que no llega a cero no sale
	ld a,(ix+001h)		;85ea   ; la fila de arranque
	ld (ix+005h),a		;85ed
	ld (ix+006h),a		;85f0   ; en las dos puntas
	xor a			;85f3
	ld (ix+007h),a		;85f4
	ld (ix+009h),a		;85f7
	ld a,055h		;85fa   ; la pieza 0x55, que es el ruido del agua
	call pide_pieza_si_toca		;85fc
	call pinta_una_casilla_del_chorro		;85ff   ; y se pinta la primera casilla
	inc (ix+007h)		;8602
	jr sube_de_estado		;8605
chorro_bajando:
	ld a,(ix+001h)		;8607   ; la fila de arriba
	ld c,a			;860a
	ld a,(ix+005h)		;860b   ; contra donde va la punta
	sub c			;860e
	cp (ix+003h)		;860f   ; si ya ha bajado lo suyo
	jr nz,L_8620		;8612
	inc (ix+007h)		;8614   ; se pasa al estado siguiente
	ld a,(ix+004h)		;8617   ; con su espera
	ld (ix+008h),a		;861a
	call sube_de_estado		;861d
L_8620:
	call pinta_una_casilla_del_chorro		;8620   ; y si no, otra casilla mas abajo
	inc (ix+005h)		;8623
	ret			;8626
pinta_una_casilla_del_chorro:
	call apunta_lo_que_el_agua_tapa		;8627
	ld hl,086d6h		;862a   ; los tres dibujos del agua: la superficie, el chorro y la espuma
	ld b,(ix+005h)		;862d   ; la fila
L_8630:
	ld a,(ix+007h)		;8630   ; y cual de los tres toca
	call puntero_numero_a		;8633
	ld l,b			;8636
	ld h,(ix+002h)		;8637   ; la columna, que no cambia: el agua cae recta
	jp planta_en_la_pantalla		;863a
chorro_parado:
	dec (ix+008h)		;863d   ; la espera
	ret nz			;8640
	xor a			;8641   ; y al acabarse, a recogerse
	ld (ix+007h),a		;8642
	ld (ix+009h),a		;8645
	call borra_la_casilla_de_arriba		;8648
	inc (ix+007h)		;864b
sube_de_estado:
	inc (ix+000h)		;864e
	ret			;8651

; ----------------------------------------------------------------------
; DATOS un_byte_suelto: cae entre dos trozos de codigo y no lo lee nadie
;   0x8652..0x8653  (1 bytes)
DATA_un_byte_suelto:
	defb 0afh	; 8652

; ======================================================================
; CODIGO 0x8653..0x86d6  (131 bytes)
; ======================================================================


chorro_pon_estado:
	ld (ix+000h),a		;8653
	ret			;8656
chorro_recogiendose:
	ld a,(ix+001h)		;8657   ; la fila de arriba
	ld c,a			;865a
	ld a,(ix+006h)		;865b   ; contra la punta de arriba del agua
	sub c			;865e
	cp (ix+003h)		;865f   ; si ya se recogio del todo
	jr nz,chorro_borra_una_casilla		;8662
	inc (ix+007h)		;8664   ; se pasa de dibujo
	ld a,(ix+004h)		;8667   ; con su espera
	ld (ix+008h),a		;866a
	ld a,001h		;866d   ; y de vuelta al estado 1
	call chorro_pon_estado		;866f
chorro_borra_una_casilla:
	call borra_la_casilla_de_arriba		;8672   ; y si no, una casilla menos
	inc (ix+006h)		;8675
	ret			;8678
borra_la_casilla_de_arriba:
	ld hl,086eeh		;8679   ; el dibujo de borrar
	ld b,(ix+006h)		;867c   ; la fila de arriba
	call L_8630		;867f
	jr devuelve_lo_que_el_agua_tapaba		;8682   ; y de paso se devuelve lo que hubiera
apunta_lo_que_el_agua_tapa:
	ld a,(ix+007h)		;8684   ; solo con los dos primeros dibujos
	cp 002h		;8687
	ret nc			;8689
	and a			;868a
	ld l,(ix+005h)		;868b   ; la fila de la punta
	jr z,apunta_mira_la_casilla		;868e
	inc l			;8690   ; una mas abajo con el segundo
apunta_mira_la_casilla:
	ld h,(ix+002h)		;8691   ; la columna
	ld c,l			;8694
	call L_45D7		;8695   ; a direccion dentro de la sala
	ld a,(hl)			;8698   ; si esta vacia, no hay nada que guardar
	and a			;8699
	ret z			;869a
	push iy		;869b   ; el cuaderno de esta sala
	pop de			;869d
	ld a,(ix+009h)		;869e   ; cuatro bytes por apunte
	add a,a			;86a1
	add a,a			;86a2
	call suma_a_a_de		;86a3
	ex de,hl			;86a6
	ld (hl),c			;86a7   ; la fila
	inc hl			;86a8
	ex de,hl			;86a9
	ld bc,00003h		;86aa   ; y las tres casillas que habia
	ldir		;86ad
	inc (ix+009h)		;86af   ; un apunte mas
	ret			;86b2
devuelve_lo_que_el_agua_tapaba:
	ld a,(ix+007h)		;86b3   ; con el agua fuera, nada
	and a			;86b6
	ret z			;86b7
	ld l,(ix+006h)		;86b8   ; la fila de arriba del agua
	ld h,(ix+002h)		;86bb   ; y su columna
	push iy		;86be   ; el cuaderno
	pop de			;86c0
	ld a,(ix+009h)		;86c1   ; por el apunte que toca
	add a,a			;86c4
	add a,a			;86c5
	call suma_a_a_de		;86c6
	ld a,(de)			;86c9   ; y solo si es de esta fila
	cp l			;86ca
	ret nz			;86cb
	inc (ix+009h)		;86cc   ; el siguiente
	inc de			;86cf
	ld bc,00103h		;86d0   ; y las tres casillas vuelven a su sitio
	jp L_83F3		;86d3

; ----------------------------------------------------------------------
; DATOS punteros_del_agua: tres punteros a los dibujos de 0x86DC: la
;   superficie, el chorro y la espuma
;   0x86d6..0x86dc  (6 bytes)
DATA_punteros_del_agua:
	defw 086dch,086e1h,086e9h	; 86d6  -> DATA_dibujos_del_agua 0x86e1 0x86e9

; ----------------------------------------------------------------------
; DATOS dibujos_del_agua: cuarenta y dos bytes: los tres dibujos del chorro,
;   cada uno con sus filas y columnas delante
;   0x86dc..0x8706  (42 bytes)
DATA_dibujos_del_agua:
	defb 001h,003h,0cdh,06bh,0efh,002h,003h,0cfh,06dh,0f1h,0cdh,06bh,0efh,001h,003h,0cch	; 86dc  ...k....m..k....
	defb 06ah,0eeh,0f4h,086h,0f9h,086h,001h,087h,001h,003h,0ceh,06ch,0f0h,002h,003h,000h	; 86ec  j..........l....
	defb 000h,000h,0ceh,06ch,0f0h,001h,003h,000h,000h,000h	; 86fc  ...l......

; ======================================================================
; CODIGO 0x8706..0x872f  (41 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS CINCO COLUMNAS QUE CRECEN
; ----------------------------------------------------------------------
mueve_las_columnas:
	ld ix,0e248h		;8706   ; el tipo 0 de la lista del nivel
	ld de,00008h		;870a   ; ocho bytes de ficha
	ld b,005h		;870d   ; CINCO por nivel
L_870F:
	exx			;870f   ; una columna cada vez
	call mueve_una_columna		;8710
	exx			;8713
	add ix,de		;8714
	djnz L_870F		;8716
	ret			;8718
mueve_una_columna:
	ld hl,0e062h		;8719   ; la sala en la que estamos
	ld a,(ix+001h)		;871c   ; contra la suya
	cp (hl)			;871f
	ret nz			;8720
	ld a,(ix+005h)		;8721   ; si ya termino de crecer, nada
	and a			;8724
	ret nz			;8725
	ld a,(ix+000h)		;8726   ; y el estado
	and a			;8729
	ret z			;872a
	dec a			;872b
	call reparte_por_tabla		;872c   ; dos estados

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_872f: 2 entradas; detras sigue la primera, 0x8733
;   0x872f..0x8733  (4 bytes)
DATA_tabla_de_subescenas_872f:
	defw 08733h,08741h	; 872f  -> arranca_la_columna crece_la_columna

; ======================================================================
; CODIGO 0x8733..0x8787  (84 bytes)
; ======================================================================


arranca_la_columna:
	call el_jugador_esta_cerca		;8733   ; mira si el jugador esta cerca
	ret z			;8736
	ld a,(ix+002h)		;8737   ; la fila de arranque
	ld (ix+007h),a		;873a   ; y de ahi empieza a crecer
	inc (ix+000h)		;873d
	ret			;8740
crece_la_columna:
	ld a,(0e003h)		;8741   ; el contador de cuadros
	and 01eh		;8744   ; y con los bits 1 a 4 a cero: una casilla cada 32 cuadros
	ret nz			;8746
	ld hl,08787h		;8747   ; los tres dibujos de la columna
	ld b,000h		;874a
	ld a,(ix+007h)		;874c   ; por donde va
	sub (ix+002h)		;874f   ; si es la primera casilla, la punta
	jr z,L_875C		;8752
	inc b			;8754
	inc a			;8755
	cp (ix+004h)		;8756   ; si es la ultima, la ancha
	jr nz,L_875C		;8759
	inc b			;875b   ; y entre medias, la de en medio
L_875C:
	ld a,b			;875c
	call puntero_numero_a		;875d
	ld l,(ix+007h)		;8760   ; la fila, que va BAJANDO: 0x8733 arranca en (ix+002h) y 0x8773 la incrementa, o sea que la punta queda arriba y la base, al cabo de (ix+004h) casillas, abajo
	ld h,(ix+003h)		;8763   ; y la columna, que no cambia
	push hl			;8766
	push de			;8767
	call planta_en_la_pantalla		;8768   ; se pinta en la pantalla
	pop de			;876b
	pop hl			;876c
	ld a,(ix+001h)		;876d
	call planta_leyendo_el_tamano		;8770   ; y ADEMAS se planta en la sala: la columna pasa a ser suelo de verdad, no solo dibujo
	inc (ix+007h)		;8773   ; una casilla mas
	ld c,(ix+002h)		;8776
	ld a,(ix+007h)		;8779
	sub c			;877c
	cp (ix+004h)		;877d   ; hasta que llega a lo suyo
	ret nz			;8780
	ld a,001h		;8781   ; y ahi se queda quieta
	ld (ix+005h),a		;8783
	ret			;8786

; ----------------------------------------------------------------------
; DATOS punteros_de_la_columna: tres punteros a los dibujos de 0x878D: la
;   punta, el tramo de en medio y la base
;   0x8787..0x878d  (6 bytes)
DATA_punteros_de_la_columna:
	defw 0878dh,08791h,08795h	; 8787  -> DATA_dibujos_de_la_columna 0x8791 0x8795

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_columna: tres dibujos de una fila por dos columnas, cada
;   uno con su tamano delante
;   0x878d..0x8799  (12 bytes)
DATA_dibujos_de_la_columna:
	defb 001h,002h,0c1h,0e3h,001h,002h,0bfh,0e1h,001h,002h,0c2h,0e4h	; 878d  ............

; ======================================================================
; CODIGO 0x8799..0x881c  (131 bytes)
; ======================================================================


el_jugador_esta_cerca:
	ld e,002h		;8799   ; dos casillas de margen
el_jugador_esta_cerca_con_margen:
	ld b,(ix+002h)		;879b   ; la fila
	ld c,(ix+003h)		;879e   ; la columna
	ld d,(ix+004h)		;87a1   ; y el alto
mira_si_esta_dentro:
	ld hl,0e110h		;87a4   ; la ficha del jugador
	ld a,(hl)			;87a7
	cp 002h		;87a8   ; en la escalera no cuenta
	jr z,no_esta_cerca		;87aa
	cp 003h		;87ac   ; ni cayendo
	jr z,no_esta_cerca		;87ae
	ld a,d			;87b0   ; el alto
	cp 004h		;87b1   ; de cuatro casillas no pasa
	jr z,mira_si_esta_dentro_de_fila		;87b3
	jr c,mira_si_esta_dentro_de_fila		;87b5
	sub 004h		;87b7   ; lo que sobre se le quita por arriba
	add a,b			;87b9
	ld b,a			;87ba
	ld d,004h		;87bb
mira_si_esta_dentro_de_fila:
	ld a,b			;87bd   ; la fila de arriba, de casillas a pixeles
	add a,a			;87be
	add a,a			;87bf
	add a,a			;87c0
	inc hl			;87c1   ; contra la fila del jugador
	inc hl			;87c2
	inc hl			;87c3
	cp (hl)			;87c4
	jr nc,no_esta_cerca		;87c5   ; por encima, no
	ld a,b			;87c7   ; y la de abajo
	add a,d			;87c8
	add a,a			;87c9
	add a,a			;87ca
	add a,a			;87cb
	cp (hl)			;87cc
	jr c,no_esta_cerca		;87cd   ; por debajo, tampoco
	ld a,e			;87cf   ; con margen de dos
	cp 002h		;87d0
	ld b,004h		;87d2   ; el centro va cuatro pixeles a la derecha
	jr z,mira_si_esta_dentro_de_columna		;87d4
	ld b,008h		;87d6   ; y con mas margen, ocho
mira_si_esta_dentro_de_columna:
	inc hl			;87d8
	inc hl			;87d9
	ld a,c			;87da   ; la columna, de casillas a pixeles
	add a,a			;87db
	add a,a			;87dc
	add a,a			;87dd
	add a,b			;87de
	sub (hl)			;87df   ; menos la del jugador
	jr nc,L_87E4		;87e0
	neg		;87e2   ; en valor absoluto
L_87E4:
	cp e			;87e4   ; y si cae dentro del margen, esta cerca
	jr nc,no_esta_cerca		;87e5
	or 001h		;87e7
	ret			;87e9
no_esta_cerca:
	xor a			;87ea
	ret			;87eb

; ----------------------------------------------------------------------
; LAS ONCE ESTALACTITAS
; ----------------------------------------------------------------------
mueve_las_estalactitas:
	ld ix,0e270h		;87ec   ; el tipo 1 de la lista del nivel
	ld de,00007h		;87f0   ; siete bytes de ficha
	ld b,00bh		;87f3   ; once por nivel
mueve_las_estalactitas_bucle:
	exx			;87f5   ; una estalactita cada vez
	call mueve_una_estalactita		;87f6
	exx			;87f9
	add ix,de		;87fa
	djnz mueve_las_estalactitas_bucle		;87fc
	ret			;87fe
mueve_una_estalactita:
	ld a,(ix+000h)		;87ff   ; apagada, nada
	and a			;8802
	ret z			;8803
	ld hl,0e062h		;8804   ; la sala de ahora
	ld a,(ix+001h)		;8807
	cp (hl)			;880a   ; si esta en otra
	ld a,(ix+000h)		;880b
	jr z,estalactita_estado		;880e
	cp 002h		;8810   ; y ya habia empezado a caer
	ret c			;8812
	ld (ix+000h),000h		;8813   ; se olvida: al volver a la sala esta otra vez arriba
	ret			;8817
estalactita_estado:
	dec a			;8818   ; cuatro estados
	call reparte_por_tabla		;8819

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_881c: 4 entradas; detras sigue la primera, 0x8824
;   0x881c..0x8824  (8 bytes)
DATA_tabla_de_subescenas_881c:
	defw 08824h,0883eh,08863h,08882h	; 881c  -> estalactita_colgando estalactita_cayendo estalactita_rompiendose L_8882

; ======================================================================
; CODIGO 0x8824..0x8891  (109 bytes)
; ======================================================================


estalactita_colgando:
	call estalactita_su_caja		;8824   ; hasta que el jugador no se pone debajo, nada
	ret z			;8827
	ld l,(ix+002h)		;8828   ; su fila
	ld h,(ix+003h)		;882b   ; y su columna
	ld a,(ix+001h)		;882e
	call casilla_de_la_sala		;8831   ; en la sala, no en la pantalla
	xor a			;8834   ; las dos casillas del techo se borran: la estalactita se desprende
	ld (hl),a			;8835
	inc hl			;8836
	ld (hl),a			;8837
	ld (ix+005h),001h		;8838   ; y el dibujo pasa al de caer
	jr estalactita_siguiente_estado		;883c
estalactita_cayendo:
	ld a,(0e003h)		;883e   ; los bits 1 y 2 del contador: una casilla cada cuatro cuadros
	and 006h		;8841
	ret nz			;8843
	call pinta_la_estalactita		;8844   ; se pinta
	inc (ix+002h)		;8847   ; una fila mas abajo
	ld l,(ix+002h)		;884a   ; la de debajo
	inc l			;884d
	ld h,(ix+003h)		;884e
	call L_45D7		;8851   ; a direccion dentro de la sala
	ld a,(hl)			;8854   ; mientras este libre, sigue cayendo
	and a			;8855
	ret z			;8856
	ld (ix+005h),002h		;8857   ; y al chocar, el dibujo del golpe
	ld (ix+006h),002h		;885b   ; con dos cuadros
estalactita_siguiente_estado:
	inc (ix+000h)		;885f
	ret			;8862
estalactita_rompiendose:
	dec (ix+006h)		;8863   ; la cuenta
	ret nz			;8866
	call pinta_la_estalactita		;8867   ; se pinta
	ld (ix+006h),008h		;886a   ; y ocho cuadros de esquirlas
	jr estalactita_siguiente_estado		;886e
pinta_la_estalactita:
	ld hl,08891h		;8870   ; los seis dibujos
	ld a,(ix+005h)		;8873   ; el que toque
	call puntero_numero_a		;8876
	ld l,(ix+002h)		;8879   ; su fila
	ld h,(ix+003h)		;887c   ; y su columna
	jp planta_en_la_pantalla		;887f
L_8882:
	dec (ix+006h)		;8882   ; la cuenta de las esquirlas
	ret nz			;8885
	inc (ix+005h)		;8886   ; el ultimo dibujo, que las borra
	call pinta_la_estalactita		;8889
	ld (ix+000h),000h		;888c   ; y la estalactita vuelve a colgar del techo
	ret			;8890

; ----------------------------------------------------------------------
; DATOS punteros_de_la_estalactita: seis punteros a los dibujos de 0x889D: la
;   punta colgando, la que cae, el golpe contra el suelo y las esquirlas
;   0x8891..0x889d  (12 bytes)
DATA_punteros_de_la_estalactita:
	defw 0889dh,088a1h,088a7h,088adh,088b3h,088b7h	; 8891

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_estalactita: treinta bytes: seis dibujos con sus filas y
;   columnas delante, que es como los lee 0x83ED
;   0x889d..0x88bb  (30 bytes)
DATA_dibujos_de_la_estalactita:
	defb 001h,002h,055h,056h,002h,002h,000h,000h,055h,056h,002h,002h,000h,000h,05ch,05dh	; 889d  ..UV....UV....\]
	defb 002h,002h,000h,000h,040h,040h,001h,002h,05ah,05bh,001h,002h,000h,000h	; 88ad  ....@@..Z[....

; ======================================================================
; CODIGO 0x88bb..0x88d5  (26 bytes)
; ======================================================================


estalactita_su_caja:
	ld b,000h		;88bb
	ld a,(ix+004h)		;88bd   ; por donde va cayendo
	cp 005h		;88c0   ; hasta la mitad, un dibujo
	jr c,L_88CA		;88c2
	inc b			;88c4
	cp 008h		;88c5   ; y luego otro
	jr c,L_88CA		;88c7
	inc b			;88c9
L_88CA:
	ld hl,088d5h		;88ca
	ld a,b			;88cd
	call suma_a_a_hl		;88ce
	ld e,(hl)			;88d1
	jp el_jugador_esta_cerca_con_margen		;88d2

; ----------------------------------------------------------------------
; DATOS margen_de_la_estalactita: tres bytes: 6, 0x0D y 0x20. Cuanto mas lleva
;   caida, mas ancho es el margen con el que mira si el jugador esta debajo
;   0x88d5..0x88d8  (3 bytes)
DATA_margen_de_la_estalactita:
	defb 006h,00dh,020h	; 88d5

; ======================================================================
; CODIGO 0x88d8..0x88f4  (28 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS TRES LLAMARADAS
; ----------------------------------------------------------------------
mueve_las_llamaradas:
	ld ix,0e363h		;88d8   ; el tipo 2 de la sala
	ld de,00006h		;88dc   ; seis bytes de ficha
	ld b,003h		;88df   ; TRES por sala
L_88E1:
	exx			;88e1   ; una llamarada cada vez
	call mueve_una_llamarada		;88e2
	exx			;88e5
	add ix,de		;88e6
	djnz L_88E1		;88e8
	ret			;88ea
mueve_una_llamarada:
	ld a,(ix+000h)		;88eb
	and a			;88ee
	ret z			;88ef   ; quieta
	dec a			;88f0
	call reparte_por_tabla		;88f1   ; cuatro estados

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_88f4: 4 entradas; detras sigue la primera, 0x88FC
;   0x88f4..0x88fc  (8 bytes)
DATA_tabla_de_subescenas_88f4:
	defw 088fch,0890fh,08932h,08948h	; 88f4  -> llamarada_dormida llamarada_creciendo llamarada_ardiendo llamarada_apagandose

; ======================================================================
; CODIGO 0x88fc..0x896c  (112 bytes)
; ======================================================================


llamarada_dormida:
	call L_898F		;88fc   ; mira si el jugador se ha acercado
	ret z			;88ff   ; y si no, nada
	ld a,002h		;8900   ; se enciende
	ld (ix+000h),a		;8902
	xor a			;8905
	ld (ix+003h),a		;8906   ; empieza por el dibujo 0
	ld a,003h		;8909   ; y cambia cada tres cuadros
	ld (ix+004h),a		;890b
	ret			;890e
llamarada_creciendo:
	dec (ix+004h)		;890f   ; la cuenta
	ret nz			;8912
	ld a,005h		;8913   ; cinco cuadros por fase
	ld (ix+004h),a		;8915
	call pinta_la_llamarada		;8918   ; se pinta
	inc (ix+003h)		;891b   ; y crece
	ld a,(ix+003h)		;891e
	cp 002h		;8921   ; hasta la fase 2
	ret c			;8923
	ld a,030h		;8924   ; 0x30 cuadros ardiendo
	ld (ix+004h),a		;8926
	ld a,054h		;8929   ; la pieza 0x54, que es el fuego
	call pide_pieza		;892b
L_892E:
	inc (ix+000h)		;892e
	ret			;8931
llamarada_ardiendo:
	ld a,(0e003h)		;8932   ; el contador de cuadros
	bit 2,a		;8935   ; su bit 2 alterna las fases 2 y 3: la llama tiembla
	ld a,002h		;8937
	jr z,L_893C		;8939
	inc a			;893b
L_893C:
	ld (ix+003h),a		;893c
	call pinta_la_llamarada		;893f   ; se pinta
	dec (ix+004h)		;8942   ; y cuando se acaba la cuenta, se apaga
	ret nz			;8945
	jr L_892E		;8946
llamarada_apagandose:
	ld a,004h		;8948   ; la fase 4, que son las brasas del suelo
	ld (ix+003h),a		;894a
	call pinta_la_llamarada		;894d
	ld a,001h		;8950
	ld (ix+000h),a		;8952   ; y de vuelta a dormir
	ret			;8955
pinta_la_llamarada:
	ld hl,0896ch		;8956   ; los cinco dibujos
	ld a,(ix+003h)		;8959   ; el que toque
	call puntero_numero_a		;895c
	ld a,(ix+001h)		;895f   ; la fila de la base
	ex de,hl			;8962
	sub (hl)			;8963   ; menos lo que mide el dibujo, que es lo primero que trae: la llama crece HACIA ARRIBA, asi que el sitio donde se pinta sube con ella
	ex de,hl			;8964
	ld l,a			;8965
	ld h,(ix+002h)		;8966   ; y la columna, fija
	jp planta_en_la_pantalla		;8969

; ----------------------------------------------------------------------
; DATOS punteros_de_la_llamarada: cinco punteros a los dibujos de 0x8976: como
;   brota, como crece, las dos fases de arder y las brasas
;   0x896c..0x8976  (10 bytes)
DATA_punteros_de_la_llamarada:
	defw 08976h,08979h,0897dh,08983h,08989h	; 896c

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_llamarada: veinticinco bytes: cinco dibujos con sus
;   filas y columnas delante. Lo primero de cada uno es el alto, y por eso la
;   llama crece hacia arriba
;   0x8976..0x898f  (25 bytes)
DATA_dibujos_de_la_llamarada:
	defb 001h,001h,061h,002h,001h,07bh,062h,004h,001h,000h,07dh,07ch,063h,004h,001h,080h	; 8976  ..a..{b...}|c...
	defb 07fh,07eh,064h,004h,001h,000h,000h,000h,040h	; 8986  .~d.....@

; ======================================================================
; CODIGO 0x898f..0x8a05  (118 bytes)
; ======================================================================


L_898F:
	call el_jugador_esta_ante_la_llamarada		;898f
	ld b,(ix+005h)		;8992
	ld a,001h		;8995
	jr nz,llamarada_guarda_la_fase		;8997
	xor a			;8999
llamarada_guarda_la_fase:
	ld (ix+005h),a		;899a   ; la fase nueva
	ld c,a			;899d
	xor b			;899e   ; y se avisa si ha cambiado
	ret z			;899f
	ld a,c			;89a0
	and a			;89a1
	ret			;89a2
el_jugador_esta_ante_la_llamarada:
	ld d,004h		;89a3   ; cuatro casillas de alto
	ld e,020h		;89a5   ; y 0x20 de margen
	ld a,(ix+001h)		;89a7   ; desde su fila
	sub d			;89aa   ; cuatro mas arriba
	inc a			;89ab
	ld b,a			;89ac
	ld c,(ix+002h)		;89ad
	jp mira_si_esta_dentro		;89b0
planta_las_estalactitas:
	ld ix,0e270h		;89b3   ; las once del nivel
	ld de,00007h		;89b7   ; siete bytes de ficha
	ld b,00bh		;89ba
planta_las_estalactitas_bucle:
	exx			;89bc   ; una estalactita cada vez
	call planta_una_estalactita		;89bd
	exx			;89c0
	add ix,de		;89c1
	djnz planta_las_estalactitas_bucle		;89c3
	ret			;89c5
planta_una_estalactita:
	ld a,(ix+000h)		;89c6   ; si no la hay, nada
	and a			;89c9
	ret z			;89ca
	xor a			;89cb
	ld hl,08891h		;89cc   ; su primer dibujo, el de colgar
	call puntero_numero_a		;89cf
	ld a,(ix+001h)		;89d2   ; en su sala
	ld l,(ix+002h)		;89d5   ; su fila
	ld h,(ix+003h)		;89d8   ; y su columna: esto va a la sala, no a la pantalla
	jp planta_leyendo_el_tamano		;89db

; ----------------------------------------------------------------------
; LAS CUATRO FUGAS DE LAS TUBERIAS
; ----------------------------------------------------------------------
mueve_las_fugas:
	ld ix,0e375h		;89de   ; el tipo 3 de la sala
	ld a,(0e003h)		;89e2   ; el bit 1 del contador
	bit 1,a		;89e5
	jr z,L_89ED		;89e7
	ld ix,0e37eh		;89e9   ; turna las dos mitades: cada cuadro se mueven cuatro, no las ocho
L_89ED:
	ld de,00012h		;89ed   ; dieciocho bytes de ficha
	ld b,004h		;89f0   ; cuatro cada vez
mueve_las_fugas_bucle:
	exx			;89f2   ; una fuga cada vez
	call mueve_una_fuga		;89f3
	exx			;89f6
	add ix,de		;89f7
	djnz mueve_las_fugas_bucle		;89f9
	ret			;89fb
mueve_una_fuga:
	ld a,(ix+000h)		;89fc   ; apagada, nada
	and a			;89ff
	ret z			;8a00
	dec a			;8a01   ; cuatro estados
	call reparte_por_tabla		;8a02

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_8a05: 4 entradas; detras sigue la primera, 0x8A0D
;   0x8a05..0x8a0d  (8 bytes)
DATA_tabla_de_subescenas_8a05:
	defw 08a0dh,08a13h,08a20h,08a3dh	; 8a05  -> fuga_arranca fuga_espera fuga_goteando fuga_chorreando

; ======================================================================
; CODIGO 0x8a0d..0x8a95  (136 bytes)
; ======================================================================


fuga_arranca:
	ld (ix+006h),005h		;8a0d   ; cinco cuadros
	jr fuga_siguiente_estado		;8a11
fuga_espera:
	dec (ix+006h)		;8a13   ; la cuenta
	ret nz			;8a16
	ld a,00ah		;8a17   ; y otros diez
	ld (ix+006h),a		;8a19
fuga_siguiente_estado:
	inc (ix+000h)		;8a1c
	ret			;8a1f
fuga_goteando:
	ld a,(ix+006h)		;8a20   ; el bit 0 de la cuenta
	bit 0,a		;8a23
	ld a,000h		;8a25   ; turna las dos gotas
	jr nz,L_8A2A		;8a27
	inc a			;8a29
L_8A2A:
	call pinta_la_fuga		;8a2a
	dec (ix+006h)		;8a2d   ; hasta que se acaba
	ret nz			;8a30
	ld a,020h		;8a31   ; 0x20 cuadros de chorro
	ld (ix+006h),a		;8a33
	ld a,053h		;8a36   ; con la pieza 0x53
	call pide_pieza		;8a38
	jr fuga_siguiente_estado		;8a3b
fuga_chorreando:
	ld a,(ix+007h)		;8a3d   ; se apunta el dibujo de antes
	ld (ix+008h),a		;8a40
	ld a,(ix+006h)		;8a43   ; el bit 0 de la cuenta
	bit 0,a		;8a46
	ld a,002h		;8a48   ; turna los dos dibujos del chorro
	jr nz,L_8A4D		;8a4a
	inc a			;8a4c
L_8A4D:
	call pinta_la_fuga		;8a4d
	dec (ix+006h)		;8a50   ; y al acabarse
	ret nz			;8a53
	ld a,004h		;8a54   ; el quinto dibujo, que esta vacio: asi se borra
	call pinta_la_fuga		;8a56
	ld a,(ix+004h)		;8a59   ; se recarga la cuenta de la ficha
	ld (ix+006h),a		;8a5c
	ld a,002h		;8a5f   ; y vuelta al estado 2
	ld (ix+000h),a		;8a61
	ret			;8a64
pinta_la_fuga:
	ld (ix+005h),a		;8a65   ; el dibujo que toca
	add a,a			;8a68   ; dos bloques por dibujo, uno hacia cada lado
	ld b,a			;8a69
	ld c,(ix+002h)		;8a6a   ; la columna del tubo
	inc c			;8a6d
	ld a,(ix+003h)		;8a6e   ; si la fuga sale hacia el otro lado
	and a			;8a71
	jr z,L_8A78		;8a72
	dec c			;8a74   ; se pinta tres casillas mas a la izquierda
	dec c			;8a75
	dec c			;8a76
	inc b			;8a77   ; y con el bloque de al lado
L_8A78:
	ld a,(ix+005h)		;8a78   ; el quinto dibujo, el de borrar
	cp 004h		;8a7b
	jr nz,L_8A81		;8a7d
	ld b,008h		;8a7f   ; no tiene pareja: es el mismo para los dos lados
L_8A81:
	ld a,b			;8a81   ; cuatro casillas por bloque
	add a,a			;8a82
	add a,a			;8a83
	ld hl,08a95h		;8a84
	call suma_a_a_hl		;8a87
	ex de,hl			;8a8a
	ld l,(ix+001h)		;8a8b   ; la fila
	ld h,c			;8a8e
	ld bc,00202h		;8a8f   ; y dos por dos
	jp L_83F3		;8a92

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_fuga: nueve bloques de dos por dos casillas, en parejas:
;   el mismo chorro hacia un lado y hacia el otro. 0x8A84 entra con el dibujo
;   por dos mas el lado
;   0x8a95..0x8ab9  (36 bytes)
DATA_dibujos_de_la_fuga:
	defb 000h,000h,0fbh,000h	; 8a95
	defb 000h,000h,000h,0d9h	; 8a99
	defb 000h,000h,0feh,000h	; 8a9d
	defb 000h,000h,000h,0dch	; 8aa1
	defb 000h,0fbh,0fdh,0fch	; 8aa5
	defb 0d9h,000h,0dah,0dbh	; 8aa9
	defb 000h,0feh,0fdh,0ffh	; 8aad
	defb 0dch,000h,0ddh,0dbh	; 8ab1
	defb 000h,000h,000h,000h	; 8ab5

; ======================================================================
; CODIGO 0x8ab9..0x8b95  (220 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LOS CUATRO LANZADORES
; ----------------------------------------------------------------------
mueve_los_lanzadores:
	ld ix,0e3bdh		;8ab9   ; el tipo 4 de la sala
	ld de,00006h		;8abd   ; seis bytes de ficha
	ld b,004h		;8ac0   ; cuatro
mueve_los_lanzadores_bucle:
	exx			;8ac2   ; un lanzador cada vez
	call mueve_un_lanzador		;8ac3
	exx			;8ac6
	add ix,de		;8ac7
	djnz mueve_los_lanzadores_bucle		;8ac9
	ret			;8acb
mueve_un_lanzador:
	ld a,(ix+000h)		;8acc   ; apagado, nada
	and a			;8acf
	ret z			;8ad0
	ld a,(ix+005h)		;8ad1   ; la cuenta
	inc a			;8ad4
	cp (ix+004h)		;8ad5   ; contra lo que tarda este
	ld (ix+005h),a		;8ad8
	ret nz			;8adb
	ld (ix+005h),000h		;8adc   ; y cuando cuadra, a soltar otro
	ld hl,0e3d5h		;8ae0   ; los cinco huecos de ficha
	ld b,005h		;8ae3   ; se busca uno libre
busca_hueco_de_ficha:
	ld a,(hl)			;8ae5   ; con el primero que este a cero
	and a			;8ae6
	jr z,arranca_la_ficha		;8ae7
	ld a,005h		;8ae9   ; cinco bytes cada uno
	call suma_a_a_hl		;8aeb
	djnz busca_hueco_de_ficha		;8aee   ; y si estan los cinco cogidos, no sale ninguno
	ret			;8af0
arranca_la_ficha:
	ld a,(ix+003h)		;8af1   ; hacia donde va
	and a			;8af4
	ld a,081h		;8af5
	jr nz,L_8AFB		;8af7
	ld a,001h		;8af9
L_8AFB:
	ld (hl),a			;8afb   ; el estado, con el bit 7 puesto cuando va al reves
	inc hl			;8afc
	ld a,(ix+001h)		;8afd   ; la fila
	ld (hl),a			;8b00
	inc hl			;8b01
	ld a,(ix+002h)		;8b02   ; y la columna, copiadas del lanzador
	ld (hl),a			;8b05
	xor a			;8b06
	inc hl			;8b07
	ld (hl),a			;8b08
	inc a			;8b09
	inc hl			;8b0a
	ld (hl),a			;8b0b
	ret			;8b0c
suelta_una_ficha_de_0xe30b:
	ld a,(ix+000h)		;8b0d   ; solo con el bit 7 del estado
	and 080h		;8b10
	ret z			;8b12
	ld c,011h		;8b13   ; el objeto 0x11
	call se_lleva_el_objeto		;8b15
	ld b,002h		;8b18   ; con el, una de cada dos
	jr nz,L_8B1E		;8b1a
	ld b,00ah		;8b1c   ; y sin el, una de cada diez
L_8B1E:
	ld hl,0e12ch		;8b1e   ; la cuenta comun
	inc (hl)			;8b21
	ld a,(hl)			;8b22
	cp b			;8b23
	ret c			;8b24
	ld (hl),000h		;8b25   ; se recarga
	ld a,b			;8b27
	cp 002h		;8b28
	jr nz,L_8B3C		;8b2a
	ld a,011h		;8b2c   ; con el objeto puesto, ademas se gasta
	ld hl,0e150h		;8b2e
	call suma_a_a_hl		;8b31
	dec (hl)			;8b34   ; y cuando se acaba
	jr nz,L_8B3C		;8b35
	ld c,011h		;8b37
	call saca_del_inventario		;8b39   ; el objeto se pierde
L_8B3C:
	ld hl,0e30bh		;8b3c   ; los cuatro huecos de 0xE30B
	ld b,004h		;8b3f   ; siete bytes cada uno
busca_hueco_en_0xe30b:
	ld a,(hl)			;8b41   ; el primero libre
	and a			;8b42
	jr z,arranca_lo_de_0xe30b		;8b43
	ld a,007h		;8b45   ; siete bytes
	call suma_a_a_hl		;8b47
	djnz busca_hueco_en_0xe30b		;8b4a   ; y si no hay, nada
	ret			;8b4c
arranca_lo_de_0xe30b:
	ld a,001h		;8b4d   ; ocupado
	ld (hl),a			;8b4f
	inc hl			;8b50
	ld a,(0e062h)		;8b51   ; la sala de ahora
	ld (hl),a			;8b54
	inc hl			;8b55
	ld a,(ix+001h)		;8b56   ; la fila, de casillas a pixeles
	add a,a			;8b59
	add a,a			;8b5a
	add a,a			;8b5b
	add a,008h		;8b5c
	ld (hl),a			;8b5e
	inc hl			;8b5f
	inc hl			;8b60
	ld a,(ix+002h)		;8b61   ; la columna, lo mismo
	add a,a			;8b64
	add a,a			;8b65
	add a,a			;8b66
	add a,004h		;8b67
	ld (hl),a			;8b69
	inc hl			;8b6a
	ld a,(0e11bh)		;8b6b   ; y hacia donde mira el jugador
	ld (hl),a			;8b6e
	inc hl			;8b6f
	ld (hl),000h		;8b70
	ld a,00bh		;8b72
	jp pide_pieza		;8b74   ; con la pieza 0x0B

; ----------------------------------------------------------------------
; LAS OCHO GOTAS
; ----------------------------------------------------------------------
mueve_las_gotas:
	ld ix,0e3d5h		;8b77   ; los ocho huecos
	ld de,00005h		;8b7b   ; cinco bytes cada uno
	ld b,008h		;8b7e
mueve_las_gotas_bucle:
	exx			;8b80   ; una gota cada vez
	call mueve_una_gota		;8b81
	exx			;8b84
	add ix,de		;8b85
	djnz mueve_las_gotas_bucle		;8b87
	ret			;8b89
mueve_una_gota:
	ld a,(ix+000h)		;8b8a   ; apagada, nada
	and a			;8b8d
	ret z			;8b8e
	and 00fh		;8b8f   ; el bit 7 no cuenta para el estado
	dec a			;8b91
	call reparte_por_tabla		;8b92   ; cuatro estados

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_8b95: 4 entradas; detras sigue la primera, 0x8B9D
;   0x8b95..0x8b9d  (8 bytes)
DATA_tabla_de_subescenas_8b95:
	defw 08b9dh,08bb6h,08bdch,08bf7h	; 8b95  -> gota_formandose gota_cayendo gota_salpicando gota_se_borra

; ======================================================================
; CODIGO 0x8b9d..0x8c15  (120 bytes)
; ======================================================================


gota_formandose:
	dec (ix+004h)		;8b9d   ; la cuenta
	ret nz			;8ba0
	ld a,006h		;8ba1   ; seis cuadros por dibujo
	ld (ix+004h),a		;8ba3
	call pinta_la_gota		;8ba6   ; se pinta
	inc (ix+003h)		;8ba9   ; y el siguiente
	ld a,(ix+003h)		;8bac
	cp 003h		;8baf   ; tres dibujos de formarse
	ret nz			;8bb1
gota_siguiente_estado:
	inc (ix+000h)		;8bb2
	ret			;8bb5
gota_cayendo:
	dec (ix+004h)		;8bb6   ; cinco cuadros por casilla
	ret nz			;8bb9
	ld a,005h		;8bba
	ld (ix+004h),a		;8bbc
	call pinta_la_gota		;8bbf   ; se pinta
	inc (ix+001h)		;8bc2   ; y baja una fila
	ld l,(ix+001h)		;8bc5   ; la de debajo
	inc l			;8bc8
	ld h,(ix+002h)		;8bc9
	call L_45D7		;8bcc   ; a direccion dentro de la sala
	ld a,(hl)			;8bcf   ; si esta libre, sigue cayendo
	and a			;8bd0
	ret z			;8bd1
	ld (ix+004h),006h		;8bd2   ; y si no, seis cuadros y a salpicar
	ld (ix+003h),004h		;8bd6
	jr gota_siguiente_estado		;8bda
gota_salpicando:
	dec (ix+004h)		;8bdc   ; ocho cuadros por dibujo
	ret nz			;8bdf
	ld a,008h		;8be0
	ld (ix+004h),a		;8be2
	call pinta_la_gota		;8be5
	inc (ix+003h)		;8be8   ; el siguiente
	inc (ix+000h)		;8beb
	ld a,(ix+003h)		;8bee   ; y al quinto
	cp 005h		;8bf1
	jp z,suelta_una_ficha_de_0xe30b		;8bf3   ; suelta lo suyo
	ret			;8bf6
gota_se_borra:
	dec (ix+004h)		;8bf7
	ret nz			;8bfa
	call pinta_la_gota		;8bfb   ; el ultimo dibujo esta vacio
	ld (ix+000h),000h		;8bfe   ; y el hueco queda libre
	ret			;8c02
pinta_la_gota:
	ld hl,08c15h		;8c03   ; los ocho dibujos
	ld a,(ix+003h)		;8c06   ; el que toque
	call puntero_numero_a		;8c09
	ld l,(ix+001h)		;8c0c   ; la fila
	ld h,(ix+002h)		;8c0f   ; y la columna
	jp planta_en_la_pantalla		;8c12

; ----------------------------------------------------------------------
; DATOS punteros_de_la_gota: ocho punteros a los dibujos de 0x8C25: la gota
;   formandose, estirandose, cayendo y salpicando
;   0x8c15..0x8c25  (16 bytes)
DATA_punteros_de_la_gota:
	defw 08c25h,08c28h,08c2bh,08c2eh,08c32h,08c36h,08c3ah,08c3dh	; 8c15

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_gota: veintisiete bytes: ocho dibujos con sus filas y
;   columnas delante, y el ultimo esta vacio porque es el que borra
;   0x8c25..0x8c40  (27 bytes)
DATA_dibujos_de_la_gota:
	defb 001h,001h,070h,001h,001h,071h,001h,001h,072h,002h,001h,000h,072h,002h,001h,000h	; 8c25  ..p..q..r...r...
	defb 060h,002h,001h,000h,040h,001h,001h,073h,001h,001h,000h	; 8c35  `...@..s...

; ======================================================================
; CODIGO 0x8c40..0x8c66  (38 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LO QUE LA GOTA DEJA AL SALPICAR
; ----------------------------------------------------------------------
mueve_lo_que_dejan_las_gotas:
	ld ix,0e30bh		;8c40   ; los cuatro huecos
	ld de,00007h		;8c44   ; siete bytes cada uno
	ld b,004h		;8c47   ; cuatro
mueve_lo_que_dejan_bucle:
	exx			;8c49   ; una cada vez
	call mueve_una_de_esas		;8c4a
	exx			;8c4d
	add ix,de		;8c4e
	djnz mueve_lo_que_dejan_bucle		;8c50
	ret			;8c52
mueve_una_de_esas:
	ld a,(ix+000h)		;8c53   ; apagada, nada
	and a			;8c56
	ret z			;8c57
	push af			;8c58
	cp 003h		;8c59   ; en los estados 1 y 2
	call c,mira_el_choque_de_la_ficha		;8c5b   ; se mira si toca al jugador
	call monta_el_sprite_de_esa		;8c5e   ; se monta su sprite
	pop af			;8c61
	dec a			;8c62
	call reparte_por_tabla		;8c63   ; y tres estados

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_8c66: 3 entradas; detras sigue la primera, 0x8C6C
;   0x8c66..0x8c6c  (6 bytes)
DATA_tabla_de_subescenas_8c66:
	defw 08c6ch,08cbch,08cd1h	; 8c66  -> esa_rodando esa_cayendo esa_se_apaga

; ======================================================================
; CODIGO 0x8c6c..0x8d1b  (175 bytes)
; ======================================================================


esa_rodando:
	call esa_se_sale_de_lado		;8c6c   ; mira si tiene que cambiar de sala
	call la_casilla_de_esa		;8c6f   ; la casilla de donde esta
	jr z,esa_siguiente_estado		;8c72
	ld a,l			;8c74   ; una fila mas arriba
	sub 01fh		;8c75
	ld l,a			;8c77
	jr nc,L_8C7B		;8c78
	dec h			;8c7a
L_8C7B:
	ld a,(ix+005h)		;8c7b   ; si va hacia la izquierda
	and a			;8c7e
	jr z,L_8C83		;8c7f
	dec hl			;8c81   ; dos casillas menos
	dec hl			;8c82
L_8C83:
	call casilla_que_frena		;8c83   ; y con una casilla que frene
	jr nz,esa_avanza		;8c86
	ld a,(ix+005h)		;8c88   ; se da la vuelta
	xor 001h		;8c8b
	ld (ix+005h),a		;8c8d
	inc (ix+006h)		;8c90   ; hasta dos veces
	ld a,(ix+006h)		;8c93
	cp 002h		;8c96
	ld a,003h		;8c98   ; y a la tercera, al estado 3
	jr nc,esa_pon_estado		;8c9a
esa_avanza:
	ld de,00180h		;8c9c   ; un pixel y medio por cuadro
	ld l,(ix+003h)		;8c9f   ; su columna, con fraccion
	ld h,(ix+004h)		;8ca2
	ld a,(ix+005h)		;8ca5   ; hacia la derecha se suma
	and a			;8ca8
	jr nz,L_8CAE		;8ca9
	add hl,de			;8cab
	jr esa_guarda_la_columna		;8cac
L_8CAE:
	and a			;8cae   ; y hacia la izquierda se resta
	sbc hl,de		;8caf
esa_guarda_la_columna:
	ld (ix+003h),l		;8cb1
	ld (ix+004h),h		;8cb4
	ret			;8cb7
esa_siguiente_estado:
	inc (ix+000h)		;8cb8
	ret			;8cbb
esa_cayendo:
	call esa_cambia_de_sala		;8cbc   ; mira si se sale de la sala por abajo
	call la_casilla_de_esa		;8cbf   ; la casilla de debajo
	jr nz,esa_vuelve_a_rodar		;8cc2   ; con suelo, se para
	inc (ix+002h)		;8cc4   ; y sin el, dos pixeles mas abajo
	inc (ix+002h)		;8cc7
	ret			;8cca
esa_vuelve_a_rodar:
	ld a,001h		;8ccb   ; al estado 1
esa_pon_estado:
	ld (ix+000h),a		;8ccd
	ret			;8cd0
esa_se_apaga:
	ld (ix+000h),000h		;8cd1   ; el hueco queda libre
	ld c,001h		;8cd5   ; y el sprite, sin dibujo
	jr monta_el_sprite_de_esa_2		;8cd7
monta_el_sprite_de_esa:
	ld c,000h		;8cd9   ; con dibujo
monta_el_sprite_de_esa_2:
	ld hl,0e0f0h		;8cdb   ; el bufer
	exx			;8cde
	ld a,b			;8cdf   ; cual de las cuatro es
	exx			;8ce0
	ld b,a			;8ce1
	ld a,004h		;8ce2   ; se numeran al reves
	sub b			;8ce4
	add a,a			;8ce5   ; cuatro bytes cada una
	add a,a			;8ce6
	call suma_a_a_hl		;8ce7
	ld a,(0e062h)		;8cea   ; si esta en otra sala
	cp (ix+001h)		;8ced
	jr nz,esa_fuera_de_la_pantalla		;8cf0
	ld a,(ix+002h)		;8cf2   ; su fila
	add a,0f7h		;8cf5   ; nueve pixeles mas arriba
	ld b,a			;8cf7
	ld a,c			;8cf8   ; y si se estaba apagando
	and a			;8cf9
	ld a,b			;8cfa
	jr z,esa_escribe_el_sprite		;8cfb
esa_fuera_de_la_pantalla:
	ld a,0e0h		;8cfd   ; a la fila 0xE0, fuera
esa_escribe_el_sprite:
	ld (hl),a			;8cff   ; la fila
	inc hl			;8d00
	ld a,(ix+004h)		;8d01   ; la columna
	add a,0f8h		;8d04   ; ocho pixeles a la izquierda
	ld (hl),a			;8d06
	inc hl			;8d07
	ld a,(0e003h)		;8d08   ; los bits 2 y 3 del contador
	rra			;8d0b
	rra			;8d0c
	and 003h		;8d0d
	ld de,08d1bh		;8d0f   ; pasan los cuatro patrones: el circulo, el ovalo, la raya y el ovalo otra vez
	call suma_a_a_de		;8d12
	ld a,(de)			;8d15
	ld (hl),a			;8d16
	inc hl			;8d17
	ld (hl),00fh		;8d18   ; y siempre en blanco
	ret			;8d1a

; ----------------------------------------------------------------------
; DATOS patrones_de_lo_que_deja_la_gota: cuatro patrones en el orden 0x08,
;   0x0C, 0x10, 0x0C: el circulo, el mismo de canto, una raya y otra vez de
;   canto. Girando
;   0x8d1b..0x8d1f  (4 bytes)
DATA_patrones_de_lo_que_deja_la_gota:
	defb 008h,00ch,010h,00ch	; 8d1b

; ======================================================================
; CODIGO 0x8d1f..0x8e6b  (332 bytes)
; ======================================================================


la_casilla_de_esa:
	ld l,(ix+002h)		;8d1f   ; su fila
	ld h,(ix+004h)		;8d22   ; y su columna
	ld a,(ix+001h)		;8d25
	call casilla_de_la_sala_en_pixeles		;8d28   ; a direccion dentro de la sala
	ld a,(hl)			;8d2b
	and a			;8d2c
	ret			;8d2d
esa_cambia_de_sala:
	ld a,(ix+002h)		;8d2e   ; su fila
	cp 0b0h		;8d31   ; por encima de 0xB0 sigue dentro
	ret c			;8d33
	ld (ix+002h),011h		;8d34   ; y si no, reaparece por arriba
	ld hl,05327h		;8d38   ; la tabla de a que sala se pasa
	ld b,(ix+001h)		;8d3b
	call busca_en_la_tabla_de_salas		;8d3e
	ld (ix+001h),a		;8d41   ; y esa pasa a ser la suya
	ret			;8d44
esa_se_sale_de_lado:
	ld a,(ix+005h)		;8d45   ; a que lado va
	and a			;8d48
	ld a,(ix+004h)		;8d49   ; su columna
	jr nz,esa_se_sale_por_la_izquierda		;8d4c
	cp 0f7h		;8d4e   ; pasada la 0xF7 por la derecha
	ret c			;8d50
	ld (ix+004h),00ah		;8d51   ; reaparece en la 0x0A
	inc (ix+001h)		;8d55   ; de la sala de al lado
	ret			;8d58
esa_se_sale_por_la_izquierda:
	cp 008h		;8d59   ; y por debajo de 8
	ret nc			;8d5b
	ld (ix+004h),0f6h		;8d5c   ; reaparece en la 0xF6
	dec (ix+001h)		;8d60   ; de la anterior
	ret			;8d63

; ----------------------------------------------------------------------
; LO QUE TRAE EL NIVEL: bichos, fichas y trastos
; ----------------------------------------------------------------------
reparte_los_objetos:
	ld a,(hl)			;8d64   ; la lista va por tipos: un byte 0xF0+tipo y detras sus registros
	inc hl			;8d65
	and 00fh		;8d66   ; el nibble bajo dice de que va el tramo
	jr z,tipo_0		;8d68   ; tipo 0
	dec a			;8d6a
	jr z,tipo_1		;8d6b   ; tipo 1
	dec a			;8d6d
	jp z,tipo_2		;8d6e   ; tipo 2
	dec a			;8d71
	jr z,tipo_3		;8d72   ; tipo 3
	dec a			;8d74
	jp z,tipo_4		;8d75   ; tipo 4
	dec a			;8d78
	jr z,tipo_5		;8d79   ; tipo 5
	dec a			;8d7b
	jr z,tipo_6		;8d7c   ; tipo 6
	dec a			;8d7e
	jr z,tipo_7		;8d7f   ; tipo 7
	ld a,(0e2d9h)		;8d81   ; y cualquier otra cosa -el 0xFF que cierra- se cae por aqui y remata
	and a			;8d84
	ret nz			;8d85
	ld a,(0e071h)		;8d86
	and a			;8d89
	ret z			;8d8a   ; si habia algo pendiente
	xor a			;8d8b
	ld (0e2d5h),a		;8d8c   ; se apaga
	ret			;8d8f
tipo_1:
	ld de,0e270h		;8d90   ; a 0xE270
	ld a,002h		;8d93   ; dos bytes de sitio entre registro y registro
	jr mete_registros		;8d95
tipo_0:
	ld de,0e248h		;8d97   ; a 0xE248
	ld a,003h		;8d9a   ; tres
	jr mete_registros		;8d9c
tipo_3:
	ld de,0e2bdh		;8d9e   ; a 0xE2BD
mete_un_registro_de_tres:
	call sala_y_sitio		;8da1   ; el primer byte: sala y sitio
	ld a,(hl)			;8da4   ; el segundo, tal cual
	ld (de),a			;8da5
	inc hl			;8da6
	inc de			;8da7
	ld a,(hl)			;8da8
	and 03fh		;8da9   ; del tercero, los seis bits bajos
	ld (de),a			;8dab
	inc de			;8dac
	ld a,(hl)			;8dad   ; y los dos altos aparte: son LA ENTRADA, el numero de puerta por la que se aparece alli. Las 64 del cartucho emparejan: la puerta j de A dice (B, k) y la k de B dice (A, j)
	rla			;8dae
	rla			;8daf
	rla			;8db0
	and 003h		;8db1
	ld (de),a			;8db3
	inc de			;8db4
	inc de			;8db5
	inc de			;8db6
	inc hl			;8db7
	ld a,(hl)			;8db8   ; mientras no venga otro 0xF0
	cp 0f0h		;8db9
	jr c,mete_un_registro_de_tres		;8dbb
	jp reparte_los_objetos		;8dbd   ; y cuando venga, a por el tramo siguiente
tipo_7:
	ld de,0e2d5h		;8dc0   ; a 0xE2D5, con el mismo formato que el tipo 3
	jr mete_un_registro_de_tres		;8dc3
tipo_5:
	ld de,0e2f9h		;8dc5   ; a 0xE2F9
	jr L_8DCD		;8dc8
tipo_6:
	ld de,0e2edh		;8dca   ; a 0xE2ED
L_8DCD:
	ld a,001h		;8dcd   ; un byte de sitio
mete_registros:
	ld c,002h		;8dcf   ; dos bytes por registro, ademas de la sala y el sitio
un_registro:
	push af			;8dd1
	call sala_y_sitio		;8dd2
	pop af			;8dd5
	ld b,000h		;8dd6
	push bc			;8dd8
	ldir		;8dd9   ; los dos bytes, tal cual
	pop bc			;8ddb
	ld b,a			;8ddc   ; y el hueco que el tipo deja detras
	call suma_a_a_de		;8ddd
	ld a,(hl)			;8de0   ; mientras no venga un 0xF0
	cp 0f0h		;8de1
	ld a,b			;8de3
	jr c,un_registro		;8de4
	jp reparte_los_objetos		;8de6
sala_y_sitio:
	ld a,001h		;8de9   ; el 1 dice que la casilla esta ocupada
	ld (de),a			;8deb
	inc de			;8dec
	ld a,(hl)			;8ded   ; del byte, los bits 7 y 6 son LA SALA
	rla			;8dee   ; tres rotaciones a la izquierda los bajan al 1 y al 0
	rla			;8def
	rla			;8df0
	and 003h		;8df1
	ld (de),a			;8df3
	inc de			;8df4
	ld a,(hl)			;8df5   ; y los seis de abajo son el sitio dentro de la sala
	and 03fh		;8df6
	ld (de),a			;8df8
	inc hl			;8df9
	inc de			;8dfa
	ret			;8dfb
tipo_4:
	ld de,0e2ddh		;8dfc   ; a 0xE2DD
L_8DFF:
	ld a,(0e120h)		;8dff   ; y este ademas lleva la cuenta de cuantos hay
	inc a			;8e02
	ld (0e120h),a		;8e03
	call sala_y_sitio		;8e06
	ld bc,00001h		;8e09   ; un solo byte de carga
	ldir		;8e0c
	ld a,(hl)			;8e0e
	cp 0f0h		;8e0f
	jr c,L_8DFF		;8e11
	jp reparte_los_objetos		;8e13

; ----------------------------------------------------------------------
; EL TIPO 2: dos bytes que se despliegan en un sprite entero
; ----------------------------------------------------------------------
tipo_2:
	ld de,0e4d1h		;8e16   ; a 0xE4D1
L_8E19:
	ld a,(hl)			;8e19   ; el primer byte
	rla			;8e1a   ; los bits 7 y 6, la sala
	rla			;8e1b
	rla			;8e1c
	and 003h		;8e1d
	push af			;8e1f
	ld (de),a			;8e20
	inc de			;8e21
	inc de			;8e22
	inc hl			;8e23
	ld a,(hl)			;8e24   ; el segundo
	and 0f0h		;8e25   ; su nibble alto
	or 00dh		;8e27   ; con un 0x0D pegado
	ld c,a			;8e29
	ld (de),a			;8e2a
	inc de			;8e2b
	inc de			;8e2c
	ld a,(hl)			;8e2d   ; y el bajo, subido a nibble alto
	rla			;8e2e
	rla			;8e2f
	rla			;8e30
	rla			;8e31
	and 0f0h		;8e32
	ld b,a			;8e34
	ld (de),a			;8e35
	ld a,00bh		;8e36   ; once bytes mas alla
	call suma_a_a_de		;8e38
	ld a,00dh		;8e3b
	ld (de),a			;8e3d
	dec hl			;8e3e
	inc de			;8e3f
	ld a,(hl)			;8e40   ; los seis bits bajos del primero: el sitio
	and 03fh		;8e41
	ld (de),a			;8e43
	inc hl			;8e44
	dec de			;8e45
	dec de			;8e46
	push hl			;8e47
	ld hl,08e6bh		;8e48   ; la tabla de ocho segun el nibble bajo
	and 00fh		;8e4b
	call suma_a_a_hl		;8e4d
	ld a,(hl)			;8e50
	pop hl			;8e51
	ld (de),a			;8e52
	ld a,011h		;8e53   ; y diecisiete mas alla
	call suma_a_a_de		;8e55
	ex de,hl			;8e58
	ld (hl),c			;8e59
	inc hl			;8e5a
	ld (hl),b			;8e5b
	inc hl			;8e5c
	pop af			;8e5d
	ld (hl),a			;8e5e
	ex de,hl			;8e5f
	inc de			;8e60
	inc de			;8e61
	inc hl			;8e62
	ld a,(hl)			;8e63
	cp 0f0h		;8e64
	jr c,L_8E19		;8e66
	jp reparte_los_objetos		;8e68

; ----------------------------------------------------------------------
; DATOS estado_de_arranque_del_perseguidor: ocho bytes: 0x80 para el primero,
;   0x84 para cuatro mas y cero para los tres ultimos. 0x8E48 entra con el
;   nibble bajo del segundo byte del registro
;   0x8e6b..0x8e73  (8 bytes)
DATA_estado_de_arranque_del_perseguidor:
	defb 080h,084h,084h,084h,084h,000h,000h,000h	; 8e6b  ........

; ======================================================================
; CODIGO 0x8e73..0x8f89  (278 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LO QUE LLEVA MONTADO CADA SALA
; ----------------------------------------------------------------------
reparte_los_trastos:
	ld a,(hl)			;8e73   ; la misma pinta que la lista del nivel: 0xF0+tipo y sus registros
	inc hl			;8e74
	and 00fh		;8e75
	jr z,trastos_tipo_0		;8e77   ; tipo 0
	dec a			;8e79
	jr z,trastos_tipo_1		;8e7a   ; tipo 1
	dec a			;8e7c
	jr z,trastos_tipo_2		;8e7d   ; tipo 2
	dec a			;8e7f
	jr z,trastos_tipo_3		;8e80   ; tipo 3
	dec a			;8e82
	jr z,trastos_tipo_4		;8e83   ; tipo 4
	dec a			;8e85
	jr z,trastos_tipo_5		;8e86   ; tipo 5
	dec a			;8e88
	jp z,trastos_tipo_6		;8e89   ; tipo 6
	dec a			;8e8c
	jp z,trastos_tipo_7		;8e8d   ; tipo 7
	ret			;8e90   ; y el 0xFF cierra
trastos_tipo_4:
	ld de,0e3bdh		;8e91   ; a 0xE3BD
L_8E94:
	call trasto_con_sitio		;8e94
	inc de			;8e97   ; un byte de hueco
	ld a,(hl)			;8e98
	cp 0f0h		;8e99
	jr c,L_8E94		;8e9b
	jr reparte_los_trastos		;8e9d
trastos_tipo_0:
	ld de,0e345h		;8e9f   ; a 0xE345
	ld c,004h		;8ea2   ; cuatro bytes de carga
	ld a,005h		;8ea4   ; y uno de hueco
L_8EA6:
	call mete_un_trasto		;8ea6
	jr reparte_los_trastos		;8ea9
mete_un_trasto:
	ex de,hl			;8eab
	ld (hl),001h		;8eac   ; el 1 de ocupado va DELANTE del registro
	ex de,hl			;8eae
	inc de			;8eaf
	ld b,000h		;8eb0
	push bc			;8eb2
	ldir		;8eb3   ; y detras, los bytes tal cual
	pop bc			;8eb5
	ld b,a			;8eb6
	call suma_a_a_de		;8eb7   ; mas el hueco del tipo
	ld a,(hl)			;8eba   ; mientras no venga un 0xF0
	cp 0f0h		;8ebb
	ld a,b			;8ebd
	jr c,mete_un_trasto		;8ebe
	ret			;8ec0
trastos_tipo_1:
	ld de,0e327h		;8ec1   ; a 0xE327, cinco bytes por registro
	ld c,005h		;8ec4
	ld a,004h		;8ec6
	jr L_8EA6		;8ec8
trastos_tipo_2:
	ld de,0e363h		;8eca   ; a 0xE363, dos bytes
	ld c,002h		;8ecd
	ld a,003h		;8ecf
	jr L_8EA6		;8ed1
trastos_tipo_3:
	ld de,0e375h		;8ed3   ; a 0xE375
L_8ED6:
	call trasto_con_sitio		;8ed6
	inc de			;8ed9   ; y cuatro bytes de hueco
	inc de			;8eda
	inc de			;8edb
	inc de			;8edc
	ld a,(hl)			;8edd
	cp 0f0h		;8ede
	jr c,L_8ED6		;8ee0
	jr reparte_los_trastos		;8ee2
trasto_con_sitio:
	ld a,001h		;8ee4   ; ocupado
	ld (de),a			;8ee6
	inc de			;8ee7
	ld a,(hl)			;8ee8   ; el primer byte, tal cual
	ld (de),a			;8ee9
	inc hl			;8eea
	inc de			;8eeb
	ld a,(hl)			;8eec   ; del segundo, siete bits
	and 07fh		;8eed
	ld (de),a			;8eef
	inc de			;8ef0
	ld a,(hl)			;8ef1   ; y el de mas peso, aparte
	rla			;8ef2
	rla			;8ef3
	and 001h		;8ef4
	ld (de),a			;8ef6
	inc hl			;8ef7
	inc de			;8ef8
	ld a,(hl)			;8ef9   ; y un tercero, tal cual
	ld (de),a			;8efa
	inc hl			;8efb
	inc de			;8efc
	ret			;8efd
trastos_tipo_5:
	ld de,0e3fdh		;8efe   ; a 0xE3FD
L_8F01:
	ld a,001h		;8f01
	ld (de),a			;8f03
	inc de			;8f04
	ld a,(hl)			;8f05   ; el primer byte
	ld (de),a			;8f06
	inc de			;8f07
	inc de			;8f08
	inc hl			;8f09
	ld a,(hl)			;8f0a   ; del segundo, el nibble alto
	and 0f0h		;8f0b
	or 00dh		;8f0d   ; con un 0x0D pegado, como en el tipo 2 del nivel
	ld (de),a			;8f0f
	inc de			;8f10
	inc de			;8f11
	ld a,(hl)			;8f12   ; y el bajo, subido
	rla			;8f13
	rla			;8f14
	rla			;8f15
	rla			;8f16
	and 0f0h		;8f17
	ld (de),a			;8f19
	inc hl			;8f1a
	ld a,009h		;8f1b   ; nueve bytes de hueco
	call suma_a_a_de		;8f1d
	ld a,(hl)			;8f20
	cp 0f0h		;8f21
	jr c,L_8F01		;8f23
	jp reparte_los_trastos		;8f25
trastos_tipo_6:
	ld de,0e443h		;8f28   ; a 0xE443
L_8F2B:
	ld a,001h		;8f2b
	ld (de),a			;8f2d
	inc de			;8f2e
	inc de			;8f2f
	ld a,(hl)			;8f30
	ld (de),a			;8f31
	ld (0e124h),a		;8f32   ; y ademas se copia a 0xE124
	inc de			;8f35
	inc de			;8f36
	inc hl			;8f37
	ld a,(hl)			;8f38
	ld (de),a			;8f39
	ld (0e125h),a		;8f3a   ; y a 0xE125, para tenerlo a mano
	inc hl			;8f3d
	ld a,(hl)			;8f3e
	cp 0f0h		;8f3f
	jr c,L_8F2B		;8f41
	jp reparte_los_trastos		;8f43
trastos_tipo_7:
	ld de,0e453h		;8f46   ; a 0xE453
L_8F49:
	ld a,001h		;8f49
	ld (de),a			;8f4b
	inc de			;8f4c
	ld a,(hl)			;8f4d
	ld (de),a			;8f4e
	ld (0e1b2h),a		;8f4f   ; copiado tambien a 0xE1B2
	inc de			;8f52
	inc hl			;8f53
	ld a,(hl)			;8f54
	ld (de),a			;8f55
	add a,0fch		;8f56   ; y el segundo, menos cuatro, a 0xE1B3
	ld (0e1b3h),a		;8f58
	inc hl			;8f5b
	ld a,(hl)			;8f5c
	cp 0f0h		;8f5d
	jr c,L_8F49		;8f5f
	jp reparte_los_trastos		;8f61

; ----------------------------------------------------------------------
; EL BICHO DE LA SALA
; ----------------------------------------------------------------------
mueve_al_bicho:
	ld a,(0e453h)		;8f64   ; si no lo hay, nada
	and a			;8f67
	ret z			;8f68
	xor a			;8f69   ; se empieza sin tocar a nadie
	ld (0e465h),a		;8f6a
	call bicho_estado		;8f6d   ; su estado
	call monta_el_sprite_del_bicho		;8f70   ; y su sprite
	ld a,(0e453h)		;8f73   ; en los estados 3 y 4
	cp 003h		;8f76
	ret c			;8f78
	cp 005h		;8f79
	ret nc			;8f7b
	call bicho_recibe_una_patada		;8f7c   ; se mira si le da al jugador
	jp bicho_toca_al_jugador		;8f7f
bicho_estado:
	ld a,(0e453h)		;8f82   ; seis estados
	dec a			;8f85
	call reparte_por_tabla		;8f86

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas_8f89: 6 entradas; detras sigue la primera, 0x8F95
;   0x8f89..0x8f95  (12 bytes)
DATA_tabla_de_subescenas_8f89:
	defw 08f95h,08fcah,08fe9h,0902ch,0917fh,0918bh	; 8f89

; ======================================================================
; CODIGO 0x8f95..0x9027  (146 bytes)
; ======================================================================


bicho_dormido:
	ld a,(0e1b1h)		;8f95   ; con algo en marcha, no
	and a			;8f98
	ret nz			;8f99
	ld c,013h		;8f9a   ; el objeto 0x13
	call se_lleva_el_objeto		;8f9c   ; si se lleva, el bicho ni se despierta
	jr nz,bicho_se_despierta		;8f9f
	ld hl,0e1b2h		;8fa1   ; el sitio donde esta escondido
	ld d,(hl)			;8fa4
	inc hl			;8fa5
	ld e,(hl)			;8fa6
	ld h,008h		;8fa7   ; ocho por ocho
	ld l,h			;8fa9
	call toca_al_jugador		;8faa   ; y hasta que el jugador no lo pisa, nada
	ret z			;8fad
bicho_se_despierta:
	ld hl,0e454h		;8fae   ; de donde sale
	ld de,0e459h		;8fb1
	ld a,(hl)			;8fb4
	add a,003h		;8fb5   ; tres pixeles mas abajo
	ld (de),a			;8fb7
	inc hl			;8fb8
	inc de			;8fb9
	inc de			;8fba
	ld a,(hl)			;8fbb
	add a,00dh		;8fbc   ; y trece a la derecha
	ld (de),a			;8fbe
	ld a,040h		;8fbf   ; 0x40 cuadros
	ld (0e45fh),a		;8fc1
	xor a			;8fc4
	ld (0e463h),a		;8fc5
	jr bicho_siguiente_estado		;8fc8
bicho_saliendo:
	ld de,0e462h		;8fca   ; el color
	ld a,(0e003h)		;8fcd   ; el bit 2 del contador
	bit 2,a		;8fd0
	ld a,00fh		;8fd2   ; lo turna entre blanco y nada: mientras sale, parpadea
	jr z,L_8FD7		;8fd4
	xor a			;8fd6
L_8FD7:
	ld (de),a			;8fd7
	ld hl,0e45fh		;8fd8   ; la cuenta
	dec (hl)			;8fdb
	ret nz			;8fdc
	ld a,00fh		;8fdd   ; y al acabarse se queda blanco
	ld (de),a			;8fdf
	ld a,001h		;8fe0
	dec hl			;8fe2
	ld (hl),a			;8fe3
	dec hl			;8fe4
	xor a			;8fe5
	ld (hl),a			;8fe6
	jr bicho_siguiente_estado		;8fe7
bicho_apunta_al_jugador:
	ld hl,0e113h		;8fe9   ; la fila del jugador
	ld a,(hl)			;8fec
	add a,0f8h		;8fed   ; ocho mas arriba
	ld e,a			;8fef
	inc hl			;8ff0
	inc hl			;8ff1
	ld d,(hl)			;8ff2   ; y su columna
	ld (0e460h),de		;8ff3
	ld a,(0e460h)		;8ff7
	ld hl,0e459h		;8ffa   ; contra la fila del bicho
	cp (hl)			;8ffd
	ld b,000h		;8ffe   ; por debajo
	jr c,L_9008		;9000
	ld b,002h		;9002   ; por encima
	jr nz,L_9008		;9004
	ld b,00ah		;9006   ; o a la misma altura
L_9008:
	ld a,(0e461h)		;9008   ; y lo mismo con la columna
	inc hl			;900b
	inc hl			;900c
	cp (hl)			;900d
	ld c,001h		;900e
	jr c,L_9018		;9010
	ld c,000h		;9012
	jr nz,L_9018		;9014
	ld c,005h		;9016
L_9018:
	ld a,b			;9018
	or c			;9019
	ld (0e45ch),a		;901a   ; los cuatro bits juntos son el rumbo, y ya no se toca mas
	ld a,0ffh		;901d   ; y la cuenta al tope
	ld (0e45fh),a		;901f
bicho_siguiente_estado:
	ld hl,0e453h		;9022
	inc (hl)			;9025
	ret			;9026

; ----------------------------------------------------------------------
; DATOS colores_por_patada_del_bicho: cinco colores: el bicho va cambiando de
;   color a cada patada que aguanta, y 0x903F entra con las que lleva
;   0x9027..0x902c  (5 bytes)
DATA_colores_por_patada_del_bicho:
	defb 00fh,00bh,003h,008h,007h	; 9027

; ======================================================================
; CODIGO 0x902c..0x90df  (179 bytes)
; ======================================================================


bicho_volando:
	ld a,(0e1b1h)		;902c   ; con algo en marcha, no
	and a			;902f
	ret nz			;9030
	ld hl,0e464h		;9031   ; la cuenta del color
	ld a,(hl)			;9034
	and a			;9035
	jr z,bicho_se_mueve		;9036
	dec (hl)			;9038   ; que va bajando
	ld a,(hl)			;9039
	and a			;903a
	jr nz,bicho_se_mueve		;903b
	dec hl			;903d
	ld a,(hl)			;903e   ; y al llegar a cero cambia de color
	ld de,09027h		;903f
	call suma_a_a_de		;9042
	ld a,(de)			;9045
	dec hl			;9046
	ld (hl),a			;9047
bicho_se_mueve:
	call bicho_avanza		;9048   ; el avance
	call bicho_vaiven		;904b   ; y el vaiven
	ld hl,0e456h		;904e   ; lo que el vaiven desplaza
	ld de,0e459h		;9051   ; sobre donde esta
	ld a,(de)			;9054
	add a,(hl)			;9055
	ld (0e454h),a		;9056   ; sale la fila que se pinta
	inc hl			;9059
	inc de			;905a
	inc de			;905b
	ld a,(hl)			;905c   ; y la columna, con signo
	and a			;905d
	jp p,bicho_columna_a_la_derecha		;905e
	neg		;9061   ; hacia la izquierda
	ld b,a			;9063
	ld a,(de)			;9064
	sub b			;9065
	jr nc,bicho_guarda_la_columna		;9066
	xor a			;9068   ; sin pasarse de cero
	jr bicho_guarda_la_columna		;9069
bicho_columna_a_la_derecha:
	ld b,a			;906b
	ld a,(de)			;906c
	add a,b			;906d
	cp 0f3h		;906e   ; y sin pasarse de 0xF3
	jr c,bicho_guarda_la_columna		;9070
	ld a,0f3h		;9072
bicho_guarda_la_columna:
	ld (0e455h),a		;9074
	ret			;9077
bicho_avanza:
	ld c,000h		;9078   ; si ya esta en la fila del jugador
	ld hl,0e460h		;907a
	ld de,0e459h		;907d
	ld a,(de)			;9080
	cp (hl)			;9081
	jr z,L_9085		;9082
	inc c			;9084
L_9085:
	inc hl			;9085   ; y en su columna
	inc de			;9086
	inc de			;9087
	ld a,(de)			;9088
	cp (hl)			;9089
	ld b,000h		;908a
	jr z,L_9090		;908c
	ld b,002h		;908e
L_9090:
	ld a,b			;9090
	or c			;9091
	jr nz,bicho_avanza_de_verdad		;9092
	ld hl,0e453h		;9094   ; el bicho se para: al estado de antes
	dec (hl)			;9097
	ret			;9098
bicho_avanza_de_verdad:
	push af			;9099
	ld hl,090dfh		;909a   ; lo que avanza en fila
	call puntero_numero_a		;909d
	ld a,(0e45ch)		;90a0   ; el rumbo
	bit 3,a		;90a3   ; con el bit 3 no se mueve en vertical
	jr nz,bicho_avanza_en_columna		;90a5
	bit 1,a		;90a7   ; el bit 1 dice hacia abajo
	ld hl,(0e458h)		;90a9
	jr nz,L_90B3		;90ac
	and a			;90ae   ; hacia arriba se resta
	sbc hl,de		;90af
	jr L_90B4		;90b1
L_90B3:
	add hl,de			;90b3   ; y hacia abajo se suma
L_90B4:
	ld (0e458h),hl		;90b4
bicho_avanza_en_columna:
	pop af			;90b7
	ld hl,090e7h		;90b8   ; lo que avanza en columna
	call puntero_numero_a		;90bb
	ld a,(0e45ch)		;90be
	bit 2,a		;90c1   ; con el bit 2 no se mueve de lado
	jr nz,bicho_cuenta_de_vida		;90c3
	bit 0,a		;90c5   ; el bit 0 dice hacia donde
	ld hl,(0e45ah)		;90c7
	jr z,L_90D1		;90ca
	and a			;90cc
	sbc hl,de		;90cd
	jr L_90D2		;90cf
L_90D1:
	add hl,de			;90d1
L_90D2:
	ld (0e45ah),hl		;90d2
bicho_cuenta_de_vida:
	ld hl,0e45fh		;90d5   ; y la cuenta de vida
	dec (hl)			;90d8
	ret nz			;90d9
	ld hl,0e453h		;90da   ; al acabarse, se para
	dec (hl)			;90dd
	ret			;90de

; ----------------------------------------------------------------------
; DATOS avance_del_bicho: ocho palabras de dieciseis bits en dos tandas: lo
;   que avanza en fila y lo que avanza en columna, segun el rumbo. Los ceros
;   son los rumbos en los que no se mueve por ese eje
;   0x90df..0x90ef  (16 bytes)
DATA_avance_del_bicho:
	defw 00000h,00100h,00000h,000b5h,00000h,00000h,00100h,000b5h	; 90df

; ======================================================================
; CODIGO 0x90ef..0x912d  (62 bytes)
; ======================================================================


bicho_vaiven:
	ld hl,0e45eh		;90ef   ; un paso cada cuadro
	dec (hl)			;90f2
	ret nz			;90f3
	ld (hl),001h		;90f4
	dec hl			;90f6
	ld a,(hl)			;90f7
	bit 6,a		;90f8   ; el bit 6 dice si el vaiven va o vuelve
	jr nz,bicho_vaiven_atras		;90fa
	inc (hl)			;90fc   ; hacia delante
	ld a,(hl)			;90fd
	and 03fh		;90fe   ; dieciseis pasos
	cp 010h		;9100
	jr c,bicho_vaiven_aplica		;9102
L_9104:
	ld a,(hl)			;9104   ; y en el tope se da la vuelta
	add a,040h		;9105
	ld (hl),a			;9107
	jr bicho_vaiven_aplica		;9108
bicho_vaiven_atras:
	dec (hl)			;910a   ; hacia atras
	ld a,(hl)			;910b
	and 03fh		;910c   ; hasta cero
	jr z,L_9104		;910e
bicho_vaiven_aplica:
	ld b,(hl)			;9110
	ld hl,0e456h		;9111   ; el desplazamiento
	ld a,b			;9114
	and 00fh		;9115   ; solo en los pasos redondos
	jr nz,$+30		;9117
	ld de,0912dh		;9119   ; la tabla de cuatro parejas
	ld a,b			;911c
	rla			;911d   ; los dos bits altos eligen
	rla			;911e
	rla			;911f
	and 003h		;9120
	add a,a			;9122
	call suma_a_a_de		;9123
	ld a,(de)			;9126
	ld (hl),a			;9127
	inc de			;9128
	inc hl			;9129
	ld a,(de)			;912a
	ld (hl),a			;912b
	ret			;912c

; ----------------------------------------------------------------------
; DATOS desplazamiento_del_vaiven: cuatro parejas de fila y columna: las
;   cuatro direcciones del vaiven del bicho, con 0xF0 y 0x10 como los dos
;   sentidos
;   0x912d..0x9135  (8 bytes)
DATA_desplazamiento_del_vaiven:
	defb 000h,0f0h,0f0h,000h,000h,010h,010h,000h	; 912d  ........

; ======================================================================
; CODIGO 0x9135..0x916e  (57 bytes)
; ======================================================================


bicho_seno:
	ld de,0916eh		;9135   ; la tabla de senos
	call suma_a_a_de		;9138
	ld a,(de)			;913b
	rra			;913c   ; entre dieciseis
	rra			;913d
	rra			;913e
	rra			;913f
	and 00fh		;9140
	bit 7,b		;9142   ; con signo segun el bit 7
	jr nz,bicho_seno_la_otra_mitad		;9144
	neg		;9146
bicho_seno_la_otra_mitad:
	ld (hl),a			;9148   ; la primera componente
	inc hl			;9149
	ld a,b			;914a   ; y la segunda es la del angulo complementario: dieciseis menos el paso
	and 03fh		;914b
	ld c,a			;914d
	ld a,010h		;914e   ; dieciseis menos: el angulo complementario
	sub c			;9150
	ld de,0916eh		;9151   ; en la misma tabla
	call suma_a_a_de		;9154
	ld a,(de)			;9157
	rra			;9158
	rra			;9159
	rra			;915a
	rra			;915b
	and 00fh		;915c
	ld c,a			;915e
	ld a,b			;915f
	and 0c0h		;9160
	jr z,L_9169		;9162
	cp 0c0h		;9164
	ld a,c			;9166
	jr nz,L_916C		;9167
L_9169:
	ld a,c			;9169
	neg		;916a
L_916C:
	ld (hl),a			;916c
	ret			;916d

; ----------------------------------------------------------------------
; DATOS senos_del_vaiven: diecisiete valores: un cuarto de onda, que 0x9135
;   lee dos veces -por el paso y por su complementario a dieciseis- para sacar
;   las dos componentes del vaiven
;   0x916e..0x917f  (17 bytes)
DATA_senos_del_vaiven:
	defb 000h,019h,031h,044h,061h,078h,08eh,0a2h,0b5h,0c5h,0d4h,0e1h,0ech,0f4h,0fbh,0feh,000h	; 916e  ..1Dax...........

; ======================================================================
; CODIGO 0x917f..0x927f  (256 bytes)
; ======================================================================


bicho_esperando:
	ld hl,0e45fh		;917f   ; la cuenta
	dec (hl)			;9182
	ret nz			;9183
	xor a			;9184   ; el color a cero
	ld (0e462h),a		;9185
	jp bicho_siguiente_estado		;9188   ; y al estado siguiente
bicho_vuelve_a_esconderse:
	ld hl,(0e1b2h)		;918b   ; donde estaba escondido
	ld a,h			;918e
	add a,004h		;918f   ; cuatro pixeles a la derecha
	ld h,a			;9191
	ld (0e454h),hl		;9192
	ld a,001h		;9195   ; y a esperar otra vez
	ld (0e453h),a		;9197
	ret			;919a
monta_el_sprite_del_bicho:
	ld hl,0e454h		;919b   ; su sitio
	ld de,0e0d4h		;919e   ; y su hueco del bufer
	ld a,(hl)			;91a1   ; la fila, ocho pixeles arriba
	add a,0f8h		;91a2
	ld (de),a			;91a4
	inc de			;91a5
	inc hl			;91a6
	ld a,(hl)			;91a7   ; la columna, ocho a la izquierda
	add a,0f8h		;91a8
	ld (de),a			;91aa
	inc de			;91ab
	inc hl			;91ac
	ld a,(0e453h)		;91ad   ; en el estado 5
	cp 005h		;91b0
	ld a,004h		;91b2   ; el patron 4, que es el de irse
	jr z,bicho_escribe_el_color		;91b4
	ld a,(0e003h)		;91b6   ; y si no, el bit 3 del contador
	bit 3,a		;91b9
	ld a,09ch		;91bb   ; turna el bicho
	jr nz,bicho_escribe_el_color		;91bd
	ld a,0f4h		;91bf   ; con su espejo
bicho_escribe_el_color:
	ld (de),a			;91c1
	inc de			;91c2
	ld hl,0e464h		;91c3   ; la cuenta del parpadeo
	ld a,(hl)			;91c6
	dec hl			;91c7
	dec hl			;91c8
	and a			;91c9
	ld b,(hl)			;91ca   ; el color de ahora
	jr z,bicho_guarda_el_color		;91cb
	ld a,(0e003h)		;91cd   ; si esta parpadeando, el bit 1 del contador
	bit 1,a		;91d0
	jr z,bicho_guarda_el_color		;91d2
	ld b,000h		;91d4   ; lo apaga la mitad de los cuadros
bicho_guarda_el_color:
	ld a,b			;91d6
	ld (de),a			;91d7
	ret			;91d8
bicho_toca_al_jugador:
	call caja_del_bicho		;91d9   ; su caja
	call toca_al_jugador		;91dc   ; si le toca
	jr z,bicho_esta_en_su_sitio		;91df
	ld a,(0e1b1h)		;91e1   ; y no hay nada en marcha
	and a			;91e4
	jr nz,bicho_se_acaba_de_golpe		;91e5
	jr bicho_hace_dano		;91e7   ; le hace dano
bicho_esta_en_su_sitio:
	ld de,0e459h		;91e9   ; donde esta
	ld hl,0e460h		;91ec   ; contra a donde iba
	ld a,(0e113h)		;91ef   ; la fila del jugador
	add a,0f8h		;91f2   ; ocho arriba
	ld b,a			;91f4
	ld a,(de)			;91f5
	cp (hl)			;91f6   ; si no ha llegado, nada
	ret nz			;91f7
	cp b			;91f8   ; ni si el jugador se movio
	ret nz			;91f9
	inc de			;91fa
	inc de			;91fb
	inc hl			;91fc
	ld a,(0e115h)		;91fd   ; y lo mismo con la columna
	ld b,a			;9200
	ld a,(de)			;9201
	cp (hl)			;9202
	ret nz			;9203
	cp b			;9204
	ret nz			;9205
bicho_hace_dano:
	ld a,001h		;9206   ; (0xE465) avisa de que este cuadro ha tocado
	ld (0e465h),a		;9208
	call dano_de_la_fuga		;920b   ; y duele lo que la fuga
	ret			;920e
bicho_recibe_una_patada:
	ld a,(0e464h)		;920f   ; mientras parpadea no se le puede pegar
	and a			;9212
	ret nz			;9213
	call caja_del_bicho		;9214   ; su caja
	call le_da_una_patada		;9217   ; y si el jugador le da una patada
	ret z			;921a
	ld a,(0e1b1h)		;921b   ; con algo en marcha, se acaba de golpe
	and a			;921e
	jr nz,bicho_se_acaba_de_golpe		;921f
	ld de,00100h		;9221   ; 0x0100 puntos
	call pieza_del_choque		;9224
	ld c,006h		;9227   ; el objeto 6
	call se_lleva_el_objeto		;9229   ; si NO se lleva
	jr nz,bicho_se_va_a_patadas		;922c
	ld hl,0e463h		;922e   ; se cuentan las patadas
	inc (hl)			;9231
	ld a,(hl)			;9232
	inc hl			;9233
	ld (hl),00ah		;9234   ; diez cuadros de parpadeo
	cp 005h		;9236   ; y hacen falta cinco
	ret c			;9238
bicho_se_va_a_patadas:
	ld c,006h		;9239   ; el objeto 6
	call se_lleva_el_objeto		;923b
	call nz,gasta_un_uso_del_objeto		;923e   ; se gasta
	ld c,013h		;9241   ; y el 0x13
	call se_lleva_el_objeto		;9243
	call nz,gasta_un_uso_del_objeto		;9246   ; tambien
bicho_se_acaba:
	xor a			;9249   ; sin patadas apuntadas
	ld (0e464h),a		;924a
	ld a,008h		;924d   ; ocho cuadros
	ld (0e45fh),a		;924f
	ld a,005h		;9252   ; y al estado 5, el de irse
	ld (0e453h),a		;9254
	ret			;9257
bicho_se_acaba_de_golpe:
	ld de,01000h		;9258   ; 0x1000 puntos
	call pieza_del_choque		;925b
	jr bicho_se_acaba		;925e
gasta_un_uso_del_objeto:
	ld a,c			;9260   ; los usos que le quedan
	ld hl,0e150h		;9261
	call suma_a_a_hl		;9264
	dec (hl)			;9267   ; uno menos
	ld a,(hl)			;9268
	and a			;9269
	ret nz			;926a
	jp saca_del_inventario		;926b   ; y al acabarse, fuera del inventario
caja_del_bicho:
	ld hl,0e454h		;926e   ; su sitio
	ld a,(hl)			;9271
	add a,0f9h		;9272   ; siete pixeles arriba
	ld d,a			;9274
	inc hl			;9275
	ld a,(hl)			;9276
	add a,0f9h		;9277   ; y siete a la izquierda
	ld e,a			;9279
	ld h,00eh		;927a   ; catorce por catorce
	ld l,00eh		;927c
	ret			;927e

; ----------------------------------------------------------------------
; DATOS patrones_de_sprite: RLE con la direccion dentro: 1344 bytes en 0x1800,
;   o sea 42 patrones de 16x16
;   0x927f..0x95db  (860 bytes)
DATA_patrones_de_sprite:
	defb 000h,018h,020h,0ffh,08bh,000h,004h,000h,020h,010h,000h,000h,060h,000h,000h,008h	; 927f  .. ..... ...`...
	defb 006h,000h,08ah,040h,000h,008h,010h,000h,000h,00ch,000h,000h,020h,007h,000h,08ch	; 928f  ...@........ ...
	defb 003h,00ch,012h,014h,02ah,02ch,02eh,02ah,014h,012h,00ch,003h,004h,000h,08ch,0c0h	; 929f  ....*,.*........
	defb 030h,088h,028h,094h,034h,094h,094h,028h,098h,030h,0c0h,004h,000h,086h,001h,002h	; 92af  0.(.4..(.0......
	defb 003h,007h,005h,005h,003h,006h,083h,003h,002h,001h,004h,000h,083h,080h,040h,040h	; 92bf  ..............@@
	defb 006h,0a0h,002h,040h,081h,080h,005h,000h,08bh,003h,000h,003h,000h,003h,000h,003h	; 92cf  ...@............
	defb 000h,003h,000h,003h,013h,000h,086h,020h,060h,010h,008h,006h,004h,01ch,000h,083h	; 92df  ....... `.......
	defb 040h,07eh,002h,01bh,000h,081h,018h,004h,010h,081h,030h,019h,000h,002h,0c0h,01eh	; 92ef  @~........0.....
	defb 000h,002h,010h,086h,03ah,03bh,07bh,065h,041h,040h,008h,000h,002h,010h,002h,0b8h	; 92ff  ....:;{eA@......
	defb 084h,0bch,04ch,004h,004h,008h,000h,088h,008h,00ah,00dh,00bh,00bh,00dh,004h,004h	; 930f  ..L.............
	defb 008h,000h,088h,020h,0a0h,040h,0a0h,0a0h,060h,040h,040h,008h,000h,088h,07ch,032h	; 931f  ... .@..`@@...|2
	defb 010h,008h,004h,00ch,01ch,018h,018h,000h,081h,003h,004h,007h,08ch,003h,00dh,01eh	; 932f  ................
	defb 01fh,007h,003h,00fh,00bh,004h,003h,001h,0c0h,004h,0e0h,090h,0c0h,0b0h,078h,0f8h	; 933f  ..............x.
	defb 0e0h,0c0h,0f0h,0d0h,020h,0c0h,080h,00fh,00bh,004h,003h,001h,00bh,000h,085h,0f0h	; 934f  .... ...........
	defb 0d0h,020h,0c0h,080h,00bh,000h,0a6h,003h,007h,007h,00fh,00fh,00bh,00dh,00eh,007h	; 935f  . ..............
	defb 007h,003h,00fh,01ch,00eh,007h,006h,0c0h,0e0h,0e0h,0f0h,0f0h,0d0h,0b0h,070h,0e0h	; 936f  ..............p.
	defb 0e0h,0c0h,0f0h,038h,070h,0e0h,060h,003h,00fh,01ch,00eh,007h,006h,00ah,000h,086h	; 937f  ...8p.`.........
	defb 0c0h,0f0h,038h,070h,0e0h,060h,00ah,000h,087h,0ffh,03eh,05ch,01ah,01ch,018h,018h	; 938f  ..8p.`....>\....
	defb 008h,010h,081h,030h,010h,000h,003h,003h,002h,002h,005h,003h,081h,002h,005h,003h	; 939f  ...0............
	defb 014h,000h,089h,001h,005h,007h,001h,00bh,00bh,005h,007h,001h,007h,000h,089h,080h	; 93af  ................
	defb 0c0h,0a0h,0e0h,050h,0b0h,0e0h,0a0h,080h,005h,000h,002h,003h,08ah,00ch,01fh,00fh	; 93bf  ...P............
	defb 01fh,00bh,007h,017h,019h,00ah,001h,004h,000h,08ch,080h,0e0h,0c0h,0e8h,0d8h,0a4h	; 93cf  ................
	defb 0f4h,0f0h,060h,098h,0e8h,0c0h,007h,000h,08bh,003h,007h,007h,004h,002h,000h,01eh	; 93df  ..`.............
	defb 03fh,007h,003h,003h,005h,000h,082h,0f0h,0f8h,005h,000h,084h,0e0h,0e8h,0e8h,0e0h	; 93ef  ?...............
	defb 008h,000h,081h,003h,003h,001h,083h,000h,030h,030h,008h,000h,08dh,0a0h,0b0h,0f0h	; 93ff  ........00......
	defb 0e0h,0c0h,000h,006h,006h,000h,003h,011h,01ch,038h,00ch,000h,084h,0c0h,0e0h,074h	; 940f  .........8.....t
	defb 03ch,011h,000h,087h,007h,00fh,00eh,008h,004h,000h,000h,003h,007h,081h,002h,005h	; 941f  <...............
	defb 000h,082h,0e0h,0f0h,005h,000h,003h,0c0h,081h,040h,007h,000h,082h,001h,007h,003h	; 942f  .........@......
	defb 003h,003h,000h,081h,001h,007h,000h,085h,040h,060h,0e0h,0c0h,080h,003h,000h,082h	; 943f  ........@`......
	defb 080h,007h,003h,003h,081h,007h,00bh,000h,085h,0c0h,080h,000h,000h,0c0h,010h,000h	; 944f  ................
	defb 08bh,003h,007h,007h,004h,002h,000h,000h,01bh,003h,007h,007h,005h,000h,082h,0f0h	; 945f  ................
	defb 0f8h,005h,000h,088h,0e0h,0f0h,0f8h,0c0h,003h,01bh,01fh,038h,00ch,000h,084h,0c0h	; 946f  ...........8....
	defb 0a0h,036h,01eh,00ch,000h,085h,00fh,06fh,0fch,0d8h,080h,00bh,000h,085h,081h,0f3h	; 947f  .6.....o........
	defb 01fh,006h,004h,011h,000h,08ah,003h,007h,007h,004h,002h,000h,003h,003h,007h,007h	; 948f  ................
	defb 006h,000h,08ah,0f0h,0f8h,000h,000h,006h,07eh,0feh,0f8h,0c0h,0c0h,008h,000h,084h	; 949f  ........~.......
	defb 002h,00eh,007h,006h,00ch,000h,08dh,080h,0c6h,0c7h,007h,006h,000h,060h,0c0h,003h	; 94af  .............`..
	defb 003h,00fh,00ch,00eh,00bh,000h,085h,0c0h,030h,018h,030h,078h,00ch,000h,081h,003h	; 94bf  ........0.0x....
	defb 003h,007h,09ch,003h,001h,01fh,03fh,039h,01eh,001h,033h,079h,0cch,000h,000h,0f8h	; 94cf  ......?9..3y....
	defb 0f0h,0a0h,0b8h,0f0h,0f8h,0c0h,0e3h,0f7h,0f7h,0e0h,0c0h,0e0h,032h,01eh,007h,003h	; 94df  ............2...
	defb 00fh,09eh,007h,003h,007h,00fh,00fh,007h,003h,004h,003h,003h,007h,007h,0f0h,0e0h	; 94ef  ................
	defb 040h,070h,0e0h,0f0h,080h,0c0h,0e0h,0e0h,040h,0c0h,080h,080h,000h,0e0h,000h,003h	; 94ff  @p......@.......
	defb 003h,007h,0cbh,003h,001h,03bh,037h,007h,006h,023h,077h,0ffh,08eh,000h,000h,0f8h	; 950f  .....;7..#w.....
	defb 0f0h,0a0h,0b8h,0f0h,0f8h,0c0h,0d8h,0fch,0f8h,000h,0c0h,099h,00fh,006h,000h,000h	; 951f  ................
	defb 00fh,01fh,01eh,01eh,00fh,007h,01fh,03fh,039h,01eh,0cdh,0f2h,09eh,0cch,000h,000h	; 952f  .......?9.......
	defb 0e0h,0c0h,080h,0e0h,0c0h,0e0h,000h,08fh,0dch,08ch,0f0h,070h,030h,07ch,000h,000h	; 953f  ...........p0|..
	defb 00ch,00ch,00eh,006h,004h,004h,000h,01bh,077h,037h,0c7h,0e7h,0e3h,0c1h,006h,000h	; 954f  ........w7......
	defb 08ah,060h,033h,007h,0c7h,0e3h,0e8h,0e8h,0eeh,0cch,090h,006h,000h,09ah,001h,003h	; 955f  .`3.............
	defb 002h,001h,001h,000h,002h,00ch,004h,007h,03ch,072h,076h,038h,018h,0a6h,040h,040h	; 956f  ........<rv8..@@
	defb 0b0h,00ch,084h,020h,010h,000h,010h,03ch,006h,000h,085h,001h,003h,003h,002h,001h	; 957f  ... ...<........
	defb 004h,000h,0b9h,001h,078h,0c4h,0c8h,07ch,018h,040h,0a0h,040h,0b0h,088h,008h,080h	; 958f  ....x..|.@.@....
	defb 040h,040h,080h,0e0h,000h,003h,007h,005h,009h,00ah,004h,004h,00bh,01dh,019h,00bh	; 959f  @@..............
	defb 003h,003h,001h,000h,0c0h,080h,0c0h,040h,020h,0a0h,040h,040h,0a0h,070h,030h,0a0h	; 95af  .......@ .@@.p0.
	defb 080h,0c0h,0c0h,080h,03ch,052h,095h,091h,06fh,052h,052h,07ch,018h,000h,08ah,03ch	; 95bf  ....<R..oRR|...<
	defb 052h,095h,0a9h,057h,000h,001h,020h,052h,07ch,016h,000h,000h	; 95cf  R..W.. R|...

; ----------------------------------------------------------------------
; DATOS casillas_40_a_94: RLE, 680 bytes en los tres bancos desde 0x2200: las
;   85 casillas del decorado
;   0x95db..0x9822  (583 bytes)
DATA_casillas_40_a_94:
	defb 004h,000h,08ch,05bh,0a9h,0a4h,01bh,018h,028h,00ch,008h,0e7h,0cdh,0e3h,01bh,003h	; 95db  ...[....(.......
	defb 000h,085h,020h,018h,0c8h,066h,0aah,005h,000h,083h,084h,0d3h,0aah,00ch,02ch,0b9h	; 95eb  .. ..f........,.
	defb 0b3h,0c3h,0a4h,01bh,007h,03fh,07fh,07fh,0fch,0efh,0dfh,0dfh,0e0h,0fch,0feh,0feh	; 95fb  .....?..........
	defb 08bh,0e1h,039h,018h,0dfh,0feh,0dfh,077h,05bh,059h,05ch,0cfh,015h,001h,0fah,0fah	; 960b  ..9....w[Y\.....
	defb 0f6h,090h,0d0h,0f4h,0afh,0a7h,05eh,04fh,065h,034h,018h,002h,0c1h,09bh,06fh,09eh	; 961b  ......^Oe4....o.
	defb 0fah,0dch,0b0h,000h,018h,0fdh,063h,030h,020h,003h,000h,09dh,0ffh,0f3h,0deh,05eh	; 962b  ......c0 ......^
	defb 03eh,02ch,018h,018h,0ffh,0c3h,0e3h,07eh,07eh,05ch,028h,028h,0d2h,02eh,091h,04ah	; 963b  >,.....~~\((...J
	defb 00ah,002h,002h,000h,0c4h,0a7h,012h,018h,020h,00ch,000h,002h,07eh,0a0h,01eh,06eh	; 964b  ........ ...~..n
	defb 06eh,02ch,000h,028h,0e7h,018h,00ch,018h,028h,00ch,008h,008h,018h,00ch,00ah,018h	; 965b  n,.(....(.......
	defb 00ch,008h,008h,00dh,00fh,00eh,007h,007h,003h,002h,001h,0f0h,0f0h,0e0h,003h,0c0h	; 966b  ................
	defb 002h,080h,085h,0bfh,0f5h,0dbh,052h,088h,008h,000h,087h,0dbh,0fdh,0b2h,0ffh,0edh	; 967b  ......R.........
	defb 082h,080h,005h,000h,0d7h,004h,000h,004h,006h,041h,032h,010h,000h,000h,068h,078h	; 968b  .........A2...hx
	defb 068h,060h,04ch,0a8h,000h,001h,007h,007h,0f2h,0f8h,0a4h,01bh,030h,0c0h,0b8h,0f0h	; 969b  h`L.........0...
	defb 0c3h,027h,08fh,01bh,0ffh,0fbh,048h,034h,003h,020h,00ch,087h,0c3h,038h,000h,043h	; 96ab  .'....H4. ...8.C
	defb 0fbh,0dfh,004h,077h,010h,008h,081h,0cbh,07eh,07eh,0d6h,01bh,000h,000h,010h,018h	; 96bb  ...w....~~......
	defb 03ch,03ch,018h,010h,07eh,07eh,03ch,07eh,066h,066h,0e7h,01bh,077h,076h,074h,07ch	; 96cb  <<..~~<~ff..wvt|
	defb 03ch,03ch,038h,018h,0d7h,0e7h,07eh,03ch,03ch,01ch,03ch,018h,004h,080h,002h,07fh	; 96db  <<8...~<<.<.....
	defb 082h,0a4h,01bh,008h,000h,004h,001h,002h,0feh,0aah,0a4h,01bh,07eh,03ch,07eh,07eh	; 96eb  ............~<~~
	defb 066h,0e7h,0a4h,01bh,0dbh,0ffh,0dbh,0dbh,024h,024h,0a4h,01bh,0efh,05eh,015h,038h	; 96fb  f.......$$...^.8
	defb 010h,08dh,04bh,080h,098h,02ah,042h,0c8h,029h,0dfh,0dfh,065h,06dh,0fah,0afh,0fbh	; 970b  ..K..*B.)..em...
	defb 09ah,044h,032h,098h,009h,000h,091h,048h,086h,030h,009h,01ah,061h,00ah,000h,010h	; 971b  .D2....H.0..a...
	defb 0c6h,000h,00ch,060h,006h,000h,018h,018h,006h,000h,081h,018h,003h,03ch,081h,018h	; 972b  ...`.........<..
	defb 003h,000h,003h,018h,004h,03ch,09bh,018h,000h,000h,020h,004h,081h,0cbh,07eh,03ch	; 973b  .....<.... ...~<
	defb 0cbh,0afh,0ebh,03ah,0e4h,022h,048h,006h,094h,0ebh,0bfh,09dh,038h,00eh,060h,006h	; 974b  ...:."H.....8.`.
	defb 000h,0ffh,005h,0dbh,081h,0ffh,005h,0dbh,093h,0ffh,0dbh,0dbh,001h,000h,001h,001h	; 975b  ................
	defb 000h,001h,001h,000h,040h,080h,040h,040h,080h,040h,040h,080h,003h,0dbh,081h,0ffh	; 976b  ....@.@@.@@.....
	defb 004h,0dbh,003h,000h,002h,010h,093h,008h,02ch,03ch,03eh,03eh,07eh,07fh,0ffh,0f6h	; 977b  ........,<>>~...
	defb 0feh,07eh,000h,000h,008h,000h,010h,014h,01ch,03ch,003h,07fh,002h,0d7h,085h,0e3h	; 978b  .~.......<......
	defb 0c3h,0c7h,07ch,07eh,004h,0feh,09fh,018h,07fh,000h,008h,008h,028h,020h,034h,03ch	; 979b  ..|~........( 4<
	defb 07ch,07eh,0e7h,0c3h,0ffh,0ffh,0a1h,0b5h,000h,000h,0efh,0bbh,0fdh,0fbh,0ffh,03ch	; 97ab  |~.............<
	defb 03ch,000h,0ffh,0ffh,000h,0ffh,003h,000h,009h,02ch,081h,000h,004h,05eh,094h,000h	; 97bb  <........,...^..
	defb 02ch,000h,005h,00ah,004h,048h,070h,050h,038h,000h,000h,003h,00eh,016h,036h,076h	; 97cb  ,....HpP8.....6v
	defb 0ffh,000h,0ffh,005h,0dbh,089h,0ffh,000h,000h,0c0h,070h,068h,06ch,06eh,0ffh,003h	; 97db  ..........phln..
	defb 0b6h,005h,080h,003h,0dbh,005h,000h,003h,06dh,005h,001h,008h,080h,008h,001h,008h	; 97eb  ........m.......
	defb 000h,094h,07eh,0ffh,05ah,05ah,066h,0bdh,0dbh,07eh,018h,038h,00ch,032h,077h,0ffh	; 97fb  ..~.ZZf..~.8.2w.
	defb 0ffh,07eh,07ch,06ch,044h,044h,003h,06ch,082h,000h,0ffh,007h,000h,088h,03ch,024h	; 980b  .~|lDD.l......<$
	defb 024h,052h,0a1h,05eh,07eh,07eh,000h	; 981b

; ----------------------------------------------------------------------
; DATOS casillas_95_y_9e: RLE, 72 bytes; se carga DOS veces, en 0x24A8 y en
;   0x24F0
;   0x9822..0x9845  (35 bytes)
DATA_casillas_95_y_9e:
	defb 081h,0ffh,005h,080h,003h,0ffh,005h,0c0h,003h,0ffh,005h,0e0h,003h,0ffh,005h,0f0h	; 9822  ................
	defb 003h,0ffh,005h,0f8h,003h,0ffh,005h,0fch,003h,0ffh,005h,0feh,00bh,0ffh,005h,000h	; 9832  ................
	defb 002h,0ffh,000h	; 9842

; ----------------------------------------------------------------------
; DATOS casillas_a6_a_ba: RLE, 168 bytes en dos bancos desde 0x2530: 21
;   casillas
;   0x9845..0x98d3  (142 bytes)
DATA_casillas_a6_a_ba:
	defb 08ah,003h,00fh,03ch,073h,06fh,0dfh,0d6h,0c0h,040h,040h,005h,0c0h,002h,040h,005h	; 9845  ...<so...@@...@.
	defb 0c0h,087h,040h,0c0h,003h,00fh,03ch,073h,06fh,003h,0dfh,002h,05fh,005h,0dfh,002h	; 9855  ..@...<so..._...
	defb 05fh,005h,0dfh,085h,05fh,0dfh,0ffh,0ffh,000h,003h,0ffh,085h,0dbh,000h,0ffh,0ffh	; 9865  _..._...........
	defb 000h,004h,0ffh,09bh,0c3h,081h,036h,076h,06ah,008h,083h,0d5h,0d5h,03ch,03ch,0dbh	; 9875  ......6vj....<<.
	defb 0e7h,0dbh,03ch,03ch,0ffh,0c0h,0f0h,03ch,0ceh,0f6h,0fbh,06bh,003h,002h,002h,005h	; 9885  ..<<...<...k....
	defb 003h,002h,002h,005h,003h,087h,002h,003h,0c0h,0f0h,03ch,0ceh,0f6h,003h,0fbh,002h	; 9895  ..........<.....
	defb 0fah,005h,0fbh,002h,0fah,005h,0fbh,082h,0fah,0fbh,004h,0c0h,084h,01fh,0a9h,0a4h	; 98a5  ................
	defb 01bh,004h,003h,084h,0f8h,0a9h,0a4h,01bh,004h,0dfh,084h,000h,0a9h,0a4h,01bh,004h	; 98b5  ................
	defb 0ffh,084h,000h,0a9h,0a4h,01bh,004h,0fbh,084h,000h,0a9h,0a4h,01bh,000h	; 98c5  ..............

; ----------------------------------------------------------------------
; DATOS casillas_bc_a_dd: RLE, 272 bytes en tres bancos desde 0x25E0: las 34
;   casillas que se espejan
;   0x98d3..0x99d2  (255 bytes)
DATA_casillas_bc_a_dd:
	defb 002h,060h,086h,0a0h,070h,058h,0a9h,0a4h,01bh,004h,000h,093h,00fh,03fh,0a6h,015h	; 98d3  .`..pX.......?..
	defb 00bh,00fh,00fh,01fh,01bh,01fh,00dh,00fh,00dh,01fh,01bh,00fh,005h,007h,007h,003h	; 98e3  ................
	defb 00fh,099h,005h,007h,007h,00fh,00fh,005h,0ffh,0ffh,0e0h,077h,07fh,037h,03bh,01fh	; 98f3  ...........w.7;.
	defb 007h,01fh,07bh,0ffh,016h,01fh,0a4h,01bh,0ffh,0ech,07fh,003h,03fh,086h,01bh,00bh	; 9903  ..{.........?...
	defb 00fh,0bfh,0dch,050h,004h,000h,088h,037h,079h,06eh,0c4h,0c4h,0c0h,0c0h,080h,003h	; 9913  ...P...7yn......
	defb 0c0h,095h,080h,0c0h,0e4h,07bh,06fh,050h,020h,060h,0c0h,0a0h,0c0h,040h,0a0h,000h	; 9923  .....{oP `...@..
	defb 003h,007h,00ch,01ah,034h,010h,060h,003h,008h,085h,00ch,05bh,0a9h,0a4h,01bh,003h	; 9933  ....4.`....[....
	defb 009h,0a5h,00ch,05bh,0a9h,0a4h,01bh,0b6h,0ffh,0b6h,0b6h,049h,049h,0a4h,01bh,0f5h	; 9943  ...[.......II...
	defb 023h,002h,020h,08ch,008h,044h,0c8h,039h,0b5h,088h,07eh,0ebh,057h,027h,002h,002h	; 9953  #. ..D.9..~.W'..
	defb 024h,00eh,055h,04fh,0bbh,0e4h,0d4h,008h,000h,083h,038h,018h,018h,005h,008h,002h	; 9963  $.UO......8.....
	defb 060h,0a6h,0f1h,0ffh,0ffh,07ch,03ah,058h,000h,001h,007h,01fh,03fh,038h,030h,060h	; 9973  `....|:X....?80`
	defb 0ffh,008h,022h,000h,041h,000h,022h,008h,000h,008h,022h,000h,041h,000h,022h,008h	; 9983  ..".A."...".A.".
	defb 000h,000h,003h,00eh,016h,036h,076h,0ffh,005h,0b6h,081h,0ffh,005h,0b6h,081h,0ffh	; 9993  .....6v.........
	defb 004h,0b6h,081h,000h,005h,001h,002h,000h,093h,008h,054h,028h,058h,0eah,0d4h,060h	; 99a3  ..........T(X..`
	defb 076h,0bdh,077h,0eah,0e8h,052h,0a4h,030h,014h,0f0h,0ffh,060h,006h,000h,08fh,004h	; 99b3  v.w..R.0...`....
	defb 000h,018h,04ah,014h,0b0h,016h,00dh,037h,03ah,058h,010h,008h,010h,000h,000h	; 99c3  ..J....7:X.....

; ----------------------------------------------------------------------
; DATOS color_de_40_a_94: RLE, 680 bytes en los tres bancos desde 0x0200
;   0x99d2..0x9b46  (372 bytes)
DATA_color_de_40_a_94:
	defb 004h,090h,004h,09bh,088h,0c0h,020h,020h,0c0h,0bch,0bch,09ch,09bh,005h,060h,083h	; 99d2  ......  ......`.
	defb 06ch,08ch,029h,005h,060h,002h,06ch,009h,029h,004h,0e0h,084h,09eh,090h,09bh,09bh	; 99e2  l.).`.l.).......
	defb 004h,060h,083h,089h,069h,080h,003h,060h,082h,080h,090h,004h,089h,083h,060h,089h	; 99f2  .`..i..`......`.
	defb 060h,003h,080h,002h,060h,002h,089h,003h,090h,003h,069h,004h,060h,081h,080h,003h	; 9a02  `...`.....i.`...
	defb 060h,002h,069h,082h,060h,080h,004h,060h,083h,086h,080h,060h,005h,080h,002h,068h	; 9a12  `.i.`..`...`...h
	defb 089h,060h,080h,080h,060h,080h,080h,060h,068h,068h,005h,080h,083h,028h,06ch,06ch	; 9a22  .`..`..`hh...(ll
	defb 005h,0c0h,083h,029h,06ch,06ch,00dh,060h,008h,0e0h,08ah,028h,08ch,028h,020h,0c0h	; 9a32  ...)ll.`...(.( .
	defb 020h,0c0h,0c0h,020h,0c0h,003h,020h,08bh,0c0h,020h,020h,060h,080h,060h,080h,060h	; 9a42   .. .. ..  `.`.`
	defb 080h,080h,060h,008h,080h,083h,090h,080h,080h,005h,060h,006h,090h,084h,080h,060h	; 9a52  ..`.......`....`
	defb 090h,080h,006h,060h,003h,090h,003h,060h,002h,080h,004h,090h,002h,080h,005h,090h	; 9a62  ...`...`........
	defb 085h,080h,060h,090h,09bh,09bh,003h,090h,087h,080h,060h,060h,0b0h,09bh,080h,080h	; 9a72  ..`.......``....
	defb 00ah,068h,002h,080h,002h,068h,088h,0f0h,070h,0f0h,070h,079h,05bh,09bh,09bh,003h	; 9a82  .h...h..p.py[...
	defb 060h,085h,080h,099h,099h,0a9h,0b9h,003h,0f0h,004h,04bh,091h,09bh,090h,0a0h,090h	; 9a92  `.........K.....
	defb 0a0h,0a9h,0a9h,0b9h,0b9h,09ah,09ah,0a0h,0a0h,099h,0a9h,0b9h,0b9h,004h,0c0h,084h	; 9aa2  ................
	defb 09ch,090h,09bh,09bh,00ch,0c0h,08ch,089h,090h,09bh,09bh,0f0h,0f0h,040h,040h,04bh	; 9ab2  .............@@K
	defb 04bh,09bh,09bh,004h,0c0h,084h,06ch,060h,09bh,09bh,007h,05fh,081h,05eh,003h,057h	; 9ac2  K.....l`..._.^.W
	defb 003h,0f7h,006h,0f0h,083h,0f7h,0f5h,0f5h,009h,057h,010h,075h,081h,070h,007h,0f0h	; 9ad2  .........W.u.p..
	defb 004h,070h,004h,0f0h,081h,050h,006h,070h,006h,0f0h,002h,070h,085h,0f0h,089h,086h	; 9ae2  .p...P.p...p....
	defb 08fh,076h,004h,075h,084h,089h,086h,086h,076h,004h,075h,010h,0c0h,010h,0e0h,008h	; 9af2  .v.u....v.u.....
	defb 0c0h,008h,060h,088h,080h,090h,080h,090h,090h,080h,090h,090h,008h,060h,088h,080h	; 9b02  ..`..........`..
	defb 090h,090h,08ah,09ah,08ah,09ah,09ah,003h,080h,085h,090h,080h,090h,089h,080h,008h	; 9b12  ................
	defb 060h,010h,0f0h,018h,0e0h,008h,0a0h,048h,0c0h,002h,060h,004h,0b0h,085h,0a0h,0f0h	; 9b22  `......H..`.....
	defb 0b0h,0a0h,060h,006h,0b0h,007h,0a0h,081h,0f0h,007h,000h,081h,060h,004h,0f0h,002h	; 9b32  ..`.........`...
	defb 02fh,081h,0f0h,000h	; 9b42

; ----------------------------------------------------------------------
; DATOS color_de_a6_a_ba: RLE, 168 bytes en dos bancos desde 0x0530
;   0x9b46..0x9b65  (31 bytes)
DATA_color_de_a6_a_ba:
	defb 030h,040h,020h,050h,030h,070h,004h,040h,081h,090h,003h,09bh,004h,070h,081h,090h	; 9b46  0@ P0p.@.....p..
	defb 003h,09bh,005h,040h,003h,09bh,005h,050h,003h,09bh,005h,070h,003h,09bh,000h	; 9b56  ...@...P...p...

; ----------------------------------------------------------------------
; DATOS color_de_bc_a_dd: RLE, 272 bytes; se carga DOS veces, en 0x05E0 y en
;   0x06F0, porque las casillas espejadas llevan EL MISMO color que las
;   originales
;   0x9b65..0x9be5  (128 bytes)
DATA_color_de_bc_a_dd:
	defb 005h,060h,003h,09bh,005h,0b0h,085h,090h,09bh,09bh,080h,060h,003h,080h,08ah,060h	; 9b65  .`.........`...`
	defb 080h,060h,060h,080h,080h,060h,060h,080h,060h,003h,080h,081h,060h,004h,080h,003h	; 9b75  .``..``.`...`...
	defb 060h,083h,068h,080h,060h,005h,080h,002h,060h,089h,069h,06bh,09bh,09bh,068h,068h	; 9b85  `.h.`...`.ik..hh
	defb 080h,080h,060h,003h,080h,083h,086h,080h,060h,006h,090h,002h,080h,002h,060h,08bh	; 9b95  ..`.....`.....`.
	defb 090h,080h,090h,090h,060h,080h,090h,090h,080h,080h,060h,005h,080h,002h,060h,085h	; 9ba5  ....`.....`...`.
	defb 080h,090h,090h,080h,090h,003h,080h,081h,090h,004h,0f0h,004h,09bh,004h,0f0h,004h	; 9bb5  ................
	defb 09bh,004h,0c0h,084h,06ch,060h,09bh,09bh,007h,05fh,086h,05eh,057h,057h,0f7h,0f0h	; 9bc5  ....l`..._.^WW..
	defb 0f7h,009h,0f0h,002h,0f5h,008h,057h,028h,0f0h,018h,0c0h,008h,0f0h,028h,070h,000h	; 9bd5  ......W(.....(p.

; ----------------------------------------------------------------------
; DATOS cuatro_casillas_crudas: cinco bloques de 0x20 bytes cada uno; L_4E13
;   los copia sin comprimir
;   0x9be5..0x9c85  (160 bytes)
DATA_cuatro_casillas_crudas:
	defb 000h,000h,000h,003h,00fh,01fh,03fh,020h,000h,000h,000h,0e0h,0f8h,0cch,0f6h,0feh	; 9be5  ......? ........
	defb 01ch,002h,002h,002h,006h,039h,040h,03fh,03ah,01eh,01eh,012h,00ah,024h,0d8h,000h	; 9bf5  .....9@?:....$..
	defb 000h,000h,000h,007h,008h,00bh,012h,012h,000h,000h,000h,0fch,002h,0e2h,0c2h,042h	; 9c05  ...............B
	defb 027h,024h,040h,05fh,060h,060h,01fh,000h,0e2h,032h,002h,0fch,004h,004h,0feh,000h	; 9c15  '$@_``...2......
	defb 000h,000h,000h,01fh,015h,01eh,016h,01eh,000h,000h,000h,0f0h,050h,0f0h,0d0h,0f0h	; 9c25  ............P...
	defb 010h,01eh,016h,01eh,00ah,00eh,007h,003h,010h,0f0h,0d0h,0f0h,0a0h,0e0h,0c0h,080h	; 9c35  ................
	defb 000h,000h,00fh,030h,020h,03fh,030h,038h,000h,000h,0feh,002h,00ah,0fah,01ah,03ah	; 9c45  ...0 ?08.......:
	defb 03ch,038h,033h,030h,03ch,030h,03fh,03fh,07ah,03ah,01ah,01ah,07ah,01ah,0feh,0f8h	; 9c55  <830<0??z:..z...
	defb 000h,000h,003h,004h,008h,008h,004h,007h,000h,000h,0c0h,0e0h,060h,060h,0e0h,0c0h	; 9c65  ............``..
	defb 00dh,01fh,015h,017h,015h,017h,005h,007h,0e0h,0f0h,0b0h,0b0h,0b0h,0b0h,080h,0e0h	; 9c75  ................

; ----------------------------------------------------------------------
; DATOS casillas_del_marcador: guion RLE de 136 bytes: las casillas del
;   marcador y de las dos barras, que se cargan detras de las del decorado
;   0x9c85..0x9d01  (124 bytes)
DATA_casillas_del_marcador:
	defb 005h,000h,083h,001h,005h,03bh,004h,000h,0dch,0f0h,0c4h,082h,046h,07eh,04dh,037h	; 9c85  .....;......F~M7
	defb 00fh,01fh,017h,018h,00fh,03eh,05eh,05ch,0b2h,0ech,0d0h,020h,0c0h,000h,000h,002h	; 9c95  .....>^\... ....
	defb 003h,000h,00fh,01ah,01dh,000h,000h,040h,0c0h,000h,0f0h,058h,0f8h,01dh,01dh,00bh	; 9ca5  .......@...X....
	defb 000h,001h,001h,002h,001h,0f8h,0f8h,0f0h,000h,080h,0c0h,040h,080h,000h,000h,030h	; 9cb5  ...........@...0
	defb 067h,058h,017h,02eh,02eh,000h,000h,00ch,0e6h,01ah,0e8h,0f4h,0f4h,02eh,02eh,02fh	; 9cc5  gX............./
	defb 02fh,017h,018h,007h,030h,0f4h,014h,0f4h,0f4h,0e8h,018h,0e0h,00ch,000h,000h,024h	; 9cd5  /...0..........$
	defb 000h,080h,003h,007h,08fh,008h,000h,084h,08fh,08eh,000h,001h,006h,000h,086h,0a0h	; 9ce5  ................
	defb 0d0h,0e0h,070h,038h,010h,004h,000h,081h,07eh,003h,000h,000h	; 9cf5  ..p8....~...

; ----------------------------------------------------------------------
; DATOS dos_casillas_crudas: dieciseis bytes sin comprimir a 0x3010, o sea las
;   casillas 2 y 3: van sueltas porque no caben en ningun guion
;   0x9d01..0x9d11  (16 bytes)
DATA_dos_casillas_crudas:
	defb 0ffh,03ch,07eh,07eh,074h,076h,03ch,018h,000h,03ch,07eh,07eh,074h,076h,03ch,018h	; 9d01  .<~~tv<..<~~tv<.

; ----------------------------------------------------------------------
; DATOS color_del_marcador_arriba: RLE, 496 bytes desde 0x1010
;   0x9d11..0x9d3c  (43 bytes)
DATA_color_del_marcador_arriba:
	defb 081h,0ffh,003h,080h,004h,0b0h,081h,000h,003h,080h,004h,0b0h,020h,070h,020h,0a0h	; 9d11  ............ p .
	defb 020h,050h,020h,0d0h,020h,060h,020h,0a0h,020h,0d0h,020h,0f0h,020h,0a0h,020h,0f0h	; 9d21   P . ` . . . . .
	defb 020h,050h,020h,0d0h,020h,0c0h,020h,060h,020h,070h,000h	; 9d31   P . . ` p.

; ----------------------------------------------------------------------
; DATOS color_del_marcador_abajo: RLE, 264 bytes desde 0x14A8
;   0x9d3c..0x9d67  (43 bytes)
DATA_color_del_marcador_abajo:
	defb 020h,070h,020h,0a0h,020h,0e0h,020h,0c0h,020h,0f0h,006h,0a0h,002h,0b0h,008h,0a0h	; 9d3c   p . . . .......
	defb 004h,0b0h,00ch,0a0h,005h,050h,003h,040h,00dh,050h,003h,040h,081h,050h,005h,040h	; 9d4c  .....P.@.P.@.P.@
	defb 002h,050h,010h,0f0h,003h,0e0h,00dh,080h,008h,0f0h,000h	; 9d5c  .P.........

; ----------------------------------------------------------------------
; DATOS el_reparto_de_salas_de_cada_nivel: 25 bytes, uno por nivel; 0x4F82 lo
;   lee y lo deja en (0xE06A). Es CUAL DE LOS 19 REPARTOS de 0x52DB le toca, o
;   sea la forma del plano del nivel: 1, 10 y 15 en columna; 2 y 19 en fila;
;   3, 9, 13, 17, 24 y 25 en 2x2; y los otros catorce con forma rara
;   0x9d67..0x9d80  (25 bytes)
DATA_el_reparto_de_salas_de_cada_nivel:
	defb 000h,012h,007h,00fh,006h,00bh,008h,00dh,007h,000h,00eh,004h,007h,00ah,000h,005h	; 9d67  ................
	defb 007h,002h,012h,001h,00ch,008h,002h,007h,007h	; 9d77  .........

; ----------------------------------------------------------------------
; DATOS tabla_de_mapas: 25 punteros, uno por nivel; los lee 0x59B5 con
;   (0xE061)-1
;   0x9d80..0x9db2  (50 bytes)
DATA_tabla_de_mapas:
	defw 09db2h,09e41h,09eb8h,09f3ah,09fc0h,0a052h,0a0dfh,0a17ch	; 9d80
	defw 0a20eh,0a291h,0a634h,0a6b3h,0a743h,0a7d3h,0a865h,0a8f0h	; 9d90
	defw 0a97ah,0a9feh,0aa7bh,0aafdh,0ade8h,0ae71h,0af03h,0af8ch	; 9da0
	defw 0b015h	; 9db0  -> DATA_mapa_del_nivel_25

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_01: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0x9db2..0x9e02  (80 bytes)
DATA_mapa_del_nivel_01:
	defb 001h,001h,001h,001h,031h,068h,0b1h,031h,042h,0e4h,0d0h,04dh,036h,063h,059h,0b4h,001h,001h,001h,001h	; 9db2  ....1h.1B..M6cY.....
	defb 031h,052h,069h,068h,000h,01fh,05dh,0e4h,02fh,060h,065h,0deh,02ah,000h,000h,000h,004h,004h,004h,004h	; 9dc6  1Rih..]./`e.*.......
	defb 0e8h,052h,038h,057h,064h,0d0h,03eh,03eh,02fh,09ch,051h,09bh,032h,0d9h,0e3h,059h,001h,001h,001h,001h	; 9dda  .R8Wd.>>/.Q.2..Y....
	defb 0b8h,052h,052h,0b1h,0beh,04fh,01ah,0c1h,09ch,000h,03dh,0b2h,0d9h,0e7h,0b3h,001h,040h,0d8h,0b4h,001h	; 9dee  .RR..O....=.....@...

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_01: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0x9e02..0x9e41  (63 bytes)
DATA_objetos_del_nivel_01:
	defb 0f1h,007h,00fh,005h,00dh,007h,002h,043h,003h,009h,083h,003h,002h,08dh,007h,005h	; 9e02  .......C........
	defb 087h,017h,002h,0c3h,013h,002h,0cfh,013h,007h,0f2h,080h,05ch,0f3h,0c4h,00dh,002h	; 9e12  ...........\....
	defb 0c4h,018h,005h,0f4h,010h,00bh,046h,019h,090h,014h,0d0h,009h,0f5h,00eh,017h,001h	; 9e22  ......F.........
	defb 08eh,003h,081h,0cah,01ch,082h,0f6h,00ah,009h,010h,0f7h,008h,00ch,000h,0ffh	; 9e32  ...............

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_02: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0x9e41..0x9e91  (80 bytes)
DATA_mapa_del_nivel_02:
	defb 031h,038h,0b8h,0b1h,02ah,0beh,052h,0aah,02ch,060h,0dfh,0abh,028h,000h,0bch,0aah,028h,000h,0bch,0aah	; 9e41  18..*.R.,`..(...(...
	defb 028h,000h,0bch,0aah,028h,053h,0d9h,0b2h,028h,03bh,0b1h,001h,028h,0bch,000h,0b1h,028h,051h,01ah,0abh	; 9e55  (...(S..(;..(...(Q..
	defb 028h,000h,03ch,0aah,036h,063h,0bfh,0aah,001h,001h,035h,0aah,031h,052h,03fh,0b2h,042h,0cfh,052h,0b5h	; 9e69  (.<.6c....5.1R?.B.R.
	defb 0d6h,053h,0d3h,056h,033h,039h,0b9h,0b3h,02dh,05eh,0deh,0adh,02ah,000h,000h,0aah,004h,004h,004h,004h	; 9e7d  .S.V39..-^..*.......

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_02: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0x9e91..0x9eb8  (39 bytes)
DATA_objetos_del_nivel_02:
	defb 0f1h,04bh,00fh,009h,04fh,01bh,005h,0f2h,000h,053h,0f3h,008h,018h,001h,0c2h,00eh	; 9e91  .K..O....S......
	defb 003h,0f4h,052h,01eh,088h,00bh,0c4h,011h,0f5h,008h,003h,001h,050h,015h,081h,090h	; 9ea1  ..R.........P...
	defb 007h,081h,0f6h,004h,00eh,000h,0ffh	; 9eb1

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_03: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0x9eb8..0x9f08  (80 bytes)
DATA_mapa_del_nivel_03:
	defb 031h,005h,009h,00fh,0c9h,00ch,006h,006h,0d6h,013h,00dh,00fh,033h,017h,006h,006h,026h,009h,00fh,013h	; 9eb8  1...........3...&...
	defb 005h,005h,005h,0b1h,006h,006h,00eh,04bh,011h,007h,00fh,04ch,015h,000h,00ch,054h,00fh,000h,011h,0b3h	; 9ecc  .......K...L...T....
	defb 026h,00ch,006h,016h,0cch,013h,018h,00fh,0d4h,015h,066h,00ch,031h,03eh,0eah,012h,030h,0dch,003h,05ch	; 9ee0  &.........f.1>..0..\
	defb 00eh,066h,014h,04ch,011h,067h,015h,0b5h,015h,012h,008h,056h,008h,03ch,000h,0b3h,002h,05ch,002h,0dbh	; 9ef4  .f.L.g.....V.<...\..

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_03: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0x9f08..0x9f3a  (50 bytes)
DATA_objetos_del_nivel_03:
	defb 0f1h,003h,00fh,007h,043h,007h,004h,043h,00fh,007h,08fh,003h,005h,08fh,00bh,002h	; 9f08  ....C..C........
	defb 0f2h,000h,049h,0f3h,006h,018h,042h,086h,004h,045h,0d0h,010h,004h,0f4h,006h,004h	; 9f18  ..I...B..E......
	defb 084h,010h,092h,016h,0c8h,00eh,0f5h,00eh,011h,082h,044h,01ah,001h,0f6h,0c8h,00ah	; 9f28  ..........D.....
	defb 00ah,0ffh	; 9f38

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_04: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0x9f3a..0x9f8a  (80 bytes)
DATA_mapa_del_nivel_04:
	defb 031h,052h,052h,0b1h,02ah,000h,01fh,0c2h,042h,05dh,023h,0c3h,036h,0e7h,021h,0ach,031h,0beh,000h,0a8h	; 9f3a  1RR.*...B]#.6.!.1...
	defb 032h,059h,019h,0b6h,033h,03eh,052h,0b1h,02dh,0a3h,0a1h,045h,02ah,067h,019h,0b4h,02ah,03eh,052h,0b3h	; 9f4e  2Y..3>R.-..E*g..*>R.
	defb 001h,037h,0b1h,001h,040h,0d8h,0b2h,001h,001h,033h,038h,057h,040h,0bfh,0b1h,001h,0d4h,0d8h,063h,057h	; 9f62  .7..@....38W@.....cW
	defb 032h,0bdh,000h,0a6h,031h,0beh,050h,0adh,0e3h,0bfh,0bch,0aah,001h,035h,051h,0a4h,057h,0d9h,0e3h,0b4h	; 9f76  2...1.P......5Q.W...

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_04: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0x9f8a..0x9fc0  (54 bytes)
DATA_objetos_del_nivel_04:
	defb 0f1h,003h,007h,009h,047h,007h,002h,047h,013h,002h,083h,013h,007h,0c7h,00bh,007h	; 9f8a  ....G..G........
	defb 0f2h,000h,05ah,0c1h,0ach,0f3h,004h,017h,083h,08eh,00ch,085h,0f4h,006h,014h,010h	; 9f9a  ..Z.............
	defb 009h,084h,00ah,088h,001h,094h,013h,0f5h,04eh,014h,001h,0cch,018h,081h,0d2h,00ah	; 9faa  ........N.......
	defb 001h,0f6h,0d4h,014h,009h,0ffh	; 9fba

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_05: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0x9fc0..0xa010  (80 bytes)
DATA_mapa_del_nivel_05:
	defb 032h,0e7h,069h,052h,033h,052h,066h,000h,02dh,05eh,065h,0deh,02ah,000h,000h,000h,004h,004h,004h,004h	; 9fc0  2.iR3Rf.-^e.*.......
	defb 0b1h,001h,001h,001h,0eah,052h,0e9h,0b1h,064h,0a1h,067h,019h,000h,000h,052h,0b1h,004h,004h,004h,004h	; 9fd4  .....R..d.g...R.....
	defb 001h,001h,001h,001h,031h,052h,052h,0b1h,0bah,050h,05dh,0c2h,040h,0d9h,019h,0b6h,033h,0b1h,033h,0b3h	; 9fe8  ....1RR..P].@...3.3.
	defb 0cch,0aah,026h,04ch,035h,03ah,0bfh,0b3h,028h,0b1h,031h,046h,043h,0aeh,02eh,0c3h,030h,0dch,05ch,0b0h	; 9ffc  ..&L5:..(.1FC...0.\.

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_05: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa010..0xa052  (66 bytes)
DATA_objetos_del_nivel_05:
	defb 0f1h,043h,003h,009h,047h,01bh,007h,087h,003h,007h,087h,00fh,002h,087h,017h,005h	; a010  .C..G...........
	defb 08dh,00fh,002h,08dh,013h,002h,08dh,017h,002h,0f2h,0c1h,047h,0f3h,008h,006h,041h	; a020  ...........G...A
	defb 088h,012h,043h,0cch,015h,044h,0f4h,004h,009h,04ch,016h,0cah,01ch,0d2h,00fh,0f5h	; a030  ..C..D...L......
	defb 048h,00bh,082h,0cch,00ah,002h,0f6h,004h,00dh,011h,04ch,01ah,01ah,0f7h,0c2h,004h	; a040  H.........L.....
	defb 0c6h,0ffh	; a050

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_06: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa052..0xa0a2  (80 bytes)
DATA_mapa_del_nivel_06:
	defb 031h,0b1h,031h,0b1h,042h,0cfh,04fh,0c2h,029h,01ah,09ah,0a9h,032h,059h,0d9h,0b2h,031h,0beh,052h,0b3h	; a052  1.1.B.O.)...2Y..1.R.
	defb 032h,0d5h,067h,0d9h,033h,0b9h,0b5h,001h,034h,063h,0b6h,001h,033h,0b3h,001h,001h,026h,03fh,057h,057h	; a066  2.g.3...4c..3...&?WW
	defb 0e3h,0bah,039h,0b1h,001h,033h,04fh,0ach,001h,02dh,01ah,0a9h,001h,02ch,0d1h,049h,057h,0d9h,063h,0b6h	; a07a  ..9..3O..-...,.IW.c.
	defb 026h,052h,052h,0b1h,027h,09fh,050h,0abh,028h,01eh,09bh,0c2h,036h,0e3h,059h,0b6h,001h,001h,001h,001h	; a08e  &RR.'.P.(...6.Y.....

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_06: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa0a2..0xa0df  (61 bytes)
DATA_objetos_del_nivel_06:
	defb 0f0h,00ch,00fh,006h,0cch,015h,006h,0f1h,0c3h,017h,005h,0c9h,003h,009h,0f2h,000h	; a0a2  ................
	defb 08bh,046h,067h,042h,0a8h,096h,057h,0f3h,004h,015h,007h,092h,01bh,047h,0c4h,01ah	; a0b2  .FgB..W......G..
	defb 00ah,0f4h,044h,016h,084h,004h,094h,013h,0d0h,00ch,0f5h,00eh,004h,001h,04ah,006h	; a0c2  ..D...........J.
	defb 082h,084h,015h,001h,0f6h,08eh,01dh,019h,0f7h,004h,008h,000h,0ffh	; a0d2  .............

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_07: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa0df..0xa12f  (80 bytes)
DATA_mapa_del_nivel_07:
	defb 032h,057h,057h,057h,031h,052h,0b1h,031h,032h,0d3h,03ah,0e3h,033h,0b9h,052h,052h,05bh,002h,002h,002h	; a0df  2WWW1R.12.:.3.RR[...
	defb 057h,057h,0b8h,0b1h,0b1h,031h,052h,045h,019h,019h,019h,0b4h,052h,0e8h,052h,0b1h,02fh,064h,0a1h,045h	; a0f3  WW...1RE....R.R./d.E
	defb 031h,0b1h,031h,0a6h,042h,0d0h,066h,0a6h,043h,023h,0a2h,0bch,02ah,050h,0d1h,01ch,030h,0dch,002h,05ch	; a107  1.1.B.f.C#..*P..0..\
	defb 031h,0b7h,001h,001h,032h,058h,0c0h,001h,0beh,052h,069h,0b1h,023h,05fh,0deh,0c1h,002h,05ch,002h,0b0h	; a11b  1...2X...Ri.#_...\..

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_07: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa12f..0xa17c  (77 bytes)
DATA_objetos_del_nivel_07:
	defb 0f1h,007h,007h,007h,007h,013h,007h,00fh,007h,005h,00fh,01bh,002h,047h,00fh,007h	; a12f  .............G..
	defb 04fh,007h,002h,04fh,013h,005h,083h,003h,009h,083h,013h,009h,08dh,007h,004h,0cbh	; a13f  O..O............
	defb 007h,009h,0f2h,006h,061h,047h,03eh,083h,077h,0c6h,07ah,0f3h,002h,005h,006h,088h	; a14f  ....aG>.w.z.....
	defb 010h,046h,0c6h,004h,008h,0f4h,00ch,01ch,052h,00eh,086h,007h,0c4h,00dh,0f5h,010h	; a15f  .F......R.......
	defb 016h,082h,04ah,00ch,001h,0cch,018h,081h,0f6h,00ch,00ah,012h,0ffh	; a16f  ..J..........

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_08: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa17c..0xa1cc  (80 bytes)
DATA_mapa_del_nivel_08:
	defb 031h,0e8h,052h,052h,024h,064h,09ah,05dh,02dh,0d0h,03fh,063h,032h,0bfh,052h,038h,0d4h,057h,063h,054h	; a17c  1.RR$d.]-.?c2.R8.WcT
	defb 052h,068h,052h,0b1h,01ah,0e4h,0cfh,04bh,059h,0e7h,050h,0a5h,0d8h,0d8h,0d9h,0b4h,033h,0b5h,031h,0b5h	; a190  RhR....KY.P.....3.1.
	defb 026h,0a8h,02ah,0a8h,027h,0a9h,032h,0b6h,036h,019h,0b8h,0b3h,001h,035h,052h,04ch,001h,036h,063h,054h	; a1a4  &.*.'.2.6....5RL.6cT
	defb 001h,001h,001h,001h,001h,031h,0b1h,001h,001h,042h,0cfh,0b1h,040h,0d9h,019h,0b2h,001h,040h,054h,001h	; a1b8  .....1...B..@....@T.

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_08: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa1cc..0xa20e  (66 bytes)
DATA_objetos_del_nivel_08:
	defb 0f0h,002h,018h,006h,042h,006h,006h,0f1h,003h,013h,005h,003h,01bh,00bh,00dh,007h	; a1cc  ....B...........
	defb 002h,043h,00fh,005h,08bh,01bh,007h,08fh,00fh,007h,0f2h,007h,054h,047h,038h,083h	; a1dc  .C..........TG8.
	defb 0aeh,0c6h,0a6h,0f3h,08ah,009h,087h,0c8h,00fh,009h,0f4h,014h,013h,043h,00ch,0d0h	; a1ec  .............C..
	defb 002h,0d4h,00ah,0f5h,004h,007h,001h,086h,014h,001h,0ceh,01ah,082h,0f6h,046h,009h	; a1fc  ..............F.
	defb 005h,0ffh	; a20c

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_09: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa20e..0xa25e  (80 bytes)
DATA_mapa_del_nivel_09:
	defb 031h,005h,005h,005h,0c9h,00ch,006h,006h,028h,005h,005h,005h,036h,006h,006h,006h,033h,012h,00dh,008h	; a20e  1.......(...6...3...
	defb 005h,005h,005h,0b1h,006h,006h,00eh,049h,005h,013h,00fh,0a8h,006h,016h,006h,0b6h,007h,00dh,008h,0b3h	; a222  .......I............
	defb 026h,03ch,00ch,063h,027h,0d1h,013h,00fh,028h,067h,016h,006h,0c7h,013h,00dh,008h,034h,016h,006h,063h	; a236  &<.c'...(g......4..c
	defb 019h,00eh,000h,0a6h,013h,00fh,04fh,0a7h,016h,006h,063h,0b6h,012h,00dh,00fh,0b3h,059h,006h,006h,0b4h	; a24a  ......O...c.....Y...

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_09: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa25e..0xa291  (51 bytes)
DATA_objetos_del_nivel_09:
	defb 0f1h,003h,00fh,007h,043h,007h,003h,0c9h,017h,009h,0f2h,000h,049h,086h,06ch,0d6h	; a25e  ....C.......I.l.
	defb 025h,0c2h,0a3h,0f3h,044h,01bh,048h,084h,003h,04ah,0f4h,008h,019h,084h,01bh,094h	; a26e  %...D.H..J......
	defb 01bh,0cch,013h,0f5h,00eh,019h,081h,0c2h,005h,082h,0f6h,08ch,00eh,006h,0f7h,004h	; a27e  ................
	defb 002h,0cbh,0ffh	; a28e

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_10: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa291..0xa2e1  (80 bytes)
DATA_mapa_del_nivel_10:
	defb 031h,0b1h,001h,001h,042h,0d0h,068h,052h,029h,023h,0e4h,05dh,02ah,000h,000h,000h,004h,004h,004h,004h	; a291  1...B.hR)#.]*.......
	defb 001h,031h,0e9h,052h,0e8h,066h,000h,000h,064h,05eh,065h,0deh,000h,000h,04fh,0cfh,004h,004h,004h,004h	; a2a5  .1.R.f..d^e...O.....
	defb 001h,001h,031h,052h,0e9h,069h,06ah,01fh,05eh,0deh,0e2h,03dh,000h,000h,000h,052h,004h,004h,004h,004h	; a2b9  ..1R.ij.^..=...R....
	defb 052h,052h,0b1h,001h,05dh,0d0h,067h,0c0h,0e7h,03ch,068h,0b5h,052h,020h,0e4h,0a9h,004h,004h,004h,004h	; a2cd  RR..].g..<h.R ......

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_10: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa2e1..0xa304  (35 bytes)
DATA_objetos_del_nivel_10:
	defb 0f1h,089h,01bh,005h,0cbh,017h,002h,0f2h,006h,05dh,0d6h,076h,0f3h,004h,007h,086h	; a2e1  .........].v....
	defb 0c4h,005h,049h,0f4h,00ah,011h,04ah,006h,0c8h,016h,0f5h,084h,01bh,082h,0f6h,0cch	; a2f1  ..I...J.........
	defb 001h,007h,0ffh	; a301

; ----------------------------------------------------------------------
; DATOS tabla_de_datos_de_sala: 25 punteros, uno por nivel; detras de cada uno
;   van los cuatro de sus salas
;   0xa304..0xa336  (50 bytes)
DATA_tabla_de_datos_de_sala:
	defw 0a336h,0a33eh,0a346h,0a34eh,0a356h,0a35eh,0a366h,0a36eh	; a304
	defw 0a376h,0a37eh,0ab82h,0ab8ah,0ab92h,0ab9ah,0aba2h,0abaah	; a314
	defw 0abb2h,0abbah,0abc2h,0abcah,0b0b7h,0b0bfh,0b0c7h,0b0cfh	; a324
	defw 0b0d7h	; a334  -> DATA_salas_del_nivel_25

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_01: cuatro punteros, uno por sala
;   0xa336..0xa33e  (8 bytes)
DATA_salas_del_nivel_01:
	defw 0a386h,0a391h,0a3a0h,0a3b5h	; a336  -> DATA_sala_1_del_nivel_01 DATA_sala_2_del_nivel_01 DATA_sala_3_del_nivel_01 DATA_sala_4_del_nivel_01

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_02: cuatro punteros, uno por sala
;   0xa33e..0xa346  (8 bytes)
DATA_salas_del_nivel_02:
	defw 0a3c1h,0a3c2h,0a3c8h,0a3d4h	; a33e  -> DATA_sala_1_del_nivel_02 DATA_sala_2_del_nivel_02 DATA_sala_3_del_nivel_02 DATA_sala_4_del_nivel_02

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_03: cuatro punteros, uno por sala
;   0xa346..0xa34e  (8 bytes)
DATA_salas_del_nivel_03:
	defw 0a3deh,0a3f6h,0a408h,0a420h	; a346  -> DATA_sala_1_del_nivel_03 DATA_sala_2_del_nivel_03 DATA_sala_3_del_nivel_03 DATA_sala_4_del_nivel_03

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_04: cuatro punteros, uno por sala
;   0xa34e..0xa356  (8 bytes)
DATA_salas_del_nivel_04:
	defw 0a43dh,0a450h,0a463h,0a473h	; a34e  -> DATA_sala_1_del_nivel_04 DATA_sala_2_del_nivel_04 DATA_sala_3_del_nivel_04 DATA_sala_4_del_nivel_04

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_05: cuatro punteros, uno por sala
;   0xa356..0xa35e  (8 bytes)
DATA_salas_del_nivel_05:
	defw 0a480h,0a491h,0a49eh,0a4afh	; a356  -> DATA_sala_1_del_nivel_05 DATA_sala_2_del_nivel_05 DATA_sala_3_del_nivel_05 DATA_sala_4_del_nivel_05

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_06: cuatro punteros, uno por sala
;   0xa35e..0xa366  (8 bytes)
DATA_salas_del_nivel_06:
	defw 0a4c2h,0a4dbh,0a4e4h,0a4efh	; a35e  -> DATA_sala_1_del_nivel_06 DATA_sala_2_del_nivel_06 DATA_sala_3_del_nivel_06 DATA_sala_4_del_nivel_06

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_07: cuatro punteros, uno por sala
;   0xa366..0xa36e  (8 bytes)
DATA_salas_del_nivel_07:
	defw 0a501h,0a51ah,0a533h,0a542h	; a366  -> DATA_sala_1_del_nivel_07 DATA_sala_2_del_nivel_07 DATA_sala_3_del_nivel_07 DATA_sala_4_del_nivel_07

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_08: cuatro punteros, uno por sala
;   0xa36e..0xa376  (8 bytes)
DATA_salas_del_nivel_08:
	defw 0a54ch,0a559h,0a56dh,0a57ah	; a36e  -> DATA_sala_1_del_nivel_08 DATA_sala_2_del_nivel_08 DATA_sala_3_del_nivel_08 DATA_sala_4_del_nivel_08

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_09: cuatro punteros, uno por sala
;   0xa376..0xa37e  (8 bytes)
DATA_salas_del_nivel_09:
	defw 0a586h,0a5a7h,0a5c5h,0a5dbh	; a376  -> DATA_sala_1_del_nivel_09 DATA_sala_2_del_nivel_09 DATA_sala_3_del_nivel_09 DATA_sala_4_del_nivel_09

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_10: cuatro punteros, uno por sala
;   0xa37e..0xa386  (8 bytes)
DATA_salas_del_nivel_10:
	defw 0a5f9h,0a607h,0a615h,0a626h	; a37e  -> DATA_sala_1_del_nivel_10 DATA_sala_2_del_nivel_10 DATA_sala_3_del_nivel_10 DATA_sala_4_del_nivel_10

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_01: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa386..0xa391  (11 bytes)
DATA_sala_1_del_nivel_01:
	defb 0f4h,007h,01ah,038h,00dh,00eh,04ch,0f5h,000h,08ah,0ffh	; a386  ...8..L....

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_01: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa391..0xa3a0  (15 bytes)
DATA_sala_2_del_nivel_01:
	defb 0f0h,004h,010h,00eh,012h,0f4h,003h,00ah,030h,0f5h,000h,03bh,000h,053h,0ffh	; a391  ........0..;.S.

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_01: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa3a0..0xa3b5  (21 bytes)
DATA_sala_3_del_nivel_01:
	defb 0f1h,007h,010h,020h,006h,000h,0f4h,003h,08eh,038h,007h,01ah,040h,0f5h,000h,056h	; a3a0  ... .....8..@..V
	defb 000h,085h,001h,08bh,0ffh	; a3b0

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_01: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa3b5..0xa3c1  (12 bytes)
DATA_sala_4_del_nivel_01:
	defb 0f4h,009h,016h,038h,0f5h,000h,039h,000h,06ah,000h,086h,0ffh	; a3b5  ...8..9.j...

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_02: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa3c1..0xa3c2  (1 bytes)
DATA_sala_1_del_nivel_02:
	defb 0ffh	; a3c1

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_02: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa3c2..0xa3c8  (6 bytes)
DATA_sala_2_del_nivel_02:
	defb 0f5h,000h,047h,000h,097h,0ffh	; a3c2

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_02: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa3c8..0xa3d4  (12 bytes)
DATA_sala_3_del_nivel_02:
	defb 0f4h,00bh,016h,030h,0f5h,001h,043h,000h,04ah,000h,089h,0ffh	; a3c8  ...0..C.J...

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_02: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa3d4..0xa3de  (10 bytes)
DATA_sala_4_del_nivel_02:
	defb 0f4h,007h,006h,02ch,0f5h,003h,026h,000h,05bh,0ffh	; a3d4  ...,..&.[.

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_03: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa3de..0xa3f6  (24 bytes)
DATA_sala_1_del_nivel_03:
	defb 0f3h,007h,08dh,038h,007h,00dh,040h,00fh,08dh,030h,00fh,00dh,048h,00fh,015h,050h	; a3de  ...8..@..0..H..P
	defb 00fh,09dh,038h,0f4h,009h,002h,038h,0ffh	; a3ee  ..8...8.

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_03: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa3f6..0xa408  (18 bytes)
DATA_sala_2_del_nivel_03:
	defb 0f3h,007h,08dh,038h,00fh,095h,030h,00fh,015h,038h,0f4h,003h,082h,040h,0f5h,001h	; a3f6  ...8..0..8...@..
	defb 048h,0ffh	; a406

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_03: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa408..0xa420  (24 bytes)
DATA_sala_3_del_nivel_03:
	defb 0f0h,00ch,015h,008h,018h,0f3h,003h,08dh,038h,003h,095h,030h,003h,015h,040h,00bh	; a408  ........8..0..@.
	defb 08dh,030h,0f5h,000h,063h,001h,095h,0ffh	; a418  .0..c...

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_03: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa420..0xa43d  (29 bytes)
DATA_sala_4_del_nivel_03:
	defb 0f0h,004h,00dh,010h,020h,0f3h,007h,095h,038h,007h,015h,040h,00bh,085h,038h,0f4h	; a420  .... ...8..@..8.
	defb 00bh,096h,038h,00fh,006h,040h,00fh,01ah,030h,0f5h,000h,09bh,0ffh	; a430  ..8..@..0....

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_04: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa43d..0xa450  (19 bytes)
DATA_sala_1_del_nivel_04:
	defb 0f1h,003h,01dh,004h,008h,000h,0f4h,003h,012h,030h,00dh,006h,040h,0f5h,000h,079h	; a43d  .........0..@..y
	defb 000h,081h,0ffh	; a44d

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_04: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa450..0xa463  (19 bytes)
DATA_sala_2_del_nivel_04:
	defb 0f1h,007h,018h,018h,006h,000h,0f4h,007h,012h,030h,00dh,012h,040h,0f5h,000h,057h	; a450  .........0..@..W
	defb 001h,088h,0ffh	; a460

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_04: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa463..0xa473  (16 bytes)
DATA_sala_3_del_nivel_04:
	defb 0f4h,007h,00ah,038h,00bh,09ah,030h,00fh,016h,044h,0f5h,000h,042h,000h,0a4h,0ffh	; a463  ...8..0..D..B...

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_04: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa473..0xa480  (13 bytes)
DATA_sala_4_del_nivel_04:
	defb 0f4h,007h,002h,060h,0f5h,000h,03bh,001h,0a8h,0f6h,064h,024h,0ffh	; a473  ...`..;...d$.

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_05: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa480..0xa491  (17 bytes)
DATA_sala_1_del_nivel_05:
	defb 0f0h,004h,010h,00eh,018h,008h,015h,00ah,018h,0f4h,007h,08ah,030h,0f5h,000h,022h	; a480  ............0.."
	defb 0ffh	; a490

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_05: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa491..0xa49e  (13 bytes)
DATA_sala_2_del_nivel_05:
	defb 0f0h,008h,015h,00ah,018h,0f4h,007h,012h,030h,0f6h,054h,034h,0ffh	; a491  ........0.T4.

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_05: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa49e..0xa4af  (17 bytes)
DATA_sala_3_del_nivel_05:
	defb 0f1h,007h,008h,018h,006h,000h,0f4h,007h,01ah,030h,00dh,012h,030h,0f5h,001h,088h	; a49e  .........0..0...
	defb 0ffh	; a4ae

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_05: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa4af..0xa4c2  (19 bytes)
DATA_sala_4_del_nivel_05:
	defb 0f4h,007h,006h,030h,00bh,012h,030h,011h,006h,030h,011h,01ah,030h,0f5h,000h,046h	; a4af  ...0..0..0..0..F
	defb 000h,073h,0ffh	; a4bf

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_06: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa4c2..0xa4db  (25 bytes)
DATA_sala_1_del_nivel_06:
	defb 0f1h,003h,00dh,010h,004h,000h,003h,011h,014h,004h,000h,0f4h,003h,086h,040h,003h	; a4c2  ..............@.
	defb 01ah,038h,00dh,012h,048h,0f5h,001h,084h,0ffh	; a4d2  .8..H....

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_06: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa4db..0xa4e4  (9 bytes)
DATA_sala_2_del_nivel_06:
	defb 0f5h,000h,029h,003h,0aah,0f6h,064h,05ch,0ffh	; a4db  ..)...d\.

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_06: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa4e4..0xa4ef  (11 bytes)
DATA_sala_3_del_nivel_06:
	defb 0f4h,003h,01ah,040h,00dh,016h,038h,0f5h,000h,0a5h,0ffh	; a4e4  ...@..8....

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_06: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa4ef..0xa501  (18 bytes)
DATA_sala_4_del_nivel_06:
	defb 0f4h,003h,096h,040h,009h,006h,058h,0f5h,000h,058h,000h,081h,001h,087h,0f6h,084h	; a4ef  ...@..X..X......
	defb 064h,0ffh	; a4ff

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_07: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa501..0xa51a  (25 bytes)
DATA_sala_1_del_nivel_07:
	defb 0f1h,007h,00eh,005h,008h,000h,007h,019h,01eh,002h,000h,0f4h,003h,00eh,038h,003h	; a501  ..............8.
	defb 01ah,042h,007h,082h,050h,00fh,012h,034h,0ffh	; a511  .B..P..4.

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_07: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa51a..0xa533  (25 bytes)
DATA_sala_2_del_nivel_07:
	defb 0f1h,007h,005h,024h,002h,000h,007h,009h,01eh,002h,000h,0f4h,003h,006h,030h,007h	; a51a  ...$..........0.
	defb 016h,040h,00fh,00ah,034h,0f5h,001h,098h,0ffh	; a52a  .@..4....

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_07: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa533..0xa542  (15 bytes)
DATA_sala_3_del_nivel_07:
	defb 0f0h,008h,015h,00ch,010h,0f1h,003h,00dh,01ch,004h,000h,0f5h,000h,034h,0ffh	; a533  .............4.

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_07: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa542..0xa54c  (10 bytes)
DATA_sala_4_del_nivel_07:
	defb 0f0h,00ch,010h,008h,014h,0f4h,003h,00ah,030h,0ffh	; a542  ........0.

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_08: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa54c..0xa559  (13 bytes)
DATA_sala_1_del_nivel_08:
	defb 0f4h,009h,08eh,038h,00fh,016h,030h,0f5h,001h,038h,000h,0a6h,0ffh	; a54c  ...8..0..8...

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_08: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa559..0xa56d  (20 bytes)
DATA_sala_2_del_nivel_08:
	defb 0f4h,003h,096h,044h,009h,006h,028h,009h,012h,034h,00fh,00ah,030h,0f5h,001h,089h	; a559  ...D..(..4..0...
	defb 0f6h,064h,04ch,0ffh	; a569

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_08: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa56d..0xa57a  (13 bytes)
DATA_sala_3_del_nivel_08:
	defb 0f4h,009h,00eh,030h,00fh,016h,038h,0f5h,002h,04dh,000h,067h,0ffh	; a56d  ...0..8..M.g.

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_08: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa57a..0xa586  (12 bytes)
DATA_sala_4_del_nivel_08:
	defb 0f1h,007h,009h,004h,006h,000h,007h,015h,008h,006h,000h,0ffh	; a57a  ............

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_09: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa586..0xa5a7  (33 bytes)
DATA_sala_1_del_nivel_09:
	defb 0f3h,007h,08dh,038h,007h,015h,032h,007h,09dh,042h,00fh,08dh,030h,00fh,00dh,034h	; a586  ...8..2..B..0..4
	defb 00fh,095h,048h,00fh,015h,036h,0f4h,003h,006h,038h,00bh,012h,032h,0f5h,002h,083h	; a596  ..H..6...8..2...
	defb 0ffh	; a5a6

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_09: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa5a7..0xa5c5  (30 bytes)
DATA_sala_2_del_nivel_09:
	defb 0f3h,007h,085h,050h,007h,08dh,038h,007h,00dh,040h,00fh,085h,032h,00fh,00dh,044h	; a5a7  ...P..8..@..2..D
	defb 00fh,095h,040h,00fh,015h,038h,0f4h,003h,01ah,030h,0f5h,001h,044h,0ffh	; a5b7  ..@..8...0..D.

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_09: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa5c5..0xa5db  (22 bytes)
DATA_sala_3_del_nivel_09:
	defb 0f3h,003h,015h,038h,00bh,095h,044h,013h,08dh,034h,013h,00dh,050h,013h,015h,030h	; a5c5  ...8..D..4..P..0
	defb 0f5h,000h,033h,001h,0a8h,0ffh	; a5d5

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_09: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa5db..0xa5f9  (30 bytes)
DATA_sala_4_del_nivel_09:
	defb 0f3h,003h,00dh,030h,00bh,085h,038h,00bh,08dh,040h,00bh,00dh,048h,013h,08dh,030h	; a5db  ...0..8..@..H..0
	defb 013h,00dh,048h,013h,015h,068h,0f4h,00fh,01ah,030h,0f5h,003h,03ah,0ffh	; a5eb  ..H..h...0..:.

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_10: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa5f9..0xa607  (14 bytes)
DATA_sala_1_del_nivel_10:
	defb 0f1h,003h,00dh,022h,004h,000h,0f4h,003h,002h,030h,007h,016h,028h,0ffh	; a5f9  ...".....0..(.

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_10: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa607..0xa615  (14 bytes)
DATA_sala_2_del_nivel_10:
	defb 0f0h,004h,015h,00eh,018h,008h,00dh,00ah,010h,0f4h,003h,08ah,030h,0ffh	; a607  ............0.

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_10: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa615..0xa626  (17 bytes)
DATA_sala_3_del_nivel_10:
	defb 0f0h,008h,005h,00ah,014h,008h,008h,00ah,014h,0f4h,003h,016h,032h,0f6h,054h,08ch	; a615  ............2.T.
	defb 0ffh	; a625

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_10: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xa626..0xa634  (14 bytes)
DATA_sala_4_del_nivel_10:
	defb 0f1h,003h,00dh,00ah,004h,008h,0f4h,009h,006h,028h,0f6h,074h,08ch,0ffh	; a626  .........(.t..

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_11: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa634..0xa684  (80 bytes)
DATA_mapa_del_nivel_11:
	defb 001h,031h,0b1h,001h,001h,032h,0b2h,001h,031h,0b5h,001h,001h,032h,0b6h,001h,001h,033h,0b3h,001h,001h	; a634  .1...2..1...2...3...
	defb 031h,0b1h,031h,0b1h,0cbh,03ah,019h,019h,026h,068h,03eh,0b1h,027h,0e2h,051h,0a4h,05ah,002h,002h,0dbh	; a648  1.1..:..&h>.'.Q.Z...
	defb 026h,0a6h,040h,0c0h,059h,0d9h,0d8h,054h,035h,052h,052h,0b3h,029h,061h,0d0h,048h,042h,064h,01bh,0c2h	; a65c  &.@.Y..T5RR.)a.HBd..
	defb 028h,03ah,0bdh,0a8h,0d6h,052h,0beh,056h,033h,053h,059h,0c0h,0c6h,03bh,0e8h,0b3h,05ah,0dch,003h,0dbh	; a670  (:...R.V3SY..;..Z...

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_11: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa684..0xa6b3  (47 bytes)
DATA_objetos_del_nivel_11:
	defb 0f0h,0ceh,019h,006h,0f1h,003h,00bh,007h,003h,00fh,003h,0f2h,016h,085h,047h,047h	; a684  ..............GG
	defb 046h,07ah,0c4h,027h,0f3h,006h,013h,00ch,0d0h,00fh,00fh,0f4h,052h,003h,083h,012h	; a694  Fz.'........R...
	defb 0d2h,016h,0f5h,00eh,005h,082h,0f6h,0ceh,004h,003h,0f7h,044h,004h,000h,0ffh	; a6a4  ...........D...

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_12: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa6b3..0xa703  (80 bytes)
DATA_mapa_del_nivel_12:
	defb 031h,052h,052h,0b1h,02bh,05dh,0a1h,045h,02ah,053h,019h,0d9h,0cbh,039h,052h,0b1h,02dh,05fh,0deh,0a4h	; a6b3  1RR.+].E*S...9R.-_..
	defb 001h,001h,031h,052h,001h,040h,0e7h,050h,057h,058h,057h,0d9h,001h,001h,001h,001h,001h,001h,001h,001h	; a6c7  ..1R.@.PWXW.........
	defb 0e8h,0b1h,001h,001h,064h,0c2h,031h,0b1h,063h,0bfh,050h,0c2h,031h,03eh,03fh,0b6h,032h,0d9h,054h,001h	; a6db  ....d.1.c.P.1>?.2.T.
	defb 032h,059h,019h,0b4h,033h,052h,052h,0b1h,027h,05dh,0d0h,04bh,029h,0d0h,020h,0a7h,032h,059h,019h,0b6h	; a6ef  2Y..3RR.'].K). .2Y..

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_12: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa703..0xa743  (64 bytes)
DATA_objetos_del_nivel_12:
	defb 0f0h,08ch,017h,006h,0f1h,003h,007h,005h,003h,00fh,002h,009h,013h,00bh,00fh,01bh	; a703  ................
	defb 002h,0c7h,007h,009h,0c7h,00fh,005h,0d1h,017h,002h,0f2h,007h,068h,087h,034h,0d6h	; a713  ............h.4.
	defb 0a9h,0f3h,004h,003h,00bh,092h,004h,00dh,0c8h,01ah,04fh,0f4h,00eh,001h,006h,01eh	; a723  ..........O.....
	defb 048h,011h,086h,006h,0f5h,088h,018h,081h,0d2h,00eh,081h,0f6h,08ch,00bh,00bh,0ffh	; a733  H...............

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_13: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa743..0xa793  (80 bytes)
DATA_mapa_del_nivel_13:
	defb 031h,052h,052h,052h,042h,0a1h,050h,05dh,028h,000h,03fh,063h,0c7h,000h,0beh,068h,026h,04fh,01bh,0e4h	; a743  1RRRB.P](.?c...h&O..
	defb 0e8h,052h,052h,0b1h,064h,0d0h,021h,0c2h,019h,0bfh,000h,0a8h,0e8h,03eh,000h,047h,064h,09bh,0cfh,0a6h	; a757  .RR.d.!......>.Gd...
	defb 026h,067h,0bdh,0e6h,026h,03eh,052h,000h,027h,0a3h,05eh,065h,028h,000h,000h,06ah,05ah,002h,002h,083h	; a76b  &g..&>R.'.^e(..jZ...
	defb 000h,03dh,0e7h,0a6h,066h,052h,03eh,0a6h,065h,0deh,0a3h,0a7h,000h,06ah,000h,0a8h,002h,083h,002h,0dah	; a77f  .=..fR>.e....j......

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_13: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa793..0xa7d3  (64 bytes)
DATA_objetos_del_nivel_13:
	defb 0f1h,003h,017h,005h,003h,01bh,00bh,009h,00bh,002h,04fh,00bh,002h,087h,00fh,00dh	; a793  ..........O.....
	defb 08dh,007h,007h,08dh,00fh,003h,0c7h,00fh,002h,0cdh,013h,007h,0f2h,041h,066h,084h	; a7a3  .............Af.
	defb 028h,0f3h,004h,00ah,04ch,090h,013h,04eh,0f4h,00eh,006h,046h,006h,084h,00eh,0c4h	; a7b3  (...L..N...F....
	defb 011h,0f5h,044h,012h,081h,088h,004h,001h,0d0h,00dh,082h,0f6h,0d2h,009h,002h,0ffh	; a7c3  ..D.............

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_14: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa7d3..0xa823  (80 bytes)
DATA_mapa_del_nivel_14:
	defb 001h,001h,001h,001h,031h,005h,005h,0b1h,032h,006h,006h,0b2h,035h,013h,008h,0b3h,028h,017h,0bah,0a6h	; a7d3  ....1...2...5...(...
	defb 028h,009h,00fh,0a6h,0c7h,00ch,00eh,0a6h,0cch,007h,00fh,046h,0d4h,063h,006h,0b6h,033h,052h,005h,0b3h	; a7e7  (..........F.c..3R..
	defb 026h,067h,006h,0b4h,0c6h,013h,00dh,00dh,036h,016h,010h,006h,033h,007h,00fh,013h,034h,063h,010h,016h	; a7fb  &g......6...3...4c..
	defb 032h,006h,019h,0b2h,00dh,00fh,03eh,0b3h,010h,00eh,055h,0b4h,008h,011h,039h,0b5h,019h,016h,063h,0b6h	; a80f  2.....>...U...9...c.

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_14: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa823..0xa865  (66 bytes)
DATA_objetos_del_nivel_14:
	defb 0f1h,007h,007h,007h,04dh,01bh,002h,08fh,003h,007h,08fh,017h,007h,0c7h,017h,00fh	; a823  ....M...........
	defb 0cfh,007h,003h,0cfh,017h,007h,0f2h,042h,031h,087h,025h,0c6h,029h,0c1h,06ch,0f3h	; a833  .......B1.%.).l.
	defb 00ah,010h,08fh,0cah,007h,04dh,0f4h,050h,00bh,084h,00eh,094h,00bh,0d4h,013h,0f5h	; a843  .....M.P........
	defb 046h,00fh,081h,084h,004h,001h,0c2h,005h,081h,0f6h,0d4h,01eh,00ch,0f7h,082h,019h	; a853  F...............
	defb 0d0h,0ffh	; a863

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_15: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa865..0xa8b5  (80 bytes)
DATA_mapa_del_nivel_15:
	defb 031h,0b1h,001h,001h,032h,0b2h,001h,001h,033h,03eh,052h,052h,034h,0d9h,063h,019h,001h,001h,001h,001h	; a865  1...2...3>RR4.c.....
	defb 001h,001h,001h,001h,001h,001h,001h,001h,052h,052h,052h,052h,019h,063h,019h,019h,001h,001h,001h,001h	; a879  ........RRRR.c......
	defb 001h,001h,001h,001h,001h,031h,0b1h,031h,0b1h,02ah,0aah,02ah,019h,019h,063h,019h,001h,001h,001h,001h	; a88d  .....1.1.*.*..c.....
	defb 001h,001h,001h,001h,001h,031h,0b1h,001h,052h,050h,0abh,001h,063h,0bdh,000h,0b1h,001h,0d4h,063h,0b2h	; a8a1  .....1..RP..c.....c.

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_15: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa8b5..0xa8f0  (59 bytes)
DATA_objetos_del_nivel_15:
	defb 0f1h,003h,007h,007h,003h,00bh,003h,00bh,007h,007h,00bh,01bh,003h,04bh,007h,007h	; a8b5  .............K..
	defb 04bh,00fh,007h,04bh,017h,007h,087h,01bh,00bh,0f2h,006h,08bh,056h,08ah,0d6h,057h	; a8c5  K..K........V..W
	defb 0f3h,006h,003h,04bh,08eh,00ch,08ch,0d2h,01ah,00eh,0f4h,050h,00bh,090h,013h,0f5h	; a8d5  ...K.......P....
	defb 08eh,004h,001h,0c8h,012h,001h,0f6h,010h,013h,017h,0ffh	; a8e5  ...........

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_16: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa8f0..0xa940  (80 bytes)
DATA_mapa_del_nivel_16:
	defb 031h,052h,0e9h,052h,0c9h,04fh,05eh,0dfh,028h,000h,067h,0d9h,029h,0a1h,052h,0b1h,004h,004h,004h,004h	; a8f0  1R.R.O^.(.g.).R.....
	defb 052h,0b1h,001h,001h,09ah,0cfh,0b7h,001h,0d9h,0e7h,03eh,0b1h,001h,0d4h,0d9h,063h,001h,001h,031h,0b3h	; a904  R.........>....c..1.
	defb 001h,001h,031h,0b7h,001h,031h,03ah,054h,031h,03ah,054h,001h,019h,054h,001h,001h,001h,001h,001h,001h	; a918  ..1..1:T1:T..T......
	defb 02ah,066h,0e6h,04ch,0cbh,000h,000h,0b5h,02dh,05eh,0deh,0a9h,02ah,000h,000h,0aah,004h,004h,004h,004h	; a92c  *f.L....-^..*.......

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_16: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa940..0xa97a  (58 bytes)
DATA_objetos_del_nivel_16:
	defb 0f1h,009h,003h,007h,043h,007h,00bh,04bh,017h,003h,0f2h,046h,061h,043h,089h,086h	; a940  ....C..K...FaC..
	defb 064h,0c7h,05bh,0f3h,004h,003h,014h,086h,013h,011h,0c4h,004h,013h,0f4h,00ch,016h	; a950  d.[.............
	defb 048h,013h,0c6h,001h,0f5h,004h,00dh,081h,08ah,00ch,001h,08eh,004h,001h,0f6h,0c4h	; a960  H...............
	defb 01bh,008h,006h,01dh,018h,0f7h,044h,004h,000h,0ffh	; a970  ......D...

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_17: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa97a..0xa9ca  (80 bytes)
DATA_mapa_del_nivel_17:
	defb 02ah,00ch,010h,057h,02ah,011h,005h,038h,032h,016h,006h,058h,035h,013h,00fh,0b1h,0c7h,017h,006h,019h	; a97a  *..W*..82..X5.......
	defb 0b8h,052h,0b1h,031h,0b8h,04fh,0d0h,0aah,058h,0e3h,059h,0b2h,031h,013h,008h,0b3h,019h,016h,0d3h,046h	; a98e  .R.1.O..X.Y.1......F
	defb 0cch,052h,005h,0b7h,0d4h,0d3h,00ch,058h,033h,0bbh,012h,008h,026h,01dh,023h,01ah,034h,0d9h,063h,059h	; a9a2  .R.....X3...&.#.4.cY
	defb 037h,011h,0b9h,0a8h,0d8h,016h,0d3h,04ah,012h,008h,0bbh,0aah,023h,09fh,04eh,0a4h,019h,0d9h,059h,0b4h	; a9b6  7......J....#.N...Y.

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_17: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xa9ca..0xa9fe  (52 bytes)
DATA_objetos_del_nivel_17:
	defb 0f0h,090h,017h,006h,0f1h,043h,01bh,00bh,08bh,003h,00bh,0d1h,007h,002h,0f2h,003h	; a9ca  .....C..........
	defb 061h,097h,022h,0c6h,043h,0f3h,012h,01ah,050h,092h,008h,053h,0d2h,016h,012h,0f4h	; a9da  a.".C...P..S....
	defb 04ch,00ch,084h,01dh,088h,008h,0d4h,01eh,0f5h,044h,00eh,082h,08ch,018h,001h,0f6h	; a9ea  L........D......
	defb 094h,01ch,00eh,0ffh	; a9fa

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_18: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xa9fe..0xaa4e  (80 bytes)
DATA_mapa_del_nivel_18:
	defb 031h,068h,068h,0b1h,024h,0e4h,0e4h,0a4h,026h,000h,000h,0a6h,027h,0afh,02fh,0a7h,028h,0aah,02ah,0a8h	; a9fe  1hh.$...&...'./.(.*.
	defb 031h,052h,0b1h,001h,024h,0d0h,000h,0b1h,026h,020h,0d0h,067h,034h,0e7h,03ch,052h,001h,0d4h,059h,019h	; aa12  1R..$...& .g4.<R..Y.
	defb 036h,019h,019h,0b6h,035h,052h,052h,0b5h,0d9h,063h,019h,059h,0b5h,001h,001h,035h,0b6h,001h,001h,036h	; aa26  6...5RR..c.Y...5...6
	defb 001h,001h,031h,0b1h,031h,0b1h,032h,0b2h,0bah,000h,0beh,0b3h,052h,067h,059h,0b4h,019h,054h,001h,001h	; aa3a  ..1.1.2.....RgY..T..

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_18: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xaa4e..0xaa7b  (45 bytes)
DATA_objetos_del_nivel_18:
	defb 0f1h,009h,003h,007h,0f2h,016h,03ah,056h,058h,086h,025h,0c6h,089h,0f3h,00ch,009h	; aa4e  ......:VX.%.....
	defb 091h,052h,01bh,094h,0f4h,006h,009h,006h,011h,050h,009h,0d0h,00eh,0f5h,0c6h,014h	; aa5e  .R.......P......
	defb 082h,0d2h,003h,081h,0f6h,08ch,00bh,015h,0f7h,08ah,013h,0d5h,0ffh	; aa6e  .............

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_19: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xaa7b..0xaacb  (80 bytes)
DATA_mapa_del_nivel_19:
	defb 001h,031h,052h,0b1h,040h,063h,019h,0b2h,001h,035h,03eh,0b1h,001h,028h,0bch,0aah,0b8h,0bch,0bch,0aah	; aa7b  .1R.@c...5>..(......
	defb 001h,028h,0bch,000h,001h,028h,0bch,04dh,001h,028h,0bch,048h,001h,028h,0bch,0aah,001h,028h,0bch,0aah	; aa8f  .(...(.M.(.H.(...(..
	defb 031h,0a6h,028h,0aah,041h,0a7h,029h,0c1h,02ah,03dh,0bah,0aah,0c5h,068h,03eh,0aah,027h,0e2h,051h,0a4h	; aaa3  1.(.A.).*=...h>.'.Q.
	defb 0d6h,0e6h,0eah,0a6h,031h,066h,062h,0a7h,024h,0a1h,0e6h,0a8h,027h,05eh,0dfh,0a9h,05ah,002h,0dch,0b0h	; aab7  ....1fb.$...'^..Z...

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_19: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xaacb..0xaafd  (50 bytes)
DATA_objetos_del_nivel_19:
	defb 0f1h,003h,017h,007h,08fh,00bh,002h,0c9h,017h,007h,0f2h,006h,042h,046h,05dh,096h	; aacb  ............BF].
	defb 065h,083h,096h,0f3h,006h,00fh,090h,006h,019h,051h,0c8h,003h,054h,0f4h,008h,00bh	; aadb  e........Q..T...
	defb 092h,009h,0c6h,016h,0d2h,019h,0f5h,08ah,00eh,082h,0cch,01ch,001h,0f6h,08eh,002h	; aaeb  ................
	defb 004h,0ffh	; aafb

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_20: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xaafd..0xab4d  (80 bytes)
DATA_mapa_del_nivel_20:
	defb 040h,057h,057h,0c0h,035h,038h,0b8h,0b5h,0c7h,052h,052h,047h,034h,019h,019h,0b4h,033h,052h,052h,0b5h	; aafd  @WW.58...RRG4...3RR.
	defb 026h,000h,000h,0a8h,025h,0d0h,0e6h,03ch,02dh,060h,0dfh,023h,0cbh,06ah,051h,0d0h,05bh,083h,002h,05ch	; ab11  &...%..<-`.#.jQ.[..\
	defb 001h,001h,001h,001h,0e8h,052h,052h,052h,064h,0cfh,021h,05dh,000h,0eah,000h,000h,002h,003h,002h,002h	; ab25  .....RRRd.!]........
	defb 001h,031h,0b1h,001h,052h,000h,0aah,001h,09fh,050h,0d0h,0b1h,0bch,0bch,03ch,045h,0dch,0dch,05ch,0dbh	; ab39  .1..R....P....<E..\.

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_20: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xab4d..0xab82  (53 bytes)
DATA_objetos_del_nivel_20:
	defb 0f1h,00bh,00fh,007h,087h,003h,002h,0c7h,003h,00dh,0f2h,004h,051h,046h,05bh,040h	; ab4d  ............QF[@
	defb 096h,0d7h,09bh,0f3h,00eh,00ch,010h,090h,010h,093h,0c8h,00dh,052h,0f4h,008h,010h	; ab5d  ............R...
	defb 046h,006h,052h,009h,0ceh,01dh,0f5h,088h,015h,081h,090h,006h,002h,090h,018h,081h	; ab6d  F.R.............
	defb 0f6h,08ah,006h,00fh,0ffh	; ab7d

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_11: cuatro punteros, uno por sala
;   0xab82..0xab8a  (8 bytes)
DATA_salas_del_nivel_11:
	defw 0abd2h,0abd3h,0abe9h,0abf6h	; ab82  -> DATA_sala_1_del_nivel_11 DATA_sala_2_del_nivel_11 DATA_sala_3_del_nivel_11 DATA_sala_4_del_nivel_11

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_12: cuatro punteros, uno por sala
;   0xab8a..0xab92  (8 bytes)
DATA_salas_del_nivel_12:
	defw 0ac0bh,0ac16h,0ac1bh,0ac23h	; ab8a  -> DATA_sala_1_del_nivel_12 DATA_sala_2_del_nivel_12 DATA_sala_3_del_nivel_12 DATA_sala_4_del_nivel_12

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_13: cuatro punteros, uno por sala
;   0xab92..0xab9a  (8 bytes)
DATA_salas_del_nivel_13:
	defw 0ac2dh,0ac3dh,0ac4ah,0ac57h	; ab92  -> DATA_sala_1_del_nivel_13 DATA_sala_2_del_nivel_13 DATA_sala_3_del_nivel_13 DATA_sala_4_del_nivel_13

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_14: cuatro punteros, uno por sala
;   0xab9a..0xaba2  (8 bytes)
DATA_salas_del_nivel_14:
	defw 0ac69h,0ac74h,0ac88h,0aca7h	; ab9a  -> DATA_sala_1_del_nivel_14 DATA_sala_2_del_nivel_14 DATA_sala_3_del_nivel_14 DATA_sala_4_del_nivel_14

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_15: cuatro punteros, uno por sala
;   0xaba2..0xabaa  (8 bytes)
DATA_salas_del_nivel_15:
	defw 0acbbh,0acc0h,0acc8h,0acd8h	; aba2  -> DATA_sala_1_del_nivel_15 DATA_sala_2_del_nivel_15 DATA_sala_3_del_nivel_15 DATA_sala_4_del_nivel_15

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_16: cuatro punteros, uno por sala
;   0xabaa..0xabb2  (8 bytes)
DATA_salas_del_nivel_16:
	defw 0ace3h,0acf2h,0acfdh,0ad08h	; abaa  -> DATA_sala_1_del_nivel_16 DATA_sala_2_del_nivel_16 DATA_sala_3_del_nivel_16 DATA_sala_4_del_nivel_16

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_17: cuatro punteros, uno por sala
;   0xabb2..0xabba  (8 bytes)
DATA_salas_del_nivel_17:
	defw 0ad12h,0ad2fh,0ad40h,0ad56h	; abb2  -> DATA_sala_1_del_nivel_17 DATA_sala_2_del_nivel_17 DATA_sala_3_del_nivel_17 DATA_sala_4_del_nivel_17

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_18: cuatro punteros, uno por sala
;   0xabba..0xabc2  (8 bytes)
DATA_salas_del_nivel_18:
	defw 0ad6ah,0ad7ah,0ad8dh,0ad98h	; abba  -> DATA_sala_1_del_nivel_18 DATA_sala_2_del_nivel_18 DATA_sala_3_del_nivel_18 DATA_sala_4_del_nivel_18

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_19: cuatro punteros, uno por sala
;   0xabc2..0xabca  (8 bytes)
DATA_salas_del_nivel_19:
	defw 0adaah,0adabh,0adach,0adb0h	; abc2  -> DATA_sala_1_del_nivel_19 DATA_sala_2_del_nivel_19 DATA_sala_3_del_nivel_19 DATA_sala_4_del_nivel_19

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_20: cuatro punteros, uno por sala
;   0xabca..0xabd2  (8 bytes)
DATA_salas_del_nivel_20:
	defw 0adc1h,0adceh,0add7h,0ade1h	; abca  -> DATA_sala_1_del_nivel_20 DATA_sala_2_del_nivel_20 DATA_sala_3_del_nivel_20 DATA_sala_4_del_nivel_20

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_11: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xabd2..0xabd3  (1 bytes)
DATA_sala_1_del_nivel_11:
	defb 0ffh	; abd2

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_11: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xabd3..0xabe9  (22 bytes)
DATA_sala_2_del_nivel_11:
	defb 0f1h,003h,013h,01bh,002h,000h,003h,019h,020h,002h,000h,0f4h,003h,00ah,034h,0f5h	; abd3  ........ .....4.
	defb 000h,097h,0f6h,074h,04ch,0ffh	; abe3

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_11: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xabe9..0xabf6  (13 bytes)
DATA_sala_3_del_nivel_11:
	defb 0f4h,00bh,092h,028h,0f5h,000h,029h,000h,044h,0f6h,094h,074h,0ffh	; abe9  ...(..).D..t.

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_11: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xabf6..0xac0b  (21 bytes)
DATA_sala_4_del_nivel_11:
	defb 0f1h,007h,009h,004h,008h,000h,0f4h,007h,00eh,02ch,0f5h,003h,04dh,000h,069h,001h	; abf6  .........,..M.i.
	defb 095h,0f6h,094h,0b4h,0ffh	; ac06

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_12 (tramo): lo que lleva montado la sala; L_8E73 lo
;   lee por tipos, del 0xF0 al 0xF7
;   0xac0b..0xac16  (11 bytes)  de 0xac0b..0xac1b (16 bytes)
DATA_sala_1_del_nivel_12:
	defb 0f1h,003h,018h,00bh,004h,006h,0f5h,000h,034h,001h,09bh	; ac0b  ........4..

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_12: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xac16..0xac1b  (5 bytes)
DATA_sala_2_del_nivel_12:
	defb 0f4h,003h,09ah,030h,0ffh	; ac16

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_12: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xac1b..0xac23  (8 bytes)
DATA_sala_3_del_nivel_12:
	defb 0f4h,007h,012h,038h,0f5h,000h,08ah,0ffh	; ac1b  ...8....

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_12: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xac23..0xac2d  (10 bytes)
DATA_sala_4_del_nivel_12:
	defb 0f5h,003h,022h,002h,02ah,003h,056h,002h,0a2h,0ffh	; ac23  ..".*.V...

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_13: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xac2d..0xac3d  (16 bytes)
DATA_sala_1_del_nivel_13:
	defb 0f4h,003h,006h,020h,00fh,016h,024h,0f5h,000h,03ch,002h,097h,0f7h,094h,0cch,0ffh	; ac2d  ... ..$..<......

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_13: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xac3d..0xac4a  (13 bytes)
DATA_sala_2_del_nivel_13:
	defb 0f4h,003h,096h,038h,0f5h,001h,034h,000h,095h,0f6h,094h,034h,0ffh	; ac3d  ...8..4....4.

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_13: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xac4a..0xac57  (13 bytes)
DATA_sala_3_del_nivel_13:
	defb 0f0h,004h,018h,010h,014h,0f4h,00dh,00ah,024h,0f5h,002h,096h,0ffh	; ac4a  ........$....

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_13: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xac57..0xac69  (18 bytes)
DATA_sala_4_del_nivel_13:
	defb 0f0h,008h,005h,00ch,010h,0f4h,007h,012h,030h,00dh,012h,036h,0f5h,003h,026h,001h	; ac57  ........0..6..&.
	defb 099h,0ffh	; ac67

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_14: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xac69..0xac74  (11 bytes)
DATA_sala_1_del_nivel_14:
	defb 0f2h,00eh,019h,0f3h,00bh,08dh,038h,00bh,095h,042h,0ffh	; ac69  ......8..B.

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_14: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xac74..0xac88  (20 bytes)
DATA_sala_2_del_nivel_14:
	defb 0f3h,007h,08dh,034h,007h,095h,030h,007h,015h,042h,00fh,015h,038h,0f5h,000h,087h	; ac74  ...4..0..B..8...
	defb 0f6h,084h,05ch,0ffh	; ac84

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_14: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xac88..0xaca7  (31 bytes)
DATA_sala_3_del_nivel_14:
	defb 0f2h,00eh,013h,016h,008h,0f3h,003h,095h,030h,003h,015h,042h,00bh,08dh,038h,00bh	; ac88  ........0..B..8.
	defb 00dh,040h,013h,09dh,030h,0f4h,009h,002h,030h,0f5h,000h,06bh,001h,0a2h,0ffh	; ac98  .@..0...0..k...

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_14: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xaca7..0xacbb  (20 bytes)
DATA_sala_4_del_nivel_14:
	defb 0f3h,003h,00dh,030h,003h,08dh,034h,00bh,08dh,038h,013h,08dh,046h,0f5h,003h,06ah	; aca7  ...0..4..8..F..j
	defb 0f6h,0a4h,09ch,0ffh	; acb7

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_15: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xacbb..0xacc0  (5 bytes)
DATA_sala_1_del_nivel_15:
	defb 0f4h,00bh,00eh,034h,0ffh	; acbb

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_15: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xacc0..0xacc8  (8 bytes)
DATA_sala_2_del_nivel_15:
	defb 0f4h,00bh,012h,030h,00bh,01ah,040h,0ffh	; acc0  ...0..@.

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_15: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xacc8..0xacd8  (16 bytes)
DATA_sala_3_del_nivel_15:
	defb 0f1h,007h,009h,006h,006h,000h,007h,015h,010h,003h,006h,0f4h,007h,01eh,048h,0ffh	; acc8  ..............H.

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_15: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xacd8..0xace3  (11 bytes)
DATA_sala_4_del_nivel_15:
	defb 0f4h,007h,08ah,038h,00dh,016h,040h,0f6h,0a4h,09ch,0ffh	; acd8  ...8..@....

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_16: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xace3..0xacf2  (15 bytes)
DATA_sala_1_del_nivel_16:
	defb 0f0h,004h,015h,00eh,018h,0f1h,003h,008h,00bh,004h,008h,0f5h,000h,074h,0ffh	; ace3  .............t.

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_16: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xacf2..0xacfd  (11 bytes)
DATA_sala_2_del_nivel_16:
	defb 0f4h,009h,082h,030h,00bh,012h,034h,0f6h,084h,0dch,0ffh	; acf2  ...0..4....

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_16: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xacfd..0xad08  (11 bytes)
DATA_sala_3_del_nivel_16:
	defb 0f4h,003h,092h,040h,007h,00ah,034h,0f5h,003h,06ah,0ffh	; acfd  ...@..4..j.

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_16: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xad08..0xad12  (10 bytes)
DATA_sala_4_del_nivel_16:
	defb 0f0h,004h,00dh,00eh,018h,004h,010h,00eh,018h,0ffh	; ad08  ..........

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_17: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xad12..0xad2f  (29 bytes)
DATA_sala_1_del_nivel_17:
	defb 0f3h,003h,00dh,038h,003h,08dh,030h,00bh,00dh,028h,00bh,08dh,040h,00bh,015h,048h	; ad12  ...8..0..(..@..H
	defb 013h,08dh,030h,013h,015h,038h,013h,095h,044h,0f5h,000h,02ch,0ffh	; ad22  ..0..8..D..,.

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_17: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xad2f..0xad40  (17 bytes)
DATA_sala_2_del_nivel_17:
	defb 0f1h,003h,015h,01ch,006h,000h,0f2h,016h,010h,0f4h,003h,012h,034h,0f5h,000h,0a2h	; ad2f  ............4...
	defb 0ffh	; ad3f

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_17: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xad40..0xad56  (22 bytes)
DATA_sala_3_del_nivel_17:
	defb 0f3h,007h,015h,030h,0f4h,003h,00ah,048h,00bh,006h,060h,0f5h,002h,04ch,001h,075h	; ad40  ...0...H..`..L.u
	defb 003h,0a2h,0f6h,0a4h,09ch,0ffh	; ad50

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_17: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xad56..0xad6a  (20 bytes)
DATA_sala_4_del_nivel_17:
	defb 0f2h,010h,008h,0f3h,007h,08dh,032h,0f4h,009h,01ah,048h,011h,01ah,030h,0f5h,004h	; ad56  ......2...H..0..
	defb 07ah,001h,0a4h,0ffh	; ad66

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_18: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xad6a..0xad7a  (16 bytes)
DATA_sala_1_del_nivel_18:
	defb 0f2h,008h,00dh,010h,017h,0f4h,003h,01ah,048h,009h,006h,040h,0f5h,001h,077h,0ffh	; ad6a  ........H..@..w.

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_18: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xad7a..0xad8d  (19 bytes)
DATA_sala_2_del_nivel_18:
	defb 0f1h,003h,015h,004h,007h,00eh,0f2h,008h,007h,00ch,00eh,0f4h,00fh,01ah,038h,0f6h	; ad7a  ..............8.
	defb 064h,0f4h,0ffh	; ad8a

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_18: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xad8d..0xad98  (11 bytes)
DATA_sala_3_del_nivel_18:
	defb 0f2h,00eh,00fh,0f4h,007h,002h,050h,0f5h,003h,02bh,0ffh	; ad8d  ......P..+.

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_18: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xad98..0xadaa  (18 bytes)
DATA_sala_4_del_nivel_18:
	defb 0f2h,00ah,019h,00eh,005h,012h,016h,0f4h,007h,00ah,044h,0f5h,000h,04dh,0f7h,084h	; ad98  ..........D..M..
	defb 074h,0ffh	; ada8

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_19: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xadaa..0xadab  (1 bytes)
DATA_sala_1_del_nivel_19:
	defb 0ffh	; adaa

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_19: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xadab..0xadac  (1 bytes)
DATA_sala_2_del_nivel_19:
	defb 0ffh	; adab

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_19: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xadac..0xadb0  (4 bytes)
DATA_sala_3_del_nivel_19:
	defb 0f6h,094h,04ch,0ffh	; adac

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_19: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xadb0..0xadc1  (17 bytes)
DATA_sala_4_del_nivel_19:
	defb 0f0h,004h,008h,010h,014h,00ch,010h,008h,017h,0f4h,00dh,006h,028h,0f6h,034h,0b4h	; adb0  ............(.4.
	defb 0ffh	; adc0

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_20: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xadc1..0xadce  (13 bytes)
DATA_sala_1_del_nivel_20:
	defb 0f2h,012h,011h,0f4h,00dh,006h,030h,0f5h,003h,045h,003h,08bh,0ffh	; adc1  ......0..E...

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_20: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xadce..0xadd7  (9 bytes)
DATA_sala_2_del_nivel_20:
	defb 0f0h,008h,010h,00ch,014h,0f5h,000h,034h,0ffh	; adce  .......4.

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_20: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xadd7..0xade1  (10 bytes)
DATA_sala_3_del_nivel_20:
	defb 0f2h,00ch,01bh,0f6h,094h,074h,0f7h,080h,074h,0ffh	; add7  .....t..t.

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_20: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xade1..0xade8  (7 bytes)
DATA_sala_4_del_nivel_20:
	defb 0f1h,00bh,018h,004h,004h,000h,0ffh	; ade1

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_21: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xade8..0xae38  (80 bytes)
DATA_mapa_del_nivel_21:
	defb 031h,052h,0b1h,001h,02bh,0d0h,03ah,057h,032h,0bfh,0b5h,040h,001h,035h,047h,001h,031h,0bch,0a6h,001h	; ade8  1R..+.:W2..@.5G.1...
	defb 001h,031h,069h,0b1h,0b8h,050h,05dh,0c2h,0d8h,0d9h,019h,0b6h,031h,052h,052h,0b1h,004h,004h,004h,004h	; adfc  .1i..P].....1RR.....
	defb 02ah,03fh,0b4h,001h,02ah,0b5h,001h,001h,0cbh,03ch,038h,0c0h,026h,03ch,0b3h,001h,026h,03ch,0a6h,001h	; ae10  *?..*....<8.&<..&<..
	defb 034h,0bfh,0a6h,001h,001h,035h,0bch,0b1h,031h,051h,09bh,0ach,041h,0d0h,03ch,0a8h,030h,05ch,05ch,0dah	; ae24  4....5..1Q..A.<.0\\.

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_21: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xae38..0xae71  (57 bytes)
DATA_objetos_del_nivel_21:
	defb 0f1h,009h,007h,005h,049h,013h,005h,0cdh,00fh,007h,0cdh,01bh,007h,0f2h,000h,032h	; ae38  ....I..........2
	defb 086h,069h,096h,06eh,0c3h,05ch,0f3h,04ah,009h,016h,088h,002h,019h,0f4h,08bh,019h	; ae48  .i.n.\.J........
	defb 08bh,01ah,08ch,018h,08ch,01bh,0f5h,00ah,003h,001h,044h,016h,001h,0cch,005h,001h	; ae58  ..........D.....
	defb 0f6h,084h,012h,001h,0f7h,006h,013h,000h,0ffh	; ae68  .........

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_22: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xae71..0xaec1  (80 bytes)
DATA_mapa_del_nivel_22:
	defb 031h,052h,052h,052h,0c4h,06bh,02fh,0afh,0cbh,04ch,032h,063h,034h,058h,057h,057h,0d4h,057h,058h,057h	; ae71  1RRR.k/..L2c4XWW.WXW
	defb 052h,052h,052h,0b1h,02fh,0a2h,050h,0c1h,019h,0d5h,03fh,0b2h,0b8h,0b9h,038h,054h,057h,063h,054h,031h	; ae85  RRR./.P...?...8TWcT1
	defb 032h,0b2h,031h,0b1h,031h,038h,019h,019h,02ah,0beh,052h,052h,024h,0d1h,01fh,05dh,034h,063h,059h,019h	; ae99  2.1.18..*.RR$..]4cY.
	defb 031h,0b1h,037h,0b1h,019h,019h,0b8h,0aah,052h,052h,03eh,045h,05dh,09fh,051h,0a7h,063h,0d9h,019h,0b6h	; aead  1.7.....RR>E].Q.c...

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_22: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xaec1..0xaf03  (66 bytes)
DATA_objetos_del_nivel_22:
	defb 0f1h,003h,00fh,005h,003h,017h,002h,043h,00bh,005h,049h,003h,002h,083h,013h,007h	; aec1  .......C..I.....
	defb 083h,01bh,00dh,0c3h,003h,007h,0d1h,007h,002h,0d1h,017h,005h,0f2h,006h,08ah,045h	; aed1  ...............E
	defb 06dh,0d7h,045h,0c4h,074h,0f3h,004h,01ah,015h,092h,005h,057h,0c8h,01bh,098h,0f4h	; aee1  m.E.t......W....
	defb 00ch,01bh,054h,00bh,094h,00bh,0f5h,00ah,00ah,082h,0c6h,006h,081h,0f6h,04ch,017h	; aef1  ..T...........L.
	defb 014h,0ffh	; af01

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_23: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xaf03..0xaf53  (80 bytes)
DATA_mapa_del_nivel_23:
	defb 031h,052h,052h,0b1h,02ch,05dh,05dh,0ach,036h,019h,019h,0b6h,001h,035h,0b3h,001h,001h,028h,0a6h,001h	; af03  1RR.,]].6....5...(..
	defb 040h,0b8h,052h,0b1h,0d4h,0b8h,053h,019h,033h,052h,03bh,0b1h,027h,0e1h,09bh,0d0h,05ah,083h,05ch,05ch	; af17  @.R...S.3R;.'...Z.\\
	defb 031h,03fh,0bdh,000h,063h,0b8h,0beh,050h,031h,038h,059h,0d9h,000h,052h,0e8h,0beh,02fh,05dh,064h,023h	; af2b  1?..c..P18Y..R../]d#
	defb 052h,052h,069h,0b1h,05dh,05eh,0dfh,0abh,019h,019h,0d9h,0b2h,0b1h,033h,068h,0b3h,0b0h,05bh,083h,0dbh	; af3f  RRi.]^.......3h..[..

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_23: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xaf53..0xaf8c  (57 bytes)
DATA_objetos_del_nivel_23:
	defb 0f1h,003h,007h,005h,009h,013h,005h,04bh,017h,002h,0f2h,006h,067h,056h,044h,086h	; af53  .......K....gVD.
	defb 096h,0c4h,064h,0f3h,0c4h,006h,018h,004h,010h,056h,04ch,00ah,099h,0f4h,052h,009h	; af63  ..d......VL...R.
	defb 088h,003h,092h,016h,0d2h,011h,0f5h,00ah,009h,001h,046h,018h,001h,0d0h,018h,082h	; af73  ..........F.....
	defb 0f6h,0c6h,01ah,00dh,0f7h,08ah,018h,0c1h,0ffh	; af83  .........

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_24: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xaf8c..0xafdc  (80 bytes)
DATA_mapa_del_nivel_24:
	defb 031h,005h,052h,005h,02ah,00ch,019h,006h,0c9h,013h,00fh,013h,036h,015h,00ah,017h,033h,005h,00ah,012h	; af8c  1.R.*.......6...3...
	defb 052h,005h,038h,0c0h,0bah,00ah,03eh,0b7h,00fh,00ch,0bdh,0b3h,00eh,012h,008h,0a6h,00fh,03ch,022h,0a7h	; afa0  R.8...>..........<".
	defb 026h,00ch,006h,059h,0c8h,012h,00fh,0beh,024h,09eh,00ch,059h,025h,0d0h,009h,018h,034h,059h,006h,019h	; afb4  &..Y....$..Y%...4Y..
	defb 006h,0bfh,0bch,056h,007h,00fh,03fh,054h,0bah,00bh,011h,0b3h,00fh,00ch,015h,0a6h,006h,058h,057h,0b4h	; afc8  ...V..?T.........XW.

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_24: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xafdc..0xb015  (57 bytes)
DATA_objetos_del_nivel_24:
	defb 0f0h,090h,006h,006h,0f1h,003h,013h,007h,00dh,003h,002h,043h,003h,007h,04bh,01bh	; afdc  ...........C..K.
	defb 009h,087h,01bh,003h,0f2h,044h,042h,082h,06eh,0f3h,04ah,010h,017h,092h,01ah,059h	; afec  .....DB.n.J....Y
	defb 0c6h,011h,096h,0f4h,048h,01ah,086h,003h,08eh,005h,0f5h,008h,002h,081h,050h,016h	; affc  ....H.........P.
	defb 001h,0cah,004h,081h,0f6h,044h,019h,016h,0ffh	; b00c  .....D...

; ----------------------------------------------------------------------
; DATOS mapa_del_nivel_25: 80 bytes: 4x20 bloques de 8x4 casillas, o sea las
;   cuatro salas de 32x20 seguidas
;   0xb015..0xb065  (80 bytes)
DATA_mapa_del_nivel_25:
	defb 031h,0b1h,031h,0b7h,032h,063h,0bah,0b5h,035h,0b1h,035h,03dh,036h,063h,0d9h,054h,031h,0b1h,033h,0b5h	; b015  1.1.2c..5.5=6c.T1.3.
	defb 031h,052h,052h,0b1h,02ch,0a1h,053h,0b2h,0d9h,0e7h,039h,0b3h,031h,0beh,067h,0b4h,02bh,0d1h,0beh,0b1h	; b029  1RR.,.S...9.1.g.+...
	defb 032h,063h,059h,059h,033h,052h,03eh,068h,027h,05dh,09bh,0e4h,036h,063h,059h,019h,040h,0d8h,057h,058h	; b03d  2cYY3R>h']..6cY.@.WX
	defb 019h,063h,059h,0b2h,03eh,052h,0e8h,0b3h,09bh,05dh,064h,0a7h,059h,063h,019h,0b6h,057h,058h,0d8h,0c0h	; b051  .cY.>R...]d.Yc..WX..

; ----------------------------------------------------------------------
; DATOS objetos_del_nivel_25: lo que hay repartido por las cuatro salas;
;   L_8D64 lo lee por tipos, del 0xF0 al 0xF7, y lo cierra el 0xFF
;   0xb065..0xb0b7  (82 bytes)
DATA_objetos_del_nivel_25:
	defb 0f0h,002h,007h,008h,086h,009h,006h,08ch,00fh,006h,0c6h,00fh,006h,0cch,006h,006h	; b065  ................
	defb 0f1h,003h,013h,007h,007h,01bh,007h,00bh,007h,007h,043h,017h,007h,087h,003h,005h	; b075  ..........C.....
	defb 087h,00fh,002h,08dh,017h,002h,0cdh,013h,002h,0f2h,015h,049h,096h,027h,0c4h,08bh	; b085  ...........I.'..
	defb 0f3h,044h,008h,055h,08eh,01bh,058h,0c2h,016h,097h,0f4h,008h,001h,008h,00bh,090h	; b095  .D.U..X.........
	defb 00bh,0d0h,00bh,0f5h,044h,003h,081h,082h,015h,001h,0c8h,00ah,081h,0f6h,0c4h,00bh	; b0a5  ....D...........
	defb 013h,0ffh	; b0b5

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_21: cuatro punteros, uno por sala
;   0xb0b7..0xb0bf  (8 bytes)
DATA_salas_del_nivel_21:
	defw 0b0dfh,0b0eah,0b0f3h,0b0f4h	; b0b7  -> DATA_sala_1_del_nivel_21 DATA_sala_2_del_nivel_21 DATA_sala_3_del_nivel_21 DATA_sala_4_del_nivel_21

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_22: cuatro punteros, uno por sala
;   0xb0bf..0xb0c7  (8 bytes)
DATA_salas_del_nivel_22:
	defw 0b102h,0b10fh,0b127h,0b13ch	; b0bf  -> DATA_sala_1_del_nivel_22 DATA_sala_2_del_nivel_22 DATA_sala_3_del_nivel_22 DATA_sala_4_del_nivel_22

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_23: cuatro punteros, uno por sala
;   0xb0c7..0xb0cf  (8 bytes)
DATA_salas_del_nivel_23:
	defw 0b150h,0b158h,0b16ah,0b180h	; b0c7  -> DATA_sala_1_del_nivel_23 DATA_sala_2_del_nivel_23 DATA_sala_3_del_nivel_23 DATA_sala_4_del_nivel_23

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_24: cuatro punteros, uno por sala
;   0xb0cf..0xb0d7  (8 bytes)
DATA_salas_del_nivel_24:
	defw 0b189h,0b19eh,0b1b3h,0b1d0h	; b0cf  -> DATA_sala_1_del_nivel_24 DATA_sala_2_del_nivel_24 DATA_sala_3_del_nivel_24 DATA_sala_4_del_nivel_24

; ----------------------------------------------------------------------
; DATOS salas_del_nivel_25: cuatro punteros, uno por sala
;   0xb0d7..0xb0df  (8 bytes)
DATA_salas_del_nivel_25:
	defw 0b1e4h,0b1f6h,0b20ah,0b21ah	; b0d7  -> DATA_sala_1_del_nivel_25 DATA_sala_2_del_nivel_25 DATA_sala_3_del_nivel_25 DATA_sala_4_del_nivel_25

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_21: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb0df..0xb0ea  (11 bytes)
DATA_sala_1_del_nivel_21:
	defb 0f4h,003h,012h,030h,007h,01ah,02ch,0f5h,000h,066h,0ffh	; b0df  ...0..,..f.

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_21: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb0ea..0xb0f3  (9 bytes)
DATA_sala_2_del_nivel_21:
	defb 0f0h,004h,010h,00eh,01ch,0f5h,001h,06bh,0ffh	; b0ea  .......k.

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_21: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb0f3..0xb0f4  (1 bytes)
DATA_sala_3_del_nivel_21:
	defb 0ffh	; b0f3

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_21: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb0f4..0xb102  (14 bytes)
DATA_sala_4_del_nivel_21:
	defb 0f4h,007h,00ah,03ch,007h,09ah,048h,00dh,016h,04ch,0f5h,001h,09bh,0ffh	; b0f4  ...<..H..L....

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_22: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb102..0xb10f  (13 bytes)
DATA_sala_1_del_nivel_22:
	defb 0f2h,008h,00bh,0f4h,003h,006h,048h,0f5h,001h,06ah,003h,0abh,0ffh	; b102  ......H..j...

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_22: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb10f..0xb127  (24 bytes)
DATA_sala_2_del_nivel_22:
	defb 0f1h,003h,011h,006h,004h,006h,0f2h,00eh,006h,016h,008h,0f4h,009h,08eh,048h,0f5h	; b10f  ..............H.
	defb 000h,089h,001h,08eh,0f6h,0a4h,05ch,0ffh	; b11f  ......\.

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_22: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb127..0xb13c  (21 bytes)
DATA_sala_3_del_nivel_22:
	defb 0f2h,010h,005h,016h,01ah,0f4h,007h,082h,050h,00bh,016h,030h,0f5h,002h,04bh,000h	; b127  ........P..0..K.
	defb 0aah,0f6h,0a4h,05ch,0ffh	; b137

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_22: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb13c..0xb150  (20 bytes)
DATA_sala_4_del_nivel_22:
	defb 0f1h,003h,00dh,00fh,002h,000h,0f2h,010h,006h,0f4h,003h,09ah,034h,0f5h,001h,0a8h	; b13c  ............4...
	defb 0f6h,0a4h,01ch,0ffh	; b14c

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_23: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb150..0xb158  (8 bytes)
DATA_sala_1_del_nivel_23:
	defb 0f4h,003h,00ah,030h,003h,016h,048h,0ffh	; b150  ...0..H.

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_23: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb158..0xb16a  (18 bytes)
DATA_sala_2_del_nivel_23:
	defb 0f4h,003h,096h,03ch,003h,08bh,030h,0f5h,001h,072h,003h,078h,000h,091h,0f6h,094h	; b158  ...<..0..r.x....
	defb 04ch,0ffh	; b168

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_23: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb16a..0xb180  (22 bytes)
DATA_sala_3_del_nivel_23:
	defb 0f1h,003h,006h,009h,002h,000h,00bh,006h,006h,004h,000h,0f4h,00fh,012h,02ch,0f5h	; b16a  ..............,.
	defb 001h,065h,0f6h,094h,0b4h,0ffh	; b17a

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_23: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb180..0xb189  (9 bytes)
DATA_sala_4_del_nivel_23:
	defb 0f0h,004h,010h,010h,01ch,0f7h,094h,08ch,0ffh	; b180  .........

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_24: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb189..0xb19e  (21 bytes)
DATA_sala_1_del_nivel_24:
	defb 0f3h,007h,08dh,030h,007h,00dh,044h,007h,09dh,060h,00fh,09dh,048h,0f4h,003h,016h	; b189  ...0..D..`..H...
	defb 034h,0f5h,001h,049h,0ffh	; b199

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_24: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb19e..0xb1b3  (21 bytes)
DATA_sala_2_del_nivel_24:
	defb 0f3h,00bh,00dh,030h,00bh,08dh,03ch,00fh,005h,034h,0f4h,003h,08ah,044h,00bh,01ah	; b19e  ...0..<..4...D..
	defb 050h,0f5h,003h,099h,0ffh	; b1ae

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_24: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb1b3..0xb1d0  (29 bytes)
DATA_sala_3_del_nivel_24:
	defb 0f3h,003h,00dh,030h,003h,095h,040h,003h,015h,04ch,00bh,015h,050h,013h,015h,038h	; b1b3  ...0..@..L..P..8
	defb 013h,095h,044h,0f4h,00dh,00eh,038h,0f5h,000h,02dh,003h,053h,0ffh	; b1c3  ..D...8..-.S.

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_24: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb1d0..0xb1e4  (20 bytes)
DATA_sala_4_del_nivel_24:
	defb 0f3h,003h,005h,040h,00fh,095h,048h,0f4h,007h,002h,060h,00bh,01ah,040h,0f5h,002h	; b1d0  ...@..H...`..@..
	defb 04bh,000h,0ach,0ffh	; b1e0

; ----------------------------------------------------------------------
; DATOS sala_1_del_nivel_25: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb1e4..0xb1f6  (18 bytes)
DATA_sala_1_del_nivel_25:
	defb 0f1h,003h,00dh,00bh,002h,000h,00bh,011h,006h,002h,000h,0f5h,000h,083h,0f6h,084h	; b1e4  ................
	defb 05ch,0ffh	; b1f4

; ----------------------------------------------------------------------
; DATOS sala_2_del_nivel_25: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb1f6..0xb20a  (20 bytes)
DATA_sala_2_del_nivel_25:
	defb 0f1h,003h,010h,004h,004h,00ah,0f4h,00bh,01ah,038h,00fh,006h,02ch,0f5h,003h,063h	; b1f6  .........8..,..c
	defb 0f7h,084h,0b4h,0ffh	; b206

; ----------------------------------------------------------------------
; DATOS sala_3_del_nivel_25: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb20a..0xb21a  (16 bytes)
DATA_sala_3_del_nivel_25:
	defb 0f4h,007h,012h,038h,013h,016h,044h,0f5h,001h,056h,000h,08ah,0f7h,054h,0cch,0ffh	; b20a  ...8..D..V...T..

; ----------------------------------------------------------------------
; DATOS sala_4_del_nivel_25: lo que lleva montado la sala; L_8E73 lo lee por
;   tipos, del 0xF0 al 0xF7
;   0xb21a..0xb227  (13 bytes)
DATA_sala_4_del_nivel_25:
	defb 0f4h,007h,01ah,048h,013h,006h,030h,0f5h,005h,02eh,001h,0a6h,0ffh	; b21a  ...H..0......

; ----------------------------------------------------------------------
; DATOS guion_del_titulo: RLE, 128 bytes; lo carga 0x55A0
;   0xb227..0xb29d  (118 bytes)
DATA_guion_del_titulo:
	defb 0bdh,087h,0f8h,01fh,081h,0ffh,00fh,0e1h,0ffh,0c7h,018h,01fh,081h,0ffh,00fh,0e1h	; b227  ................
	defb 0ffh,0c7h,018h,01fh,081h,0ffh,00fh,0e1h,0ffh,000h,000h,07eh,0ffh,0b7h,011h,0dbh	; b237  ...........~....
	defb 0dbh,0ffh,05ah,066h,0e7h,0ffh,03ch,0bdh,03ch,03ch,07eh,072h,04eh,06eh,06eh,0efh	; b247  ..Zf..<.<<~rNnn.
	defb 0efh,000h,000h,07eh,0ffh,0b7h,011h,0ffh,099h,00eh,006h,007h,003h,001h,003h,000h	; b257  ...~............
	defb 084h,0ffh,0c3h,066h,0c3h,004h,0ffh,085h,030h,0f0h,0e0h,0c0h,080h,003h,000h,002h	; b267  ...f....0.......
	defb 07eh,086h,072h,04eh,06eh,06eh,0efh,0efh,004h,000h,003h,001h,004h,000h,081h,001h	; b277  ~.rNnn..........
	defb 003h,003h,083h,001h,000h,001h,005h,000h,081h,003h,004h,000h,002h,001h,082h,00ah	; b287  ................
	defb 01eh,007h,000h,081h,003h,000h	; b297

; ----------------------------------------------------------------------
; DATOS guion_del_titulo_2: RLE, 88 bytes; lo carga 0x55B5
;   0xb29d..0xb2ca  (45 bytes)
DATA_guion_del_titulo_2:
	defb 008h,068h,002h,09ah,006h,068h,002h,029h,006h,068h,004h,080h,002h,08bh,005h,0b0h	; b29d  .h...h.).h......
	defb 081h,08bh,003h,080h,083h,08bh,05bh,05bh,006h,050h,004h,080h,002h,08bh,003h,0b0h	; b2ad  ......[[.P......
	defb 007h,080h,003h,0b0h,005h,08bh,081h,0b0h,007h,080h,008h,050h,000h	; b2bd  ...........P.

; ----------------------------------------------------------------------
; DATOS guion_del_titulo_3: RLE, 40 bytes; lo cargan 0x55BE y 0x55C7
;   0xb2ca..0xb2d7  (13 bytes)
DATA_guion_del_titulo_3:
	defb 010h,080h,002h,0b0h,006h,050h,006h,080h,002h,0b0h,008h,050h,000h	; b2ca  .....P.....P.

; ----------------------------------------------------------------------
; DATOS patrones_de_sprite_del_titulo: RLE con la direccion dentro: 928 bytes
;   en 0x1800, 29 patrones de 16x16
;   0xb2d7..0xb585  (686 bytes)
DATA_patrones_de_sprite_del_titulo:
	defb 000h,018h,002h,000h,087h,00ch,03ch,034h,0f6h,0feh,07ch,070h,005h,000h,002h,060h	; b2d7  ......<4..|p...`
	defb 010h,000h,090h,002h,001h,03fh,07fh,0fch,0f0h,0f0h,0c0h,040h,020h,000h,03ch,07eh	; b2e7  .....?.....@ .<~
	defb 077h,07bh,03ah,003h,000h,003h,080h,00ah,000h,088h,08ch,04ch,038h,038h,030h,030h	; b2f7  w{:........L8800
	defb 078h,07ch,01ah,000h,08bh,003h,00fh,00dh,03dh,03fh,01fh,01ch,000h,000h,0e0h,0c0h	; b307  x|......=?......
	defb 008h,000h,002h,080h,002h,000h,002h,0c0h,081h,080h,006h,000h,094h,00fh,01fh,03fh	; b317  ...............?
	defb 03ch,03ch,030h,010h,008h,000h,03fh,0c7h,0c3h,007h,00eh,080h,040h,0c0h,0e0h,020h	; b327  <<0...?.....@.. 
	defb 020h,006h,000h,002h,080h,002h,000h,085h,040h,0efh,0feh,0dch,088h,00bh,000h,086h	; b337   .......@.......
	defb 078h,0fch,00dh,00fh,006h,006h,00ah,000h,087h,002h,000h,01ch,000h,006h,00fh,060h	; b347  x..............`
	defb 003h,0f0h,085h,060h,000h,000h,030h,038h,003h,000h,083h,060h,0c8h,018h,00ah,000h	; b357  ...`..08...`....
	defb 084h,07eh,03eh,03fh,01fh,003h,000h,09ah,03ch,007h,003h,03fh,000h,003h,027h,07fh	; b367  .~>?....<..?..'.
	defb 0ffh,01fh,000h,080h,0e0h,0f0h,030h,078h,0d8h,090h,0e0h,040h,0e0h,0f0h,0f8h,0f8h	; b377  ......0x...@....
	defb 0dch,03ch,003h,000h,090h,001h,019h,033h,063h,061h,070h,078h,070h,070h,060h,0c0h	; b387  .<.....3capxpp`.
	defb 000h,000h,07ch,0fch,0fch,003h,0f8h,088h,0f0h,0e0h,0f8h,07eh,01eh,00ch,00ch,018h	; b397  ..|........~....
	defb 006h,000h,08eh,002h,004h,00ch,00ch,01ch,018h,018h,038h,03ch,0fch,000h,000h,00fh	; b3a7  ..........8<....
	defb 07fh,003h,07eh,089h,0feh,0fch,078h,078h,03fh,01fh,007h,007h,00eh,004h,000h,081h	; b3b7  ..~...xx?.......
	defb 007h,003h,000h,081h,002h,003h,000h,083h,0f0h,038h,038h,003h,000h,087h,080h,000h	; b3c7  .........88.....
	defb 018h,002h,016h,010h,0a0h,004h,000h,088h,00ch,01ch,00eh,000h,07eh,01fh,01fh,00fh	; b3d7  ............~...
	defb 003h,000h,081h,01eh,003h,000h,0a4h,01eh,001h,003h,037h,037h,017h,000h,0c0h,0f0h	; b3e7  ..........77....
	defb 0f8h,018h,03ch,07ch,078h,070h,020h,0feh,0ffh,0f7h,0efh,09eh,01ch,0e0h,0f1h,07eh	; b3f7  ..<|xp ........~
	defb 07eh,0feh,0fch,0f8h,070h,078h,03ch,01ch,01eh,07eh,0feh,012h,000h,084h,01fh,03fh	; b407  ~...px<..~.....?
	defb 037h,01bh,006h,000h,081h,003h,003h,007h,084h,017h,013h,0e0h,0f0h,003h,0f8h,08bh	; b417  7...............
	defb 058h,010h,060h,000h,040h,0f8h,0feh,0dfh,0e7h,0f6h,0e0h,003h,003h,089h,007h,00fh	; b427  X.`.@...........
	defb 00ch,01ch,018h,098h,0f8h,078h,038h,004h,000h,08bh,0c0h,0e0h,0e0h,0c0h,000h,018h	; b437  .....x8.........
	defb 03fh,00fh,007h,006h,00ch,005h,000h,08ah,010h,008h,016h,037h,03fh,01fh,01fh,007h	; b447  ?..........7?...
	defb 000h,000h,003h,0c0h,006h,000h,082h,040h,0c0h,008h,000h,002h,01ch,085h,018h,01fh	; b457  .......@........
	defb 03fh,037h,01bh,006h,000h,088h,003h,007h,005h,01bh,01fh,00fh,0e0h,0f0h,003h,0f8h	; b467  ?7..............
	defb 097h,058h,010h,060h,000h,060h,0fch,0f6h,0fbh,0dbh,0bah,07ch,003h,007h,003h,003h	; b477  .X.`.`.....|....
	defb 001h,00dh,00ch,098h,0f8h,070h,070h,030h,004h,000h,089h,0c0h,0e0h,0e0h,0c0h,0ceh	; b487  .....pp0........
	defb 0feh,0ffh,063h,001h,007h,000h,084h,00fh,01fh,01bh,00dh,006h,000h,081h,003h,005h	; b497  ..c.............
	defb 007h,08ch,0f0h,0f8h,0fch,0fch,07ch,02ch,008h,030h,000h,020h,0f0h,0f8h,003h,0b8h	; b4a7  ......|,.0. ....
	defb 08dh,070h,0c0h,0e4h,0fch,0f8h,070h,078h,038h,038h,01ch,01ch,07ch,0fch,014h,000h	; b4b7  .p....px88..|...
	defb 088h,040h,020h,058h,0ddh,0ffh,07ch,07ch,01ch,006h,000h,082h,00eh,006h,011h,000h	; b4c7  .@ X..||........
	defb 086h,030h,038h,03ch,01eh,01eh,01ch,004h,038h,085h,03ch,01fh,01fh,00fh,007h,004h	; b4d7  .08<....8.<.....
	defb 000h,08ch,00eh,01ch,03ch,03eh,00eh,003h,00fh,01fh,0feh,0fch,0f8h,030h,00dh,000h	; b4e7  ....<>.......0..
	defb 083h,080h,0a0h,0f0h,00dh,000h,08fh,001h,005h,00fh,03fh,03fh,05fh,06eh,0eeh,0ceh	; b4f7  ..........??_n..
	defb 0eeh,06fh,037h,017h,06fh,09fh,014h,000h,09ah,03fh,07fh,0ffh,0feh,0d8h,0c8h,070h	; b507  .o7.o....?.....p
	defb 03bh,01fh,03fh,07fh,07ch,0fbh,0ffh,07eh,000h,0c0h,0e0h,0e0h,0c0h,004h,01ch,0fch	; b517  ;.?.|..~........
	defb 0f8h,0f0h,0c0h,006h,000h,086h,001h,002h,04dh,06dh,01eh,008h,00ah,000h,003h,007h	; b527  ........Mm......
	defb 081h,087h,005h,000h,083h,040h,0c0h,0c0h,004h,000h,08ch,007h,00fh,00fh,066h,0e0h	; b537  .....@........f.
	defb 0f0h,070h,038h,018h,00ch,007h,001h,003h,000h,096h,003h,0f8h,0fch,0feh,0feh,03eh	; b547  .p8............>
	defb 016h,004h,018h,000h,018h,0feh,0e7h,01fh,07fh,0feh,0f0h,028h,068h,070h,068h,030h	; b557  ...........(hph0
	defb 00fh,000h,098h,020h,058h,0ddh,0ffh,07ch,07ch,01ch,000h,000h,060h,070h,070h,031h	; b567  ... X..||...`pp1
	defb 039h,05fh,06eh,0eeh,0ceh,0eeh,06fh,037h,017h,06fh,09fh,014h,000h,000h	; b577  9_n...o7.o....

; ======================================================================
; CODIGO 0xb585..0xb80a  (645 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; PEDIR UNA PIEZA
; ----------------------------------------------------------------------
pide_pieza_si_toca:
	di			;b585
	push hl			;b586
	ld hl,0e002h		;b587   ; el bit 6 de (0xE002) apaga el sonido
	bit 6,(hl)		;b58a
	jr z,suelta_las_interrupciones		;b58c
	jr pide_pieza_con_registros		;b58e
pide_pieza:
	di			;b590   ; el motor se toca con las interrupciones cerradas: si le entra otra peticion a mitad, se lleva las voces por delante
	push hl			;b591
pide_pieza_con_registros:
	push de			;b592   ; los registros, que la pieza los usa
	push bc			;b593
	push af			;b594
	call arranca_la_pieza		;b595   ; se arranca
	pop af			;b598
	pop bc			;b599
	pop de			;b59a
suelta_las_interrupciones:
	pop hl			;b59b
	ei			;b59c
	ret			;b59d
arranca_la_pieza:
	ld c,a			;b59e   ; c guarda el numero entero, con sus banderas de arriba
	and 03fh		;b59f   ; y a se queda con los seis bits del numero
	ld b,002h		;b5a1   ; dos voces por defecto
	ld hl,0e012h		;b5a3   ; la primera voz
	cp 016h		;b5a6   ; por debajo de 0x16
	jr c,L_B5B1		;b5a8
	cp 018h		;b5aa   ; de 0x16 a 0x17
	jr c,L_B5C2		;b5ac
	inc b			;b5ae   ; y de 0x18 arriba, tres voces
	jr L_B5C2		;b5af
L_B5B1:
	dec b			;b5b1   ; una voz sola
	cp 00fh		;b5b2
	jr nc,L_B5BB		;b5b4
	ld hl,0e02eh		;b5b6   ; los efectos por debajo de 0x0F van a la tercera voz
	jr L_B5C2		;b5b9
L_B5BB:
	cp 012h		;b5bb
	jr c,L_B5C2		;b5bd
	ld hl,0e020h		;b5bf   ; y de 0x12 a 0x15, a la segunda
L_B5C2:
	ld a,(hl)			;b5c2   ; lo que esta sonando en esa voz
	and 03fh		;b5c3
	ld e,a			;b5c5
	ld a,c			;b5c6
	and 03fh		;b5c7
	cp e			;b5c9   ; y si lo nuevo tiene menos peso que lo de ahora, no suena: un efecto flojo no pisa a la musica
	ret c			;b5ca
	add a,a			;b5cb   ; dos bytes por voz
	ld de,0b814h		;b5cc   ; la bolsa de punteros
	call suma_a_a_de		;b5cf
	dec hl			;b5d2   ; dos bytes atras esta el contador
	dec hl			;b5d3
arranca_una_voz:
	ld (hl),001h		;b5d4   ; el contador de duracion, a uno: la voz suena en el cuadro siguiente
	inc hl			;b5d6
	ld (hl),001h		;b5d7   ; y el de repeticion
	inc hl			;b5d9
	ld (hl),c			;b5da   ; el numero de pieza, que es tambien su peso
	inc hl			;b5db
	ld a,(de)			;b5dc   ; el puntero al guion
	ld (hl),a			;b5dd
	inc hl			;b5de
	inc de			;b5df
	ld a,(de)			;b5e0
	ld (hl),a			;b5e1
	ld a,005h		;b5e2   ; cinco bytes mas alla
	call suma_a_a_hl		;b5e4
	xor a			;b5e7
	ld (hl),a			;b5e8   ; el volumen a cero
	ld a,005h		;b5e9
	call suma_a_a_hl		;b5eb
	inc de			;b5ee   ; las voces van seguidas en la bolsa
	djnz arranca_una_voz		;b5ef   ; dos o tres
	ret			;b5f1

; ----------------------------------------------------------------------
; EL 0xFE DEL GUION: repetir un trozo
; ----------------------------------------------------------------------
repite_un_trozo:
	inc hl			;b5f2
	ld a,(ix+009h)		;b5f3   ; cuantas vueltas lleva
	inc a			;b5f6
	cp (hl)			;b5f7   ; contra las que pide el guion
	jr z,L_B60D		;b5f8   ; si ya estan hechas, se sigue de largo
	jp m,L_B5FE		;b5fa   ; el 0x00 quiere decir para siempre
	dec a			;b5fd
L_B5FE:
	ld (ix+009h),a		;b5fe
	inc hl			;b601   ; y si no, se vuelve a la direccion que trae el guion
	ld a,(hl)			;b602
	ld (ix+003h),a		;b603
	inc hl			;b606
	ld a,(hl)			;b607
	ld (ix+004h),a		;b608
	jr L_B616		;b60b
L_B60D:
	inc hl			;b60d   ; dos bytes de la orden
	inc hl			;b60e
	xor a			;b60f
	ld (ix+009h),a		;b610   ; la cuenta se reinicia
	call avanza_el_guion		;b613
L_B616:
	inc (ix+000h)		;b616
	jr mira_si_hay_pieza_nueva		;b619

; ----------------------------------------------------------------------
; EL MEZCLADOR. OJO: las tres rotaciones dan 0x08, 0x10 y 0x20, o sea
; los bits del RUIDO, no los del tono. La copia del registro 7 (0xE048)
; arranca a cero con el borrado de 0x4098 y esta es la UNICA rutina del
; cartucho que escribe el registro 7, asi que los tonos de las voces A
; y C quedan abiertos de principio a fin: para callar una voz se le baja
; el volumen, no se cierra aqui.
; Y el sentido de D es el contrario del que parece: el `dec d` manda al
; `or e` con D=1, y el registro 7 del PSG va al reves, asi que con D=1
; el bit se PONE y el ruido se APAGA.
; La voz B es la excepcion: 0xB630 le cierra el tono salvo cuando su
; ruido esta cerrado, o sea que suena a ruido O a tono, nunca a los dos.
; ----------------------------------------------------------------------
enciende_o_apaga_el_ruido:
	ld a,(0e048h)		;b61b   ; la copia del registro 7
	ld e,a			;b61e
	ld a,c			;b61f   ; c es 1, 3 o 5: la voz
	cp 001h		;b620
	jr z,L_B625		;b622
	dec a			;b624
L_B625:
	rlca			;b625   ; tres rotaciones dejan 0x08, 0x10 o 0x20, los bits de RUIDO
	rlca			;b626
	rlca			;b627
	dec d			;b628   ; con D a uno...
	jr z,L_B62F		;b629
	cpl			;b62b   ; el bit se quita y el ruido suena
	and e			;b62c
	jr L_B630		;b62d
L_B62F:
	or e			;b62f   ; ...el bit se pone y el ruido calla
L_B630:
	set 1,a		;b630   ; el bit 1 es el TONO de la voz B, que se cierra siempre
	bit 4,a		;b632   ; salvo cuando su ruido -el bit 4- esta cerrado, y entonces se abre
	jr z,escribe_el_mezclador		;b634
	res 1,a		;b636
escribe_el_mezclador:
	ld (0e048h),a		;b638
	ld e,a			;b63b
	ld a,007h		;b63c   ; el registro 7 del PSG es el mezclador
	jp 00093h		;b63e   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; EL SONIDO DE CADA CUADRO
; ----------------------------------------------------------------------
suena_el_cuadro:
	ld a,(0e048h)		;b641   ; primero el mezclador, tal como quedo
	call escribe_el_mezclador		;b644
	ld c,001h		;b647   ; la voz A, que en el PSG es el registro 1
	ld ix,0e010h		;b649   ; y su bloque de catorce bytes
	exx			;b64d
	ld b,003h		;b64e   ; tres voces
	ld de,0000eh		;b650   ; catorce bytes de una a otra
L_B653:
	exx			;b653
	ld a,(ix+002h)		;b654   ; si la voz esta callada
	or a			;b657
	jr nz,L_B65F		;b658
	call calla_la_voz		;b65a   ; se apaga
	jr L_B662		;b65d
L_B65F:
	call apaga_la_voz_del_mezclador		;b65f   ; y si no, suena
L_B662:
	inc c			;b662   ; c va 1, 3, 5: son los registros de periodo de las tres voces
	inc c			;b663
	exx			;b664
	add ix,de		;b665   ; y ix salta al siguiente bloque
	djnz L_B653		;b667
	ret			;b669
voz_callada:
	ld a,(ix+002h)		;b66a   ; la pieza de esta voz
	cp 08eh		;b66d   ; con la 0x8E el guion sigue
	jr z,sigue_el_guion		;b66f
	xor a			;b671   ; y si no, volumen a cero
	ld h,a			;b672
	jp escribe_el_volumen		;b673
apaga_la_voz_del_mezclador:
	bit 6,a		;b676
	ld d,001h		;b678   ; la voz que toca
	call z,enciende_o_apaga_el_ruido		;b67a
mira_si_hay_pieza_nueva:
	ld a,(0e07fh)		;b67d   ; la pieza pedida
	or a			;b680
	jr nz,voz_callada		;b681   ; y si la hay, se atiende

; ----------------------------------------------------------------------
; LEER EL GUION DE UNA VOZ
; ----------------------------------------------------------------------
sigue_el_guion:
	ld a,(ix+002h)		;b683
	or a			;b686
	jp m,envolvente		;b687
	dec (ix+000h)		;b68a   ; la nota de ahora todavia dura
	ret nz			;b68d
L_B68E:
	ld l,(ix+003h)		;b68e   ; el puntero del guion
	ld h,(ix+004h)		;b691
	ld de,0bb7fh		;b694   ; y aqui una comparacion contra una direccion concreta de la musica
	sbc hl,de		;b697
	ld a,096h		;b699   ; para meter la pieza 0x96 en las dos primeras voces justo en ese punto
	ld l,(ix+003h)		;b69b
	ld h,(ix+004h)		;b69e
	jr nz,L_B6A9		;b6a1
	ld (0e012h),a		;b6a3
	ld (0e020h),a		;b6a6
L_B6A9:
	ld a,(hl)			;b6a9   ; la orden
	cp 0feh		;b6aa   ; 0xFE, repetir
	jp z,repite_un_trozo		;b6ac
	jr nc,calla_la_voz		;b6af   ; y de 0xFF arriba, callar
	bit 7,(ix+002h)		;b6b1   ; el bit 7 del numero de pieza manda a las ordenes largas
	jp nz,orden_larga		;b6b5
	and 0f0h		;b6b8   ; 0x2n fija la duracion de las notas que vienen
	cp 020h		;b6ba
	ld a,(hl)			;b6bc
	jr nz,L_B6C6		;b6bd
	and 00fh		;b6bf
	ld (ix+001h),a		;b6c1
	inc hl			;b6c4
	ld a,(hl)			;b6c5
L_B6C6:
	ld b,a			;b6c6
	and 0f0h		;b6c7   ; 0x1n toca el ruido
	cp 010h		;b6c9
	jr nz,mira_si_es_la_tercera		;b6cb
	ld a,(hl)			;b6cd
	and 01fh		;b6ce   ; cinco bits de periodo
	ld e,a			;b6d0
	ld a,c			;b6d1
	cp 003h		;b6d2   ; y solo en la tercera voz
	jr nz,L_B6E3		;b6d4
	inc hl			;b6d6
	bit 4,(hl)		;b6d7
	ld b,(hl)			;b6d9
	jr nz,L_B6E0		;b6da
	ld a,e			;b6dc
	sub 010h		;b6dd
	ld e,a			;b6df
L_B6E0:
	res 4,b		;b6e0
	dec hl			;b6e2
L_B6E3:
	ld a,006h		;b6e3   ; el registro 6 es el periodo del ruido
	call 00093h		;b6e5   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;b6e8
	call enciende_o_apaga_el_ruido		;b6ea
	inc hl			;b6ed
mira_si_es_la_tercera:
	bit 6,(ix+002h)		;b6ee   ; el bit 6 de la voz
	jr z,toca_la_nota		;b6f2
	ld a,c			;b6f4   ; y solo en la tercera
	cp 003h		;b6f5
	ld a,(hl)			;b6f7
	jr nz,toca_la_nota		;b6f8
	call avanza_el_guion		;b6fa   ; se salta un byte del guion
	ld a,b			;b6fd
	jr L_B713		;b6fe

; ----------------------------------------------------------------------
; LA NOTA
; ----------------------------------------------------------------------
toca_la_nota:
	and 0f0h		;b700   ; el nibble alto es el semitono
	ld b,a			;b702
	xor (hl)			;b703
	ld d,a			;b704
	inc hl			;b705
	ld e,(hl)			;b706   ; y detras va el segundo byte de la nota
	call avanza_el_guion		;b707
	ex de,hl			;b70a
	call L_B7F0		;b70b   ; se escribe el periodo en el PSG
	ld a,b			;b70e
	rrca			;b70f   ; el nibble bajo, bajado
	rrca			;b710
	rrca			;b711
	rrca			;b712
L_B713:
	ld h,a			;b713
	ld e,(ix+001h)		;b714   ; la duracion que fijo el 0x2n
	ld (ix+000h),e		;b717
	ld a,(ix+00ch)		;b71a   ; mas el ataque
	add a,e			;b71d
	ld (ix+008h),a		;b71e
	jr escribe_el_volumen		;b721

; ----------------------------------------------------------------------
; CALLAR LA VOZ
; ----------------------------------------------------------------------
calla_la_voz:
	ld a,(ix+002h)		;b723
	ld (0e049h),a		;b726   ; lo ultimo que sono, apuntado
	ld d,001h		;b729   ; con D=1: se cierra el ruido de esa voz
	call enciende_o_apaga_el_ruido		;b72b
	xor a			;b72e
	ld (ix+002h),a		;b72f   ; y la voz queda libre
	ld (ix+00bh),a		;b732
	ld h,a			;b735
	call escribe_el_volumen		;b736   ; volumen cero
	ld a,c			;b739   ; solo la tercera voz
	cp 005h		;b73a
	ret nz			;b73c
	ld a,(0e049h)		;b73d
	cp 098h		;b740   ; y solo si lo que acaba de callarse era la pieza 0x98
	ret nz			;b742
	jp pieza_del_nivel		;b743   ; avisa al juego: asi el juego sabe cuando la musica ha terminado

; ----------------------------------------------------------------------
; LA ENVOLVENTE
; ----------------------------------------------------------------------
envolvente:
	dec (ix+000h)		;b746   ; la nota se acaba
	jp z,L_B68E		;b749
	dec (ix+008h)		;b74c   ; el volumen baja
	ld a,(ix+008h)		;b74f
	cp (ix+000h)		;b752   ; hasta el sostenido
	jr nz,L_B760		;b755
	ld e,a			;b757
	ld a,(ix+00dh)		;b758   ; y de ahi, la caida
	cp e			;b75b
	ld a,e			;b75c
	jr nc,L_B763		;b75d
	ret			;b75f
L_B760:
	dec (ix+008h)		;b760
L_B763:
	ld a,(ix+007h)		;b763   ; el volumen de ahora
	dec a			;b766   ; uno menos cada vez
	ret m			;b767   ; y por debajo de cero, nada
	ld (ix+007h),a		;b768
	ld h,a			;b76b
escribe_el_volumen:
	ld a,c			;b76c   ; c es 1, 3 o 5
	rrca			;b76d   ; una rotacion y sumar 0x88 los convierte en los registros 8, 9 y 10, que son los tres volumenes: un truco para no llevar tabla
	add a,088h		;b76e
	ld e,h			;b770
	jp 00093h		;b771   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; LAS ORDENES LARGAS
; ----------------------------------------------------------------------
orden_larga:
	ld a,(hl)			;b774
	and 0f0h		;b775   ; 0xDn fija el paso del volumen
	cp 0d0h		;b777
	ld a,(hl)			;b779
	jr nz,L_B783		;b77a
	and 00fh		;b77c
	ld (ix+00ah),a		;b77e
	inc hl			;b781
	ld a,(hl)			;b782
L_B783:
	cp 0f0h		;b783   ; 0xFn, el ataque y el sostenido
	jr c,L_B79F		;b785
	and 00fh		;b787
	ld (ix+006h),a		;b789
	inc hl			;b78c
	ld a,(hl)			;b78d
	and 00fh		;b78e   ; el sostenido, en el nibble bajo
	ld (ix+00dh),a		;b790
	xor (hl)			;b793   ; y el ataque en el alto
	rrca			;b794
	rrca			;b795
	rrca			;b796
	rrca			;b797
	and 00fh		;b798
	ld (ix+00ch),a		;b79a
	inc hl			;b79d
	ld a,(hl)			;b79e
L_B79F:
	cp 0e0h		;b79f   ; 0xEn
	jr c,L_B7B4		;b7a1
	and 00fh		;b7a3
	bit 3,a		;b7a5   ; con el bit 3 puesto es una cosa
	jr z,L_B7AF		;b7a7
	ld (ix+00bh),a		;b7a9
	inc hl			;b7ac
	jr orden_larga		;b7ad
L_B7AF:
	ld (ix+005h),a		;b7af   ; y sin el, la octava
	inc hl			;b7b2
	ld a,(hl)			;b7b3
L_B7B4:
	and 00fh		;b7b4   ; y lo que queda es cuantas veces se suma el paso del volumen
	ld b,a			;b7b6
	ld a,(ix+00ah)		;b7b7
	jr z,L_B7C1		;b7ba
L_B7BC:
	add a,(ix+00ah)		;b7bc   ; de ahi sale el volumen de arranque
	djnz L_B7BC		;b7bf
L_B7C1:
	ld (ix+001h),a		;b7c1
	ld a,(hl)			;b7c4   ; y detras, ya, la nota
	call avanza_el_guion		;b7c5
	and 0f0h		;b7c8
	rrca			;b7ca
	rrca			;b7cb
	rrca			;b7cc
	rrca			;b7cd
	ld b,a			;b7ce
	sub 00ch		;b7cf   ; el semitono 12 -o sea el 0x0C- no cambia la nota: es un silencio o un ligado
	jr z,L_B7D6		;b7d1
	ld a,(ix+006h)		;b7d3
L_B7D6:
	ld (ix+007h),a		;b7d6
	call L_B713		;b7d9
	ld a,b			;b7dc

; ----------------------------------------------------------------------
; PONER EL PERIODO DE UNA NOTA
; ----------------------------------------------------------------------
pon_el_periodo:
	ld hl,0b80ah		;b7dd   ; la octava cromatica de doce valores
	call suma_a_a_hl		;b7e0
	ld l,(hl)			;b7e3   ; el periodo de esa nota, en la octava mas alta
	ld h,000h		;b7e4
	ld a,(ix+005h)		;b7e6   ; y la octava
	or a			;b7e9
	jr z,L_B7F0		;b7ea
	ld b,a			;b7ec
L_B7ED:
	add hl,hl			;b7ed   ; doblar el periodo es bajar una octava exacta
	djnz L_B7ED		;b7ee
L_B7F0:
	ld a,(ix+00bh)		;b7f0   ; con esto se le suma uno, para desafinar a proposito
	or a			;b7f3
	jr z,L_B7F7		;b7f4
	inc hl			;b7f6
L_B7F7:
	ld a,c			;b7f7   ; c es el registro alto del periodo
	ld e,h			;b7f8
	call 00093h		;b7f9   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;b7fc
	dec a			;b7fd   ; y c-1 el bajo
	ld e,l			;b7fe
	jp 00093h		;b7ff   ; BIOS WRTPSG - Writes data to PSG-register
avanza_el_guion:
	inc hl			;b802
	ld (ix+003h),l		;b803
	ld (ix+004h),h		;b806
	ret			;b809

; ----------------------------------------------------------------------
; DATOS tabla_de_periodos: DOCE bytes, una octava cromatica entera: 107 101 95
;   90 85 80 76 71 67 64 60 57. 0xB7DD la indexa con el semitono y 0xB7ED baja
;   de octava doblando el periodo con `add hl,hl`
;   0xb80a..0xb816  (12 bytes)
DATA_tabla_de_periodos:
	defb 06bh,065h,05fh,05ah,055h,050h,04ch,047h,043h,040h,03ch,039h	; b80a  ke_ZUPLGC@<9

; ----------------------------------------------------------------------
; DATOS punteros_de_voz: 47 punteros; cada pieza gasta dos o tres seguidos,
;   uno por voz del PSG. La cuenta de 0x5BCB es 0xB814 + n*2, o sea que la
;   pieza 1 es la PRIMERA entrada: no hay pieza 0
;   0xb816..0xb874  (94 bytes)
DATA_punteros_de_voz:
	defw 0b874h,0b8b0h,0b883h,0b88bh,0b8a1h,0b8dbh,0b906h,0b928h	; b816
	defw 0b8f9h,0b916h,0b93ah,0b950h,0b963h,0b96dh,0ba73h,0ba81h	; b826
	defw 0b97ah,0ba8dh,0bac9h,0bad6h,0bae6h,0bb7fh,0bc82h,0baf8h	; b836
	defw 0bb13h,0bb1dh,0bb39h,0bc65h,0bd58h,0bdbdh,0bdc0h,0be03h	; b846
	defw 0be64h,0be7ah,0be9bh,0beb4h,0beeah,0bf22h,0bf6ch,0bf8dh	; b856
	defw 0bfadh,0bfc8h,0bfc9h,0bfdeh,0bfeeh,0bfeeh,0bfeeh	; b866

; ----------------------------------------------------------------------
; DATOS guiones_de_musica: los guiones que el motor de 0xB585 va leyendo, uno
;   por voz
;   0xb874..0xbfee  (1914 bytes)
DATA_guiones_de_musica:
	defb 0d1h,0fch,00fh,0e2h,040h,070h,0e1h,000h,040h,070h,040h,000h,040h,070h,0ffh,021h	; b874  ....@p..@p@.@p.!
	defb 0e1h,0a0h,0f2h,0c0h,0f2h,030h,0ffh,021h,0e1h,0cfh,022h,000h,000h,021h,0e0h,040h	; b884  .....0.!.."..!.@
	defb 0d0h,048h,0c0h,050h,0b0h,058h,0a0h,060h,090h,068h,080h,070h,0ffh,0d1h,0fch,000h	; b894  .H.P.X.`.h.p....
	defb 0e4h,090h,0e3h,040h,0e2h,000h,040h,070h,0e0h,000h,040h,0ffh,024h,0c5h,080h,0a5h	; b8a4  ...@..@p..@.$...
	defb 000h,0c5h,070h,0a4h,0f0h,0feh,003h,0b0h,0b8h,022h,0c5h,010h,0a4h,010h,0c4h,0f0h	; b8b4  ..p......"......
	defb 0a3h,0f0h,0c4h,0d0h,0a3h,0d0h,0c4h,0c0h,0a3h,0c0h,0c4h,0b0h,0a3h,0b0h,0c4h,0a0h	; b8c4  ................
	defb 0a3h,0a0h,0c4h,090h,0a3h,090h,0ffh,021h,0d0h,080h,0c0h,082h,0c0h,07fh,0b0h,081h	; b8d4  .......!........
	defb 0b0h,07eh,0a0h,080h,0c0h,07eh,0b0h,081h,0feh,005h,0e8h,0b8h,0d0h,081h,0b0h,084h	; b8e4  .~...~..........
	defb 0feh,008h,0f0h,0b8h,0ffh,0d3h,0fdh,00fh,0e1h,000h,040h,070h,020h,050h,090h,0e0h	; b8f4  ..........@p P..
	defb 001h,0ffh,021h,0e0h,01ch,0d0h,01ch,0c0h,01ch,0b0h,01ch,0a0h,01ch,090h,01ch,080h	; b904  ..!.............
	defb 01ch,0ffh,023h,0b0h,038h,0c0h,038h,0d0h,048h,0c0h,040h,0b0h,040h,0a0h,040h,090h	; b914  ..#.8.8.H.@.@.@.
	defb 040h,080h,040h,0ffh,023h,0b0h,040h,0c0h,040h,0d0h,068h,0c0h,058h,0b0h,058h,0a0h	; b924  @.@.#.@.@.h.X.X.
	defb 058h,090h,058h,080h,058h,0ffh,023h,0b0h,020h,0c0h,021h,0b0h,020h,0b0h,021h,0a0h	; b934  X.X.X.#. .!. .!.
	defb 020h,0a0h,021h,090h,020h,080h,021h,070h,020h,060h,020h,0ffh,021h,0d2h,000h,0e2h	; b944   .!. .!p ` .!...
	defb 080h,0e3h,000h,0e3h,080h,022h,0e4h,000h,0e5h,000h,0e6h,000h,0e7h,000h,0ffh,022h	; b954  ....."........."
	defb 0b0h,070h,0b0h,058h,0feh,010h,063h,0b9h,0ffh,0d1h,0fdh,088h,0e1h,005h,075h,045h	; b964  .p.X..c.......uE
	defb 075h,0fdh,033h,0e0h,009h,0ffh,0d7h,0fch,025h,0e3h,020h,020h,0e2h,020h,0e3h,020h	; b974  u.3.....%.  . . 
	defb 070h,090h,0e2h,000h,0e3h,050h,0c3h,0d5h,0fbh,000h,0e1h,020h,030h,0f8h,000h,020h	; b984  p....P..... 0.. 
	defb 030h,0f6h,000h,020h,030h,0f4h,000h,020h,0c1h,0feh,002h,08ah,0b9h,0c3h,0d5h,0fbh	; b994  0.. 0.. ........
	defb 000h,0e1h,020h,030h,0f8h,000h,020h,030h,0f6h,000h,020h,030h,0f4h,000h,020h,0d7h	; b9a4  .. 0.. 0.. 0.. .
	defb 0fch,025h,0e3h,020h,020h,0e2h,020h,0e3h,020h,070h,090h,0e2h,000h,050h,0c3h,0d5h	; b9b4  .%.  . . p...P..
	defb 0fbh,000h,0e1h,020h,030h,0f8h,000h,020h,030h,0f6h,000h,020h,030h,0f4h,000h,020h	; b9c4  ... 0.. 0.. 0.. 
	defb 0c1h,0feh,002h,0c2h,0b9h,0c3h,0d5h,0fbh,000h,0e1h,020h,030h,0f8h,000h,020h,030h	; b9d4  .......... 0.. 0
	defb 0f6h,000h,020h,030h,0f4h,000h,020h,0d7h,0fch,025h,0e3h,070h,070h,0e2h,070h,0e3h	; b9e4  .. 0.. ..%.pp.p.
	defb 070h,0e2h,000h,020h,050h,0e3h,0a0h,0c3h,0d5h,0fbh,000h,0e1h,070h,080h,0f8h,000h	; b9f4  p.. P.......p...
	defb 070h,080h,0f6h,000h,070h,080h,0f4h,000h,070h,0c1h,0feh,002h,0fbh,0b9h,0c3h,0d5h	; ba04  p...p...p.......
	defb 0fbh,000h,0e1h,070h,080h,0f8h,000h,070h,080h,0f6h,000h,070h,080h,0f4h,000h,070h	; ba14  ...p...p...p...p
	defb 0d7h,0fch,025h,0e3h,070h,070h,0e2h,070h,0e3h,070h,0e2h,000h,020h,050h,0a0h,0c3h	; ba24  ..%.pp.p.p.. P..
	defb 0d5h,0fbh,000h,0e1h,070h,080h,0f8h,000h,070h,080h,0f6h,000h,070h,080h,0f4h,000h	; ba34  ....p...p...p...
	defb 070h,0c1h,0c3h,0d5h,0fbh,000h,0e1h,070h,080h,0f8h,000h,070h,080h,0f6h,000h,070h	; ba44  p......p...p...p
	defb 080h,0f4h,000h,070h,0d7h,0fch,030h,0e2h,0a0h,0e3h,0a1h,0e2h,090h,0e3h,091h,0e2h	; ba54  ...p..0.........
	defb 080h,0e3h,081h,0e2h,070h,0e3h,071h,060h,050h,040h,030h,0feh,0ffh,07ah,0b9h,021h	; ba64  ....p.q`P@0..z.!
	defb 0c0h,017h,0c0h,030h,02fh,000h,000h,000h,000h,0feh,0ffh,073h,0bah,021h,0c0h,017h	; ba74  ...0/......s.!..
	defb 0c0h,030h,02fh,000h,000h,0feh,0ffh,081h,0bah,021h,0f5h,000h,000h,000h,0f3h,080h	; ba84  .0/......!......
	defb 000h,000h,0feh,002h,08dh,0bah,0e5h,000h,000h,000h,0e3h,080h,000h,000h,0d5h,000h	; ba94  ................
	defb 000h,000h,0d3h,080h,000h,000h,0c5h,000h,000h,000h,0c3h,080h,000h,000h,0b5h,000h	; baa4  ................
	defb 000h,000h,0b3h,080h,000h,000h,0a5h,000h,000h,000h,0a3h,080h,000h,000h,095h,000h	; bab4  ................
	defb 000h,000h,093h,080h,0ffh,026h,014h,009h,00ah,00bh,00ah,009h,008h,0feh,003h,0cfh	; bac4  .....&..........
	defb 0bah,0ffh,022h,01ch,01bh,00ah,00bh,00ch,025h,019h,01ah,015h,01bh,0feh,006h,0ddh	; bad4  ..".....%.......
	defb 0bah,0ffh,02eh,01ch,017h,008h,009h,00ah,00bh,00ch,009h,00ah,00bh,00ah,02fh,009h	; bae4  ............../.
	defb 007h,006h,005h,0ffh,0d5h,0fch,010h,0e1h,000h,020h,040h,050h,040h,050h,070h,0fch	; baf4  ......... @P@Pp.
	defb 000h,090h,0fbh,000h,090h,0fah,000h,090h,0f9h,000h,090h,0f8h,000h,090h,0ffh,0e8h	; bb04  ................
	defb 0d2h,0fch,010h,0e1h,0c0h,0feh,0ffh,0f8h,0bah,0d5h,0fch,010h,0e3h,050h,090h,0e2h	; bb14  .............P..
	defb 000h,050h,000h,040h,070h,0fch,000h,050h,0fbh,000h,050h,0fah,000h,050h,0f9h,000h	; bb24  .P.@p..P..P..P..
	defb 050h,0f8h,000h,050h,0ffh,0d1h,0fbh,0a1h,0e2h,0c0h,0dbh,020h,0c0h,0e1h,020h,0e2h	; bb34  P..P....... .. .
	defb 020h,070h,090h,0e1h,000h,020h,0c0h,0e2h,020h,0e1h,020h,0e2h,020h,070h,090h,0e1h	; bb44   p... .. . . p..
	defb 000h,020h,0e2h,020h,0c0h,0e1h,020h,0e2h,020h,070h,090h,0e1h,000h,020h,0c0h,0fbh	; bb54  . . .. . p... ..
	defb 022h,0e2h,020h,0e1h,020h,0e2h,020h,070h,090h,0e1h,070h,050h,0dah,0f9h,000h,092h	; bb64  ". . . p..pP....
	defb 0d5h,0b0h,0e0h,010h,0d9h,02eh,0dbh,0e1h,062h,042h,069h,0dbh,0fch,052h,0e3h,050h	; bb74  ........bBi..R.P
	defb 050h,0e2h,000h,0e3h,050h,0feh,003h,07fh,0bbh,050h,070h,080h,090h,020h,020h,090h	; bb84  P...P....Pp..  .
	defb 020h,0feh,003h,091h,0bbh,020h,000h,020h,000h,050h,050h,090h,050h,050h,050h,0e2h	; bb94   .... . .PP.PPP.
	defb 000h,0e3h,050h,0feh,002h,09dh,0bbh,020h,020h,090h,020h,020h,020h,090h,020h,000h	; bba4  ..P....  .   . .
	defb 000h,020h,020h,040h,040h,050h,050h,0e4h,0a0h,0a0h,0e3h,050h,0e4h,0a0h,0feh,002h	; bbb4  .  @@PP....P....
	defb 0bbh,0bbh,0e3h,000h,000h,070h,000h,000h,000h,020h,040h,050h,050h,090h,050h,050h	; bbc4  .....p... @PP.PP
	defb 050h,090h,050h,070h,0e4h,071h,070h,090h,090h,0a0h,0e3h,000h,0e4h,0a0h,0a0h,0e3h	; bbd4  P.Pp.qp.........
	defb 050h,0e4h,0a0h,0a0h,0a0h,0e3h,050h,0e4h,0a0h,0e3h,000h,000h,000h,000h,000h,000h	; bbe4  P.....P.........
	defb 020h,040h,0fbh,033h,0e3h,050h,0e2h,050h,0feh,008h,0f8h,0bbh,0e3h,020h,0e2h,020h	; bbf4   @.3.P.P..... . 
	defb 0feh,004h,000h,0bch,0e4h,0a0h,0e3h,0a0h,0feh,004h,008h,0bch,0e3h,000h,0e2h,000h	; bc04  ................
	defb 0feh,008h,010h,0bch,0d6h,0fbh,026h,0e4h,092h,0d5h,090h,0dbh,0e3h,040h,0dah,091h	; bc14  ......&......@..
	defb 0dbh,0e4h,090h,0e3h,040h,090h,0d6h,0e4h,0a2h,0d5h,0a0h,0dbh,0e3h,020h,050h,000h	; bc24  ....@........ P.
	defb 000h,020h,040h,0dbh,0fbh,043h,0e3h,021h,0e2h,020h,0e3h,020h,021h,0e2h,020h,0e3h	; bc34  . @..C.!. . !. .
	defb 021h,020h,0e2h,020h,0e3h,020h,0e4h,091h,0e3h,001h,021h,0e2h,020h,0e3h,020h,021h	; bc44  ! . . ....!. . !
	defb 0e2h,020h,0e3h,021h,020h,0e2h,020h,0e3h,020h,000h,000h,020h,040h,0feh,0ffh,07fh	; bc54  . .! . . .. @...
	defb 0bbh,0dbh,0fch,0a7h,0e3h,020h,0feh,01eh,065h,0bch,050h,000h,0fbh,051h,0e3h,021h	; bc64  ..... ..e.P..Q.!
	defb 0c0h,020h,021h,0c0h,020h,0c3h,0e4h,091h,0e3h,001h,0feh,002h,070h,0bch,0dbh,0fbh	; bc74  . !. .......p...
	defb 033h,0e1h,0c1h,091h,050h,091h,050h,0a1h,091h,071h,050h,0d5h,070h,0dch,095h,0dbh	; bc84  3...P.P..qP.p...
	defb 000h,020h,0c0h,0f9h,024h,0e2h,020h,020h,020h,040h,050h,070h,050h,0c1h,0fbh,023h	; bc94  . ..$.   @PpP..#
	defb 0e1h,090h,090h,091h,091h,0a1h,091h,071h,051h,0c0h,050h,050h,050h,070h,091h,041h	; bca4  .......qQ.PPPp.A
	defb 040h,051h,071h,091h,0fbh,041h,0e0h,0c1h,001h,0e1h,0a1h,091h,071h,051h,040h,052h	; bcb4  @Qq..A......qQ@R
	defb 0c1h,091h,071h,051h,041h,021h,010h,022h,0e0h,0c1h,001h,0e1h,0a1h,091h,071h,050h	; bcc4  ..qQA!."......qP
	defb 091h,090h,070h,050h,0c1h,0d6h,092h,0d5h,090h,093h,0d6h,0f9h,041h,0e2h,092h,0d5h	; bcd4  ..pP........A...
	defb 090h,093h,0dbh,0fah,041h,0e1h,091h,091h,091h,0c1h,0d6h,0fbh,041h,092h,0d5h,090h	; bce4  ....A.......A...
	defb 0dbh,090h,070h,051h,0c1h,0a1h,0a2h,0d6h,0e0h,000h,0d7h,024h,0d6h,001h,0dbh,007h	; bcf4  ..pQ.......$....
	defb 0e1h,090h,0e0h,000h,000h,0d6h,003h,0dbh,001h,020h,0c0h,0e2h,050h,090h,0e1h,000h	; bd04  ......... ..P...
	defb 0d2h,0f9h,022h,0e0h,058h,047h,0d5h,021h,0dbh,001h,0d5h,000h,0d2h,028h,0dbh,0fbh	; bd14  ..".XG.!.....(..
	defb 0a1h,0e2h,020h,0c0h,0e1h,020h,0e2h,020h,070h,090h,0e1h,000h,020h,0c0h,0e2h,020h	; bd24  .. .. . p... .. 
	defb 0e1h,020h,0e2h,020h,070h,090h,0e1h,000h,020h,0e2h,020h,0c0h,0e1h,020h,0e2h,020h	; bd34  . . p... . .. . 
	defb 070h,090h,0e1h,000h,020h,0c0h,0e2h,020h,0e1h,020h,0e2h,020h,040h,050h,070h,050h	; bd44  p... .. . . @PpP
	defb 0feh,0ffh,082h,0bch,0dbh,0fbh,071h,0e1h,020h,0c0h,0e0h,020h,0e1h,020h,070h,090h	; bd54  ......q. .. . p.
	defb 0e0h,000h,020h,0c0h,0e1h,020h,0e0h,020h,0e1h,020h,070h,090h,0e0h,000h,020h,0e1h	; bd64  .. .. . . p... .
	defb 020h,0c0h,0e0h,020h,0e1h,020h,070h,090h,0e0h,000h,020h,0c0h,0e1h,020h,0e0h,020h	; bd74   .. . p... .. . 
	defb 0e1h,020h,070h,090h,0e0h,000h,020h,0e3h,020h,0c0h,0e2h,020h,0e3h,020h,070h,090h	; bd84  . p... . .. . p.
	defb 0e2h,000h,020h,0c0h,0e3h,020h,0dbh,0e2h,020h,0e3h,020h,070h,090h,0e2h,000h,020h	; bd94  .. .. .. . p... 
	defb 0e3h,020h,0c0h,0e2h,020h,0e3h,020h,070h,090h,0e2h,000h,020h,0c0h,0e3h,020h,0e2h	; bda4  . .. . p... .. .
	defb 020h,0e3h,020h,070h,090h,0e2h,000h,020h,0ffh,022h,000h,000h,023h,0c0h,0d0h,0c0h	; bdb4   . p... ."..#...
	defb 0b0h,0c0h,0c0h,0c0h,0a0h,0c0h,0d0h,0c0h,0b0h,0c0h,0c0h,0c0h,0a0h,022h,0b0h,0d0h	; bdc4  ............."..
	defb 0b0h,0b0h,0b0h,0c0h,0b0h,0a0h,0a0h,0d0h,0a0h,0b0h,0a0h,0c0h,0a0h,0a0h,090h,0d0h	; bdd4  ................
	defb 090h,0b0h,090h,0c0h,090h,0a0h,080h,0d0h,080h,0b0h,080h,0c0h,080h,0a0h,070h,0d0h	; bde4  ..............p.
	defb 070h,0b0h,070h,0c0h,070h,0a0h,060h,0d0h,060h,0b0h,060h,0c0h,060h,0a0h,0ffh,021h	; bdf4  p.p.p.`.`.`.`..!
	defb 0c5h,005h,0c4h,0dfh,0c4h,0b1h,0c4h,084h,0c4h,058h,0d4h,02dh,0d4h,003h,0d3h,0dah	; be04  .........X.-....
	defb 0d3h,0b2h,0e3h,08bh,0e3h,065h,0e3h,040h,0d3h,01ch,0d2h,0f9h,0d2h,0d7h,0c2h,0b6h	; be14  .....e.@........
	defb 0c2h,096h,0c2h,077h,0c2h,059h,0c2h,03ch,0b2h,010h,0b2h,005h,0b1h,0edh,0b1h,0cfh	; be24  ...w.Y.<........
	defb 0b1h,0b4h,022h,0b1h,09ah,0b1h,081h,0b1h,069h,0b1h,057h,0a1h,03ch,0a1h,027h,0a1h	; be34  ..".....i.W.<.'.
	defb 012h,0a0h,0fdh,0a0h,0ebh,090h,0d9h,090h,0c8h,090h,0b8h,090h,0a9h,090h,09bh,080h	; be44  ................
	defb 08eh,080h,082h,080h,077h,080h,06dh,080h,064h,080h,05ch,080h,055h,080h,04fh,0ffh	; be54  ....w.m.d.\.U.O.
	defb 0d7h,0fch,041h,0e1h,052h,042h,021h,000h,090h,0c0h,052h,001h,020h,0a0h,0c0h,071h	; be64  ..A.RB!...R. ..q
	defb 040h,050h,070h,051h,0c3h,0ffh,0d7h,0fch,037h,0e4h,051h,0e3h,050h,050h,0feh,002h	; be74  @PpQ....7.Q.PP..
	defb 07dh,0beh,0e4h,091h,0e3h,090h,090h,0feh,002h,086h,0beh,0e4h,0a1h,0a1h,0e3h,000h	; be84  }...............
	defb 0e1h,000h,020h,040h,0e3h,051h,0ffh,0d7h,0fch,041h,0e1h,002h,002h,0e2h,0a1h,090h	; be94  .. @.Q...A......
	defb 0e1h,000h,0c0h,002h,0e2h,091h,0a0h,0e1h,070h,0c0h,040h,000h,0c2h,0e2h,091h,0ffh	; bea4  ........p.@.....
	defb 0d4h,0fch,051h,0e1h,0c1h,061h,0c1h,061h,061h,0c7h,041h,0c1h,041h,041h,0c7h,071h	; beb4  ..Q..a.aa.A.AA.q
	defb 0c1h,071h,063h,043h,061h,021h,0c1h,0e2h,091h,0c7h,063h,091h,0e1h,021h,0c1h,0e2h	; bec4  .qcCa!....c..!..
	defb 091h,0c1h,061h,073h,0b1h,0e1h,023h,075h,065h,061h,041h,0e2h,091h,0c1h,0e1h,021h	; bed4  ..as..#ueaA....!
	defb 0cfh,0feh,002h,0b4h,0beh,0ffh,0d4h,0fch,051h,0e1h,0c1h,021h,0c1h,021h,021h,0c7h	; bee4  ........Q..!.!!.
	defb 0e2h,091h,0c1h,091h,091h,0c7h,041h,0c1h,041h,023h,013h,021h,0e2h,091h,0c1h,021h	; bef4  ......A.A#.!...!
	defb 0c7h,021h,0c1h,061h,091h,0c1h,061h,0c1h,021h,041h,0c1h,071h,0b1h,0c1h,021h,071h	; bf04  .!.a..a.!A.q..!q
	defb 0b1h,0e1h,025h,021h,011h,0e2h,043h,091h,0cfh,0feh,002h,0eah,0beh,0ffh,0d4h,0fch	; bf14  ..%!..C.........
	defb 038h,0e3h,0c1h,023h,021h,023h,0c3h,0e4h,091h,093h,091h,093h,0c3h,0e4h,071h,073h	; bf24  8..#!#........qs
	defb 071h,093h,093h,0e3h,021h,021h,0c1h,021h,021h,071h,061h,041h,021h,0c1h,0e2h,021h	; bf34  q...!!.!!qaA!..!
	defb 021h,0e3h,021h,0c1h,0e2h,021h,021h,0e4h,071h,0c1h,0e3h,071h,071h,0e4h,071h,0c1h	; bf44  !.!..!!.q..qq.q.
	defb 0e3h,071h,071h,021h,0c1h,021h,021h,0e4h,095h,0e3h,021h,0c1h,0e4h,091h,0c1h,091h	; bf54  .qq!.!!...!.....
	defb 0e3h,021h,0c5h,0feh,002h,022h,0bfh,0ffh,0d8h,0fbh,061h,0e1h,090h,050h,0e0h,000h	; bf64  .!..."....a..P..
	defb 0e1h,090h,0a0h,090h,070h,090h,0c0h,090h,091h,070h,050h,040h,050h,0c0h,050h,051h	; bf74  ....p....pP@P.PQ
	defb 020h,000h,0e2h,0a0h,0d8h,0fbh,024h,095h,0ffh,0d8h,0fbh,024h,0e3h,051h,0e2h,051h	; bf84   .....$....$.Q.Q
	defb 0e3h,041h,0e2h,040h,0e3h,020h,0c0h,020h,021h,001h,000h,0e4h,0a0h,0c0h,0a0h,0a1h	; bf94  .A.@. . !.......
	defb 0e3h,000h,001h,051h,001h,0e4h,090h,051h,0ffh,0d8h,0fbh,024h,0e2h,050h,020h,090h	; bfa4  ...Q...Q...$.P .
	defb 040h,070h,050h,040h,050h,0c0h,050h,051h,040h,020h,000h,020h,0c0h,020h,021h,0a0h	; bfb4  @pP@P.PQ@ . . !.
	defb 090h,070h,055h,0ffh,0e8h,0d8h,0fdh,028h,0e2h,090h,050h,020h,050h,020h,0e3h,0b0h	; bfc4  .pU....(..P P ..
	defb 0d2h,0fbh,028h,080h,060h,0feh,00ch,0d4h,0bfh,0ffh,0d6h,0fdh,026h,0e3h,023h,0e4h	; bfd4  ..(.`.......&.#.
	defb 0b3h,0d2h,0fbh,026h,050h,040h,0feh,00ch,0e5h,0bfh	; bfe4  ...&P@....

; ----------------------------------------------------------------------
; DATOS relleno_antes_de_la_marca: ocho bytes 0xFF; el ultimo byte util del
;   cartucho es 0xBFED
;   0xbfee..0xbff6  (8 bytes)
DATA_relleno_antes_de_la_marca:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfee  ........

; ----------------------------------------------------------------------
; DATOS marca_oculta_de_konami: グーニーズ del reves, su longitud (7), el 0x34 de
;   RC-734 y el 0xAA que cierra
;   0xbff6..0xc000  (10 bytes)
DATA_marca_oculta_de_konami:
	defb 0b7h,08ch,0bah,095h,0bah,0b7h,087h,007h,034h,0aah	; bff6  ........4.
