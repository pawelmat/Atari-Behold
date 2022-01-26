; ******************************************************
; BEHOLD demo, Kane / Suspect, 08/2021
; Copyright (C) 2021 Pawel Matusz. Distributed under the terms of the GNU GPL-3.0.
;
; Fire effect and related procedures
; ******************************************************

firestart = 2
hscrollshiftadaptive = 1
randomboost = 1

// fire loop ------------------------
.proc burn_round_logo
	lda	timerL			; initialise fire lower timer
	clc
	adc	#10
	sta	tLocal

	lda #14
	sta HSCROL
	
	lda #>scr+firestart	; where from top should the fire effect start sliding down
	sta t4
	sta fire.fireend+1
	mwa	#dlist+1 p1

	// initialise first lines with hscroll shift
	.ifdef hscrollshiftadaptive
	ldx	#firestart+1
hs0
	jsr hscroll_shift_add
	dex
	bne hs0
	.endif

	mwa	#setfirecols nmi.nmi.dliv	; DL interrupt to change screen palette

;	lda	#height+10
	lda	#height+2
	sta t10

fireloop
	jsr	vblank

	// slowly lower the fire effect
	lda	timerL
	cmp	tLocal
	bmi noincfire
	
	dec	t10

	clc
	adc	#10
	sta	tLocal		; set next tick

	lda t4
	cmp #height+>scr-1
	beq	noincfire
	inc t4
	lda t4
	sta fire.fireend+1

	// prepare the new scroll line
	ldx	#width_s-1
	sta	andline1+2
	sta	andline2+2
andline1
	lda	scr,x
	and	#$0f
andline2
	sta	scr,x
	dex
	bne andline1
	
	// hscroll the fire lines
	.ifdef hscrollshiftadaptive
	jsr hscroll_shift_add
	.endif
noincfire

	jsr fire

	lda	t10
	bne	fireloop
	
	vblank
	jsr	nmi.remove_dli
	mwa #dlblank DLISTL					; blank DL
	jsr clear_screen
	rts

; round logo fire DLI procedure
setfirecols
	dec	dlintnr
	bne	sf1
	SetColors cols.colfire
	rts
sf1
	lda	#1
	sta	dlintnr
	SetColors cols.collogoround2
	rts

dlintnr	.byte	1

.endp ; burn_round_logo

//-----------------------------------------------------
.proc fire		; overlay the fire effect on the screen
	ldy	#>scr+1
fire1
	sty f1+2
	sty f5+2
	.ifdef randomboost
	dey
	sty f6+2
	iny
	.endif
	iny
	sty f2+2
	sty f3+2
	sty f4+2
	ldx #width_s-1
fire2				; average of 4 neighbours
f1	lda	scr,x
	inx
f2	adc scr+$100,x
	dex
f3	adc scr+$100,x
	dex
f4	adc scr+$100,x
	lsr
	lsr
	inx
f5	sta	scr,x

	.ifdef randomboost
	bit RANDOM
	bpl	f7
;	bne	f7
finx
	inx		; EA nop, E8 inx
f6	
	sta	scr,x
	dex
f7
	.endif
	
	dex
	bpl	fire2
fireend
	cpy #height+>scr-1
	bne	fire1
	rts
.endp ; fire
