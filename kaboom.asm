; ******************************************************
; BEHOLD demo, Kane / Suspect, 08/2021
; Copyright (C) 2021 Pawel Matusz. Distributed under the terms of the GNU GPL-3.0.
;
; Kaboom effect - based on what I coded for a 256 intro
; ******************************************************

.proc kaboom
seccnt	= t2
letter	= t3
kstab   = data
kscr	= scr
kwidth	= 40
kheight	= 32

	vblank
	mwa #dlblank DLISTL					; blank DL
	jsr clear_screen
	jsr create_dl4.no_scroll
	jsr	hscroll_shift_dl_fixed
	vblank
	mva #$22 DMACTL		; $21 = narrow playfield, $22 = normal
	mva	#$40 PRIOR	; 80: 9 cols (GTIA graphics 10) - 9 arbitrary colours | 40: 16 shades (GTIA graphics 9) - all shades of one background colour | C0: 16 cols (GTIA graphics 11 - all colours of the same luminance)
	mwa #dlist DLISTL

	mva	#$00 COLBK

	lda #$40
	ldx	#kwidth
	ldy	#38		;27, 29, 30
ct1
	pha
	tya
	sta kstab,x
	pla
	adc	#240	;192, 224, 240
	bcc	ct2
	dey
ct2
	dex
	bne	ct1

	mva	#0 letter
	mva	#1 seccnt
;	mva	#2 t7			; speed
	mva	#1 t7			; speed

// main loop
mainloop
	ldx	t7
wt	lda	#100
	jsr vblank.line
	dex
	bne	wt

	jsr	zoomer

	dec	seccnt
	beq	getletter
	jmp	mainloop

getletter
;	mva	#15 seccnt
	mva	#13 seccnt
	ldx	letter
	bmi	fin

ccs	lda text,x		;color
	cmp	#-2
	bne	cc0
	inx
	lda text,x		;delay
	sta	t7
	inx
	jmp	ccs
cc0	sta t4
	cmp	#-1
	bne	cc1
	mva	#4 seccnt
	ldx	#-1
	bne	cc2
cc1	inx
	lda text,x		;column
	sta	t5
	inx
	lda	text,x		; char
	sta	t6
	inx
cc2	stx	letter

printit
	lda	letter
	bmi	mainloop
	
	lda	t4
	and #$f0
	sta COLBK						; set new colour

	lda	t5
	sta scrptr1
	lda	t6
	bne	nospace
;	jsr clear_screen
	jmp	mainloop				; space - don't print
nospace
	sta	printline+1

	lda	#>kscr+kheight/2-5
	sta	scrptr1+1

printchar
	ldy #0
printline			; print one font pixel line
	lda	fontSet+$100,y
	ldx	#7
printdot			; print single font "pixel"
	lsr
	bcc	nodot
	pha
	lda	#$ff
scrptr1 = *+1
	sta kscr,x
	pla
nodot
	dex
	bpl printdot
	inc scrptr1+1
	iny
	cpy	#8
	bne printline
	jmp	mainloop

fin	jsr clear_screen
	rts

.proc zoomer
	lda #>kscr
	sta ptarget1+2
	lda	#kheight-1
	sta t1
pcollumn
	ldx t1
	lda kstab,x
	clc					; ?
	adc #>kscr
	tax
	stx	psource1+2
	stx	psource2+2
	inx
	stx	psource3+2
	dex
	dex
	stx	psource4+2
	ldx	#kwidth-1
pline					; print one pixel line
	lda kstab,x
	tay
psource1
	lda	kscr,y
	iny
psource2
	adc	kscr,y
	dey
psource3
	adc	kscr,y
	iny
psource4
	adc	kscr,y
	lsr
	lsr
ptarget1
	sta kscr,x
	dex
	bne pline

	inc ptarget1+2			; move screen to next line
	dec t1
	bne pcollumn
	rts
.endp
	
text
	.byte $00, 12, ["S"-32]*8, $00, 15, ["U"-32]*8
	.byte $00, 14, ["S"-32]*8, $00, 17, ["P"-32]*8, $00, 13, ["E"-32]*8
	.byte $00, 17, ["C"-32]*8, $00, 17, ["T"-32]*8
	.byte $00, 12, [" "]*8, -2, 1
	.byte $00, 15, ["P"-32]*8, $00, 13, ["R"-32]*8
	.byte $00, 12, ["E"-32]*8, $00, 16, ["S"-32]*8, $00, 16, ["E"-32]*8
	.byte $00, 16, ["N"-32]*8, $00, 15, ["T"-32]*8, $00, 18, ["S"-32]*8, -1
	

.endp

