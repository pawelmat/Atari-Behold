; ******************************************************
; BEHOLD demo, Kane / Suspect, 08/2021
; Copyright (C) 2021 Pawel Matusz. Distributed under the terms of the GNU GPL-3.0.
;
; Miscellaneous procedures
; ******************************************************


// ---------------------------------------------------------------------
// calculates required sinus table based on a 256-byte long quater sin
.proc calc_sin
; t1,t2 - conversion table address (size 256)
; X - amp, max is 127. 
init
	jsr	calc_size_conv_table.tab256
	ldy	#0			; = 256 
	jsr	calc_size_conv_table.invtab		// this compresses the 256b table to 128 bytes and adds a second half which is a nagative and reversed version copy of the first 128 bytes. This is to allow for conversion of negative values in the second part of the sinus. So effectively the sinus amplitude can be max 127.
	rts

; t1,t2 - conversion table address (size 256)
; t3,t4 - dst addr, must fit the whole sin table with length defined by Y
; A - centre (add)
; Y - sin table size indicator, size=256/Y. 1=256, 2=128, 4=64, 8=32
calc
	sta	t6		; centre
	sty	t5		; size add
	mwa	t1 csc+1	; set conversion table addr
	mva	#0 t1		; dst sin table running index
	mva	#0 t2		; src table running index
loop
	ldx	t2
clp	ldy	sinus256full,x
csc	lda	csc,y		; new sin value
	clc
	adc	t6			; centre
	ldy	t1
	sta	(t3),y		; first quarter
	inc	t1
	lda	t2
	clc
	adc	t5
	sta	t2
	bne	loop
	rts
	
.endp


// calculates conversion table from size A to B
.proc calc_size_conv_table
; t1,t2 - dst addr
; x - out max
; y - reference max (i.e. in value). This will also be the size of the table.
.proc fixed
	stx	cad+1		; make add value an immediate, for speed reasons
;	stx	cae+1
	sty	cc1+1		; reference max value
	sty	cc2+1
	sty	clm+1
	mwa	t1 cst+1
	txa
	ldx	#0			; table offset
	ldy	#0			; scaled value
clp	clc
cad	adc	#1
cc1	cmp	#2
	bmi	c1
	sec
cc2	sbc	#2
	iny
;	clc
;cae	adc	#1			; start always from 1 less to distribute values better
c1	pha
	tya
cst	sta	cst,x
	pla
	inx
clm	cpx	#3
	bne	clp	
	rts
.endp

; t1,t2 - dst addr
; x - out max
; ..y is reference max = 256. This will also be the size of the table.
.proc tab256
	stx	cad+1		; make add value an immediate, for speed reasons
;	stx	cae+1
	mwa	t1 cst+1
	txa
	ldx	#0			; table offset
	ldy	#0			; scaled value
clp	clc
cad	adc	#1
	bcc	c1
	iny
;	clc
;cae	adc	#1			; start always from 1 less to distribute values better
c1	pha
	tya
cst	sta	cst,x
	pla
	inx
	bne	clp	
	rts
.endp

// create half tab with the other half inverted
; t1, t2 - address
; Y - size (for tab creation that would have been the reference max)
.proc invtab
	sty	t3
	ldy	#0
	sty	t4			; full index
	sty	t5			; half index
	; create half tab
ilp	ldy	t4
	lda	(t1),y
	ldy	t5
	sta	(t1),y
	inc	t4
	inc	t4
	inc	t5
	lda	t4
	cmp	t3
	bne	ilp
	mva	t5 t6		; half size in t6

	; invert the half tab and add to not inverted
	lda	#0
	sta	t4			; first half
	lda	t3	
	sta	t5			; second half
	dec	t5
ilp2
	ldy	t4
	lda	#0
;	sec
	clc				; this means that it will start from -1, not 0
	sbc	(t1),y
	ldy	t5
	sta	(t1),y

	inc	t4
	dec	t5
	lda	t4
	cmp	t6
	bne	ilp2
	
	rts
.endp

.endp	//calc_size_conv_table


// ---------------------------------------------------------------------
; create scaled stretches, i.e. a table of linear offsets corresponding to a single texture line
; Scaling is done by shortening the list of offsets and the remaining pixels should be shown
; A = size of target tab
.proc create_scaled_stretcher 
	sta	t1
	ldx	#0
	ldy	#0
c1	lda	stretcher,x
	cmp	t1
	bpl	c2
	sta	sscaled,y
	iny
