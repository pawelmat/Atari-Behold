; ******************************************************
; BEHOLD demo
; Kane / Suspect
; started 26/11/2018 - 27/01/2019 (an hour here and there...)
; Continued in 1/08/2020 - 21/08/2021
; Presented at Silly Venture 2021 - ranked #1
;
; This should run on a stock 65k Atari XL/XE.
; 2 POKEYs recommended but works on one
; ******************************************************

playsound = 1

;-------------
; between here and start of code some data can be copied after switching off the OS
lowmem = $400
roundlogo1 = lowmem
roundlogo2 = roundlogo1 + [.len roundlogo1Load]
longlogoCpy = roundlogo2 + [.len roundlogo2Load]
lowmemend = longlogo + [.len longlogoLoad]

	.print	"R1 logo:  start: ", roundlogo1, " end: ", roundlogo1 + [.len roundlogo1Load], " (len: ", [.len roundlogo1Load], ")"
	.print	"R2 logo:  start: ", roundlogo2, " end: ", roundlogo2 + [.len roundlogo2Load], " (len: ", [.len roundlogo2Load], ")"
	.print	"L logo:   start: ", longlogoCpy, " end: ", longlogoCpy + [.len longlogoLoad], " (len: ", [.len longlogoLoad], ")"
	.print	"-------"

stablen = roundlogo_h	// 50. This has to be tmax(roundlogo_h, roundlogo_w, longlogo_h), just for the sake of memory allocation
;-------------
; this is the area for dynamic data
data	= $5F00
sscaled	= data							; scaled sctetcher, max 64
stab 	= sscaled+[.len stretcher]		; 64
stabrows = stab + (stablen*2)			; 100 (50 addresses)
stabrowsend = stabrows + ((stablen)*(stablen+1)/2)	; (n)(n+1)/2 -> 50*51/2 = 1275
roundlogo1_inv = stabrowsend
roundlogo1_trans = roundlogo1_inv + (.len roundlogo1Load)
dataend1 = roundlogo1_trans + (.len roundlogo2Load)
;----
sinus1 = stabrowsend-$100		; size: $40. Since the long logo is lower than the round one, there is some space in the stretcher tab here
sinus2 = sinus1+$40				; size: $80
longlogo = stabrowsend
longlogoClear = longlogo + (.len longlogoLoad)
dataend2 = longlogoclear + (width_n+2)*height
;----
snakeConvTab = data
snakeSinX = data+256
snakeSinY = snakeSinX+256
snakeDataEnd = snakeSinY+256
;----
plasmConvTab = data		; 256
plasmSinMap = plasmConvTab + 256
plasmSin256 = plasmSinMap + 256
plasmSinA = plasmSin256 + 256
plasmSinB = plasmSinA + 256
plasmSinJump = plasmSinB + 256
plasmSinScroll = plasmSinJump + 256
clearLine = plasmSinScroll + 256		; a(clearline) MUST have LSB set to 0, so don't change anything in front of it
dlCopy = clearLine + 256			; 4*56*3 = $2a0
dlShow = dlCopy + $300				; 4*56 addresses = $1c0
dlShowCopy = dlShow + $200				; 4*56 addresses = $1c0
dataend3 = dlShowCopy + $200

;-------------
dlist	= $8000
scr		= $8400
scr2	= scr + width_n			; spare screens
scr3	= scr + 2*width_n
fontSet = $bc00		; $400 out of which the last $200 can be re-used

;-------------
width_s	= 32		; narrow (small) playfield
width_n	= 40		; normal playfield
height	= 56
sync	= 1			; vblank line to wait for

;-------------

	icl "Includes/zeropage.asm"
	icl "Includes/registers.asm"
	icl "Includes/macros.asm"

;	opt s+

// -----------------------------------------------------------------------------------
start 	= $2000
	org	start

// -----------------------------------------------------------------------------------
// main demo flow

	jsr	init_all
	;jmp s
	
	; show intro text
;	WaitMsS 60
	WaitMsS 50
	jsr	introtext

	; explosion into "snakes"
;	WaitMsS 100
	WaitMsS 20
	jsr	snakes.init
	jsr	snakes.exec

	; round logo effects
	WaitMsS 10
	jsr rotate_roundlogo_vert.init
	; fade logo in
	LdXY cols.collogoround1
	jsr	cols.fadein

	; turn round logo up-down
	WaitMsS 160
	jsr rotate_roundlogo_vert.exec

	; turn round logo left-right
	WaitMsS 70
	jsr rotate_roundlogo_horiz.init
	jsr rotate_roundlogo_horiz.exec

	; burn round logo
	WaitMsS 180
	jsr burn_round_logo

	; suspect "kaboom" zoomer
	WaitMsS 70
	jsr kaboom

	; scroll logo in and out
	WaitMsS 125
	jsr	scroll_logo

	; sine logo
	WaitMsS 90
	jsr	sine_longlogo_vert.init
	jsr	sine_longlogo_vert.exec
	
	; plasm credits
	WaitMsS 50
	jsr plasm.init_9cols
	mwa	#plasm.settings1 t1
	jsr plasm.config_9cols
	jsr plasm.exec_9cols

	WaitMsS 35
	mwa	#plasm.settings2 t1
	jsr plasm.config_9cols
	jsr plasm.exec_9cols

	WaitMsS 35
	mwa	#plasm.settings3 t1
	jsr plasm.config_9cols
	jsr plasm.exec_9cols

	; advanced plasm
	WaitMsS 50
	jsr plasm.init_16cols
	mwa	#plasm.settings16_1 t1
	jsr plasm.config_16cols
	jsr plasm.exec_16cols

	WaitMsS 20
	jsr plasm.init_16cols
	mwa	#plasm.settings16_2 t1
	jsr plasm.config_16cols
	jsr plasm.exec_16cols
s
	jsr plasm.init_16cols
	mwa	#plasm.settings16_3 t1
	jsr plasm.config_16cols
	jsr plasm.exec_16cols
	
	WaitMsS 50
	jmp theend
	

// -----------------------------------------------------------------------------------
init_all
	// initialise (sound, interrupts, ...)
	jsr	disableScreen
	mwa #dlblank SDLSTL					; blank DL to shadow
	mwa	#0 timerL						; initialise internal master timer
	mva	#255 COLDST
	.ifdef playsound
	jsr sound.initmod
	.endif
	jsr	nmi.init
	SetColors cols.colblack
	mwa #dlblank DLISTL					; blank DL
	mva	#0 COLBK

	; move some data to lower mem now that OS is off
	MemCpy roundlogo1Load roundlogo1 [.len roundlogo1Load -1]
	MemCpy roundlogo2Load roundlogo2 [.len roundlogo2Load -1]
	MemCpy longlogoLoad longlogoCpy [.len longlogoLoad -1]

	; move fonts to upper mem
	MemCpy fontsLoaded fontSet [.len fontsLoaded -1]

;	MemClr	data [stabrowsend-data]
	rts

// -----------------------------------------------------------------------------------
// Effects
// -----------------------------------------------------------------------------------
	icl "introtext.asm"
	icl "snakes.asm"
	icl "fire.asm"
	icl "kaboom.asm"
	icl "theend.asm"
	icl "misc.asm"

