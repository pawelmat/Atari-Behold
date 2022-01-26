; ******************************************************
; BEHOLD demo, Kane / Suspect, 08/2021
;
; The end
; ******************************************************

.proc theend
	jsr clear_screen
	jsr create_dl.no_scroll
	mwa #dlist DLISTL
	mva #$21 DMACTL		; $21 = narrow playfield, $22 = normal
	mva	#$40 PRIOR	; 80: 9 cols (GTIA graphics 10) - 9 arbitrary colours | 40: 16 shades (GTIA graphics 9) - all shades of one background colour | C0: 16 cols (GTIA graphics 11 - all colours of the same luminance)
	mva	#$00 COLBK

	mva	#$90 t32
	jsr	col_anim.open

	lda	#$ea		; nop - no skew in fire
	sta	fire.finx

	lda	timerL			; initialise fire lower timer
	clc
	adc	#50
	sta	tLocal
	lda	#0
	sta	t10


endloop
	ldy	#80			; empirically selected to prevent blinking
vsync
	cpy	VCOUNT
	bne	vsync

	lda	timerL		; count seconds on t10
	cmp	tLocal
	bmi noinctimer
	clc
	adc	#40
	sta	tLocal		; set next tick
	inc	t10
noinctimer

	ldx	#0
eventcheck
	lda text,x		; valid time: from
	inx
	cmp	t10		; A-mem
	bpl	e1
	lda text,x		; valid time: to
	inx
	cmp	t10
	bmi	e2
	
	// print char
	lda text,x		;color, column
	inx
	ldy	text,x		; char
	sty	t8
	stx	t9
	
	tay
	and	#$0f
	asl
	sta scrptr1
	tya
	and #$f0
;	sta COLBK

	// color transition
	cmp	t32
	beq	nocolchange
	sta	t33
	pha
	txa
	pha	
	tya
	pha	
	lda	timerL
	sta	t34
	jsr	col_anim.closefast
	lda	t33
	sta	t32
	jsr	col_anim.openfast
	lda	t34
	sta	timerL
	pla
	tay
	pla
	tax
	pla
nocolchange

	lda	#>scr+height-6
	sta	scrptr1+1

printchar
	ldy t8
	lda	#5
	sta	t7
printline			; print one font pixel line
	lda	charsetEnd,y
	ldx	#0
printdot			; print single font "pixel"
	asl
	bcc	nodot
	pha
	lda	#$ff
scrptr1 = *+1
	sta scr,x
	pla
nodot
	inx
	cpx	#6
	bne	printdot	
	inc scrptr1+1
	iny
	dec	t7
	bne	printline

	ldx t9
	bne	e3
e1	inx
e2	inx
e3	inx
	cpx	#textend-text
	bmi	eventcheck

	jsr fire

	jmp	endloop
	
	rts

text
//	.byte $00, $05, $92, [0]*5, $01, $06, $96, [1]*5, $02, $07, $9A, [2]*5
	.byte $00, $06, $92, [0]*5, $01, $07, $96, [1]*5, $02, $08, $9A, [2]*5
//	.byte $0A, $80, $13, [2]*5, $0B, $80, $17, [3]*5, $0C, $80, $1B, [4]*5
	.byte $0C, $80, $13, [2]*5, $0D, $80, $17, [3]*5, $0E, $80, $1B, [4]*5
textend
	.endp

.local charsetEnd
	.byte $FC, $10, $10, $10, $10	; T
	.byte $84, $84, $fc, $84, $84	; H
	.byte $fc, $80, $fc, $80, $fc	; E
	.byte $C4, $A4, $94, $8C, $84	; N
	.byte $f0, $88, $84, $88, $f0	; D
.endl