c2	inx
	cpx	#.len stretcher
	bne	c1
	rts
.endp

.local stretcher
	.byte 53,17,45,9,39,19,49,3,33,25,61,11,41,29,55,1,31,15,47,7,37,21,59,5,35,23,51,13,43,27,57,0,32,24,60,14,46,28,54,6,38,22,62,8,40,16,50,2,34,30,58,12,44,26,52,4,36,20,63,10,42,18,48,56
.endl

//-----------------------------------------------------
; A - max size to scale to. Should correspond to the max length of the  texture (e.g. longlogo_h = 42)
.proc create_scaletab	
	sta t1

	mwa	#stabrows st4+1

	lda	#0
	sta	t3			; address index

	lda	#1
	sta	t2			; row length
st1
	ldx	#0
	ldy	#0
st2	lda	sscaled,x
	cmp	t2
	bpl	st3
	txa
st4	sta	stabrows,y	; save pixel index
	iny
st3	inx
	cpx	t1
	bne	st2

	ldx	t3		; save row address
	lda	st4+1
st6	sta	stab,x
	inx
	lda	st4+2
st7	sta	stab,x
	inx
	stx	t3
	
	lda	st4+1	; move to next row
	clc
	adc	t2
	sta	st4+1
	bcc	st5
	inc	st4+2	
st5
	inc	t2
	lda	t1
	cmp	t2
	bpl	st1
	rts

.endp


// ---------------------------------------------------------------------

//-----------------------------------------------------
// modify one DL dual-line to shoft alternate lines
// p1: #dlist+1
.proc hscroll_shift_add
	lda #$5f
	ldy #3
	sta (p1),y

	lda	#12
	clc
	adc	p1
	sta p1
	bcc	nf1
	inc	p1+1
nf1
	lda #$5f+$80
	ldy #3
	sta (p1),y
	lda #$5f
	ldy #9
	sta (p1),y
	rts
.endp

// shift every second line of the whole DL, making the picture blurry
.proc hscroll_shift_dl
	lda #14
	sta HSCROL
	mwa	#dlist+1 p1
	ldx	#height
hs0
	jsr hscroll_shift_add
	dex
	bne hs0
	rts
.endp