// ---------------------------------------------------------------------
.proc plasm
.proc init_16cols
	mwa #dlblank DLISTL					; blank DL
	mva	#0 COLBK
	jsr clear_screen
	jsr create_dl_lower.no_scroll
	jsr	hscroll_shift_dl_fixed

	;convtab sintab centre amp size
	MakeSin plasmConvTab plasmSinMap 7 7 1
	jsr	double_col
	InFill plasmSinMap $38 16 $ee	; small manual "fixes" in the colour mapping sine...
	MakeSin plasmConvTab plasmSin256 127 127 1
	MakeSin plasmConvTab plasmSinA 100 100 1
	MakeSin plasmConvTab plasmSinB 40 40 1
	MakeSin plasmConvTab plasmSinJump [>scr+17] 4 1
	MakeSin plasmConvTab plasmSinScroll 5 5 1
	MemClr clearLine 255
	MemCpy dlist dlCopy [4*height*3]

	// change dl addresses to point to an empty line, and also build showTab
	ldx	#4*height
	mwa	#dlShow t1
	mwa	#dlist+3 st2+1
st1	lda	#>clearLine				; clearline MUST have LSB set to 0
st2	sta	dlist+3					; +1 empty line, +1 addr load, +1 LSB (always 0)
	lda	st2+1
	ldy	#0
	sta	(t1),y					; dl show is a list of offsets into the DLlist
	lda	st2+2
	sec
	sbc	#>dlist
	iny
	sta	(t1),y
	adw	t1 #2
	adw	st2+1 #3
	dex
	bne	st1

	MemCpy dlShow dlShowCopy [2*4*height]
	
	vblank
	mva #$22 DMACTL		; $21 = narrow playfield, $22 = normal
	mva	#$40 PRIOR		; 80: 9 cols (GTIA graphics 10) - 9 arbitrary colours | 40: 16 shades (GTIA graphics 9) - all shades of one background colour | C0: 16 cols (GTIA graphics 11 - all colours of the same luminance)
	mva	#$00 COLBK
	mwa #dlist DLISTL
	rts
.endp

; no direct input - init should have been called beforehand
.proc exec_16cols
	mva	#width_n t29				; t29 scroller offset for proc3
	mva	#0 t30				; jump sin
	mva	#0 t31				; scroll sin

	lda	t7					; t7 - proc #
	bne	sp2					; scroll
	jsr	create_showtab_middle
	mva	#$20 t32
	jsr	col_anim.openhalf
	mva	#0 t18				; 0 - first DLI, 1 - second
	mwa	#flagDli nmi.nmi.dliv	; DL interrupt to change screen palette
	mva	#$cf dlist+1+height/2*3*4
	mva	#$cf dlist+1+height*3*4-3
	jmp	spc
sp2	cmp	#1
	bne	sp3					; "silly venture"
	MemCpy dlShowCopy dlShow [2*4*height]	
	jsr	col_anim.open
	jmp	spc
sp3							; no text
	jsr	create_showtab_random
	jsr	col_anim.open
spc
	mwa	#dlShow t33

	mwa	#0 t8				; t8, t9 - time counter for this proc
draw
	lda	#90
	jsr vblank.line 
;	vblank

	ldx	t28					; set length of effect
	stx nf1+1
	inx
	stx nf2+1

	inc	t8
	lda t8
	cmp	#20					; each H frame is 20 L frames
	bne	noh
	lda	#0
	sta	t8
	inc	t9
noh

	lda	t9
	bne	nofadein			; fade in in the first H frame
;	jsr	cols.fade_stepped.in
	ldx	#12
il1	
	cpw	t33	#dlShow+2*4*height
	beq	iq1
	ldy	#0
	lda	(t33),y
	sta	is1+1
	sta	id1+1
	ldy	#1
	lda	#>dlCopy
	clc
	adc	(t33),y
	sta	is1+2
	lda	#>dlist
	clc
	adc	(t33),y
	sta	id1+2
is1	lda	dlCopy
id1	sta	dlist
	adw	t33 #2
ii1		
	dex
	bne	il1
iq1
	jmp	tcont

nofadein
nf1	cmp	#11					; fade out
;	cmp #2
	bne	nofadeout
;	jsr	cols.fade_stepped.out
	ldx	#12
ol1	
	cpw	t33	#dlShow
	beq	oq1
	sbw	t33 #2
	ldy	#0
	lda	(t33),y
	sta	od1+1
	ldy	#1
	lda	#>dlist
	clc
	adc	(t33),y
	sta	od1+2
	lda	#>clearLine	
od1	sta	dlist
oi1		
	dex
	bne	ol1
oq1
	jmp	tcont

nofadeout
nf2	cmp	#12					; quit
	bne	tcont

	lda	t7					; t7 - proc #
	bne	qp2					; scroll
	jsr	nmi.remove_dli
	jsr	col_anim.closehalf
	jmp	qpc
qp2	cmp	#1
	bne	qp3					; "silly venture"
	jsr	col_anim.close
	jmp	qpc
qp3							; no text
	jsr	col_anim.close
qpc
	mwa #dlblank DLISTL					; blank DL
	rts
;------------
tcont

	adb t10 t11				; Increase sin counters (src, add_val)
	adb t12 t13
	adb t14 t15
	adb t16 t17

	adb t20 t21				; Increase 2nd sin counters (src, add_val)
	adb t22 t23
	adb t24 t25
	adb t26 t27
	
	ldx	t10
	mva	plasmSin256,x t2
	ldx	t12
	adb	t2 plasmSinA,x		; t2 = starting point 1

	ldx	t20
	mva	plasmSin256,x t3
	ldx	t22
	adb	t3 plasmSinA,x		; t3 = starting point 2

	// proc specific actions
	lda	t7					; t7 - proc #
	bne	xp2					;set jump address for the right X procedure
	mwa	#xproc3 xproc+1
	// proc 3 requires scrolling
	lda	t9					; local timer H
	cmp	#4
	bmi	xpc					; delayed scrolling start
	lda	t29
	cmp	#255-width_n		; stop before screen loops over
	beq	xpc

	lda	t30					; jump
	clc
	adc	#10
	sta	t30
	tax
	lda	plasmSinJump,x
	sta	xproc3.y1+1			; scroll y start
	clc
	adc	#21
	sta	xproc3.y2+1			; scroll y stop

	inc	t29					; scroll
	lda	t31
	clc
	adc	#13
	sta	t31
	tax
	lda	plasmSinScroll,x
	clc
	adc	t29
	sta	xproc3.xp3_1.sc0+1

	jmp	xpc
xp2	cmp	#1
	bne	xp3
	mwa	#xproc2 xproc+1
	jmp	xpc
xp3	
	mwa	#xproc1 xproc+1
xpc

	lda	#>scr2
	sta	xproc2.sc0+2				; second start screen address
	sta	xproc3.xp3_1.sc0+2				; second start screen address
	lda	#>scr
	sta	t1					; Y counter
	sta	xproc1.sc1+2				; start screen address
	sta	xproc2.sc1+2				; start screen address
	sta	xproc3.xp3_1.sc1+2				; start screen address
	sta	xproc3.xp3_2.sc1+2				; start screen address
