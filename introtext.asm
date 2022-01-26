; ******************************************************
; BEHOLD demo, Kane / Suspect, 08/2021
; Copyright (C) 2021 Pawel Matusz. Distributed under the terms of the GNU GPL-3.0.
;
; Intro text
; ******************************************************

.proc introtext
	lda #$21
	sta	DMACTL		; $21 = narrow playfield, $22 = normal
	lda	#>fontSet
	sta	CHBASE
	SetColors cols.colblack
	mwa #dlintro DLISTL

	ldx	#0
fi	WaitMs 3		; fade in
	stx	COLPF1
;	jmp fi3
	txa
	and	#8
	bne	fi2
	txa
	and	#7
	asl
	asl
	asl
	asl
	sta	dlintro
	jmp	fi3
fi2
	inx
	txa
	dex
	and	#7
	beq	fi3
	asl
	asl
	asl
	asl
	sta	dlintro+1
fi3
	inx
;introtext.dlintro
	cpx	#16
	bne	fi

	WaitMsS 200

	lda	#150
	sta	t1
choutloop
;	WaitMsS 10
	vblank
	lda	#2
	sta	t2
choutloop2
	mwa	#introtxt ch1+1
	mwa	#introtxt ch5+1
	mwa	#introtxt2 ch2+1
	ldx	#0
chloop
ch1	lda	introtxt,x
	bmi	che
ch2 cmp	introtxt2,x
	beq	ch6
	bpl	ch3
	tay
	iny
	jmp	ch4
ch3	tay
	dey
ch4	tya
ch5	sta	introtxt,x
ch6	inx
	bne	chloop
	inc	ch1+2
	inc	ch2+2
	inc	ch5+2
	jmp	chloop
che
	dec	t2
	bne	choutloop2
	dec	t1
	bne	choutloop

	WaitMsS 50
	lda	#"A"
	sta	introtxt+16
	WaitMsS 40
	lda	#" "
	sta	introtxt+16
	WaitMsS 10
	lda	#"A"
	sta	introtxt+16
	
;	WaitMsS 250
	WaitMsS 200

	ldx	#$0f
	stx	t3					; text color - set in DLI
	lda	#0
	sta	t4					; 0 - first DLI, 1 - second
	vblank
	lda	#" "
	sta	introtxt+82			; remove coma
	mwa	#keepColsDli nmi.nmi.dliv	; DL interrupt to change screen palette
fo	WaitMs 3				; fade out
	stx	t3
	dex
	bpl	fo

	// leave only the BEHOLD word
	vblank
	jsr	nmi.remove_dli		; this should really be done after changing the DL to the next one
	lda	#$02
	sta	dlintro2
	lda	#$41
	sta	dlintro2+2
	mwa	#dlintro dlintro2+3
	lda	#$0f
	sta	COLPF1
	ldx	#32
	lda	#0
cl	sta	introtxt,x			; remove first line of text
	dex
	bne	cl

	rts

keepColsDli
	lda	t4
	bne	k1
	inc	t4
	lda	#$0f
	jmp	k2
k1:	dec	t4
	lda	t3
k2:	sta	COLPF1
	rts
	
;	.align 2,0
dlintro
;	.byte	$10,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$42,a(introtxt)
	.byte	$00,$00,$70,$70,$70,$70,$70,$70,$70,$70,$70,$70,$10,$42,a(introtxt)
dlintro2:
	.byte	$82,$02,$82,$02,$02,$02,$02,$02,$02,$02,$02,$41,a(dlintro)
	
.endp