; this is a "fixed" version as the orig one omits one value, but I don't want to change it in case it's intentional (don't remember...)
.proc hscroll_shift_dl_fixed
	mva	#$5f dlist+10
	jmp	hscroll_shift_dl
.endp


// create DL for gfx 10 or 9
.proc create_dl
scroll
	ldy	#$5f
	jmp dl
no_scroll
	ldy	#$4f
dl	mwa	#dlist dl_elem_add.s1+1
	jsr dl_elem_add.s1
	ldx #>scr
dlcreate
	jsr	dl_elem_add
	jsr	dl_elem_add
	inx
	cpx #height+>scr
	bne	dlcreate
	lda	#$41				; add jump to start to list
	jsr dl_elem_add.s1
	lda	#<dlist
	jsr dl_elem_add.s1
	lda	#>dlist
	jsr dl_elem_add.s1
	rts
.endp

// create DL for gfx 10 or 9
.proc create_dl_lower
scroll
	ldy	#$5f
	jmp dl
no_scroll
	ldy	#$4f
dl	mwa	#dlist dl_elem_add.s1+1
	lda	#$70
	jsr dl_elem_add.s1
	ldx #>scr
dlcreate
	jsr	dl_elem_add
	jsr	dl_elem_add
	inx
	cpx #height+>scr
	bne	dlcreate
	lda	#$41				; add jump to start to list
	jsr dl_elem_add.s1
	lda	#<dlist
	jsr dl_elem_add.s1
	lda	#>dlist
	jsr dl_elem_add.s1
	rts
.endp

// create DL for gfx 10 or 9 with 4 rows per pixel
.proc create_dl4
scroll
	ldy	#$5f
	jmp dl
no_scroll
	ldy	#$4f
dl	mwa	#dlist dl_elem_add.s1+1
	jsr dl_elem_add.s1
	ldx #>scr
dlcreate
	jsr	dl_elem_add
	jsr	dl_elem_add
	jsr	dl_elem_add
	jsr	dl_elem_add
	inx
	cpx #height/2+>scr
	bne	dlcreate
	lda	#$41				; add jump to start to list
	jsr dl_elem_add.s1
	lda	#<dlist
	jsr dl_elem_add.s1
	lda	#>dlist
	jsr dl_elem_add.s1
	rts
.endp

// add Display List element - one mode 15 line and one blank line
.proc dl_elem_add
;	lda	#$4f
	tya
	jsr	s1
	lda #0			; on clean mem this can be cut out
	jsr	s1
	txa
	jsr	s1
;	lda	#$4f
	tya
	jsr	s1
	lda #0			; on clean mem this can be cut out
	jsr	s1
	txa
		
s1	sta dlist
	inc s1+1
	bne s2
	inc s1+2
s2	
	rts
.endp

; x - offset
.proc dl_set_screen_offset
	mwa	#[dlist+2] s1+1
	ldy	#0
s1	stx	dlist
	adw	s1+1 #3
	iny
	cpy	#height*4
	bne	s1
	rts
.endp

;----------------------------------------------------------------
// clear screen area
.proc clear_screen
	mva #width_n cl2+1
clear
	lda	#>scr
	sta	cl1+2
	lda	#0
	ldy	#height
cl2	ldx	#width_n
cl0	dex
cl1	sta scr,x
	cpx	#0
	bne	cl0
	inc cl1+2
	dey
	bne	cl2
	rts
.endp

.proc clear_entire_screen
	mva #255 clear_screen.cl2+1
	jmp	clear_screen.clear
.endp


// copy transposed logo to screen
; t1 - screen X ofs, t2 - screen Y ofs
; t3 - logo W , t4 - logo H 
; t5, t6 - logo addr
.proc copyLogoTransToScreen
	mwa	t5 cl3+1	; logo addr
	lda	#>scr
	clc
	adc	t2
	sta	cl1+2		; screen start Y
	sta	t2
	mva	t1 cl1+1	; screen start X
	lda	#0
	ldx	#0
cl2	ldy	t4			; logo H (Y)
	dey
cl3	lda	longlogo,y
cl1	sta scr,x
	inc	cl1+2		; next screen line
	dey
	bpl	cl3

	mva	t2 cl1+2	; reset screen addr
	lda	cl3+1
	clc
	adc	t4
	sta	cl3+1
	bcc	cl4
	inc	cl3+2
cl4	
	inx
	cpx	t3			; t3 - logo W (X)
	bne	cl2
	rts
.endp

;----------------------------------------------------------------
; copy memory block
; t1,t2 - src
; t3,t4 - dst
; t5,t6 - length-1
.proc	memCopy
	ldy	t5
	lda	t2
	clc
	adc	t6
	sta	t2
	lda	t4
	clc
	adc	t6
	sta	t4
lp	lda	(t1),y
	sta	(t3),y
	dey
	cpy	#255
	bne	lp
	lda	t6
	beq	le
	dec	t2				; decrease addresses
	dec	t4
	dec	t6				; MSB of the counter (LSB is Y)
	bpl	lp
le	rts
.endp

; copy memory block
; t1,t2 - src
; t3,t4 - length-1
.proc	memClear
	ldy	t3
	lda	t2
	clc
	adc	t4
	sta	t2
	lda	#0
lp	sta	(t1),y
	dey
	cpy	#255
	bne	lp
	lda	t4
	beq	le
	dec	t2				; decrease addresses
	dec	t4				; MSB of the counter (LSB is Y)
	lda	#0
	bpl	lp
le	rts
.endp

;----------------------------------------------------------------
.proc cols

; X, Y - colour table address
.proc fadein
	stx	fia+2
	sty	fia+1
	stx	fib+2
	sty	fib+1
	ldx	#8
fib	lda	collogoround1,x		; prepare starting point: black with only colour component set
	and	#$f0
	sta	colact,x
	dex
	bpl	fib

	lda	#16
	sta	t1
fi0
	ldx	#8
fi3	lda	colact,x
fia	cmp	collogoround1,x
	beq	fi4
	inc	colact,x
fi4	dex
	bpl	fi3
	
	SetColors colact
	WaitMsS 2
	dec	t1
	bne	fi0
	rts
.endp

// this is a "stepped" version to call from within another loop. Init first and then call "exec" 16 times
; X, Y - colour table address
.proc fade_stepped
init
	stx	fia+2
	sty	fia+1
	stx	fib+2
	sty	fib+1
	ldx	#8
fib	lda	collogoround1,x		; prepare starting point: black with only colour component set
	and	#$f0
	sta	colact,x
	dex
	bpl	fib
	rts

in
	ldx	#8
	ldy	#0
fi3	lda	colact,x
fia	cmp	collogoround1,x
	beq	fi4
	iny
	inc	colact,x
fi4	dex
	bpl	fi3
	tya
	beq	nf1
	SetColors colact
nf1	rts						; y=0 on exit means that procedure finished

out
	ldx	#8
	ldy	#0
fi6	lda	colact,x
	and	#$0f
	beq	fi5
	iny
	dec	colact,x
fi5	dex
	bpl	fi6

	tya					; y=0 if all components are 0 then go to completely black
	bne	fi7
	ldx	#8
	lda	#0
fi8	sta	colact,x
	dex
	bpl	fi8
fi7
	SetColors colact
	rts
.endp



// set colors (9) from color table given in X(high),Y(low)
; X, Y - colour table address
setcols
	stx	sc2+2
	sty	sc2+1
	ldx	#0
	ldy	#0
sc1	lda	colregs,y
	sta	sc3+1
	iny
	lda	colregs,y
	sta	sc3+2
	iny
sc2	lda	colact,x
sc3	sta COLPM0
	inx
	cpx	#9
	bne	sc1
	rts

colregs
	.word COLPM0,COLPM1,COLPM2,COLPM3,COLPF0,COLPF1,COLPF2,COLPF3,COLBK
colact
	.byte $00,$e0,$e0,$00,$00,$00,$00,$00,$e0
collogoround1
;	ins "Gfx/Suspect_round_50x50_9col.pal"
	ins "Gfx/Suspect_round_50x50_9col_front.pal"
collogoround2
	ins "Gfx/Suspect_round_50x50_9col_back.pal"
colfire
;	.byte $00,$11,$13,$15,$17,$19,$1b,$1e,$1f
;	.byte $00,$71,$73,$75,$77,$79,$7b,$7e,$7f
;	.byte $00,$61,$63,$65,$67,$69,$6b,$6e,$6f
;	.byte $00,$21,$23,$25,$27,$29,$2b,$2e,$2f
	.byte $00,$d1,$d3,$d5,$d7,$d9,$db,$de,$df
colblack
	.byte 0,0,0,0,0,0,0,0,0
collonglogo1
	ins "Gfx/Behold_214x42_9col.pal"
collonglogo2
	.byte $00,$19,$ed,$13,$e2,$18,$0f,$da,$24
.endp


; t32 - colour
.proc col_anim
col_st = 62
open
	ldx	#col_st
	txa
	tay
	iny
lp	jsr	updatecol
	iny
	iny
	dex
	dex
	cpx	#0
	bne	lp
	lda	t32
	sta	COLBK
	rts

openhalf
	ldx	#118
	ldy	#120
lp5	jsr	updatecol
	dex
	dex
	cpx	#62
	bne	lp5
	lda	#0
	sta	COLBK
	rts
	
openfast
	ldx	#60
	txa
	tay
	iny
lp3	jsr	updatecol
	iny
	iny
	iny
	iny
	dex
	dex
	dex
	dex
	cpx	#0
	bne	lp3
	lda	t32
	sta	COLBK
	rts
	
close
	ldx	#2
	ldy	#124
lp2	jsr	updatecol
	dey
	dey
	inx
	inx
	cpx	#62
	bne	lp2
	lda	#0
	sta	COLBK
	rts

closefast
	ldx	#2
	ldy	#124
lp4	jsr	updatecol
	dey
	dey
	dey
	dey
	inx
	inx
	inx
	inx
	cpx	#62
	bne	lp4
	lda	#0
	sta	COLBK
	rts

closehalf
	ldx	#60
	ldy	#122
lp6	jsr	updatecol
	inx
	inx
;	inx
;	inx
	cpx	#124
	bne	lp6
	lda	#0
	sta	COLBK
	rts
	
updatecol
	txa
vs1	cmp	VCOUNT
	bne	vs1
	lda	t32
	sta	COLBK
	tya
vs2	cmp	VCOUNT
	bne	vs2
	lda	#0
	sta	COLBK
	rts
.endp


// This procedure was added thx to Jac!
.proc disableScreen
	ldy #16			;Fade out colors registers
fade_loop
	ldx #8
color_loop
	lda $2c0,x
	and #$0f
	bne not_black
	sta $2c0,x
	beq next_color
not_black
	dec $2c0,x
next_color
	dex
	bne color_loop
	lda $14
	clc
	adc #3
wait	cmp $14
	bne wait
	dey
	bne fade_loop
	sty 559		;Disable screen DMA
	lda $14
wait2	cmp $14		;Wait for screen to be disabled before writing to $BCxx
	beq wait2
	rts
.endp

// ---------------------------------------------------------------------