lpy
	lda	t1
	clc
	adc	t14
	tax
	lda	t2					; Y start sin value
	clc
	adc	plasmSinA,x
	tay
	lda	t1
	clc
	adc	t16
	tax
	tya
	clc
	adc	plasmSinB,x			; X sin start
	sta	t4

	ldy	t7					; omit for proc 0
	beq	xproc
	lda	t1
	clc
	adc	t24
	tax
	lda	t3					; Y start sin value
	clc
	adc	plasmSinA,x
	tay
	lda	t1
	clc
	adc	t26
	tax
	tya
	clc
	adc	plasmSinB,x			; X sin start
	sta	t6

xproc
	jmp	xproc2

;-------------
.proc xproc1
	ldx	#width_n-1
lpx
	ldy	t4
	iny
	iny
	iny
	sty	t4
	lda	plasmSinMap,y

	ldy	t6
	iny
	iny
	sty	t6
	clc
	adc	plasmSinMap,y

sc1	sta	scr,x
	dex
	bpl	lpx

	inc	t1					; move to next row
	inc	sc1+2				; update row address
	lda	t1
	cmp	#>scr+height
	bne	lpy
	jmp	draw
.endp

;-------------
.proc xproc2
;	tay
	ldx	#width_n-1
lpx

	ldy	t4
s1	iny
	iny
	iny
	iny
	sty	t4
	lda	plasmSinMap,y

	dec	t6
	ldy	t6
;	clc
	adc	plasmSinMap,y

	clc
sc0	adc	scr2,x

sc1	sta	scr,x
	dex
	bpl	lpx
	
	inc	t1					; move to next row
	inc	sc1+2				; update row address
	inc	sc0+2				; update row address
	lda	t1
	cmp	#>scr+height
	jne	lpy
	jmp	draw
.endp

;-------------
.proc xproc3
	tay
	ldx	#width_n-1

	lda	t1
y1	cmp	#>scr+17
	bmi	xp3_2
y2	cmp	#>scr+38
	bpl	xp3_2

.proc xp3_1					// part with scroll
lpx
	iny
	iny
	iny
	lda	plasmSinMap,y

	clc
sc0	adc	scr2,x

sc1	sta	scr,x
	dex
	bpl	lpx
	
	inc	t1					; move to next row
	inc	sc1+2				; update row address
	inc	xp3_2.sc1+2				; update row address
	inc	sc0+2				; update row address
	lda	t1
	cmp	#>scr+height
	jne	lpy
	jmp	draw
.endp

.proc xp3_2					// part without scroll
lpx
	iny
	iny
	iny
	lda	plasmSinMap,y

sc1	sta	scr,x
	dex
	bpl	lpx
	
	inc	t1					; move to next row
	inc	sc1+2				; update row address
	inc	xp3_1.sc1+2				; update row address
	lda	t1
	cmp	#>scr+height
	jne	lpy
	jmp	draw
.endp

.endp	// xproc3

.endp	// exec


// configure the draw routine
; t1, t2 - settings addr
.proc config_16cols
	mwa	t1 t10
	jsr clear_entire_screen

	ldy	#20
	lda	(t1),y				; font color shift
	sta	t20
	ldy	#1
	lda	(t1),y				; text nr
	tax
	ldy	#2
	lda	(t1),y				; font multiplier
	tay
	jsr	printer

	mwa	t10 t1
	ldy	#0
	lda	(t1),y				; palette addr
;	sta	COLBK				; this is gr16 so select palette by setting only the primary colour
	sta	t32

	ldy	#3
	lda	(t1),y
	sta	t7					// t7 - internal version of the X procedure

	ldy	#4
	ldx	#0
lp	mva	(t1),y t10,x		// copy settings to t10-t17 an t20-t27
	iny
	inx
	cpx	#8
	bne	lp

	ldx	#0
lp2	mva	(t1),y t20,x		// copy settings to t10-t17 an t20-t27
	iny
	inx
	cpx	#8
	bne	lp2
	
	ldy	#21
	lda	(t1),y				; t28 - length
	sta	t28
	rts
.endp	// exec.init


// create a version of the showtab which starts from the middle
.proc	create_showtab_middle
	mwa	#dlShow ea1+1
	mwa #dlShowCopy+[4*height-2] a1+1
	mwa #dlShowCopy+[4*height-1] a2+1
	mwa #dlShowCopy+[4*height] a3+1
	mwa #dlShowCopy+[4*height+1] a4+1
	ldx	#2*height
a1	lda	dlShowCopy+[4*height-2]
	jsr	st_add_elem
	sbw	a1+1 #2
a2	lda	dlShowCopy+[4*height-1]
	jsr	st_add_elem
	sbw	a2+1 #2
a3	lda	dlShowCopy+[4*height]
	jsr	st_add_elem
	adw	a3+1 #2
a4	lda	dlShowCopy+[4*height+1]
	jsr	st_add_elem
	adw	a4+1 #2
	dex
	bne	a1
	rts

st_add_elem
ea1	sta dlShow
	inw	ea1+1
	rts
.endp

// create a radomised version of the showtab
.proc	create_showtab_random
	jsr	create_showtab_middle
	mwa	#dlShow ea1+1
	mwa	#dlShow ea2+1
	jsr	st_randomise
	jsr	st_randomise
	rts
		
st_randomise
	ldy	#2*height
a1	lda	RANDOM
	cmp	#4*height
	bmi	a2
	sec
	sbc	#4*height
a2	and	#$fe
	tax
	jsr st_get_elem		; swap pair of 16-bit pointers
	sta	t8
	lda	dlShow,x
	jsr	st_add_elem
	lda	t8
	sta	dlShow,x
	inx
	jsr st_get_elem
	sta	t8
	lda	dlShow,x
	jsr	st_add_elem
	lda	t8
	sta	dlShow,x
	dey
	bne	a1
	rts

st_add_elem
ea1	sta dlShow
	inw	ea1+1
	rts
	
st_get_elem
ea2	lda dlShow
	inw	ea2+1
	rts
.endp

.proc flagDli
	lda	t18
	bne	k1
	inc	t18
	lda	#$20
	jmp	k2
k1:	dec	t18
	lda	#0
k2:	sta	COLBK
	rts
.endp

; palette, text#, fontmulti#, inner proc version, params, font colur multiplier, length
; 0        1      2           3                   4...    20                     21
settings16_1	.byte	$50,  6, 2,  2,  0,1, 40,3, 170,2, 20,1,   80,-3, 70,-1, 10,4, 23,3,  2, 4
settings16_2	.byte	$40,  8, 2,  1,  130,-1, 0,-2, 170,2, 20,1,   80,-2, 70,-1, 0,1, 23,3,  2, 9
settings16_3	.byte	$00,  10, 3, 0,  140,-2, 89,-1, 170,1, 23,4,   80,-2, 70,-1, 0,1, 23,3,  3, 17

// -----------------------------------------------
.proc init_9cols
	vblank
	mwa #dlblank DLISTL					; blank DL
	jsr clear_screen
	jsr create_dl_lower.no_scroll
	;jsr	hscroll_shift_dl_fixed
	mva #$22 DMACTL		; $21 = narrow playfield, $22 = normal
	mva	#$80 PRIOR		; 80: 9 cols (GTIA graphics 10) - 9 arbitrary colours | 40: 16 shades (GTIA graphics 9) - all shades of one background colour | C0: 16 cols (GTIA graphics 11 - all colours of the same luminance)
	mwa #dlist DLISTL

	;convtab sintab centre amp size
	MakeSin plasmConvTab plasmSinMap 4 3 1
	InFill plasmSinMap $36 20 $77	; small manual "fixes" in the colour mapping sine...
	InFill plasmSinMap $b6 20 $00
	MakeSin plasmConvTab plasmSin256 127 127 1
	MakeSin plasmConvTab plasmSinA 90 90 1
	MakeSin plasmConvTab plasmSinB 40 40 1
	jsr	double_col
	rts
.endp

; no direct input - init should have been called beforehand
.proc exec_9cols

	InFill lpx 0 4 $EA		; prefill inner X loop with NOPs
	ldx	t9					; nr of "iny"
	lda	#$C8
fx1	sta	lpx,x
	dex
	bpl	fx1

	mwa	#0 t8				; t8, t9 - time counter for this proc
		
draw
;	lda	#10
;	jsr vblank.line 
	vblank

	inc	t8
	lda t8
	cmp	#20					; each H frame is 20 L frames
	bne	noh
	lda	#0
	sta	t8
	inc	t9
noh
	lda	t9
	bne	nofadein			; fade in in the first H frame
	jsr	cols.fade_stepped.in
	tya
	bne	tcont
	mva	#$0f COLBK			; after the rest of the palette has been set, fix highest col to white (to avoid fade in artefacts)
	jmp	tcont
nofadein
	cmp	#7					; fade out
	bne	nofadeout
	jsr	cols.fade_stepped.out
	jmp	tcont
nofadeout
	cmp	#8					; quit
	bne	tcont
	jmp	fin
tcont

	adb t10 t11				; Increase sin counters (src, add_val)
	adb t12 t13
	adb t14 t15
	adb t16 t17

	ldx	t10
	mva	plasmSin256,x t2
	ldx	t12
	adb	t2 plasmSinA,x		; t3 = starting point, combination of 2 sins

	lda	#>scr2
	sta	sc0+2				; second start screen address
	lda	#>scr
	sta	t1					; Y counter
	sta	sc1+2				; start screen address
lpy
	lda	t1
	clc
	adc	t14
	tax
	lda	t2					; Y start sin value
	clc
	adc	plasmSinA,x
	tay
	lda	t1
	clc
	adc	t16
	tax
	tya
	clc
	adc	plasmSinB,x			; X sin start

	tay
	ldx	#width_n-1
lpx
	iny
	iny
	iny
	iny
	lda	plasmSinMap,y

	clc
sc0	adc	scr2,x

sc1	sta	scr,x
	dex
	bpl	lpx

	inc	t1					; move to next row
	inc	sc1+2				; update row address
	inc	sc0+2				; update row address
	lda	t1
	cmp	#>scr+height
	bne	lpy

	jmp	draw

fin	
	rts
.endp	// exec


// configure the draw routine
; t1, t2 - settings addr
.proc config_9cols
	mwa	t1 t10
	jsr clear_entire_screen

	ldy	#13
	lda	(t1),y				; font color shift
	sta	t20
	ldy	#2
	lda	(t1),y				; text nr
	tax
	ldy	#3
	lda	(t1),y				; font multiplier
	tay
	jsr	printer

	mwa	t10 t1
	ldy	#1
	lda	(t1),y				; palette addr
	tax
	ldy	#0
	lda	(t1),y
	tay
	;jsr	cols.setcols
	jsr	cols.fade_stepped.init

	ldy	#4
	lda	(t1),y
	sta	t9					// t9 - nr to add in inner X loop
	dec	t9

	ldy	#5
	ldx	#0
lp	mva	(t1),y t10,x		// copy settings to t10-t17
	iny
	inx
	cpx	#8
	bne	lp
	
	rts
.endp	// exec.init

palette1	.byte	0,$e0,$e2,$e4,$e6,$e8,$ea,$ec,$ef
;palette2	.byte	0,$10,$12,$14,$16,$18,$1a,$1c,$0f
palette2	.byte	0,$d0,$d2,$d4,$d6,$d8,$da,$dc,$df
palette3	.byte	0,$90,$92,$94,$96,$98,$9a,$9c,$9f

; palette, text#, fontmulti#, inner X iny#, params, font color bit shift
; 0        2      3           4             5...    13
settings1	.byte	a(palette1),  0, 2,  4, 30,-1, 35,-3, 170,2, 20,1,   0
settings2	.byte	a(palette2),  2, 2,  1, 10,2, 25,1, 0,4, 0,-1,  0
settings3	.byte	a(palette3),  4, 2,  2, 0,-2, 135,-1, 10,-2, 23,-5,  0
.endp //plasm

// for every col in the tab, copy it also to the 4 upper bits
.proc double_col
	ldx	#0
lp	lda	plasmSinMap,x
	sta	t1
	asl
	asl
	asl	
	asl	
	ora	t1
	sta	plasmSinMap,x
	inx
	bne	lp	
	rts
.endp

// ---------------------------------------------------------------------
// printer
; X - text index
; Y - font heigth multiplier (1, 2, 3...)
; t20 - font shift multiplier
.proc printer
	mwa	texts,x t1
	sty	t9
	ldy	#0
	sty	t8				; text counter

loop
	ldy	t8
	lda	(t1),y
	bpl	l2
	iny
	lda	(t1),y			; text X
	jmi	fin
	clc
	adc	#<scr2			; add offset of scr2
	sta	t3				; text X
	iny
	lda	(t1),y
	clc
	adc	#>scr2
	sta	t4				; text Y
	iny
	sty	t8
	bne	loop
l2	
	iny
	sty	t8
	tay					; just to set the N flag
	jeq	nextchar		; skip if 0 (space)

	cmp	#$20
	bpl	aboveA
	mwx #fontSet fs+1
	jmp	c1
aboveA
	mwx #fontSet+$100 fs+1
	sec
	sbc	#$20
c1
	asl					; find letter in fontset
	asl
	asl
	sta	t5				; t5 - char index in table (-$100)
	mva	t3 sc1+1		; set screen address for font start
	mva	t4 sc1+2
	mva	#7 t6			; 8 rows in font
pch	
	ldx	t5
fs	lda	fontSet+$100,x	; print character loop

	ldx	#4			; 1 char = 4 screen bytes
	stx	t7
	ldy	#0			; scr counter for current font row (bytes 0..3)
scrbyte
	ldx	#$00		; handle 2 pixels at a time
	asl
	bcc	p2
	ldx	#$10		; first 1 branch
	asl
	bcc	p3
	ldx	#$11
	bne	p3
p2	asl
	bcc	p3
	ldx	#$01
p3	
	pha

	lda	sc1+2
	pha
	txa
	
	ldx	t20			; font shift multiplier
	beq	ns
shi	asl
	dex
	bne	shi
ns	
	ldx	t9			; font heigth multipier
sc1	sta	scr2,y
	inc	sc1+2		; temporarily move to next line
	dex
	bne	sc1
	pla
	sta	sc1+2		; restore row pointer

	pla
	iny				; move to next screen byte
	dec	t7
	bne	scrbyte

	ldx	t9			; font heigth multipier
m1	inc	sc1+2		; move to next line
	dex
	bne	m1
	inc	t5			; next byte in current font
	dec	t6			; repeat 8 times
	bpl	pch

nextchar
	adb	t3 #4		; move screen to start of next char
	jmp	loop
	
fin	rts

texts	.byte	a(text1),a(text2),a(text3),a(text4),a(text5),a(text6)

text1	.byte	-1,3,2,"CODING",-1,23,29,"KANE",-1,-1
text2	.byte	-1,6,8,"GRAPHICS",-1,4,34,"ART B",-1,-1
text3	.byte	-1,5,14,"MUSIC",-1,10,35,"WIECZ0R",-1,-1

text4	.byte	-1,-1
text5	.byte	-1,4,3,"SILLY",-1,8,21,"VENTURE",-1,13,38,"2021",-1,-1
;text6	.byte	-1,42,0,"GREETINGS TO THE ATARI SCENE!",-1,-1
text6	.byte	-1,46,0,"BEHOLD THE POWER OF THE ATARI!",-1,-1

.endp


// ---------------------------------------------------------------------
// rotate logo vertically (up-down) loop 
.proc rotate_roundlogo_vert

init
	jsr clear_screen
	jsr create_dl.no_scroll
	mva	#$21 DMACTL	; $21 = narrow playfield, $22 = normal
	mwa #dlist DLISTL
	mva	#$80 PRIOR	; 80: 9 cols (GTIA graphics 10) - 9 arbitrary colours | 40: 16 shades (GTIA graphics 9) - all shades of one background colour | C0: 16 cols (GTIA graphics 11 - all colours of the same luminance)
	SetColors cols.colblack

	mwa	#roundlogo2 t1
	mwa	#roundlogo1_inv t3
	jsr	invert_logo_horizontal
	mwa	#roundlogo1_inv t1
	mwa	#roundlogo1_trans t3
	jsr transpose_logo
	mwa	#roundlogo1_trans t1
	mwa	#roundlogo1_inv t3
	jsr invert_logo_vertical
	mwa	#roundlogo1 t1
	mwa	#roundlogo1_trans t3
	jsr transpose_logo
	lda	#roundlogo_h
	jsr	create_scaled_stretcher
	lda	#roundlogo_h	
	jsr create_scaletab

	lda	#roundlogo_h-1
	sta	t3
	lda	#(height-roundlogo_h-1)/2+1	;row
	ldx	#(width_s-roundlogo_w-1)/2		;collumn
	ldy	#0			; logo start offset
	; show logo (all black colours)
	jsr scalelogo_16col_vert				; just show the logo
	rts

exec
	mva	#roundlogo_h-1 t3
	jsr	lp2

	lda	#2
;	lda	#1
	sta	t5
mloop
	mva	#<roundlogo1_inv scalelogo_16col_vert.lal+1
	mva	#>roundlogo1_inv scalelogo_16col_vert.lah+1
	SetColors cols.collogoround2
	jsr	lp1
	WaitMs 8
	jsr	lp2

	mva	#<roundlogo1_trans scalelogo_16col_vert.lal+1
	mva	#>roundlogo1_trans scalelogo_16col_vert.lah+1
	SetColors cols.collogoround1
	jsr	lp1
	WaitMs 8
	dec	t5
	beq stopspin
	jsr	lp2
	jmp	mloop

lp1	jsr	vblank
	lda	#height
	clc
	sbc	t3
	lsr

;	lda	#height-51	;row
	ldx	#(width_s-roundlogo_w-1)/2			;collumn
	ldy	#0			; logo start offset
	jsr scalelogo_16col_vert

	inc t3
	lda	t3
	cmp	#roundlogo_h
	bne	lp1
	
	dec t3
	rts

lp2	jsr	vblank
	lda	#height
	clc
	sbc	t3
	lsr

//	lda	#height-51	;row
	ldx	#(width_s-roundlogo_w-1)/2			;collumn
	ldy	#0			; logo start offset
	jsr scalelogo_16col_vert

	dec t3
	lda	t3
	cmp	#255
	bne	lp2

	inc t3
	rts

stopspin
	rts
	
.endp

// -----------------------------
// rotate logo horizontally (left-right) loop 
.proc rotate_roundlogo_horiz

init
	mwa	#roundlogo1 t1
	mwa	#roundlogo1_inv t3
	jsr	invert_logo_horizontal
	lda	#roundlogo_w
	jsr	create_scaled_stretcher
	lda	#roundlogo_w	
	jsr create_scaletab
	rts

exec
	mva	#roundlogo_w-1 t3
	jsr	lp2

	lda	#3
	sta	t5
mloop
	mva	#<roundlogo2 scalelogo_16col_horiz.lal+1
	mva	#>roundlogo2 scalelogo_16col_horiz.lah+1
	SetColors cols.collogoround2
	jsr	lp1
	WaitMs 8
	jsr	lp2

	mva	#<roundlogo1 scalelogo_16col_horiz.lal+1
	mva	#>roundlogo1 scalelogo_16col_horiz.lah+1
	SetColors cols.collogoround1
	jsr	lp1
	WaitMs 8
	dec	t5
	beq stopspin
	jsr	lp2
	jmp	mloop

lp1	jsr	vblank
	lda	#width_s		; x centre
	clc
	sbc	t3
	sbc #1
	lsr
	tax					; x - start X byte on screen

	lda	#(height-roundlogo_h-1)/2+1	;row	; A - start Y row on screen
;	ldx	#0			;collumn
	ldy	#0			; logo start X offset
	jsr scalelogo_16col_horiz

	inc t3
	lda	t3
	cmp	#roundlogo_w
	bne	lp1
	
	dec t3
	rts

lp2	jsr	vblank
	lda	#width_s
	clc
	sbc	t3
	sbc #1
	lsr
	tax

	lda	#(height-roundlogo_h-1)/2+1	;row
;	ldx	#0			;collumn
	ldy	#0			; logo start offset
	jsr scalelogo_16col_horiz

	dec t3
	lda	t3
	cmp	#255
	bne	lp2

	inc t3
	rts

stopspin
	jsr	lp2
	mva	#<roundlogo2 scalelogo_16col_horiz.lal+1
	mva	#>roundlogo2 scalelogo_16col_horiz.lah+1
	SetColors cols.collogoround2
	jsr	lp1
	rts
	
.endp

//-----------------------------------------------------
// invert logo that will be resized horizonally (left-right)
// t1 - src, t3 - dst
.proc invert_logo_horizontal
	mwa	t1 il1+1
	mwa	t3 il2+1
	lda	#roundlogo_h
	sta	t1
il0
	ldx	#0
	ldy	#roundlogo_w-1
il1	lda	roundlogo1,x

	sta	t2
	asl
	asl
	asl
	asl
	sta	t3
	lda	t2
	lsr
	lsr
	lsr
	lsr
	ora	t3
il2	sta	roundlogo1_inv,y
	inx
	dey
	bpl	il1

	adw	il1+1 #roundlogo_w
	adw	il2+1 #roundlogo_w
	dec	t1
	bne	il0	
	rts
.endp

//-----------------------------------------------------
// invert logo that will be resized vertically (up-down)
// t1 - src, t3 - dst
.proc invert_logo_vertical
	mwa	t1 il1+1
	mwa	t3 il2+1
	lda	#roundlogo_w
	sta	t1
il0
	ldx	#0
	ldy	#roundlogo_h-1
il1	lda	roundlogo1_trans,x
il2	sta	roundlogo1_inv,y
	inx
	dey
	bpl	il1

	adw	il1+1 #roundlogo_h
	adw	il2+1 #roundlogo_h
	dec	t1
	bne	il0	
	rts
.endp

//-----------------------------------------------------
// transpose logo (first Y descending, then X)
// t1 - src, t3 - dst
.proc transpose_logo
	mwa	t1 il1+1
	mwa	t3 il2+1
	ldx	#0
il0
	ldy	#roundlogo_h-1
il1	lda	roundlogo1,x
il2	sta	roundlogo1_trans,y
	adw	il1+1 #roundlogo_w
	dey
	bpl	il1

;	mwa	#roundlogo1 il1+1
	mwa	t1 il1+1
	adw	il2+1 #roundlogo_h
	inx
	cpx	#roundlogo_w
	bne	il0	
	rts
.endp

//-----------------------------------------------------
//Scroll long logo left and then right
.proc scroll_logo
	vblank
	mwa #dlblank DLISTL					; blank DL
	jsr clear_entire_screen
	mva	#width_n+1 t1
	mva #7 t2
	mva #longlogo_w t3
	mva #longlogo_h t4
	mwa	#longlogoCpy t5
	jsr	copyLogoTransToScreen
	jsr create_dl.scroll
	vblank
	SetColors cols.collonglogo2
	mva #$22 DMACTL		; $21 = narrow playfield, $22 = normal
	mva	#$80 PRIOR	; 80: 9 cols (GTIA graphics 10) - 9 arbitrary colours | 40: 16 shades (GTIA graphics 9) - all shades of one background colour | C0: 16 cols (GTIA graphics 11 - all colours of the same luminance)
	mwa #dlist DLISTL

	mva	#0 t1
a1	vblank
	jsr set_offset
	inc	t1
	bne	a1

a2	dec	t1
	vblank
	jsr set_offset
	dec	t1
	bne	a2

set_offset
	; set logo addr as a combination of address and hscroll
	ldx	t1		; t1 - offset
	lda	sinus256quarter,x
	pha
	and	#1
	beq c
	lda	#12
	bne	e
c	lda	#14
e	sta HSCROL
	pla
	lsr
	tax
	jmp	dl_set_screen_offset
.endp

//-----------------------------------------------------
// sine scroll long logo loop 
.proc sine_longlogo_vert
logoscrollspd = 4

init
	jsr create_dl.no_scroll
	mwa #dlist DLISTL
	mva #$22 DMACTL		; $21 = narrow playfield, $22 = normal
	mva	#$80 PRIOR	; 80: 9 cols (GTIA graphics 10) - 9 arbitrary colours | 40: 16 shades (GTIA graphics 9) - all shades of one background colour | C0: 16 cols (GTIA graphics 11 - all colours of the same luminance)


	// SIN(centre,amp,size[,first,last])
	//	dta b(sin(longlogo_h/2+2,longlogo_h/2-1-2,64)) - logo texturing sinus, max has to be 41
	MakeSin longlogo sinus1 [longlogo_h/2+2] [longlogo_h/2-4] 4
	//dta b(sin((height-longlogo_h)/2+2,(height-longlogo_h)/2-1-2,128)) - Y screen sinus, min = 2 and max = 11
	MakeSin longlogo sinus2 [(height-longlogo_h)/2] [(height-longlogo_h)/2-3] 2

	MemCpy longlogoCpy longlogo [.len longlogoLoad -1]
	MemClr longlogoClear [(width_n+2)*height-1]

	lda	#longlogo_h	
	jsr	create_scaled_stretcher
	lda	#longlogo_h	
	jsr create_scaletab

	rts

exec
	mwa	#longlogo p1
	SetColors cols.collonglogo1

	lda	#0
	sta t9			; Y offset sine	running offset	(0..128) (values 4..13)
	sta t3			; logo Y size sine running offset (0..64) (values 1..41)
	
	lda	#logoscrollspd			; move only every X frames
	sta t7

	lda	#width_n		; start X offset
	sta	t10

	lda #longlogo_w+1		; nr of columns to draw
	sta	t5
mloop
	vblank
	
	lda #0			; screen display start Y (row)
	ldx	t10			; screen display start X (collumn)
	jsr scalelogo_16col_sine_vert

	dec t7			; scroll logo only every X frames
	bne	scr1
	lda	#logoscrollspd
	sta t7

	lda	t10
	beq	scr0
	dec	t10			; screen X = X - 1
	jmp	scr1
scr0
	adw	p1 #longlogo_h		; move logo draw start to next column
	dec t5					; decrease nr of columns to draw
scr1

	lda t9			; move on the Y offset sin
	clc
	adc	#3			; Y offset speed
	sta	t9
	
	inc t3			; move on the Y size sine offset
	lda	t5			; columns to draw counter
	bne mloop		; some still left? continue
	rts

.endp

// -----------------------------
// Long logo - vertical scaling (up-down)
// print 16 (or 9) colour logo, 
; A: start screen row, 
; X: start screen collumn
; p1 - logo start column (note: logo has to be transposed, i.e. sequential collumns in memory)
.proc scalelogo_16col_sine_vert

blanks_pre = 2
blanks_post = 5

	stx	pscr+1			; main X
	stx	pscrb+1			; blanks before X
	stx	pscrb2+1		; blanks after X
	clc
	adc	#>scr
	sta t4

	mwa	p1 plogoadr+1
	lda	t3
	sta t6
	
	lda	t9				; screen Y offset sine offset start (for sinus2)
	sta t8				; running Y screen offset

	ldy #width_n		; collumns - in bytes
	sty t1
pcolumn
	lda	t8					; calculate Y offset from sine
	inc	t8				; add 3 to running offset
	inc	t8
	inc	t8
	and	#127			; sinus2 length: 128
	tax
	lda	sinus2,x
	clc
	adc	t4
	sta	pscr+2			; start screen Y

	sec
	sbc	#blanks_pre
	sta	pscrb2+2		; save first Y line to blank
	lda	#0
	ldx	#blanks_pre
pscrb2
	sta scr
	inc	pscrb2+2
	dex
	bne	pscrb2
	inc	pscrb2+1		; move up blanks ptr to next collumn

	// get the stab entry for this column
;	lda	t3
;	tax	; x is the height of the row to print
	; remember how many rows to print. x=f(t3) (simplest x=t3 (i.e. tax), can be e.g. x=sin(t3+i))
	lda	t6
	inc	t6
	and	#63			// sinus1 length: 64
	tax
	lda sinus1,x
	tax				// X - collumn Y size
	
	; point to the right scaling tab
	asl
	tay
	mwa	stab,y pbyte+1	; set address of scale index tab to use for this collumn

	; main texturing loop
pbyte					; print one byte (2-pixel) column
	ldy stabrows,x		; get row index into the logo
plogoadr
	lda	roundlogo1,y
pscr
	sta scr
	inc pscr+2			; move screen to next line
	dex
	bpl pbyte

	inc	pscr+1			; move draw pointer to next collumn
	adw	plogoadr+1 #longlogo_h 

	lda	pscr+2			; add blank pixels at end of line
	sta	pscrb+2
	lda	#0
	ldx	#blanks_post
pscrb
	sta scr
	inc	pscrb+2
	dex
	bne	pscrb
	inc	pscrb+1			; move down blanks to new collumn

	dec t1
	bne	pcolumn			; repeat for all collumns
	rts
.endp ; plogo_16col_sine_vert

//-----------------------------------------------------
// Round logo  vertical scaling (up-down)
// print 16 colour logo, A: start screen row, X: start screen collumn, Y: logo offset
// t3 - roundlogo_h-1
.proc scalelogo_16col_vert

	stx	pscr+1
	stx	pscrb+1
	stx	pscrb2+1
	clc
	adc	#>scr
	sta	pscr+2
	sta t4
	
	tax
	dex
	stx	t2

lal	lda #<roundlogo1_trans		; set logo address
	sty	t1
	clc
	adc	t1
	sta plogoadr+1
lah	lda #>roundlogo1_trans
	adc	#0
	sta plogoadr+2

	ldy #roundlogo_w		; in bytes
;	ldy #8		; in bytes
	sty t1
pcolumn
	// get the stab entry for this column
	lda	t3
	; remember how many rows to print. x=f(t3) (simplest x=t3 (i.e. tax), can be e.g. x=sin(t3+i))
	tax	; x is the height of the row to print
	
	; point to the right scaling tab
	asl
	tay
	lda	stab,y
	sta	pbyte+1			; set address of scale index tab to use for this collumn
	lda	stab+1,y
	sta	pbyte+2

pbyte					; print one byte (2-pixel) column
	ldy stabrows,x		; get row index into the logo
plogoadr
	lda	roundlogo1,y
pscr
	sta scr
	inc pscr+2			; move screen to next line
	dex
	bpl pbyte

	lda	pscr+2			; add blank pixel at end of line
	sta	pscrb+2
	lda	#0
pscrb
	sta scr
	inc	pscrb+1

	lda	t2				; add blank pixel at start of line
	sta	pscrb2+2
	lda	#0
pscrb2
	sta scr
	inc	pscrb2+1

	lda	t4				; reset screen draw address for next collumn
	sta	pscr+2
	inc	pscr+1

	lda plogoadr+1		; move logo to next line
	clc
	adc	#roundlogo_h
	sta plogoadr+1
	bcc pl1
	inc	plogoadr+2
pl1
	dec t1
	bne	pcolumn
	rts
.endp ; plogo_16col_vert

//-----------------------------------------------------
// Round logo horizontal scaling  (left-right)
// print 16 colour logo, A: row, X: collumn, Y: logo offset
.proc scalelogo_16col_horiz
	stx	pscr+1
	stx	pscrb+1
	dex
	stx	t2			; index of pixel before the start one
	clc
	adc	#>scr
	sta	pscr+2
	sta	pscrb+2		; pixel after
	sta	pscrb2+2	; pixel before

lal	lda #<roundlogo1
	sty	t1
	clc
	adc	t1
	sta plogoadr+1
lah	lda #>roundlogo1
	adc	#0
	sta plogoadr+2

	ldy #roundlogo_h
	sty t1
pline
	// get the stab entry for this row
	lda	t3
	; remember how many pixels to print. x=f(t3) (simplest x=t3 (i.e. tax), can be e.g. x=sin(t3+i))
	tax
	
	asl
	tay

	lda	stab,y
	sta	pbyte+1
	lda	stab+1,y
	sta	pbyte+2

pbyte					; print one pixel line
	ldy stabrows,x
plogoadr
	lda	roundlogo1,y
pscr
	sta scr,x
	dex
	bpl pbyte


	lda	#0
	ldx	t3
	inx
pscrb
	sta scr,x				; add blank pixel at end of line
	ldx	t2
pscrb2
	sta scr,x				; add blank pixel at start of line
	inc	pscrb+2
	inc	pscrb2+2

	
	inc pscr+2			; move screen to next line

	lda plogoadr+1		; move logo to next line
	clc
	adc	#roundlogo_w
	sta plogoadr+1
	bcc pl1
	inc	plogoadr+2
pl1
	dec t1
	bne	pline
	rts
.endp ; plogo_16col_horiz


;----------------------------------------------------------------
// Wait for vertical sync
.proc vblank
	pha
	lda	#sync
vsync
	cmp	VCOUNT
	bne	vsync
	lda	#sync+1
vsync2
	cmp	VCOUNT
	bne	vsync2
	pla
	rts
	
n	
	jsr vblank
	dex
	bne	n
	rts

; A - scan line to wait for
line
	sta	lv1+1
	clc
	adc	#1
	sta	lv2+1
lv1	lda	#sync
lvsync
	cmp	VCOUNT
	bne	lvsync
lv2	lda	#sync+1
lvsync2
	cmp	VCOUNT
	bne	lvsync2
	rts
.endp


;----------------------------------------------------------------
// NMI routines
.proc nmi

	.proc nmi
	pha
	txa
	pha
	tya
	pha
	bit NMIST		; if the DLI bit is not set then the interrupt is VBL
	bpl vbi
dliv = *+1			; This is the DLI interrupt (display list triggered)
	jsr return
	jmp exit

vbi	sta NMIRES		; reset interrupt (toto: shouldn't this happen also for DLI?)
vbiv	= *+1
	jsr return
	lda #$c0
	sta NMIEN
	.ifdef playsound
		jsr sound.play
	.endif
	inc timerL
	bne	exit
	inc timerH
exit	
	pla
	tay
	pla
	tax
	pla
	rti

return	
	rts
	.end

	.proc init
	sei
i1	lda VCOUNT
	bne i1
	sta DMACTL
	sta COLBK
	sta NMIEN
	lda #$fe
	sta PORTB

i2	lda VCOUNT
	bne i2
	mwa #nmi $fffa
	mva #$40 NMIEN
	lda #1
	jsr wait
	mva #$c0 NMIEN
	rts
	.endp

	.proc remove_dli
	mwa	#nmi.return nmi.nmi.dliv
	rts
	.endp

	.proc wait
	clc
	adc timerL
loop
	cmp timerL
	bne loop
	rts
	.endp
.endp

;-----------------------------------------------------------------
; local data that does not fit anywhere else
dlblank	.byte	$10,$41,a(dlblank)		; blank display list

;-----------------------------------------------------------------
codeend
	.print	"Code:     start: ", start, " end: ", codeend, " (len: ", codeend-start, ")"

;-----------------------------------------------------------------
STEREOMODE	equ 1				;0 => compile RMTplayer for mono 4 tracks
;						;1 => compile RMTplayer for stereo 8 tracks
;						;2 => compile RMTplayer for 4 tracks stereo L1 R2 R3 L4
;						;3 => compile RMTplayer for 4 tracks stereo L1 L2 R3 R4

.proc sound
zp		= $CB			;19 bytes of zero pages, CB-DD
init	= player
play	= player+3		;<A>=song line/number 0...255, <X>=lo byte of module, <Y>=hi byte of module
stop	= player+9	        ;All sounds off

	.proc initmod
	ldx #<sound.module
	ldy #>sound.module
	lda #0
	jmp sound.init
	.endp

	icl "Includes/RMT-Relocator.mac"

	.ds $400
	.align $100
player
	icl "Includes/RMT-Player.asm"
	icl "Music/behold_feat.asm"
module
.local moduleLoad
	rmt_relocator 'Music/behold.rmt' module
.endl
	.print	"Player:   start: ", sound, " end: ", moduleLoad, " (len: ", moduleLoad-sound, ")"
	.print	"Module:   start: ", moduleLoad, " end: ", moduleLoad + [.len moduleLoad], " (len: ", .len moduleLoad, ")"

.endp

;-----------------------------------------------------------------
sintabs
.local	sinus256quarter
	.byte 0,2,3,5,6,8,9,11,13,14,16,17,19,20,22,23,25,27,28,30,31,33,34,36,37,39,41,42,44,45,47,48,50,51,53,54,56,57,59,60,62,63,65,67,68,70,71,73,74,76,77,79,80,81,83,84,86,87,89,90,92,93,95,96,98,99,100,102,103,105,106,108,109,110,112,113,115,116,117,119,120,122,123,124,126,127,128,130,131,132,134,135,136,138,139,140,142,143,144,146,147,148,149,151,152,153,154,156,157,158,159,161,162,163,164,165,167,168,169,170,171,172,174,175,176,177,178,179,180,181,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,208,209,210,211,212,213,214,215,215,216,217,218,219,220,220,221,222,223,223,224,225,226,226,227,228,228,229,230,231,231,232,232,233,234,234,235,236,236,237,237,238,238,239,240,240,241,241,242,242,243,243,244,244,244,245,245,246,246,247,247,247,248,248,248,249,249,249,250,250,250,251,251,251,252,252,252,252,252,253,253,253,253,253,254,254,254,254,254,254,254,255,255,255,255,255,255,255,255,255,255
.endl
.local	sinus256full
	.byte 0,3,6,9,12,16,19,22,25,28,31,34,37,40,43,46,49,51,54,57,60,63,65,68,71,73,76,78,81,83,85,88,90,92,94,96,98,100,102,104,106,107,109,111,112,113,115,116,117,118,120,121,122,122,123,124,125,125,126,126,126,127,127,127,127,127,127,127,126,126,126,125,125,124,123,122,122,121,120,118,117,116,115,113,112,111,109,107,106,104,102,100,98,96,94,92,90,88,85,83,81,78,76,73,71,68,65,63,60,57,54,51,49,46,43,40,37,34,31,28,25,22,19,16,12,9,6,3,0,-3,-6,-9,-12,-16,-19,-22,-25,-28,-31,-34,-37,-40,-43,-46,-49,-51,-54,-57,-60,-63,-65,-68,-71,-73,-76,-78,-81,-83,-85,-88,-90,-92,-94,-96,-98,-100,-102,-104,-106,-107,-109,-111,-112,-113,-115,-116,-117,-118,-120,-121,-122,-122,-123,-124,-125,-125,-126,-126,-126,-127,-127,-127,-127,-127,-127,-127,-126,-126,-126,-125,-125,-124,-123,-122,-122,-121,-120,-118,-117,-116,-115,-113,-112,-111,-109,-107,-106,-104,-102,-100,-98,-96,-94,-92,-90,-88,-85,-83,-81,-78,-76,-73,-71,-68,-65,-63,-60,-57,-54,-51,-49,-46,-43,-40,-37,-34,-31,-28,-25,-22,-19,-16,-12,-9,-6,-3
.endl
sintabsend
	.print	"Sinus:    start: ", sintabs, " end: ", sintabsend, " (len: ", sintabsend-sintabs, ")"
	.print	"-------"

; up to here nothing should be overwritten. From here on, memory may be reusable
upperbound

;-----------------------------------------------------------------
; memory can be reused from now on after initialisation and intro text
introtxt
	icl "introtxt.txt"
introtxtend
	.print	"Inttxt:   start: ", introtxt, " end: ", introtxtend, " (len: ", introtxtend-introtxt, ")"

;-----------------------------------------------------------------
.local roundlogo1Load
;	ins "Gfx/Suspect_round_50x50_9col.pic"
	ins "Gfx/Suspect_round_50x50_9col_front.pic"
.endl
.local roundlogo2Load
	ins "Gfx/Suspect_round_50x50_9col_back.pic"
.endl
	.print	"R1 Logo:  start: ", roundlogo1Load, " end: ", roundlogo1Load + .len roundlogo1Load, " (len: ", .len roundlogo1Load, ")"
	.print	"R2 Logo:  start: ", roundlogo2Load, " end: ", roundlogo2Load + .len roundlogo2Load, " (len: ", .len roundlogo2Load, ")"
	roundlogo_w = 25
	roundlogo_h = 50

.local longlogoLoad
;	ins "Gfx/Suspectlogo2_214x42_9col_trans.pic"
	ins "Gfx/Behold_214x42_9col.pic"
.endl
	.print	"L Logo:   start: ", longlogoLoad, " end: ", longlogoLoad + .len longlogoLoad, " (len: ", .len longlogoLoad, ")"
	longlogo_w = 107
	longlogo_h = 42

.local fontsLoaded
	ins	"Gfx/block.fnt"
.endl
	.print	"Fonts:    start: ", fontsLoaded, " end: ", fontsLoaded + .len fontsLoaded, " (len: ", .len fontsLoaded, ")"

;-----------------------------------------------------------------
endmain
;	.print	"Main:     start: ", start, " end: ", endmain, " (len: ", endmain-start, ")"
	.print	"-------"
	.print	"Data1:    start: ", data, " end: ", dataend1, " (len: ", dataend1-data, ")"
	.print	"Data2:    start: ", data, " end: ", dataend2, " (len: ", dataend2-data, ")"
	.print	"Data3:    start: ", data, " end: ", dataend3, " (len: ", dataend3-data, ")"
;	.print	"Stab:     start: ", stab, " end: ", stab+[stablen_h*2]+[[stablen_h+2]*[stablen_h+2]], " (len: ", [stablen_h*2]+[[stablen_h+2]*[stablen_h+2]], ")"
	.print	"DL:       start: ", dlist, " end: ", dlist+[2*6*height]+4, " (len: ", [2*6*height]+4, ")"
	.print	"Screen:   start: ", scr, " end: ", scr+[256*height], " (len: ", 256*height, ")"
	.print	"Fonts cp: start: ", fontSet, " end: ", fontSet + .len fontsLoaded, " (len: ", .len fontsLoaded, ")"


;-----------------------------------------------------------------
; stuff which can be loaded directly into other target mem locations

;	org fontSet



;-----------------------------------------------------------------
	run start
